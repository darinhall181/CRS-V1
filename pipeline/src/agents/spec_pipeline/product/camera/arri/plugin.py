"""
ARRI camera plugin.

Discovery scrapes the ARRI listing pages (current + live cameras).
Extraction clicks the "Technical Data" tab and parses the <dl> spec list.
Normalization uses cinema-cameras spec_mapping rules.
"""

import json
from pathlib import Path

from agents.spec_pipeline.core.discovery import DiscoveryConfig
from agents.spec_pipeline.core.extraction import ExtractionConfig, extract
from agents.spec_pipeline.core.normalization import NormalizationConfig, normalize_extractions

BRAND_SLUG = "arri"
PRODUCT_TYPE = "camera"
CATEGORY_SLUG = "cinema-cameras"


DISCOVERY_CONFIG = DiscoveryConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    listing_urls=[
        "https://www.arri.com/en/camera-systems/cameras",
        "https://www.arri.com/en/camera-systems/live-cameras",
    ],
    # All ARRI product page URLs contain this substring.
    product_url_pattern="/camera-systems/",
    # Skip the legacy sub-listing page; individual legacy cameras are OK.
    exclude_slug_substrings=["legacy-camera-systems"],
    headless=False,
    max_products=None,
    max_pages=5,
    max_load_more_clicks=0,
    stop_after_consecutive_empty_pages=2,
    delay_min=2.0,
    delay_max=4.0,
    long_break_every=10,
    long_break_min=6.0,
    long_break_max=10.0,
    output_path="data/url_lists/arri_camera_urls.json",
)


EXTRACTION_CONFIG = ExtractionConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    headless=False,
    max_products=None,
    html_cache_dir="data/company_product/arri/processed_data/camera/raw_html",
    cache_only=False,
    raw_html_dir="data/company_product/arri/processed_data/camera/raw_html",
    output_path="data/company_product/arri/processed_data/camera/extractions.json",
    # ARRI spec pages are lean; lower thresholds than Canon.
    min_sections_ok=1,
    min_attributes_ok=10,
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
    output_path="data/company_product/arri/processed_data/camera/normalized.json",
)


def extract_urls(url_inventory_path: str) -> str:
    """
    Reads discovery JSON, fetches each product page, parses tech specs, writes extraction JSON.
    Returns the written extraction JSON path.
    """
    inv_path = Path(url_inventory_path)
    inventory = json.loads(inv_path.read_text(encoding="utf-8"))
    urls = inventory.get("urls", [])

    payload = extract(EXTRACTION_CONFIG, urls)

    out_path = Path(EXTRACTION_CONFIG.output_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return str(out_path)


def normalize(url_inventory_path: str, db_url: str) -> str:
    """
    Normalizes the latest extraction output using DB spec_mapping rules.
    Returns written normalized JSON path.
    """
    _ = url_inventory_path
    payload = normalize_extractions(NORMALIZATION_CONFIG, EXTRACTION_CONFIG.output_path, db_url=db_url)
    out_path = Path(NORMALIZATION_CONFIG.output_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    queue_path = out_path.parent / "pdf_queue.json"
    queue_path.write_text(json.dumps(payload.get("pdf_queue", []), indent=2), encoding="utf-8")
    return str(out_path)
