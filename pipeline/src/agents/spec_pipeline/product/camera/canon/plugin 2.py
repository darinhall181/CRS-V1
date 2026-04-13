"""
Canon + camera plugin (Discovery-only for now).

This file is intentionally the single entrypoint for this brand+type.
Split into multiple modules only when it grows too large.
"""

import json
from pathlib import Path

from agents.spec_pipeline.core.discovery import DiscoveryConfig
from agents.spec_pipeline.core.extraction import ExtractionConfig, extract
from agents.spec_pipeline.core.normalization import NormalizationConfig, normalize_extractions

BRAND_SLUG = "canon"
PRODUCT_TYPE = "camera"
CATEGORY_SLUG = "mirrorless-cameras"


DISCOVERY_CONFIG = DiscoveryConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    listing_urls=[
        "https://www.usa.canon.com/shop/cameras/mirrorless-cameras",
    ],
    product_url_pattern="/shop/p/",
    exclude_slug_substrings=["kit", "with-cropping-guide-firmware", "with-stop-motion-animation-firmware"],
    headless=False,  # set True once stable
    max_products=None,  # set to an int for quick tests (e.g., 25)
    max_pages=30,
    max_load_more_clicks=30,
    stop_after_consecutive_empty_pages=3,
    delay_min=2.0,
    delay_max=5.0,
    long_break_every=10,
    long_break_min=8.0,
    long_break_max=12.0,
    output_path="data/url_lists/canon_camera_urls.json",
)


EXTRACTION_CONFIG = ExtractionConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    headless=False,
    max_products=15,  # full Canon mirrorless set from discovery
    # Use your existing Canon HTML cache first.
    html_cache_dir="data/company_product/canon/raw_html",
    cache_only=True,
    # If web fallback is needed later, set cache_only=False.
    raw_html_dir="data/company_product/canon/processed_data/camera/raw_html",
    output_path="data/company_product/canon/processed_data/camera/extractions.json",
    # Completeness heuristics (used to decide if we likely need PDF fallback)
    min_sections_ok=5,
    min_attributes_ok=40,
)


NORMALIZATION_CONFIG = NormalizationConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    output_path="data/company_product/canon/processed_data/camera/normalized.json",
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
    _ = url_inventory_path  # kept for signature symmetry; normalization reads EXTRACTION_CONFIG.output_path
    payload = normalize_extractions(NORMALIZATION_CONFIG, EXTRACTION_CONFIG.output_path, db_url=db_url)
    out_path = Path(NORMALIZATION_CONFIG.output_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    # Also write a standalone PDF queue file for manual download workflow.
    queue_path = out_path.parent / "pdf_queue.json"
    queue_path.write_text(json.dumps(payload.get("pdf_queue", []), indent=2), encoding="utf-8")
    return str(out_path)

