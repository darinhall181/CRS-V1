"""
Angenieux cinema lens plugin.

Angenieux's website (angenieux.com) hosts specs in downloadable PDFs and
inline spec tables. The site uses a mix of static HTML and JS rendering.
Discovery uses a curated static list of product family pages; headless=False
ensures JS content is loaded before parsing.

Angenieux lens families: Optimo (high-end zooms), EZ (lightweight zooms),
Type EF/EP (documentary/broadcast), Optimo Prime.
"""

import json
from pathlib import Path

from agents.spec_pipeline.core.discovery import DiscoveryConfig
from agents.spec_pipeline.core.extraction import ExtractionConfig, extract
from agents.spec_pipeline.core.normalization import NormalizationConfig, normalize_extractions

BRAND_SLUG = "angenieux"
PRODUCT_TYPE = "lens"
CATEGORY_SLUG = "cinema-lenses"

_ANGENIEUX_LENS_URLS = [
    # Optimo zooms — cinema workhorse large-format and S35
    "https://www.angenieux.com/optimo/",
    "https://www.angenieux.com/optimo-zoom-lenses/",
    # Optimo Prime — large format primes
    "https://www.angenieux.com/optimo-prime/",
    # EZ series — lightweight PL/EF/E-Mount zooms
    "https://www.angenieux.com/ez-series/",
    # Type EF / Type EP — documentary/broadcast zooms
    "https://www.angenieux.com/type-ef/",
    "https://www.angenieux.com/type-ep/",
]

DISCOVERY_CONFIG = DiscoveryConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    listing_urls=["https://www.angenieux.com/lenses/"],
    product_url_pattern="angenieux.com/",
    static_product_urls=_ANGENIEUX_LENS_URLS,
    exclude_slug_substrings=["news", "contact", "about", "service", "support"],
    output_path="data/url_lists/angenieux_lens_urls.json",
)

EXTRACTION_CONFIG = ExtractionConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    headless=False,
    max_products=None,
    html_cache_dir="data/company_product/angenieux/processed_data/lens/raw_html",
    cache_only=False,
    raw_html_dir="data/company_product/angenieux/processed_data/lens/raw_html",
    output_path="data/company_product/angenieux/processed_data/lens/extractions.json",
    min_sections_ok=1,
    min_attributes_ok=5,
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
    output_path="data/company_product/angenieux/processed_data/lens/normalized.json",
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
