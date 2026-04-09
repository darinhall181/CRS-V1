"""
Carl Zeiss AG cinema lens plugin.

Zeiss moved their cinematography pages from zeiss.com/consumer-products to
zeiss.com/photonics-and-optics in 2024. Pages are JS-rendered so headless=False
is used. Discovery uses a curated static list by lens family; each page covers
the full focal length range for that series as a spec table.

NOTE on focal-length splitting: each series page (e.g. CP.3) lists specs for
multiple focal lengths in a matrix table. During extraction, the entire series
is stored as one item with a product_spec_matrix. A future "splitter" pass will
generate one product row per focal length (e.g. zeiss-cp3-21mm-t2-9). For now,
one item per series page is correct and sufficient.
"""

import json
from pathlib import Path

from agents.spec_pipeline.core.discovery import DiscoveryConfig
from agents.spec_pipeline.core.extraction import ExtractionConfig, extract
from agents.spec_pipeline.core.normalization import NormalizationConfig, normalize_extractions

BRAND_SLUG = "zeiss"
PRODUCT_TYPE = "lens"
CATEGORY_SLUG = "cinema-lenses"

# URLs confirmed against zeiss.com/photonics-and-optics (post-2024 restructure).
# The old /consumer-products/ path now redirects or 404s.
_ZEISS_LENS_URLS = [
    # CP.3 — compact S35 primes (EF/PL/E, affordable entry point)
    "https://www.zeiss.com/photonics-and-optics/us/cinematography/lenses/compact-prime-cp-3-lenses.html",
    # AATMA — new large format primes (LPL/PL, T1.5)
    "https://www.zeiss.com/photonics-and-optics/us/cinematography/lenses/aatma-lenses.html",
    # Supreme Prime — flagship LF/S35 T1.5 primes
    "https://www.zeiss.com/photonics-and-optics/us/cinematography/lenses/supreme-prime-lenses.html",
    # Supreme Prime Radiance — flared/vintage variant of Supreme Prime
    "https://www.zeiss.com/photonics-and-optics/us/cinematography/lenses/supreme-prime-radiance-lenses.html",
    # CP.3 XD — CP.3 with eXtended Data lens metadata protocol
    "https://www.zeiss.com/photonics-and-optics/us/cinematography/lenses/compact-prime-cp3-xd-lenses.html",
]

DISCOVERY_CONFIG = DiscoveryConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    category_slug=CATEGORY_SLUG,
    listing_urls=["https://www.zeiss.com/photonics-and-optics/us/cinematography/lenses.html"],
    product_url_pattern="zeiss.com/photonics-and-optics",
    static_product_urls=_ZEISS_LENS_URLS,
    exclude_slug_substrings=["accessories", "service", "support"],
    output_path="data/url_lists/zeiss_lens_urls.json",
)

EXTRACTION_CONFIG = ExtractionConfig(
    brand_slug=BRAND_SLUG,
    product_type=PRODUCT_TYPE,
    headless=False,
    max_products=None,
    html_cache_dir="data/company_product/zeiss/processed_data/lens/raw_html",
    cache_only=False,
    raw_html_dir="data/company_product/zeiss/processed_data/lens/raw_html",
    output_path="data/company_product/zeiss/processed_data/lens/extractions.json",
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
    output_path="data/company_product/zeiss/processed_data/lens/normalized.json",
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
