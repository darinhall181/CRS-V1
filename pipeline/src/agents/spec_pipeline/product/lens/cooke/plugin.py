"""
Cooke Optics cinema lens plugin.

Cooke's website lists each lens series on a dedicated page, with specs in
definition lists or tables within a "Specifications" section. Discovery uses
a curated static list of lens series pages. Each series page covers the full
focal length range for that set.

Extraction targets the specifications section on each page. Individual focal
lengths are often listed in a table within that section.
"""

import json
from pathlib import Path

from agents.spec_pipeline.core.discovery import DiscoveryConfig
from agents.spec_pipeline.core.extraction import ExtractionConfig, extract
from agents.spec_pipeline.core.normalization import NormalizationConfig, normalize_extractions

BRAND_SLUG = "cooke"
PRODUCT_TYPE = "lens"
CATEGORY_SLUG = "cinema-lenses"

# Cooke's spec pages are per lens series. Individual focal length pages (where
# they exist) are appended separately.
_COOKE_LENS_URLS = [
    # S4/i — workhorse S35 prime set
    "https://www.cookeoptics.com/lenses/s4i/",
    # miniS4/i — compact S35 primes
    "https://www.cookeoptics.com/lenses/minis4i/",
    # S7/i — large format primes
    "https://www.cookeoptics.com/lenses/s7i/",
    # Anamorphic/i SF — anamorphic set
    "https://www.cookeoptics.com/lenses/anamorphic/",
    # Panchro/i Classic — vintage character primes
    "https://www.cookeoptics.com/lenses/panchro-classic/",
    # 5/i — large format primes
    "https://www.cookeoptics.com/lenses/5i/",
    # Varotal/i — large format zoom
    "https://www.cookeoptics.com/lenses/varotal/",
]

DISCOVERY_CONFIG = DiscoveryConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    listing_urls=["https://www.cookeoptics.com/lenses/"],
    product_url_pattern="cookeoptics.com/lenses/",
    static_product_urls=_COOKE_LENS_URLS,
    exclude_slug_substrings=["news", "case-studies", "contact"],
    output_path="data/url_lists/cooke_lens_urls.json",
)

EXTRACTION_CONFIG = ExtractionConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    headless=False,
    max_products=None,
    html_cache_dir="data/company_product/cooke/processed_data/lens/raw_html",
    cache_only=False,
    raw_html_dir="data/company_product/cooke/processed_data/lens/raw_html",
    output_path="data/company_product/cooke/processed_data/lens/extractions.json",
    min_sections_ok=1,
    min_attributes_ok=5,
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
    output_path="data/company_product/cooke/processed_data/lens/normalized.json",
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
