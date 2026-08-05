"""
scrape_missing_images.py
========================
Fetches manufacturer product pages for products that are missing a
primary_image_url and updates the cloud DB.

Strategy (in priority order for each page):
  1. og:image meta tag  — works on almost every brand site
  2. JSON-LD Product.image
  3. Brand-specific CSS selectors (fallback for known sites)

Playwright is used instead of requests so JS-rendered pages (Blackmagic,
RED, etc.) render before we parse.

Usage:
    python3 scripts/scrape_missing_images.py [--dry-run] [--brand SLUG]

Requires pipeline venv to be active (playwright, beautifulsoup4, psycopg2).
"""

import argparse
import json
import logging
import re
import sys
import time
from pathlib import Path
from typing import Optional
from urllib.parse import urljoin, urlparse

import psycopg2
import psycopg2.extras
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from playwright.sync_api import sync_playwright

# ── Env ───────────────────────────────────────────────────────────────────────

repo_root = Path(__file__).resolve().parents[2]
for p in [repo_root / "pipeline" / ".env", repo_root / ".env"]:
    if p.exists():
        load_dotenv(dotenv_path=str(p), override=False)
        break

import os
DB_URL = os.environ.get("DATABASE_URL", "") or os.environ.get("SUPABASE_DB_URL", "")
if not DB_URL:
    sys.exit("DATABASE_URL not set")

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

# ── Hardcoded image URLs ──────────────────────────────────────────────────────
# Used when scraping is blocked or the DB points to an article/landing page.
# Map product slug → direct image URL.

IMAGE_OVERRIDES: dict[str, str] = {
    # Sony VENICE 2 — pro.sony is geo-restricted; image URL confirmed manually
    "sony-venice-2": "https://pro.sony/s3/2021/10/31115504/VENICE-2_hero-image_without-Netflix.png",
    "venice-2":      "https://pro.sony/s3/2021/10/31115504/VENICE-2_hero-image_without-Netflix.png",
}

# ── URL overrides ─────────────────────────────────────────────────────────────
# Some DB manufacturer_urls point to articles/landing pages rather than the
# canonical product page.  Map product slug → better URL.

URL_OVERRIDES: dict[str, str] = {
    # Anton Bauer CINE 90 — homepage only in DB; direct product page
    "anton-bauer-cine-90": "https://www.antonbauer.com/en/products/cine-90",
}

# ── Brand-specific image selector fallbacks ───────────────────────────────────
# Keyed by brand slug.  Each entry is tried in order; return the first hit.

BRAND_SELECTORS: dict[str, list[str]] = {
    "canon": [
        "img.gallery-placeholder__image",
        ".fotorama__stage__frame img.fotorama__img",
    ],
    "arri": [
        ".stage-module__image img",
        ".hero__image img",
        ".product-hero img",
    ],
    "blackmagic-design": [
        ".product-hero-image img",
        "section.product-header img",
        "img[class*='hero']",
    ],
    "red": [
        ".hero-image img",
        "img[class*='hero']",
        ".product-image img",
    ],
    "sony": [
        ".pdp-hero-image img",
        "img[class*='hero']",
        ".sony-hero img",
    ],
    "cooke": [
        ".product-hero img",
        ".banner-image img",
        "img[class*='product']",
    ],
    "zeiss": [
        ".product-stage img",
        ".hero-image img",
        "img[class*='product']",
    ],
    "angenieux": [
        ".product-image img",
        ".hero img",
        "img[class*='product']",
    ],
}

# ── Image extraction ──────────────────────────────────────────────────────────

def _abs(url: str, base: str) -> str:
    return urljoin(base, url)


def _clean(url: str) -> str:
    """Strip query strings from image URLs (keeps canonical CDN paths clean)."""
    parsed = urlparse(url)
    # Keep query strings for sites that use them as image params (scene7, etc.)
    # Only strip fragment
    return parsed._replace(fragment="").geturl()


def _extract_og_image(soup: BeautifulSoup, base_url: str) -> Optional[str]:
    og = soup.find("meta", attrs={"property": "og:image"})
    if og and og.get("content"):
        return _abs(og["content"].strip(), base_url)
    return None


def _extract_json_ld_image(soup: BeautifulSoup, base_url: str) -> Optional[str]:
    for tag in soup.find_all("script", attrs={"type": "application/ld+json"}):
        txt = (tag.string or tag.get_text() or "").strip()
        if not txt:
            continue
        try:
            data = json.loads(txt)
        except Exception:
            continue
        nodes = data if isinstance(data, list) else [data]
        for node in nodes:
            if not isinstance(node, dict):
                continue
            img = node.get("image")
            if isinstance(img, str) and img.startswith("http"):
                return img
            if isinstance(img, list) and img:
                first = img[0]
                if isinstance(first, str):
                    return first
                if isinstance(first, dict) and first.get("url"):
                    return first["url"]
    return None


def _extract_brand_selector(soup: BeautifulSoup, base_url: str, brand_slug: str) -> Optional[str]:
    for selector in BRAND_SELECTORS.get(brand_slug, []):
        el = soup.select_one(selector)
        if el:
            src = el.get("src") or el.get("data-src") or el.get("data-lazy-src")
            if src:
                return _abs(src, base_url)
    return None


def _extract_canon_scene7(soup: BeautifulSoup, base_url: str) -> Optional[str]:
    """Canon-specific: pull the scene7 CDN image used in the product gallery."""
    for img in soup.find_all("img", src=True):
        src = img.get("src", "")
        if "s7d1.scene7.com" in src and "/is/image/canon/" in src:
            return _abs(src, base_url)
    return None


def _extract_blackmagic_hero(url: str) -> Optional[str]:
    """
    Blackmagic pages don't expose og:image.  Their hero images follow a
    consistent CDN pattern derived from the product slug in the URL.
    e.g. /products/blackmagicursacine → hero-lg.jpg
    """
    path = urlparse(url).path.rstrip("/")
    product_id = path.split("/")[-1]
    if product_id:
        return (
            f"https://images.blackmagicdesign.com/images/products/"
            f"{product_id}/landing/hero/hero-lg.jpg"
        )
    return None


def _extract_arri_cdn_img(soup: BeautifulSoup) -> Optional[str]:
    """
    ARRI pages that lack og:image still expose ARRI CDN images in <img> tags.
    Prefer landscape_ratio images (they're the product hero crops).
    """
    candidates = []
    for img in soup.find_all("img", src=True):
        src = img.get("src", "")
        if "arri.com/resource/image" in src:
            candidates.append(src)
    if not candidates:
        return None
    # Prefer landscape_ratio2x1 (hero format), fall back to any
    for src in candidates:
        if "landscape_ratio2x1" in src:
            return src
    return candidates[0]


def find_primary_image(html: str, url: str, brand_slug: str) -> Optional[str]:
    soup = BeautifulSoup(html, "html.parser")

    # 1. og:image — most reliable across all brands
    img = _extract_og_image(soup, url)
    if img:
        log.debug("og:image → %s", img)
        return _clean(img)

    # 2. JSON-LD
    img = _extract_json_ld_image(soup, url)
    if img:
        log.debug("json-ld → %s", img)
        return _clean(img)

    # 3. Brand selectors
    img = _extract_brand_selector(soup, url, brand_slug)
    if img:
        log.debug("brand-selector → %s", img)
        return _clean(img)

    # 4. Canon scene7 CDN fallback
    if brand_slug == "canon":
        img = _extract_canon_scene7(soup, url)
        if img:
            log.debug("canon-scene7 → %s", img)
            return _clean(img)

    # 5. Blackmagic hero CDN pattern
    if brand_slug == "blackmagic-design":
        img = _extract_blackmagic_hero(url)
        if img:
            log.debug("blackmagic-hero → %s", img)
            return img

    # 6. ARRI CDN image in <img> tags (for pages without og:image)
    if brand_slug == "arri":
        img = _extract_arri_cdn_img(soup)
        if img:
            log.debug("arri-cdn-img → %s", img)
            return _clean(img)

    return None


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Find images but don't update DB")
    parser.add_argument("--brand", default=None, help="Only process this brand slug")
    args = parser.parse_args()

    conn = psycopg2.connect(DB_URL)

    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        brand_filter = "AND b.slug = %s" if args.brand else ""
        params = (args.brand,) if args.brand else ()
        cur.execute(f"""
            SELECT p.id, p.slug, p.full_name, p.manufacturer_url,
                   b.slug AS brand_slug
            FROM product p
            JOIN brand b ON b.id = p.brand_id
            WHERE p.is_active = true
              AND p.primary_image_url IS NULL
              {brand_filter}
            ORDER BY b.slug, p.full_name
        """, params)
        rows = cur.fetchall()

    log.info("Found %d products missing images", len(rows))

    results: list[tuple[str, str]] = []   # (product_id, image_url)
    failed: list[str] = []

    with sync_playwright() as pw:
        browser = pw.chromium.launch(
            headless=True,
            args=["--no-sandbox", "--disable-dev-shm-usage",
                  "--disable-blink-features=AutomationControlled"],
        )
        ctx = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/122.0.0.0 Safari/537.36"
            ),
            viewport={"width": 1920, "height": 1080},
            extra_http_headers={
                "Accept-Language": "en-US,en;q=0.9",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            },
        )
        page = ctx.new_page()

        # Track which URLs we've already fetched so we don't re-fetch the same
        # page for every Cooke S4/i variant.
        url_html_cache: dict[str, str] = {}

        for i, row in enumerate(rows, 1):
            product_id: str = row["id"]
            product_slug: str = row["slug"]
            full_name: str = row["full_name"]
            brand_slug: str = row["brand_slug"]
            raw_url: str = row["manufacturer_url"] or ""

            fetch_url = URL_OVERRIDES.get(product_slug) or URL_OVERRIDES.get(raw_url) or raw_url

            # Hardcoded image override — no scraping needed
            if product_slug in IMAGE_OVERRIDES:
                img_url = IMAGE_OVERRIDES[product_slug]
                log.info("[%d/%d] %s — hardcoded image: %s", i, len(rows), full_name, img_url)
                results.append((product_id, img_url))
                continue

            if not fetch_url or fetch_url == "https://www.antonbauer.com":
                log.warning("[%d/%d] %-40s — no usable URL, skipping", i, len(rows), full_name)
                failed.append(full_name)
                continue

            log.info("[%d/%d] %s (%s)", i, len(rows), full_name, fetch_url)

            # Use cached HTML if we already fetched this URL (Cooke S4/i etc.)
            if fetch_url in url_html_cache:
                html = url_html_cache[fetch_url]
                log.debug("  (using cached HTML for %s)", fetch_url)
            else:
                # JS-heavy brands need networkidle; others use domcontentloaded
                js_heavy = brand_slug in ("blackmagic-design", "canon", "sony", "red")
                wait_until = "networkidle" if js_heavy else "domcontentloaded"
                try:
                    page.goto(fetch_url, wait_until=wait_until, timeout=30_000)
                    page.wait_for_timeout(2_000)
                    html = page.content()
                    url_html_cache[fetch_url] = html
                except Exception as e:
                    log.error("  Failed to load page: %s", e)
                    failed.append(full_name)
                    time.sleep(2)
                    continue

            img_url = find_primary_image(html, fetch_url, brand_slug)

            if img_url:
                log.info("  ✓ %s", img_url)
                results.append((product_id, img_url))
            else:
                log.warning("  ✗ No image found")
                failed.append(full_name)

            # Polite delay between different domains
            time.sleep(1.5)

        browser.close()

    # ── Write to DB ───────────────────────────────────────────────────────────
    log.info("\n--- Summary ---")
    log.info("Found images: %d / %d", len(results), len(rows))
    if failed:
        log.info("No image found for: %s", ", ".join(failed))

    if args.dry_run:
        log.info("[DRY RUN] Would update %d rows", len(results))
        for pid, url in results:
            log.info("  %s → %s", pid, url)
        conn.close()
        return 0

    if results:
        with conn:
            with conn.cursor() as cur:
                psycopg2.extras.execute_batch(
                    cur,
                    """UPDATE product
                       SET primary_image_url = %s
                       WHERE id = %s AND primary_image_url IS NULL""",
                    [(url, pid) for pid, url in results],
                    page_size=100,
                )
        log.info("Updated %d product rows in DB", len(results))

    conn.close()
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
