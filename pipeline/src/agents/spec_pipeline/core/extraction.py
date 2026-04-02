import json
import logging
import random
import re
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from urllib.parse import urljoin, urlparse, urlunparse

from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

logger = logging.getLogger(__name__)


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _normalize_url(url: str) -> str:
    parsed = urlparse(url)
    # strip fragments (e.g. #toreviews) for canonical identity
    return urlunparse(parsed._replace(fragment=""))


def _slug_from_url(url: str) -> str:
    parsed = urlparse(url)
    parts = [p for p in parsed.path.split("/") if p]
    return parts[-1] if parts else "unknown"


@dataclass
class ExtractionConfig:
    brand_slug: str
    product_type: str
    headless: bool = True
    max_products: Optional[int] = None
    # If set, attempt to read HTML from {html_cache_dir}/{slug}.html before fetching over the web.
    html_cache_dir: Optional[str] = None
    # If True, do not fetch over the web when cache is missing (record an error instead).
    cache_only: bool = False
    raw_html_dir: str = "data/extractions/raw_html"
    output_path: str = "data/extractions/extractions.json"
    # Completeness heuristics (used to decide if we likely need PDF fallback)
    min_sections_ok: int = 5
    min_attributes_ok: int = 40
    # Delay controls (seconds)
    delay_min: float = 2.0
    delay_max: float = 5.0
    long_break_every: int = 10
    long_break_min: float = 8.0
    long_break_max: float = 12.0
    max_retries: int = 3


class BaseExtractor:
    def __init__(self, config: ExtractionConfig):
        self.config = config

    def extract(self, product_urls: List[str]) -> Dict[str, Any]:
        raise NotImplementedError


class CanonCameraExtractor(BaseExtractor):
    """
    Extraction-only: fetch raw HTML for each product page and parse Canon tech specs.
    """

    def _random_delay(self, is_long_break: bool = False) -> None:
        if is_long_break:
            time.sleep(random.uniform(self.config.long_break_min, self.config.long_break_max))
        else:
            time.sleep(random.uniform(self.config.delay_min, self.config.delay_max))

    def _save_raw_html(self, slug: str, html: str) -> str:
        out_dir = Path(self.config.raw_html_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
        path = out_dir / f"{slug}.html"
        path.write_text(html, encoding="utf-8")
        return str(path)

    def _read_cached_html(self, slug: str) -> Tuple[Optional[str], Optional[str], Optional[str]]:
        """
        Returns (html, path, error)
        """
        if not self.config.html_cache_dir:
            return None, None, None

        cache_path = Path(self.config.html_cache_dir) / f"{slug}.html"
        if not cache_path.exists():
            return None, None, "cache_miss"

        try:
            html = cache_path.read_text(encoding="utf-8")
            if "Access Denied" in html or "<title>Access Denied</title>" in html:
                return None, str(cache_path), "cache_access_denied"
            return html, str(cache_path), None
        except Exception as e:
            return None, str(cache_path), f"cache_read_error:{e}"

    def _fetch_page_html(self, page, url: str) -> Tuple[Optional[str], Optional[str]]:
        """
        Returns (html, error).
        """
        last_error: Optional[str] = None
        for attempt in range(1, self.config.max_retries + 1):
            try:
                page.goto(url, wait_until="domcontentloaded", timeout=30000)
                self._random_delay()

                # If there's a specs tab, click it (best-effort)
                try:
                    specs_tab = page.get_by_text("Specifications", exact=False).first
                    if specs_tab.is_visible():
                        specs_tab.click()
                        self._random_delay()
                except Exception:
                    pass

                html = page.content()
                if "Access Denied" in html or "<title>Access Denied</title>" in html:
                    return None, "access_denied"

                return html, None
            except Exception as e:
                last_error = f"attempt_{attempt}_error:{e}"
                # exponential-ish backoff
                time.sleep(min(10, 2 ** (attempt - 1)))
        return None, last_error

    def _parse_canon_tech_specs(self, soup: BeautifulSoup, base_url: str) -> List[Dict[str, Any]]:
        """
        Returns manufacturer_sections[] shaped like:
        [{section_name, attributes:[{raw_key, raw_value, context?}]}]
        """
        tech_spec_div = soup.find("div", id="tech-spec-data")
        if not tech_spec_div:
            return []

        sections: List[Dict[str, Any]] = []
        for group in tech_spec_div.find_all("h3"):
            section_name = group.get_text(strip=True)
            container = group.find_parent("div", class_="tech-spec")
            if not container:
                continue

            attrs = container.find_all("div", class_="tech-spec-attr")
            section_attrs: List[Dict[str, Any]] = []

            for i in range(0, len(attrs), 2):
                if i + 1 >= len(attrs):
                    continue
                raw_key = attrs[i].get_text(strip=True)
                val_div = attrs[i + 1]

                table = val_div.find("table")
                if table is not None:
                    section_attrs.append(
                        {
                            "raw_key": raw_key,
                            "raw_value": "[table]",
                            "context": {
                                "table_html": str(table),
                                "text_fallback": val_div.get_text(" ", strip=True),
                            },
                        }
                    )
                else:
                    raw_value = val_div.get_text(" ", strip=True)
                    record: Dict[str, Any] = {"raw_key": raw_key, "raw_value": raw_value}

                    # If this value contains a PDF link (e.g. "View Full Technical Specs PDF"), capture it.
                    a = val_div.find("a", href=True)
                    if a and a.get("href"):
                        href = a.get("href")
                        pdf_url = urljoin(base_url, href)
                        if pdf_url.lower().endswith(".pdf") or "pdf" in (pdf_url.lower()):
                            record["context"] = {"pdf_url": pdf_url}

                    section_attrs.append(record)

            sections.append({"section_name": section_name, "attributes": section_attrs})

        return sections

    def _parse_canon_product_images(self, soup: BeautifulSoup, base_url: str) -> List[Dict[str, Any]]:
        """
        Extract product image URLs from a Canon shop product page.

        Returns images[] shaped like:
        [{"url": "...", "kind": "primary|gallery|og", "sort_order": int?, "source": {...}, "raw_metadata": {...}}]
        """
        urls: List[str] = []
        primary_url: Optional[str] = None

        def _add(u: Optional[str]) -> None:
            if not u:
                return
            u2 = urljoin(base_url, u)
            # canonicalize fragments only (keep query params like fmt=webp-alpha)
            u2 = _normalize_url(u2)
            if u2 not in urls:
                urls.append(u2)

        def _set_primary(u: Optional[str]) -> None:
            nonlocal primary_url
            if not u:
                return
            u2 = urljoin(base_url, u)
            u2 = _normalize_url(u2)
            primary_url = u2
            _add(u2)

        # 0) Canon gallery placeholder (often the main/primary image)
        placeholder = soup.select_one("img.gallery-placeholder__image")
        if placeholder and placeholder.get("src"):
            _set_primary(placeholder.get("src"))

        # 0b) Active fotorama stage frame (sometimes exposes href to the primary image)
        active = soup.select_one(".fotorama__stage__frame.fotorama__active")
        if active is not None:
            if active.get("href"):
                _set_primary(active.get("href"))
            else:
                active_img = active.select_one("img.fotorama__img")
                if active_img and active_img.get("src"):
                    _set_primary(active_img.get("src"))

        # 1) og:image (usually primary)
        og = soup.find("meta", attrs={"property": "og:image"})
        if og and og.get("content"):
            if primary_url is None:
                _set_primary(og.get("content"))
            else:
                _add(og.get("content"))

        # 2) JSON-LD Product.image (often primary)
        for s in soup.find_all("script", attrs={"type": "application/ld+json"}):
            txt = (s.string or s.get_text() or "").strip()
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
                if isinstance(img, str):
                    if primary_url is None:
                        _set_primary(img)
                    else:
                        _add(img)
                elif isinstance(img, list):
                    for x in img:
                        if isinstance(x, str):
                            _add(x)

        # 3) Fotorama gallery frames (usually full gallery)
        for img in soup.select(".fotorama__stage__frame img.fotorama__img"):
            _add(img.get("src"))

        # 4) Any explicit <img> tags pointing at scene7 canon assets (fallback)
        for img in soup.find_all("img", src=True):
            src = img.get("src") or ""
            if "s7d1.scene7.com" in src and "/is/image/canon/" in src:
                _add(src)

        out: List[Dict[str, Any]] = []
        for i, u in enumerate(urls):
            kind = "primary" if (primary_url and u == primary_url) else "gallery"
            out.append(
                {
                    "url": u,
                    "kind": kind,
                    "sort_order": i,
                    "source": {"type": "web", "url": base_url},
                    "raw_metadata": {},
                }
            )
        return out

    def _parse_canon_msrp_usd(self, soup: BeautifulSoup) -> Optional[float]:
        """
        Best-effort MSRP/price extraction from Canon shop HTML.

        Preferred source: JSON-LD (Product/Offer.price).
        Fallback: price-box DOM (data-price-amount).
        """

        def _as_float(v: Any) -> Optional[float]:
            if v is None:
                return None
            if isinstance(v, (int, float)):
                return float(v)
            if isinstance(v, str):
                s = v.strip()
                if not s:
                    return None
                # "$6,799.00" -> "6799.00"
                s = re.sub(r"[^0-9.]", "", s)
                try:
                    return float(s)
                except Exception:
                    return None
            return None

        # 1) JSON-LD
        for s in soup.find_all("script", attrs={"type": "application/ld+json"}):
            txt = (s.string or s.get_text() or "").strip()
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

                offers = node.get("offers")
                offer_nodes: List[Dict[str, Any]] = []
                if isinstance(offers, dict):
                    offer_nodes = [offers]
                elif isinstance(offers, list):
                    offer_nodes = [o for o in offers if isinstance(o, dict)]

                for offer in offer_nodes:
                    currency = (offer.get("priceCurrency") or "").strip().upper()
                    price = _as_float(offer.get("price"))
                    if price is not None and (not currency or currency == "USD"):
                        return price

                # Some pages put "price" at the top-level node
                price = _as_float(node.get("price"))
                if price is not None:
                    return price

        # 2) DOM: Magento price box (avoid cart subtotal "$0.00")
        price_span = soup.select_one(
            ".product-info-price .price-box [data-price-type='finalPrice'][data-price-amount]"
        )
        if price_span and price_span.get("data-price-amount"):
            return _as_float(price_span.get("data-price-amount"))

        # 3) DOM fallback: any visible product-info-price .price text
        price_text = soup.select_one(".product-info-price .price-box .price")
        if price_text:
            return _as_float(price_text.get_text(strip=True))

        return None

    def _compute_completeness(self, manufacturer_sections: List[Dict[str, Any]], errors: List[str]) -> Dict[str, Any]:
        total_sections = len(manufacturer_sections)
        total_attributes = 0
        pdf_urls_found = 0
        tables_found = 0

        for section in manufacturer_sections:
            attrs = section.get("attributes", []) or []
            total_attributes += len(attrs)
            for a in attrs:
                if a.get("raw_value") == "[table]":
                    tables_found += 1
                ctx = a.get("context") or {}
                if ctx.get("pdf_url"):
                    pdf_urls_found += 1

        meets_min_sections = total_sections >= self.config.min_sections_ok
        meets_min_attributes = total_attributes >= self.config.min_attributes_ok
        needs_pdf = bool(errors) or (not meets_min_sections) or (not meets_min_attributes)

        # crude 0..1 score; improves later when we have required tier-1 keys
        score = 0.0
        score += 0.5 if meets_min_sections else 0.0
        score += 0.5 if meets_min_attributes else 0.0

        return {
            "total_sections": total_sections,
            "total_attributes": total_attributes,
            "tables_found": tables_found,
            "pdf_urls_found": pdf_urls_found,
            "meets_min_sections": meets_min_sections,
            "meets_min_attributes": meets_min_attributes,
            "needs_pdf": needs_pdf,
            "score": score,
        }

    def extract(self, product_urls: List[str]) -> Dict[str, Any]:
        urls = [_normalize_url(u) for u in product_urls]
        if self.config.max_products:
            urls = urls[: self.config.max_products]

        items: List[Dict[str, Any]] = []

        with sync_playwright() as p:
            browser = p.chromium.launch(
                headless=self.config.headless,
                args=[
                    "--no-sandbox",
                    "--disable-blink-features=AutomationControlled",
                    "--disable-dev-shm-usage",
                ],
            )
            page = browser.new_page()
            page.set_viewport_size({"width": 1920, "height": 1080})
            page.set_extra_http_headers(
                {
                    "User-Agent": (
                        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                        "AppleWebKit/537.36 (KHTML, like Gecko) "
                        "Chrome/120.0.0.0 Safari/537.36"
                    ),
                    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                    "Accept-Language": "en-US,en;q=0.9",
                    "Upgrade-Insecure-Requests": "1",
                }
            )

            try:
                for idx, url in enumerate(urls, start=1):
                    slug = _slug_from_url(url)
                    logger.info("Extracting (%s/%s): %s", idx, len(urls), url)

                    # Prefer cached HTML (if provided)
                    cached_html, cached_path, cache_err = self._read_cached_html(slug)
                    if cached_html is not None:
                        html, err = cached_html, None
                        raw_html_path = cached_path
                    else:
                        if self.config.cache_only and self.config.html_cache_dir:
                            errors = [cache_err or "cache_miss"]
                            items.append(
                                {
                                    "product_url": url,
                                    "product_slug": slug,
                                    "raw_html_path": cached_path,
                                    "manufacturer_sections": [],
                                    "errors": errors,
                                    "completeness": self._compute_completeness([], errors),
                                    "scraped_at": _utc_now_iso(),
                                }
                            )
                            continue

                        html, err = self._fetch_page_html(page, url)
                        raw_html_path = None
                    if err or html is None:
                        errors = [err or "unknown_error"]
                        items.append(
                            {
                                "product_url": url,
                                "product_slug": slug,
                                "raw_html_path": None,
                                "manufacturer_sections": [],
                                "errors": errors,
                                "completeness": self._compute_completeness([], errors),
                                "scraped_at": _utc_now_iso(),
                            }
                        )
                        continue

                    # If we fetched from web, save an artifact copy; if using cache, keep cached_path.
                    if raw_html_path is None:
                        raw_html_path = self._save_raw_html(slug, html)
                    soup = BeautifulSoup(html, "html.parser")
                    manufacturer_sections = self._parse_canon_tech_specs(soup, base_url=url)
                    images = self._parse_canon_product_images(soup, base_url=url)
                    msrp_usd = self._parse_canon_msrp_usd(soup)
                    errors: List[str] = []

                    items.append(
                        {
                            "product_url": url,
                            "product_slug": slug,
                            "raw_html_path": raw_html_path,
                            "manufacturer_sections": manufacturer_sections,
                            "images": images,
                            "msrp_usd": msrp_usd,
                            "errors": errors,
                            "completeness": self._compute_completeness(manufacturer_sections, errors),
                            "scraped_at": _utc_now_iso(),
                        }
                    )

                    if idx % self.config.long_break_every == 0:
                        self._random_delay(is_long_break=True)
                    else:
                        self._random_delay()
            finally:
                browser.close()

        return {
            "brand": self.config.brand_slug,
            "product_type": self.config.product_type,
            "generated_at": _utc_now_iso(),
            "total_items": len(items),
            "items": items,
        }


def extract(config: ExtractionConfig, product_urls: List[str]) -> Dict[str, Any]:
    brand = (config.brand_slug or "").lower()
    if brand == "canon" and config.product_type in {"camera", "lens"}:
        return CanonCameraExtractor(config).extract(product_urls)
    raise ValueError(f"No extractor implementation for brand={config.brand_slug} product_type={config.product_type}")

