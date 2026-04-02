"""
Canon + lens plugin.

This mirrors the Canon camera plugin but targets Canon lens product pages.
"""

import json
from pathlib import Path

from agents.spec_pipeline.core.discovery import DiscoveryConfig
from agents.spec_pipeline.core.extraction import ExtractionConfig, extract
from agents.spec_pipeline.core.normalization import NormalizationConfig, normalize_extractions

BRAND_SLUG = "canon"
PRODUCT_TYPE = "lens"

# Use an existing category slug (present in local DB seed / remote schema).
CATEGORY_SLUG = "lenses"


DISCOVERY_CONFIG = DiscoveryConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    listing_urls=[
        # Broad catch-all category (should include most lens lines)
        "https://www.usa.canon.com/shop/lenses",
        # These are the only ones that are included in the pro website but not in commercial
        "https://www.usa.canon.com/shop/pro/lenses/cinema-lenses",
        "https://www.usa.canon.com/shop/pro/lenses/broadcast-lenses"
    ],
    product_url_pattern="/shop/p/",
    # Avoid adapters/filters/hoods/etc. when using the broad /shop/lenses entrypoint.
    exclude_slug_substrings=[
        "adapter",
        "mount-adapter",
        "filter",
        "hood",
        "cap",
        "case",
        "battery",
        "charger",
        "teleconverter",
        "extender",
        "converter",
        "ring",
        "collar",
        "tripod",
        "drop-in",
        "protector",
        "protect",
        "circular-polarizer",
        "polarizer",
        "pl-c",
    ],
    headless=False,  # set True once stable
    max_products=None,  # set to an int for quick tests (e.g., 50)
    max_pages=60,
    max_load_more_clicks=60,
    stop_after_consecutive_empty_pages=3,
    delay_min=2.0,
    delay_max=5.0,
    long_break_every=10,
    long_break_min=8.0,
    long_break_max=12.0,
    output_path="data/url_lists/canon_lens_urls.json",
)


EXTRACTION_CONFIG = ExtractionConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    headless=False,
    max_products=None,
    # Prefer your shared Canon HTML cache first; if missing/stale, allow web fetch.
    html_cache_dir="data/company_product/canon/raw_html",
    cache_only=False,
    # Save fetched HTML back into the shared cache so future runs are cache-first.
    raw_html_dir="data/company_product/canon/raw_html",
    output_path="data/company_product/canon/processed_data/lens/extractions.json",
    # Completeness heuristics: lenses often have fewer spec groups than bodies.
    min_sections_ok=3,
    min_attributes_ok=20,
)


NORMALIZATION_CONFIG = NormalizationConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    output_path="data/company_product/canon/processed_data/lens/normalized.json",
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


