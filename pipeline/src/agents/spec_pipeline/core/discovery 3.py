import json
import logging
import random
import re
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Dict, Iterable, List, Optional, Tuple
from urllib.parse import urljoin, urlparse, urlunparse

from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

logger = logging.getLogger(__name__)


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _normalize_product_url(url: str) -> Tuple[str, bool]:
    """
    Normalize product URLs for dedupe:
    - strip fragments like #toreviews
    """
    parsed = urlparse(url)
    if parsed.fragment:
        normalized = urlunparse(parsed._replace(fragment=""))
        return normalized, True
    return url, False


def _path_slug(url: str) -> str:
    parsed = urlparse(url)
    parts = [p for p in parsed.path.split("/") if p]
    return parts[-1] if parts else ""


def _is_valid_product_url(
    url: str,
    product_url_pattern: str,
    exclude_slug_substrings: Optional[List[str]] = None,
) -> Tuple[bool, Optional[str]]:
    if not url:
        return False, "empty"

    parsed = urlparse(url)
    lowered = url.lower()

    if product_url_pattern not in lowered:
        return False, "missing_product_pattern"

    if "refurbished" in lowered:
        return False, "refurbished"

    # Reject query strings entirely for canonical product URLs
    if parsed.query:
        return False, "has_query"

    # We should not emit fragment URLs; these should be normalized away upstream.
    if parsed.fragment:
        return False, "has_fragment"

    slug = _path_slug(url).lower()
    for sub in exclude_slug_substrings or []:
        if sub and sub.lower() in slug:
            return False, f"excluded_slug_contains:{sub.lower()}"

    return True, None


def _dedupe_preserve_order(urls: Iterable[str]) -> List[str]:
    seen = set()
    out: List[str] = []
    for u in urls:
        if u in seen:
            continue
        seen.add(u)
        out.append(u)
    return out


@dataclass
class DiscoveryConfig:
    brand_slug: str
    product_type: str
    category_slug: str
    listing_urls: List[str]
    product_url_pattern: str = "/shop/p/"
    # Product URL filtering
    exclude_slug_substrings: Optional[List[str]] = None
    headless: bool = True
    max_products: Optional[int] = None
    # Pagination controls
    max_pages: int = 30  # URL pagination pages (?p=2..)
    max_load_more_clicks: int = 30
    stop_after_consecutive_empty_pages: int = 3
    # Delay controls (seconds)
    delay_min: float = 2.0
    delay_max: float = 5.0
    long_break_every: int = 10
    long_break_min: float = 8.0
    long_break_max: float = 12.0
    # Output path (repo-root relative)
    output_path: str = "data/url_lists/canon_camera_urls.json"


def validate_discovery_output(payload: Dict[str, Any]) -> Tuple[bool, List[str]]:
    errors: List[str] = []
    urls = payload.get("urls", [])
    pattern = payload.get("product_url_pattern", "/shop/p/")

    if not isinstance(urls, list):
        errors.append("urls must be a list")
        return False, errors

    for u in urls:
        if pattern not in u:
            errors.append(f"URL missing pattern {pattern}: {u}")
        if "?" in u:
            errors.append(f"URL contains query string (should be excluded): {u}")
        if "#" in u:
            errors.append(f"URL contains fragment (should be stripped): {u}")
        if "refurbished" in u.lower():
            errors.append(f"URL contains refurbished (should be excluded): {u}")

    total_urls = payload.get("total_urls")
    if isinstance(total_urls, int) and total_urls != len(urls):
        errors.append(f"total_urls ({total_urls}) != len(urls) ({len(urls)})")

    return len(errors) == 0, errors


class BaseDiscovery:
    def __init__(self, config: DiscoveryConfig):
        self.config = config

    def discover(self) -> Dict[str, Any]:
        raise NotImplementedError


class CanonDiscovery(BaseDiscovery):
    """
    Canon shop discovery with URL pagination first (?p=2..),
    and fallback to "Load More" button behavior if needed.
    Heavily influenced by src/website_scrapers/canon_scraper.py.
    """

    LOAD_MORE_SELECTORS = [
        'button[class*="amscroll-load-button"]',
        'button[class*="load-more"]',
        'button[class*="loadmore"]',
        'button:has-text("Load more")',
        'button:has-text("Load More")',
        '[class*="amscroll"]:has-text("Load more")',
        '[class*="amscroll"]:has-text("Load More")',
    ]

    def _random_delay(self, is_long_break: bool = False) -> None:
        if is_long_break:
            delay = random.uniform(self.config.long_break_min, self.config.long_break_max)
        else:
            delay = random.uniform(self.config.delay_min, self.config.delay_max)
        time.sleep(delay)

    def _extract_product_links(self, soup: BeautifulSoup, base_url: str, stats: Dict[str, Any]) -> List[str]:
        product_urls: List[str] = []

        # Prefer Canon's typical selector when present
        for link in soup.find_all("a", class_=re.compile(r"product-item-link", re.I)):
            href = link.get("href")
            if not href:
                continue
            full_url = urljoin(base_url, href)
            normalized, stripped = _normalize_product_url(full_url)
            if stripped:
                stats["fragments_stripped"] += 1
            ok, reason = _is_valid_product_url(
                normalized,
                self.config.product_url_pattern,
                exclude_slug_substrings=self.config.exclude_slug_substrings,
            )
            if ok:
                product_urls.append(normalized)
            elif reason and reason.startswith("excluded_slug_contains:"):
                stats["excluded_urls"] += 1
                sub = reason.split("excluded_slug_contains:", 1)[1]
                stats["excluded_by_substring"][sub] = stats["excluded_by_substring"].get(sub, 0) + 1

        # Fallback: any link containing /shop/p/
        for link in soup.find_all("a", href=True):
            href = link.get("href")
            if not href:
                continue
            if self.config.product_url_pattern not in href and not href.startswith(self.config.product_url_pattern):
                continue
            full_url = urljoin(base_url, href)
            normalized, stripped = _normalize_product_url(full_url)
            if stripped:
                stats["fragments_stripped"] += 1
            ok, reason = _is_valid_product_url(
                normalized,
                self.config.product_url_pattern,
                exclude_slug_substrings=self.config.exclude_slug_substrings,
            )
            if ok:
                product_urls.append(normalized)
            elif reason and reason.startswith("excluded_slug_contains:"):
                stats["excluded_urls"] += 1
                sub = reason.split("excluded_slug_contains:", 1)[1]
                stats["excluded_by_substring"][sub] = stats["excluded_by_substring"].get(sub, 0) + 1

        return _dedupe_preserve_order(product_urls)

    def _scrape_url_pagination(self, page, base_url: str) -> Tuple[List[str], Dict[str, Any]]:
        collected: List[str] = []
        stats = {
            "url_pagination_pages_checked": 0,
            "url_pagination_pages_with_products": 0,
            "url_pagination_consecutive_empty_pages": 0,
            "fragments_stripped": 0,
            "excluded_urls": 0,
            "excluded_by_substring": {},
        }

        consecutive_empty = 0
        for page_num in range(1, self.config.max_pages + 1):
            page_url = base_url if page_num == 1 else f"{base_url}?p={page_num}"
            stats["url_pagination_pages_checked"] += 1

            logger.info("Canon discovery: visiting %s", page_url)
            page.goto(page_url, wait_until="domcontentloaded", timeout=30000)
            self._random_delay()

            html = page.content()
            soup = BeautifulSoup(html, "html.parser")
            urls = self._extract_product_links(soup, page_url, stats)

            if urls:
                stats["url_pagination_pages_with_products"] += 1
                consecutive_empty = 0
                stats["url_pagination_consecutive_empty_pages"] = 0
                collected.extend(urls)
            else:
                consecutive_empty += 1
                stats["url_pagination_consecutive_empty_pages"] = consecutive_empty
                if consecutive_empty >= self.config.stop_after_consecutive_empty_pages:
                    break

            if self.config.max_products and len(_dedupe_preserve_order(collected)) >= self.config.max_products:
                break

            # Throttle every N pages
            if page_num % self.config.long_break_every == 0:
                self._random_delay(is_long_break=True)

        return _dedupe_preserve_order(collected), stats

    def _find_load_more_button(self, page):
        for selector in self.LOAD_MORE_SELECTORS:
            try:
                button = page.query_selector(selector)
                if button and button.is_visible() and button.is_enabled():
                    return button
            except Exception:
                continue

        # fallback: scan buttons by text
        try:
            buttons = page.query_selector_all("button")
            for b in buttons:
                try:
                    text = (b.text_content() or "").lower()
                    if "load more" in text and b.is_visible() and b.is_enabled():
                        return b
                except Exception:
                    continue
        except Exception:
            pass
        return None

    def _scrape_load_more(self, page, base_url: str) -> Tuple[List[str], Dict[str, Any]]:
        stats = {
            "load_more_clicks": 0,
            "fragments_stripped": 0,
            "excluded_urls": 0,
            "excluded_by_substring": {},
        }
        collected: List[str] = []

        page.goto(base_url, wait_until="domcontentloaded", timeout=30000)
        self._random_delay(is_long_break=True)

        html = page.content()
        soup = BeautifulSoup(html, "html.parser")
        collected.extend(self._extract_product_links(soup, base_url, stats))

        for click in range(self.config.max_load_more_clicks):
            btn = self._find_load_more_button(page)
            if not btn:
                break

            try:
                btn.click()
            except Exception:
                break

            stats["load_more_clicks"] += 1
            self._random_delay(is_long_break=True)

            html = page.content()
            soup = BeautifulSoup(html, "html.parser")
            new_urls = self._extract_product_links(soup, base_url, stats)
            before = len(collected)
            collected.extend([u for u in new_urls if u not in collected])
            after = len(collected)

            if after == before:
                # No new items loaded, stop
                break

            if self.config.max_products and len(collected) >= self.config.max_products:
                break

            if (click + 1) % self.config.long_break_every == 0:
                self._random_delay(is_long_break=True)

        return _dedupe_preserve_order(collected), stats

    def discover(self) -> Dict[str, Any]:
        all_urls: List[str] = []
        errors: List[Dict[str, Any]] = []
        stats: Dict[str, Any] = {"listing_urls": {}}

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

            # realistic headers
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
                for idx, listing_url in enumerate(self.config.listing_urls):
                    listing_stats: Dict[str, Any] = {}
                    try:
                        urls, url_stats = self._scrape_url_pagination(page, listing_url)
                        listing_stats.update(url_stats)

                        # If URL pagination returns very few, try load-more
                        if len(urls) < 10:
                            lm_urls, lm_stats = self._scrape_load_more(page, listing_url)
                            listing_stats.update(lm_stats)
                            urls = _dedupe_preserve_order(urls + lm_urls)

                        stats["listing_urls"][listing_url] = listing_stats
                        all_urls.extend(urls)

                        # pacing between listing URLs
                        if idx < len(self.config.listing_urls) - 1:
                            self._random_delay(is_long_break=True)

                        if self.config.max_products and len(_dedupe_preserve_order(all_urls)) >= self.config.max_products:
                            break
                    except Exception as e:
                        errors.append({"listing_url": listing_url, "error": str(e)})
            finally:
                browser.close()

        final_urls = _dedupe_preserve_order(all_urls)
        duplicates_removed = len(all_urls) - len(final_urls)

        if self.config.max_products:
            final_urls = final_urls[: self.config.max_products]

        payload: Dict[str, Any] = {
            "brand": self.config.brand_slug,
            "product_type": self.config.product_type,
            "category_slug": self.config.category_slug,
            "listing_urls": self.config.listing_urls,
            "product_url_pattern": self.config.product_url_pattern,
            "discovery_date": _utc_now_iso(),
            "total_urls": len(final_urls),
            "urls": final_urls,
            "stats": {
                "duplicates_removed": duplicates_removed,
                **stats,
            },
        }
        if errors:
            payload["errors"] = errors

        return payload


def discover(config: DiscoveryConfig) -> Dict[str, Any]:
    """
    Dispatch to the correct discovery implementation.
    """
    brand = (config.brand_slug or "").lower()
    if brand == "canon":
        payload = CanonDiscovery(config).discover()
    else:
        raise ValueError(f"No discovery implementation for brand={config.brand_slug}")

    ok, errs = validate_discovery_output(payload)
    if not ok:
        raise ValueError("Discovery output validation failed: " + "; ".join(errs))

    return payload

