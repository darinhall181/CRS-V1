"""
RED (Nikon) camera plugin.

RED's website (red.com) is a JS-rendered SPA. Discovery uses a curated static
inventory of known product URLs. Extraction fetches with Playwright (headless)
and parses the spec tables rendered into the DOM.

Static URL list should be updated when RED ships new cameras.
"""

import json
from pathlib import Path

from agents.spec_pipeline.core.discovery import DiscoveryConfig
from agents.spec_pipeline.core.extraction import ExtractionConfig, extract
from agents.spec_pipeline.core.normalization import NormalizationConfig, normalize_extractions

BRAND_SLUG = "red"
PRODUCT_TYPE = "camera"
CATEGORY_SLUG = "cinema-cameras"

_RED_CINEMA_CAMERA_URLS = [
    "https://www.red.com/v-raptor-8k-vv",
    "https://www.red.com/v-raptor-x-8k-vv",
    "https://www.red.com/v-raptor-8k-s35",
    "https://www.red.com/komodo-x-6k",
    "https://www.red.com/komodo-6k",
    "https://www.red.com/monstro-8k-vv",
    "https://www.red.com/helium-8k-s35",
    "https://www.red.com/gemini-5k-s35",
]

DISCOVERY_CONFIG = DiscoveryConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    listing_urls=["https://www.red.com/cameras"],
    product_url_pattern="red.com/",
    # red.com uses a SPA — bypass crawl with static list
    static_product_urls=_RED_CINEMA_CAMERA_URLS,
    output_path="data/url_lists/red_camera_urls.json",
)

EXTRACTION_CONFIG = ExtractionConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    headless=False,
    max_products=None,
    html_cache_dir="data/company_product/red/processed_data/camera/raw_html",
    cache_only=False,
    raw_html_dir="data/company_product/red/processed_data/camera/raw_html",
    output_path="data/company_product/red/processed_data/camera/extractions.json",
    min_sections_ok=1,
    min_attributes_ok=8,
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
    output_path="data/company_product/red/processed_data/camera/normalized.json",
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
