"""
doc_discovery.py
================
Portal-level PDF discovery. Reads seed portals from
data/doc_targets/manufacturer_doc_portals.json, finds candidate official-document
URLs (sitemap pass first, then rendered portal pages), and writes a per-brand
inventory JSON. Optionally upserts rows into product_document (status='discovered',
product_slug='_unmapped' until classification assigns real products).

Usage (from pipeline/):
    python3 scripts/doc_discovery.py --brand arri --no-db          # inventory JSON only
    python3 scripts/doc_discovery.py --brand arri --sitemap-only   # no Playwright needed
    python3 scripts/doc_discovery.py --brand arri                  # + upsert to Supabase

Env (pipeline/.env): DATABASE_URL (Neon; only needed without --no-db)
"""

import argparse
import json
import logging
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.parse import urljoin, urlparse

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

PIPELINE_ROOT = Path(__file__).resolve().parents[1]
SEED_PATH = PIPELINE_ROOT / "data" / "doc_targets" / "manufacturer_doc_portals.json"
OUTPUT_DIR = PIPELINE_ROOT / "data" / "doc_targets" / "discovered"

USER_AGENT = "AltoscopeDocBot/1.0 (+darin@altoscope.so)"

# Anchor-text / URL substrings that are near-certainly not spec-relevant docs
EXCLUDE_SUBSTRINGS = [
    "press-release", "sustainability", "annual-report", "career", "privacy",
    "imprint", "legal", "terms-", "gtc", "warranty-registration", "newsletter",
]

PDF_LINK_RE = re.compile(r"https?://[^\s\)\"'<>\]]+\.pdf", re.IGNORECASE)
# e.g. "Sep. 15, 2025 pdf | 328 KB" (ARRI-style anchor metadata)
META_RE = re.compile(r"([A-Z][a-z]{2}\.? \d{1,2}, \d{4})?\s*pdf \| ([\d.]+ [KMG]B)", re.IGNORECASE)


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _is_excluded(url: str, text: str = "") -> bool:
    hay = (url + " " + text).lower()
    return any(s in hay for s in EXCLUDE_SUBSTRINGS)


def _matches_target(url: str, pdf_url_pattern: Optional[str]) -> bool:
    if url.lower().split("?")[0].endswith(".pdf"):
        return True
    if pdf_url_pattern and re.search(pdf_url_pattern, url, re.IGNORECASE):
        return True
    return False


def _parse_anchor_meta(text: str) -> Dict[str, Any]:
    """Pull publish date / size hints out of anchor text where present."""
    meta: Dict[str, Any] = {}
    m = META_RE.search(text or "")
    if m:
        if m.group(1):
            meta["doc_date_hint"] = m.group(1)
        meta["size_hint"] = m.group(2)
    return meta


# ─── Parsers (pure functions — unit-testable without network) ────────────────

def extract_pdf_links_from_html(html: str, base_url: str,
                                pdf_url_pattern: Optional[str] = None) -> List[Dict[str, Any]]:
    """Extract candidate doc links from raw portal HTML via anchor tags."""
    from bs4 import BeautifulSoup  # lazy import
    soup = BeautifulSoup(html, "html.parser")
    out, seen = [], set()
    for a in soup.find_all("a", href=True):
        url = urljoin(base_url, a["href"].strip())
        text = " ".join(a.get_text(" ", strip=True).split())
        if url in seen or not _matches_target(url, pdf_url_pattern) or _is_excluded(url, text):
            continue
        seen.add(url)
        out.append({"url": url, "title": text or None, **_parse_anchor_meta(text)})
    return out


def extract_pdf_links_from_text(text: str,
                                pdf_url_pattern: Optional[str] = None) -> List[Dict[str, Any]]:
    """Fallback extractor for plain-text/markdown content. Handles
    markdown-style '[title](url)' links; otherwise emits bare URLs."""
    out, seen = [], set()
    md_link_re = re.compile(r"\[([^\]]{0,300}?)\]\((https?://[^)\s]+)\)")
    for m in md_link_re.finditer(text):
        title, url = m.group(1).strip(), m.group(2).strip()
        if url in seen or not _matches_target(url, pdf_url_pattern) or _is_excluded(url, title):
            continue
        seen.add(url)
        out.append({"url": url, "title": title or None, **_parse_anchor_meta(title)})
    for m in PDF_LINK_RE.finditer(text):
        url = m.group(0)
        if url in seen or not _matches_target(url, pdf_url_pattern) or _is_excluded(url):
            continue
        seen.add(url)
        out.append({"url": url, "title": None})
    return out


# ─── Fetchers ────────────────────────────────────────────────────────────────

def _fetch_sitemap_urls(origin: str, timeout: int = 20) -> List[str]:
    """Fetch sitemap.xml (following one level of sitemap-index nesting)."""
    import requests  # lazy import
    urls: List[str] = []
    loc_re = re.compile(r"<loc>\s*([^<]+?)\s*</loc>")

    def _get(url: str) -> Optional[str]:
        try:
            r = requests.get(url, timeout=timeout, headers={"User-Agent": USER_AGENT})
            if r.status_code == 200 and ("<urlset" in r.text or "<sitemapindex" in r.text):
                return r.text
        except Exception as e:
            logger.debug("sitemap fetch failed %s: %s", url, e)
        return None

    root = _get(urljoin(origin, "/sitemap.xml"))
    if not root:
        return urls
    locs = loc_re.findall(root)
    if "<sitemapindex" in root:
        for child in locs[:25]:
            body = _get(child)
            if body:
                urls.extend(loc_re.findall(body))
    else:
        urls = locs
    return urls


def _fetch_portal_html(url: str, render: bool, timeout: int = 30) -> Optional[str]:
    if not render:
        import requests  # lazy import
        try:
            r = requests.get(url, timeout=timeout, headers={"User-Agent": USER_AGENT})
            r.raise_for_status()
            # Heuristic: JS shells have almost no anchors
            if r.text.lower().count("<a ") >= 5:
                return r.text
            logger.info("Portal looks JS-rendered (%s) — retrying with Playwright", url)
        except Exception as e:
            logger.warning("Plain fetch failed %s: %s — trying Playwright", url, e)
    from playwright.sync_api import sync_playwright  # lazy import
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(user_agent=USER_AGENT)
        try:
            page.goto(url, wait_until="networkidle", timeout=timeout * 1000)
            html = page.content()
        finally:
            browser.close()
    return html


# ─── Persistence ─────────────────────────────────────────────────────────────

def _upsert_discovered(docs: List[Dict[str, Any]], brand_slug: str) -> int:
    import os
    import psycopg2
    import psycopg2.extras
    from dotenv import load_dotenv
    load_dotenv(dotenv_path=str(PIPELINE_ROOT / ".env"), override=False)
    db_url = os.environ.get("DATABASE_URL") or os.environ.get("SUPABASE_DB_URL")
    if not db_url:
        raise RuntimeError("DATABASE_URL not set (pipeline/.env)")
    inserted = 0
    with psycopg2.connect(db_url) as conn, conn.cursor() as cur:
        for d in docs:
            cur.execute(
                """
                INSERT INTO product_document
                    (brand_slug, product_slug, document_kind, title, url, source_url,
                     status, raw_metadata)
                VALUES (%s, '_unmapped', 'unclassified_pdf', %s, %s, %s, 'discovered', %s)
                ON CONFLICT (product_slug, document_kind, url) DO NOTHING
                """,
                (brand_slug, d.get("title"), d["url"], d.get("source_url"),
                 psycopg2.extras.Json({k: v for k, v in d.items()
                                       if k not in ("url", "title", "source_url")})),
            )
            inserted += cur.rowcount
    return inserted


# ─── Main ────────────────────────────────────────────────────────────────────

def discover_brand(target: Dict[str, Any], sitemap_only: bool, render: bool,
                   delay: float) -> List[Dict[str, Any]]:
    brand = target["brand_slug"]
    pattern = target.get("pdf_url_pattern")
    docs: List[Dict[str, Any]] = []
    seen: set = set()

    # Pass 1: sitemaps (cheap, often complete)
    origins = {f"{urlparse(p['url']).scheme}://{urlparse(p['url']).netloc}"
               for p in target["portals"]}
    for origin in sorted(origins):
        for url in _fetch_sitemap_urls(origin):
            if url not in seen and _matches_target(url, pattern) and not _is_excluded(url):
                seen.add(url)
                docs.append({"url": url, "title": None, "source_url": origin + "/sitemap.xml",
                             "via": "sitemap"})
        time.sleep(delay)
    logger.info("[%s] sitemap pass: %d candidates", brand, len(docs))

    # Pass 2: portal pages
    if not sitemap_only:
        for portal in target["portals"]:
            html = _fetch_portal_html(portal["url"], render=render)
            if not html:
                logger.warning("[%s] no content from portal %s", brand, portal["url"])
                continue
            found = extract_pdf_links_from_html(html, portal["url"], pattern)
            new = [d for d in found if d["url"] not in seen]
            for d in new:
                seen.add(d["url"])
                d.update({"source_url": portal["url"], "via": "portal",
                          "portal_kind": portal.get("kind")})
            docs.extend(new)
            logger.info("[%s] portal %s: %d links (%d new)",
                        brand, portal["url"], len(found), len(new))
            time.sleep(delay)
    return docs


def main() -> int:
    parser = argparse.ArgumentParser(description="Discover official manufacturer doc PDFs")
    parser.add_argument("--brand", default=None, help="Filter by brand slug")
    parser.add_argument("--seed", default=str(SEED_PATH))
    parser.add_argument("--sitemap-only", action="store_true")
    parser.add_argument("--render", action="store_true",
                        help="Force Playwright rendering for portal pages")
    parser.add_argument("--no-db", action="store_true",
                        help="Write inventory JSON only; skip product_document upsert")
    parser.add_argument("--delay", type=float, default=2.0)
    args = parser.parse_args()

    seed = json.loads(Path(args.seed).read_text())
    targets = [t for t in seed["targets"]
               if not args.brand or t["brand_slug"] == args.brand]
    if not targets:
        logger.error("No targets match brand=%s", args.brand)
        return 1

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    total = 0
    for target in targets:
        brand = target["brand_slug"]
        docs = discover_brand(target, args.sitemap_only, args.render, args.delay)
        out_path = OUTPUT_DIR / f"{brand}_docs.json"
        out_path.write_text(json.dumps(
            {"generated_at": _utc_now_iso(), "brand_slug": brand,
             "count": len(docs), "docs": docs}, indent=2))
        logger.info("[%s] wrote %d docs → %s", brand, len(docs), out_path)
        total += len(docs)
        if not args.no_db and docs:
            n = _upsert_discovered(docs, brand)
            logger.info("[%s] upserted %d new product_document rows", brand, n)
    logger.info("Done. %d candidate docs across %d brand(s)", total, len(targets))
    return 0


if __name__ == "__main__":
    sys.exit(main())
