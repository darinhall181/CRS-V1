import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import psycopg2
import psycopg2.extras


def _iter_pdf_urls_from_extraction_item(item: Dict[str, Any]) -> List[Tuple[str, Dict[str, Any]]]:
    """
    Returns list of (pdf_url, raw_metadata)
    """
    pdfs: List[Tuple[str, Dict[str, Any]]] = []
    for section in item.get("manufacturer_sections", []) or []:
        for attr in section.get("attributes", []) or []:
            ctx = attr.get("context") or {}
            pdf_url = ctx.get("pdf_url")
            if pdf_url:
                pdfs.append((pdf_url, {"section_name": section.get("section_name"), "raw_key": attr.get("raw_key")}))
    return pdfs


def main() -> int:
    extraction_path = os.environ.get(
        "EXTRACTIONS_JSON",
        "data/company_product/canon/processed_data/camera/extractions.json",
    )
    db_url = os.environ.get("SUPABASE_DB_URL") or os.environ.get("DATABASE_URL")
    if not db_url:
        raise RuntimeError("Set SUPABASE_DB_URL in backend/.env (or DATABASE_URL as fallback).")

    payload = json.loads(Path(extraction_path).read_text(encoding="utf-8"))
    items = payload.get("items", [])

    conn = psycopg2.connect(db_url)
    try:
        with conn, conn.cursor() as cur:
            inserted = 0
            for item in items:
                brand = payload.get("brand")
                product_type = payload.get("product_type")
                product_slug = item.get("product_slug")
                source_url = item.get("product_url")

                for pdf_url, raw_meta in _iter_pdf_urls_from_extraction_item(item):
                    cur.execute(
                        """
                        INSERT INTO product_document (
                          brand_slug,
                          product_type,
                          product_slug,
                          document_kind,
                          url,
                          source_url,
                          status,
                          raw_metadata
                        )
                        VALUES (%s,%s,%s,%s,%s,%s,%s,%s::jsonb)
                        ON CONFLICT (product_slug, document_kind, url) DO NOTHING
                        """,
                        (
                            brand,
                            product_type,
                            product_slug,
                            "technical_specs_pdf",
                            pdf_url,
                            source_url,
                            "discovered",
                            json.dumps(raw_meta),
                        ),
                    )
                    inserted += cur.rowcount

            print(f"Inserted {inserted} product_document rows from {extraction_path}")
    finally:
        conn.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

