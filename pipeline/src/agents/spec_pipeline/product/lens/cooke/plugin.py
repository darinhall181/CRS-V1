"""
Cooke Optics cinema lens plugin.

Cooke's website lists each lens series on a dedicated page, with specs in
definition lists or tables within a "Specifications" section. Discovery uses
a curated static list of lens series pages. Each series page covers the full
focal length range for that set. Each page also has a "Download Specifications"
PDF link which the extractor captures for the pdf_queue.

URL pattern (post-2023 site): cookeoptics.com/lens/{slug}/  (no www, /lens/ not /lenses/)
"""

import json
from pathlib import Path

from agents.spec_pipeline.core.discovery import DiscoveryConfig
from agents.spec_pipeline.core.extraction import ExtractionConfig, extract
from agents.spec_pipeline.core.normalization import NormalizationConfig, normalize_extractions

BRAND_SLUG = "cooke"
PRODUCT_TYPE = "lens"
CATEGORY_SLUG = "cinema-lenses"

# Current Cooke lens lineup. URLs confirmed from cookeoptics.com/lens/{slug}/.
# The old /lenses/ path (www.cookeoptics.com) now 404s — site restructured.
_COOKE_LENS_URLS = [
    # S8/i FF — flagship T1.4 full-frame primes (18–135mm)
    "https://cookeoptics.com/lens/s8-i-ff/",
    # S7/i FF — large format primes
    "https://cookeoptics.com/lens/s7-i-ff/",
    # S4/i — classic S35 workhorse primes
    "https://cookeoptics.com/lens/s4-i/",
    # miniS4/i — compact S35 primes
    "https://cookeoptics.com/lens/minis4-i/",
    # Anamorphic/i SF — 2x anamorphic PL primes
    "https://cookeoptics.com/lens/anamorphic-i-sf/",
    # Panchro/i Classic — vintage character primes
    "https://cookeoptics.com/lens/panchro-i-classic/",
    # 5/i — large format primes (T1.4)
    "https://cookeoptics.com/lens/5-i/",
    # Varotal/i FF — full-frame zooms (19-40, 30-95, 85-215mm)
    "https://cookeoptics.com/lens/varotal-i-ff/",
]

DISCOVERY_CONFIG = DiscoveryConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    listing_urls=["https://cookeoptics.com/lenses/"],
    product_url_pattern="cookeoptics.com/lens/",
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
