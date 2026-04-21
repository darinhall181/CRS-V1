"""
Blackmagic Design camera plugin.

Blackmagic's product pages are mostly static HTML with spec data in definition
lists and tables. Discovery crawls the cameras listing page. Extraction parses
the Technical Specifications section rendered in the DOM.

Some Blackmagic pages are JS-heavy (e.g. URSA Cine); headless=False is used to
ensure full render before scraping.
"""

import json
from pathlib import Path

from agents.spec_pipeline.core.discovery import DiscoveryConfig
from agents.spec_pipeline.core.extraction import ExtractionConfig, extract
from agents.spec_pipeline.core.normalization import NormalizationConfig, normalize_extractions

BRAND_SLUG = "blackmagic"
PRODUCT_TYPE = "camera"
CATEGORY_SLUG = "cinema-cameras"

# Blackmagic's listing pages are split by product line.
_BMD_LISTING_URLS = [
    "https://www.blackmagicdesign.com/products/blackmagicursaminipro",
    "https://www.blackmagicdesign.com/products/blackmagicursacine",
    "https://www.blackmagicdesign.com/products/blackmagicpocketcinemacamera",
    "https://www.blackmagicdesign.com/products/cinema",
]

# Static fallback — Blackmagic's listing pages don't always enumerate product
# URLs in a consistent crawlable pattern.
_BMD_CAMERA_URLS = [
    "https://www.blackmagicdesign.com/products/blackmagicursaminipro",      # URSA Mini Pro 12K
    "https://www.blackmagicdesign.com/products/blackmagicursacine",         # URSA Cine 12K / 17K
    "https://www.blackmagicdesign.com/products/blackmagicpocketcinemacamera/6K",
    "https://www.blackmagicdesign.com/products/blackmagicpocketcinemacamera/6KG2",
    "https://www.blackmagicdesign.com/products/blackmagicpocketcinemacamera/6KPro",
    "https://www.blackmagicdesign.com/products/blackmagicpocketcinemacamera",  # BMPCC 4K
    "https://www.blackmagicdesign.com/products/cinema",                     # Cinema Camera 6K
]

DISCOVERY_CONFIG = DiscoveryConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    listing_urls=_BMD_LISTING_URLS,
    product_url_pattern="blackmagicdesign.com/products/",
    static_product_urls=_BMD_CAMERA_URLS,
    output_path="data/url_lists/blackmagic_camera_urls.json",
)

EXTRACTION_CONFIG = ExtractionConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    headless=False,
    max_products=None,
    html_cache_dir="data/company_product/blackmagic/processed_data/camera/raw_html",
    cache_only=False,
    raw_html_dir="data/company_product/blackmagic/processed_data/camera/raw_html",
    output_path="data/company_product/blackmagic/processed_data/camera/extractions.json",
    min_sections_ok=1,
    min_attributes_ok=8,
    delay_min=2.0,
    delay_max=5.0,
    long_break_every=5,
    long_break_min=6.0,
    long_break_max=10.0,
)

NORMALIZATION_CONFIG = NormalizationConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    output_path="data/company_product/blackmagic/processed_data/camera/normalized.json",
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
