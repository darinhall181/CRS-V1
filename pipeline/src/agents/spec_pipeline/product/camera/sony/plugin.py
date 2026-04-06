"""
Sony digital cinema camera plugin.

Sony's pro site (pro.sony) blocks automated crawling (HTTP 403), so discovery
uses a curated static inventory of known product URLs.  When Sony adds a new
camera, append its URL to DISCOVERY_CONFIG.static_product_urls.

Extraction fetches each product page with Sony-appropriate headers and parses
the spec table/definition-list markup.  If a cached HTML file exists at
data/company_product/sony/raw_html/{slug}.html it is used instead.
"""

import json
from pathlib import Path

from agents.spec_pipeline.core.discovery import DiscoveryConfig
from agents.spec_pipeline.core.extraction import ExtractionConfig, extract
from agents.spec_pipeline.core.normalization import NormalizationConfig, normalize_extractions

BRAND_SLUG = "sony"
PRODUCT_TYPE = "camera"
CATEGORY_SLUG = "cinema-cameras"

# ---------------------------------------------------------------------------
# Known Sony digital cinema camera product pages (as of 2026-04).
# Update this list when Sony releases new models.
# ---------------------------------------------------------------------------
_SONY_CINEMA_CAMERA_URLS = [
    # Flagship cinema cameras (all under /digital-cinema-cameras/)
    "https://pro.sony/ue_US/products/digital-cinema-cameras/burano",
    "https://pro.sony/ue_US/products/digital-cinema-cameras/venice2",   # Venice 2 (no hyphen)
    "https://pro.sony/ue_US/products/digital-cinema-cameras/venice",
    # NOTE: FX9 / FX6 / FX3 (Cinema Line) live under a different Sony category path.
    # Add them here once their correct pro.sony slugs are confirmed.
]


DISCOVERY_CONFIG = DiscoveryConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    listing_urls=["https://pro.sony/ue_US/products/digital-cinema-cameras"],
    # All Sony cinema camera URLs contain this pattern.
    product_url_pattern="/digital-cinema-cameras/",
    # Bypass web crawl; pro.sony returns 403 to automated scrapers.
    static_product_urls=_SONY_CINEMA_CAMERA_URLS,
    output_path="data/url_lists/sony_camera_urls.json",
)


EXTRACTION_CONFIG = ExtractionConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    headless=False,
    max_products=None,
    html_cache_dir="data/company_product/sony/processed_data/camera/raw_html",
    cache_only=False,
    raw_html_dir="data/company_product/sony/processed_data/camera/raw_html",
    output_path="data/company_product/sony/processed_data/camera/extractions.json",
    min_sections_ok=1,
    min_attributes_ok=10,
    delay_min=3.0,
    delay_max=6.0,
    long_break_every=5,
    long_break_min=8.0,
    long_break_max=14.0,
)


NORMALIZATION_CONFIG = NormalizationConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    output_path="data/company_product/sony/processed_data/camera/normalized.json",
)


def extract_urls(url_inventory_path: str) -> str:
    inv_path = Path(url_inventory_path)
    inventory = json.loads(inv_path.read_text(encoding="utf-8"))
    urls = inventory.get("urls", [])

    payload = extract(EXTRACTION_CONFIG, urls)

    out_path = Path(EXTRACTION_CONFIG.output_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return str(out_path)


def normalize(url_inventory_path: str, db_url: str) -> str:
    _ = url_inventory_path
    payload = normalize_extractions(NORMALIZATION_CONFIG, EXTRACTION_CONFIG.output_path, db_url=db_url)
    out_path = Path(NORMALIZATION_CONFIG.output_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    queue_path = out_path.parent / "pdf_queue.json"
    queue_path.write_text(json.dumps(payload.get("pdf_queue", []), indent=2), encoding="utf-8")
    return str(out_path)
