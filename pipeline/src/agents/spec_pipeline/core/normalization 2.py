import json
import re
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import psycopg2

from agents.spec_pipeline.core.extraction import _normalize_url
from agents.spec_pipeline.core.text_normalizer import clean_text_for_spec_value
from agents.spec_pipeline.core.table_normalizer import (
    normalize_canon_playback_display_format_table,
    normalize_canon_still_file_size_table,
    normalize_canon_wifi_security_table,
)
from services.spec_mapper import SpecMapperService


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _clean_extracted_label(text: str) -> str:
    """
    Best-effort cleanup for section/label strings coming from HTML extraction.

    Goals:
    - remove obvious HTML artifacts (tags, stray <br/> remnants)
    - normalize whitespace/tab/newline noise
    - keep the meaning intact (do not over-normalize)
    """
    s = (text or "").replace("\u00a0", " ").strip()
    if not s:
        return ""

    # Remove HTML tags that may leak through extraction
    s = re.sub(r"<[^>]+>", " ", s)

    # Canon pages sometimes leak weird artifacts like "@999br/>" into labels
    s = re.sub(r"@\s*\d+\s*br\s*/?>", " ", s, flags=re.IGNORECASE)

    # Normalize tabs/newlines and collapse whitespace
    s = s.replace("\t", " ").replace("\r", " ").replace("\n", " ")
    s = re.sub(r"\s+", " ", s).strip()
    return s


def _normalize_label_for_grouping(label: str) -> str:
    """
    Canonicalize a raw label for grouping in unmapped reports.

    We keep this conservative: the goal is to group obvious variants
    (case/spacing/punctuation), not to merge distinct concepts.
    """
    s = (label or "").strip().lower()
    s = s.replace("\u00a0", " ")  # nbsp
    s = s.rstrip(":")
    # collapse whitespace
    s = re.sub(r"\s+", " ", s)
    # normalize some punctuation variants
    s = s.replace("–", "-").replace("—", "-")
    return s


def build_unmapped_report(normalized_payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Build an aggregated report of unmapped attributes across all normalized items.

    This is written to JSON for prioritization/diffing during a mapping sprint.
    """
    items = normalized_payload.get("items", []) or []

    totals = {
        "items": len(items),
        "mapped_count": 0,
        "unmapped_count": 0,
        "tables_count": 0,
        "documents_count": 0,
    }

    # normalized_label -> aggregations
    raw_labels: Dict[str, Counter] = defaultdict(Counter)
    sections: Dict[str, Counter] = defaultdict(Counter)
    examples: Dict[str, List[Dict[str, Any]]] = defaultdict(list)

    for it in items:
        run_summary = it.get("run_summary") or {}
        totals["mapped_count"] += int(run_summary.get("mapped_count") or 0)
        totals["unmapped_count"] += int(run_summary.get("unmapped_count") or 0)
        totals["tables_count"] += int(run_summary.get("tables_count") or 0)
        totals["documents_count"] += int(run_summary.get("documents_count") or 0)

        product = it.get("product") or {}
        product_slug = product.get("slug")
        product_url = product.get("manufacturer_url")

        for rec in it.get("unmapped", []) or []:
            section = _clean_extracted_label(rec.get("section") or "")
            label = _clean_extracted_label(rec.get("label") or "")
            raw_value = rec.get("raw_value")

            norm = _normalize_label_for_grouping(label)
            if not norm:
                continue

            raw_labels[norm][label or norm] += 1
            if section:
                sections[norm][section] += 1

            # Keep a small set of examples per group.
            if len(examples[norm]) < 6:
                raw_value_str = raw_value if isinstance(raw_value, str) else json.dumps(raw_value, ensure_ascii=False)
                raw_value_str = (raw_value_str or "").strip()
                if len(raw_value_str) > 220:
                    raw_value_str = raw_value_str[:220] + "…"

                examples[norm].append(
                    {
                        "product_slug": product_slug,
                        "product_url": product_url,
                        "section": section,
                        "label": label,
                        "raw_value": raw_value_str,
                    }
                )

    top_unmapped: List[Dict[str, Any]] = []
    for norm, cnt in raw_labels.items():
        total = sum(cnt.values())
        # Most common raw label variant for readability.
        top_raw, _ = cnt.most_common(1)[0]
        top_unmapped.append(
            {
                "raw_label": top_raw,
                "normalized_label": norm,
                "count": total,
                "sections": dict(sections[norm].most_common(12)),
                "raw_label_variants": dict(cnt.most_common(12)),
                "examples": examples[norm],
                "suggested_action": "map_existing",  # placeholder; updated manually during sprint
            }
        )

    top_unmapped.sort(key=lambda x: int(x.get("count") or 0), reverse=True)

    return {
        "generated_at": normalized_payload.get("generated_at") or _utc_now_iso(),
        "brand": normalized_payload.get("brand"),
        "product_type": normalized_payload.get("product_type"),
        "item_count": len(items),
        "totals": totals,
        "top_unmapped": top_unmapped,
    }


@dataclass
class NormalizationConfig:
    brand_slug: str
    product_type: str
    category_slug: Optional[str] = None
    output_path: str = "data/company_product/_normalized/normalized.json"


def normalize_extractions(
    config: NormalizationConfig,
    extractions_json_path: str,
    db_url: str,
) -> Dict[str, Any]:
    payload = json.loads(Path(extractions_json_path).read_text(encoding="utf-8"))
    items = payload.get("items", [])

    conn = psycopg2.connect(db_url)
    try:
        mapper = SpecMapperService(conn, category_slug=config.category_slug)
        normalized_items: List[Dict[str, Any]] = []
        pdf_queue: List[Dict[str, Any]] = []

        for item in items:
            product_slug = item.get("product_slug")
            product_url = _normalize_url(item.get("product_url", ""))
            raw_html_path = item.get("raw_html_path")
            extraction_errors = item.get("errors", []) or []
            extraction_completeness = item.get("completeness", {}) or {}
            msrp_usd = item.get("msrp_usd")

            spec_records: List[Dict[str, Any]] = []
            unmapped: List[Dict[str, Any]] = []
            table_records: List[Dict[str, Any]] = []
            documents: List[Dict[str, Any]] = []
            matrix_records: List[Dict[str, Any]] = []
            images: List[Dict[str, Any]] = []
            primary_image_url: Optional[str] = None

            for img in item.get("images", []) or []:
                if not isinstance(img, dict):
                    continue
                url = (img.get("url") or "").strip()
                if not url:
                    continue
                kind = img.get("kind")
                if primary_image_url is None and kind == "primary":
                    primary_image_url = _normalize_url(url)
                images.append(
                    {
                        "url": _normalize_url(url),
                        "kind": kind,
                        "sort_order": img.get("sort_order"),
                        "source": img.get("source") or {"type": "web", "url": product_url},
                        "raw_metadata": img.get("raw_metadata") or {},
                    }
                )
            if primary_image_url is None and images:
                # fallback: first image in list
                primary_image_url = images[0].get("url")

            for section in item.get("manufacturer_sections", []) or []:
                section_name_raw = section.get("section_name", "") or ""
                section_name = _clean_extracted_label(section_name_raw)
                for attr in section.get("attributes", []) or []:
                    raw_key_raw = attr.get("raw_key", "") or ""
                    raw_key = _clean_extracted_label(raw_key_raw)
                    raw_value = attr.get("raw_value", "") or ""
                    ctx = attr.get("context") or {}

                    # Document handling: PDF links are assets, not specs
                    if ctx.get("pdf_url"):
                        documents.append(
                            {
                                "document_kind": "technical_specs_pdf",
                                "url": ctx.get("pdf_url"),
                                "source": {
                                    "type": "web",
                                    "url": product_url,
                                    "section": section_name,
                                    "label": raw_key,
                                },
                            }
                        )
                        continue

                    # Table handling: defer to later matrix normalizer
                    if raw_value == "[table]":
                        table_rec = {
                            "section": section_name,
                            "label": raw_key,
                            "raw_value": raw_value,
                            "raw_value_jsonb": {
                                "source": {"type": "web", "url": product_url, "section": section_name, "label": raw_key},
                                "table_html": ctx.get("table_html"),
                                "text_fallback": ctx.get("text_fallback"),
                            },
                        }

                        # Attempt concrete table→matrix conversions (Canon tables we explicitly support).
                        mapped_table = mapper.map_spec(raw_key=raw_key, raw_context=section_name, raw_value=raw_value)
                        mapped_key = None
                        if mapped_table:
                            mapped_key = mapper.definitions.get(mapped_table["spec_definition_id"], {}).get("normalized_key")

                        table_html = (ctx.get("table_html") or "")
                        converted = False

                        if mapped_key == "still_image_file_size_table":
                            normalized = normalize_canon_still_file_size_table(table_html)
                            matrix_records.append(
                                {
                                    "normalized_key": "still_image_file_size_table",
                                    "spec_value": "See product_spec_matrix",
                                    "raw_value": "HTML table: File Size (approx. MB) / possible shots / max burst",
                                    "raw_value_jsonb": {
                                        "source": {"type": "web", "url": product_url, "section": section_name, "label": raw_key},
                                        "dims": normalized.get("dims"),
                                        "value_fields": normalized.get("value_fields"),
                                    },
                                    "matrix_cells": normalized.get("cells", []),
                                }
                            )
                            converted = True

                        if mapped_key == "playback_display_format_table":
                            normalized = normalize_canon_playback_display_format_table(table_html)
                            matrix_records.append(
                                {
                                    "normalized_key": "playback_display_format_table",
                                    "spec_value": "See product_spec_matrix",
                                    "raw_value": "HTML table: Display Format (Still Photo vs Movie)",
                                    "raw_value_jsonb": {
                                        "source": {"type": "web", "url": product_url, "section": section_name, "label": raw_key},
                                        "dims": normalized.get("dims"),
                                        "value_fields": normalized.get("value_fields"),
                                    },
                                    "matrix_cells": normalized.get("cells", []),
                                }
                            )
                            converted = True

                        if mapped_key == "wifi_security_table":
                            normalized = normalize_canon_wifi_security_table(table_html)
                            matrix_records.append(
                                {
                                    "normalized_key": "wifi_security_table",
                                    "spec_value": "See product_spec_matrix",
                                    "raw_value": "HTML table: Wi-Fi Security (Authentication/Encryption)",
                                    "raw_value_jsonb": {
                                        "source": {"type": "web", "url": product_url, "section": section_name, "label": raw_key},
                                        "dims": normalized.get("dims"),
                                        "value_fields": normalized.get("value_fields"),
                                    },
                                    "matrix_cells": normalized.get("cells", []),
                                }
                            )
                            converted = True

                        table_rec["converted_to_matrix"] = converted

                        table_records.append(
                            {
                                **table_rec
                            }
                        )
                        continue

                    mapped = mapper.map_spec(raw_key=raw_key, raw_context=section_name, raw_value=raw_value)
                    if not mapped:
                        unmapped.append(
                            {
                                "section": section_name,
                                "label": raw_key,
                                "raw_value": raw_value,
                                "source": {
                                    "type": "web",
                                    "url": product_url,
                                    "section": section_name,
                                    "label": raw_key,
                                },
                            }
                        )
                        continue

                    def_id = mapped["spec_definition_id"]
                    definition = mapper.definitions.get(def_id, {})

                    spec_records.append(
                        {
                            "spec_definition_id": def_id,
                            "normalized_key": definition.get("normalized_key"),
                            # Preserve raw_value; clean spec_value for UI
                            "spec_value": clean_text_for_spec_value(mapped.get("value_text") or raw_value),
                            "raw_value": raw_value,
                            "numeric_value": mapped.get("numeric_value"),
                            "boolean_value": mapped.get("boolean_value"),
                            "unit_used": mapped.get("unit_used"),
                            "extraction_confidence": 0.9,
                            "source": {
                                "type": "web",
                                "url": product_url,
                                "section": section_name,
                                "label": raw_key,
                            },
                        }
                    )

            normalized_items.append(
                {
                    "product": {
                        "brand_slug": config.brand_slug,
                        "category_slug": config.category_slug,
                        "product_type": config.product_type,
                        "slug": product_slug,
                        "manufacturer_url": product_url,
                        "msrp_usd": msrp_usd,
                        "primary_image_url": primary_image_url,
                    },
                    "extraction": {
                        "raw_html_path": raw_html_path,
                        "errors": extraction_errors,
                        "completeness": extraction_completeness,
                    },
                    "spec_records": spec_records,
                    "table_records": table_records,
                    "matrix_records": matrix_records,
                    "documents": documents,
                    "images": images,
                    "unmapped": unmapped,
                    "run_summary": {
                        "mapped_count": len(spec_records),
                        "unmapped_count": len(unmapped),
                        "tables_count": len(table_records),
                        "documents_count": len(documents),
                        "images_count": len(images),
                    },
                }
            )

            # HTML inconsistency handling: decide if we need PDFs for this product.
            needs_pdf_reasons: List[str] = []
            needs_pdf = False
            if extraction_errors:
                needs_pdf = True
                needs_pdf_reasons.append("extraction_errors")
            if extraction_completeness.get("needs_pdf") is True:
                needs_pdf = True
                needs_pdf_reasons.append("low_completeness")

            # If Canon HTML has no sections but we did find a PDF link, treat as needs_pdf.
            if len(spec_records) == 0 and len(unmapped) == 0 and len(documents) > 0:
                needs_pdf = True
                needs_pdf_reasons.append("no_html_specs")

            # Add needs_pdf + reasons to the last appended item (same product)
            normalized_items[-1]["needs_pdf"] = needs_pdf
            normalized_items[-1]["needs_pdf_reasons"] = needs_pdf_reasons

            if needs_pdf:
                for doc in documents:
                    if doc.get("document_kind") == "technical_specs_pdf" and doc.get("url"):
                        pdf_queue.append(
                            {
                                "brand": config.brand_slug,
                                "product_type": config.product_type,
                                "product_slug": product_slug,
                                "product_url": product_url,
                                "pdf_url": doc["url"],
                                "pdf_kind": "technical_specs_pdf",
                                "reason": ";".join(needs_pdf_reasons) or "needs_pdf",
                                "status": "needs_download",
                            }
                        )

        normalized_payload = {
            "brand": config.brand_slug,
            "product_type": config.product_type,
            "generated_at": _utc_now_iso(),
            "source_extractions_path": extractions_json_path,
            "items": normalized_items,
            "pdf_queue": pdf_queue,
        }

        # Also write an aggregated unmapped report alongside normalized output.
        # This is a deterministic artifact used for mapping iteration loops.
        try:
            out_path = Path(config.output_path)
            report_path = out_path.parent / "unmapped_report.json"
            report = build_unmapped_report(normalized_payload)
            report_path.parent.mkdir(parents=True, exist_ok=True)
            report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        except Exception:
            # Never fail the core normalization output due to reporting.
            pass

        return normalized_payload
    finally:
        conn.close()

