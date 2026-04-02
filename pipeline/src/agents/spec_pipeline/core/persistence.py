import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import psycopg2
from psycopg2.extras import Json


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _humanize_slug(slug: str) -> str:
    """
    Best-effort display name from a slug.

    This is intentionally simple and deterministic; it can be overridden later once we
    extract a canonical product name.
    """
    if not slug:
        return ""

    roman = {"i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x"}
    special_upper = {"eos", "rf", "ef", "ef-s", "rf-s", "cn", "kas", "ias"}

    # Pre-process lens-specific patterns
    s = slug
    
    # Handle f-stop notation (e.g., "f2-8" → "F/2.8", "f1-4" → "F/1.4")
    s = re.sub(r'-f(\d+)-(\d+)', r'-F/\1.\2', s)
    s = re.sub(r'f(\d+)-(\d+)', r'F/\1.\2', s)
    
    # Handle focal length ranges (e.g., "28-70mm" → "28-70mm")
    s = re.sub(r'(\d+)-(\d+)mm', r'\1-\2mm', s)
    
    # Handle single focal lengths (e.g., "85mm" → "85mm") 
    s = re.sub(r'(\d+)mm', r'\1mm', s)

    out: List[str] = []
    for tok in s.replace("_", "-").split("-"):
        t = tok.strip()
        if not t:
            continue
        low = t.lower()
        if low in special_upper:
            out.append(low.upper())
        elif low in roman:
            out.append(low.upper())
        elif low == "mark":
            out.append("Mark")
        elif len(low) >= 2 and low[0] == "r" and low[1:].isdigit():
            out.append(low.upper())
        elif low in {"is", "stm", "usm", "vcm", "pz", "macro", "do"}:
            out.append(low.upper())
        elif low.startswith("f/"):
            out.append(low.upper())
        elif low.endswith("mm"):
            out.append(low)
        else:
            out.append(low.capitalize())
    return " ".join(out)


@dataclass
class PersistenceConfig:
    brand_slug: str
    product_type: str


def _lookup_ids(conn, brand_slug: str, category_slug: str) -> Tuple[str, str]:
    with conn.cursor() as cur:
        cur.execute("SELECT id FROM brand WHERE slug = %s", (brand_slug,))
        brand_row = cur.fetchone()
        if not brand_row:
            raise RuntimeError(f"brand not found for slug={brand_slug!r}")

        cur.execute("SELECT id FROM product_category WHERE slug = %s", (category_slug,))
        cat_row = cur.fetchone()
        if not cat_row:
            raise RuntimeError(f"product_category not found for slug={category_slug!r}")

        return str(brand_row[0]), str(cat_row[0])


def _upsert_product(
    conn,
    *,
    brand_id: str,
    category_id: str,
    slug: str,
    manufacturer_url: Optional[str],
    msrp_usd: Optional[float] = None,
    primary_image_url: Optional[str] = None,
    raw_payload: Dict[str, Any],
) -> str:
    model = _humanize_slug(slug)
    full_name = model or slug
    now = _utc_now()

    sql = """
        INSERT INTO product (
            brand_id,
            category_id,
            model,
            full_name,
            slug,
            msrp_usd,
            primary_image_url,
            manufacturer_url,
            source_url,
            raw_data,
            last_scraped_at,
            scraping_status,
            is_active,
            created_at,
            updated_at
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'success', TRUE, %s, %s)
        ON CONFLICT (slug) DO UPDATE SET
            brand_id = EXCLUDED.brand_id,
            category_id = EXCLUDED.category_id,
            model = EXCLUDED.model,
            full_name = EXCLUDED.full_name,
            msrp_usd = COALESCE(EXCLUDED.msrp_usd, product.msrp_usd),
            primary_image_url = COALESCE(EXCLUDED.primary_image_url, product.primary_image_url),
            manufacturer_url = COALESCE(EXCLUDED.manufacturer_url, product.manufacturer_url),
            source_url = COALESCE(EXCLUDED.source_url, product.source_url),
            raw_data = EXCLUDED.raw_data,
            last_scraped_at = EXCLUDED.last_scraped_at,
            scraping_status = EXCLUDED.scraping_status,
            is_active = EXCLUDED.is_active,
            updated_at = EXCLUDED.updated_at
        RETURNING id;
    """
    with conn.cursor() as cur:
        cur.execute(
            sql,
            (
                brand_id,
                category_id,
                model,
                full_name,
                slug,
                msrp_usd,
                primary_image_url,
                manufacturer_url,
                manufacturer_url,
                Json(raw_payload),
                now,
                now,
                now,
            ),
        )
        return str(cur.fetchone()[0])


def _upsert_product_spec(conn, *, product_id: str, rec: Dict[str, Any]) -> None:
    sql = """
        INSERT INTO product_spec (
            product_id,
            spec_definition_id,
            spec_value,
            raw_value,
            raw_value_jsonb,
            numeric_value,
            min_value,
            max_value,
            unit_used,
            boolean_value,
            extraction_confidence,
            scraped_at
        )
        VALUES (%s, %s, %s, %s, %s, %s, NULL, NULL, %s, %s, %s, NOW())
        ON CONFLICT (product_id, spec_definition_id) DO UPDATE SET
            spec_value = EXCLUDED.spec_value,
            raw_value = EXCLUDED.raw_value,
            raw_value_jsonb = EXCLUDED.raw_value_jsonb,
            numeric_value = EXCLUDED.numeric_value,
            min_value = EXCLUDED.min_value,
            max_value = EXCLUDED.max_value,
            unit_used = EXCLUDED.unit_used,
            boolean_value = EXCLUDED.boolean_value,
            extraction_confidence = EXCLUDED.extraction_confidence,
            scraped_at = NOW();
    """

    # IMPORTANT:
    # The UUIDs in normalized.json may have been generated against a different database.
    # Do not trust rec["spec_definition_id"] for FK integrity; callers should resolve the
    # current DB id via normalized_key and pass a correct spec_definition_id.
    spec_definition_id = rec.get("spec_definition_id")
    if not spec_definition_id:
        raise RuntimeError("spec_record missing resolved spec_definition_id")

    raw_jsonb = {
        "source": rec.get("source"),
        "normalized_key": rec.get("normalized_key"),
    }

    with conn.cursor() as cur:
        cur.execute(
            sql,
            (
                product_id,
                spec_definition_id,
                rec.get("spec_value"),
                rec.get("raw_value"),
                Json(raw_jsonb),
                rec.get("numeric_value"),
                rec.get("unit_used"),
                rec.get("boolean_value"),
                rec.get("extraction_confidence"),
            ),
        )


def _lookup_spec_definition_id_by_key(conn, normalized_key: str) -> str:
    with conn.cursor() as cur:
        cur.execute("SELECT id FROM spec_definition WHERE normalized_key = %s", (normalized_key,))
        row = cur.fetchone()
        if not row:
            raise RuntimeError(f"spec_definition not found for normalized_key={normalized_key!r}")
        return str(row[0])


def _load_spec_definition_ids(conn) -> Dict[str, str]:
    """
    Load mapping: normalized_key -> spec_definition.id for this DB.
    """
    out: Dict[str, str] = {}
    with conn.cursor() as cur:
        cur.execute("SELECT normalized_key, id FROM spec_definition")
        for normalized_key, spec_id in cur.fetchall():
            if normalized_key:
                out[str(normalized_key)] = str(spec_id)
    return out


def _upsert_matrix_parent_spec(conn, *, product_id: str, spec_definition_id: str, matrix_rec: Dict[str, Any]) -> None:
    """
    Ensure there's a parent product_spec row indicating the spec is stored in product_spec_matrix.
    """
    sql = """
        INSERT INTO product_spec (
            product_id,
            spec_definition_id,
            spec_value,
            raw_value,
            raw_value_jsonb,
            numeric_value,
            min_value,
            max_value,
            unit_used,
            boolean_value,
            extraction_confidence,
            scraped_at
        )
        VALUES (%s, %s, %s, %s, %s, NULL, NULL, NULL, NULL, NULL, NULL, NOW())
        ON CONFLICT (product_id, spec_definition_id) DO UPDATE SET
            spec_value = EXCLUDED.spec_value,
            raw_value = EXCLUDED.raw_value,
            raw_value_jsonb = EXCLUDED.raw_value_jsonb,
            scraped_at = NOW();
    """
    with conn.cursor() as cur:
        cur.execute(
            sql,
            (
                product_id,
                spec_definition_id,
                matrix_rec.get("spec_value") or "See product_spec_matrix",
                matrix_rec.get("raw_value"),
                Json(matrix_rec.get("raw_value_jsonb") or {}),
            ),
        )


def _upsert_matrix_cell(
    conn,
    *,
    product_id: str,
    spec_definition_id: str,
    cell: Dict[str, Any],
) -> None:
    sql = """
        INSERT INTO product_spec_matrix (
            product_id,
            spec_definition_id,
            dims,
            value_text,
            numeric_value,
            unit_used,
            width_px,
            height_px,
            is_available,
            is_inexact_proportion,
            notes,
            extraction_confidence,
            scraped_at
        )
        VALUES (%s, %s, %s, %s, %s, %s, NULL, NULL, TRUE, FALSE, NULL, %s, NOW())
        ON CONFLICT (product_id, spec_definition_id, dims) DO UPDATE SET
            value_text = EXCLUDED.value_text,
            numeric_value = EXCLUDED.numeric_value,
            unit_used = EXCLUDED.unit_used,
            is_available = EXCLUDED.is_available,
            is_inexact_proportion = EXCLUDED.is_inexact_proportion,
            notes = EXCLUDED.notes,
            extraction_confidence = EXCLUDED.extraction_confidence,
            scraped_at = NOW();
    """

    dims = cell.get("dims") or {}
    value_text = cell.get("value_text")
    value_text_str = None
    if value_text is not None:
        # column is TEXT; store structured values losslessly as JSON string
        value_text_str = json.dumps(value_text, ensure_ascii=False)

    with conn.cursor() as cur:
        cur.execute(
            sql,
            (
                product_id,
                spec_definition_id,
                Json(dims),
                value_text_str,
                cell.get("numeric_value"),
                cell.get("unit_used"),
                cell.get("extraction_confidence"),
            ),
        )


def _upsert_document(conn, *, product_id: str, product: Dict[str, Any], doc: Dict[str, Any]) -> None:
    sql = """
        INSERT INTO product_document (
            product_id,
            brand_slug,
            product_type,
            product_slug,
            document_kind,
            title,
            url,
            source_url,
            status,
            raw_metadata
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'discovered', %s)
        ON CONFLICT (product_slug, document_kind, url) DO UPDATE SET
            product_id = COALESCE(EXCLUDED.product_id, product_document.product_id),
            brand_slug = COALESCE(EXCLUDED.brand_slug, product_document.brand_slug),
            product_type = COALESCE(EXCLUDED.product_type, product_document.product_type),
            title = COALESCE(EXCLUDED.title, product_document.title),
            source_url = COALESCE(EXCLUDED.source_url, product_document.source_url),
            raw_metadata = COALESCE(EXCLUDED.raw_metadata, product_document.raw_metadata);
    """

    source_url = None
    src = doc.get("source") or {}
    if isinstance(src, dict):
        source_url = src.get("url")

    with conn.cursor() as cur:
        cur.execute(
            sql,
            (
                product_id,
                product.get("brand_slug"),
                product.get("product_type"),
                product.get("slug"),
                doc.get("document_kind"),
                doc.get("title"),
                doc.get("url"),
                source_url,
                Json(doc.get("source") or {}),
            ),
        )


def _upsert_image(conn, *, product_id: str, product: Dict[str, Any], img: Dict[str, Any]) -> None:
    sql = """
        INSERT INTO product_image (
            product_id,
            url,
            kind,
            sort_order,
            source_url,
            raw_metadata
        )
        VALUES (%s, %s, %s, %s, %s, %s)
        ON CONFLICT (product_id, url) DO UPDATE SET
            kind = COALESCE(EXCLUDED.kind, product_image.kind),
            sort_order = COALESCE(EXCLUDED.sort_order, product_image.sort_order),
            source_url = COALESCE(EXCLUDED.source_url, product_image.source_url),
            raw_metadata = COALESCE(EXCLUDED.raw_metadata, product_image.raw_metadata);
    """

    source_url = None
    src = img.get("source") or {}
    if isinstance(src, dict):
        source_url = src.get("url") or product.get("manufacturer_url")

    with conn.cursor() as cur:
        cur.execute(
            sql,
            (
                product_id,
                img.get("url"),
                img.get("kind"),
                img.get("sort_order"),
                source_url,
                Json(img.get("raw_metadata") or {}),
            ),
        )


def persist_normalized_json(
    config: PersistenceConfig,
    normalized_json_path: str,
    db_url: str,
) -> Dict[str, Any]:
    payload = json.loads(Path(normalized_json_path).read_text(encoding="utf-8"))
    items = payload.get("items", []) or []

    conn = psycopg2.connect(db_url)
    try:
        conn.autocommit = False

        spec_def_ids_by_key = _load_spec_definition_ids(conn)

        counts = {
            "products_upserted": 0,
            "spec_records_upserted": 0,
            "matrix_cells_upserted": 0,
            "documents_upserted": 0,
            "images_upserted": 0,
            "spec_records_skipped_missing_definition": 0,
            "matrix_records_skipped_missing_definition": 0,
        }

        for item in items:
            product = item.get("product") or {}
            brand_slug = product.get("brand_slug") or config.brand_slug
            category_slug = product.get("category_slug")
            product_slug = product.get("slug")
            manufacturer_url = product.get("manufacturer_url")

            if not (brand_slug and category_slug and product_slug):
                raise RuntimeError(f"normalized item missing required product fields: {product!r}")

            brand_id, category_id = _lookup_ids(conn, brand_slug, category_slug)

            product_id = _upsert_product(
                conn,
                brand_id=brand_id,
                category_id=category_id,
                slug=product_slug,
                manufacturer_url=manufacturer_url,
                msrp_usd=product.get("msrp_usd"),
                primary_image_url=product.get("primary_image_url"),
                raw_payload={
                    "pipeline": {
                        "brand": payload.get("brand"),
                        "product_type": payload.get("product_type"),
                        "generated_at": payload.get("generated_at"),
                    },
                    "extraction": item.get("extraction"),
                    "run_summary": item.get("run_summary"),
                },
            )
            counts["products_upserted"] += 1

            for rec in item.get("spec_records", []) or []:
                normalized_key = rec.get("normalized_key")
                resolved_id = spec_def_ids_by_key.get(str(normalized_key)) if normalized_key else None
                if not resolved_id:
                    counts["spec_records_skipped_missing_definition"] += 1
                    continue

                _upsert_product_spec(
                    conn,
                    product_id=product_id,
                    rec={**rec, "spec_definition_id": resolved_id},
                )
                counts["spec_records_upserted"] += 1

            for matrix in item.get("matrix_records", []) or []:
                normalized_key = matrix.get("normalized_key")
                if not normalized_key:
                    continue
                spec_definition_id = spec_def_ids_by_key.get(str(normalized_key))
                if not spec_definition_id:
                    counts["matrix_records_skipped_missing_definition"] += 1
                    continue
                _upsert_matrix_parent_spec(
                    conn,
                    product_id=product_id,
                    spec_definition_id=spec_definition_id,
                    matrix_rec=matrix,
                )
                for cell in matrix.get("matrix_cells", []) or []:
                    _upsert_matrix_cell(
                        conn,
                        product_id=product_id,
                        spec_definition_id=spec_definition_id,
                        cell=cell,
                    )
                    counts["matrix_cells_upserted"] += 1

            for doc in item.get("documents", []) or []:
                _upsert_document(conn, product_id=product_id, product=product, doc=doc)
                counts["documents_upserted"] += 1

            for img in item.get("images", []) or []:
                _upsert_image(conn, product_id=product_id, product=product, img=img)
                counts["images_upserted"] += 1

        conn.commit()
        return {
            "normalized_json_path": normalized_json_path,
            "persisted_at": _utc_now().isoformat(),
            "counts": counts,
        }
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

