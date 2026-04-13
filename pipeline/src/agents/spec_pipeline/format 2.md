## Spec pipeline format (DB-first, UI-friendly, LLM-friendly)

This document is a **playbook** for how we ingest specs (website + PDFs), normalize them, and store them in Postgres/Supabase in a way that supports:

- **interactive UIs** (filters, compare, charts, accordions)
- **reliable scraping/normalization** (typed values + provenance)
- **LLM querying** (clean keys + structured text/JSON to retrieve)

It also records the **gotchas/issues** we hit while evolving the schema and local dev workflow.

---

## Core design goals

- **One canonical key per spec** (`spec_definition.normalized_key`)
- **One row per product/spec** (`product_spec` unique on `(product_id, spec_definition_id)`)
- **Typed values whenever possible** (numeric/range/boolean) to enable search, sorting, charts, and comparisons
- **Provenance preserved** (raw strings + optional structured JSON) so we can debug extraction and cite sources
- **Tabular specs** (PDF tables) handled as **structured child data**, not shoved into a single text blob

---

## Database taxonomy (normalized backbone)

### Tables (singular naming)

- **`brand`**: Canon, Sony, etc.
- **`product_category`**: Cameras, Lenses, etc. (with parent categories)
- **`product`**: a camera model (brand/category/model/name/slug + metadata)
- **`spec_section`**: UI/semantic grouping (General, Image Sensor, Display, Shutter, Storage, etc.)
- **`spec_definition`**: canonical spec key taxonomy (Effective Pixels, Lens Mount, etc.)
- **`product_spec`**: per-product values for each `spec_definition`

### Key idea: `spec_definition` is the canonical “key”

We do **not** store a denormalized `spec_key` on `product_spec`. The key is always:

- `spec_definition.normalized_key`  (canonical key)
- `spec_definition.display_name`    (human label)
- `spec_definition.unit`            (canonical/default unit)

`product_spec` stores the values and any source/unit differences:

- `spec_value` (cleaned display text)
- `raw_value` (verbatim extraction string, may be messy/not JSON)
- `raw_value_jsonb` (optional structured provenance/extraction artifacts)
- `numeric_value/min_value/max_value` (for filtering/graphs/ranges)
- `unit_used` (what the source actually used; may differ from canonical)
- `boolean_value`
- `extraction_confidence` (0–1)

### Why we removed denormalized fields from `product_spec`

We originally had `product_spec.spec_section` and `product_spec.spec_key` as TEXT. This was removed because it can drift:

- typos / casing differences
- renaming sections breaks historical rows
- conflicting “same meaning, different string” issues

Instead, section + key come from joins:

- `product_spec` → `spec_definition` → `spec_section`

---

## Handling units and normalization

### Canonical unit vs observed unit

- **`spec_definition.unit`**: what we want as the canonical unit (target for normalization)
- **`product_spec.unit_used`**: what the source used (oz, g, in, mm, stops, ISO, etc.)

**Do not hardcode `unit_used` just because a canonical unit exists.**

### Numeric normalization guidelines

- If the value is a scalar number, populate:
  - `numeric_value`
  - `unit_used` (if known)
  - `spec_value` (human-friendly string)

- If it’s a range, populate:
  - `min_value`, `max_value`
  - `unit_used`
  - `spec_value` (human-friendly range text)

- If it’s boolean-like:
  - `boolean_value`
  - `spec_value` (“Yes/No” + short detail)

### “Stops” as a unit

`unit_used = 'stops'` is valid for things like stabilization, exposure compensation, etc.

---

## Handling tabular specs (PDF tables, matrix-like specs)

Some specs are not “single value” — they’re tables/matrices (e.g. “Recording pixels — cropping & aspect ratios”).

### The pattern

1) Create a parent `spec_definition` for the table spec
   - `normalized_key` example: `still_image_recording_pixels`
   - `data_type` can be `'matrix'` (string taxonomy)

2) Insert a parent `product_spec` row for discoverability:
   - `spec_value`: “See matrix rows”
   - `raw_value`: human pointer (“PDF table: …”)
   - `raw_value_jsonb`: structured provenance (source, notes, dimension keys)

3) Store the actual table cells in a child table:
   - **`product_spec_matrix`**

### `product_spec_matrix` shape (generic “cell table”)

Each row is one “cell”:

- `product_id`
- `spec_definition_id` (points to the table spec key)
- `dims JSONB NOT NULL` (unbounded dimensions)
  - example:
    - `{"media_type":"JPEG/HEIF","image_size":"L","aspect_ratio":"3:2"}`

Value fields (small universal set):

- `numeric_value` (e.g., MP)
- `unit_used` (e.g., MP)
- `width_px`, `height_px` (for pixel dimension tables)
- `value_text` (e.g., “Not available”)

Metadata:

- `is_available` boolean
- `is_inexact_proportion` boolean (PDF shading marker)
- `notes` text
- `extraction_confidence`

**Why JSONB `dims`**:

- avoids “dim1..dim15” empty columns
- supports future tables with many axes (quality, crop, bit-depth, etc.)
- indexable with GIN if needed

---

## Views for UI-friendly shapes

We create views so the frontend doesn’t need to reshape raw rows.

Example view:

- `v_still_image_recording_pixels_grid`
  - one row per `(product_slug, media_type, image_size)`
  - `cells` JSON keyed by `aspect_ratio`
  - includes `{mp, width_px, height_px, availability flags, notes}`

This supports:

- accordion/table display
- compare view
- easy API payloads

---

## Seeding pattern (manual skeleton → scalable ingestion)

### Why seed at all

Seed entries establish a “clean skeleton” so:

- taxonomy exists (`spec_definition`, `spec_section`)
- UI can be built immediately
- later scraping can update/overwrite with confidence and provenance

### Seed conventions

- Use `ON CONFLICT DO NOTHING` on inserts for idempotency
- Use PL/pgSQL `DO $$ ... $$` blocks for “lookup IDs then insert rows”
- Avoid variable names that conflict with column names (see gotchas)

### Gotcha: ambiguous `product_id` variable

In PL/pgSQL blocks, a variable named `product_id` conflicted with the `product_id` column in `INSERT ... SELECT`.

Fix: prefix variables with `v_`:

- `v_product_id`, `v_cat_id`, etc.

---

## Migration + local dev workflow (Supabase CLI)

### Goal

Stop copy/pasting schema/seed into Supabase Cloud SQL editor and instead have:

- versioned migrations
- repeatable local reset
- predictable push to cloud

### What we set up

- `supabase/` directory via `supabase init`
- `supabase/migrations/*.sql` migration files
- `supabase/config.toml` configured to seed from `backend/db/seed.sql`

### Local run loop

- `supabase start` (requires Docker daemon)
- `supabase db reset` (rebuild schema + seed)
- use **Supabase Studio** at `http://localhost:54323`:
  - Table Editor: browse rows
  - SQL Editor: run queries and see results

### Gotcha: Docker daemon not running

`supabase start` failed with:

- “Cannot connect to the Docker daemon…”

Fix: start Docker Desktop or Colima.

### Gotcha: psql meta-commands in migrations/seeds

We initially tried to use:

- `\set ON_ERROR_STOP on`
- `\ir path/to/file.sql`

These are `psql` meta-commands and **not valid SQL** when Supabase executes migration files.

Fix:

- migrations must contain plain SQL
- seed paths in `supabase/config.toml` should point directly to an SQL file (no `\ir`)

### Best practice for future schema changes

Do not edit the init migration after it’s established. Instead:

- create new migrations for incremental schema changes
- reset locally to test:
  - `supabase db reset`
- push to hosted project:
  - `supabase link --project-ref <ref>`
  - `supabase db push`

---

## Extraction confidence guidelines

Use `extraction_confidence` to reflect how direct the value is:

- **1.0**: verbatim from an official spec table / clearly labeled field
- **0.9–0.95**: strong match but mild formatting normalization
- **0.7–0.85**: derived/inferred (e.g., “focal length multiplier 1.0x because full-frame”)
- **< 0.7**: uncertain; prefer leaving blank until confirmed

Never guess values if the source cannot be verified—store a TODO or omit the spec until verified.

---

## Why this structure supports “hands-on” UI + LLM queries

### UI (JS queries)

- filtering/sorting uses typed columns (`numeric_value`, `min/max`, booleans)
- grouping uses `spec_section`
- complex tables use `product_spec_matrix` + views

### LLM

LLMs benefit from:

- stable keys (`normalized_key`)
- clear display names (`display_name`)
- provenance (`raw_value`, `raw_value_jsonb`)
- pre-grouped views for retrieval (one query to fetch a structured payload)

---

## Suggested agent responsibilities (for later implementation)

### Discovery Agent

- finds product pages + PDFs
- outputs URLs + candidate sections

### Extraction Agent

- extracts raw key/value pairs
- extracts table specs into structured JSON (dims + cells)
- outputs `raw_value` (verbatim) and `raw_value_jsonb` (structured)

### Normalization Agent

- maps raw keys to `spec_definition.normalized_key`
- parses numeric/range/boolean
- sets `unit_used`
- sets `extraction_confidence`
- writes to `product_spec` and `product_spec_matrix`

---

## Agent output contract (what each stage must emit)

This contract is designed so you can swap implementations (Playwright scraper vs PDF parser vs LLM extractor)
without changing the downstream normalization + DB writer.

### Contract principles

- **Every extracted spec must be traceable** to a source: URL/PDF + location.
- Keep **both**:
  - verbatim text (`raw_value`) and
  - structured data (`raw_value_jsonb`, table cells)
- For tabular specs: emit both
  - parent spec (a single object keyed by `normalized_key`), and
  - `matrix_cells[]` rows (one per “cell”).

### 1) Discovery output (URL inventory)

```json
{
  "brand": "canon",
  "product_type": "camera",
  "category_slug": "mirrorless-cameras",
  "listing_urls": ["https://www.usa.canon.com/shop/cameras/mirrorless-cameras"],
  "product_url_pattern": "/shop/p/",
  "discovery_date": "2025-12-28T04:16:22.936985+00:00",
  "total_urls": 15,
  "urls": [
    "https://www.usa.canon.com/shop/p/eos-r6-mark-iii"
  ],
  "stats": {
    "duplicates_removed": 0,
    "listing_urls": {
      "https://www.usa.canon.com/shop/cameras/mirrorless-cameras": {
        "url_pagination_pages_checked": 7,
        "url_pagination_pages_with_products": 4,
        "url_pagination_consecutive_empty_pages": 3,
        "fragments_stripped": 40,
        "excluded_urls": 181,
        "excluded_by_substring": { "kit": 141 }
      }
    }
  }
}
```

### 2) Extraction output (raw manufacturer keys grouped by manufacturer sections)

We standardize on a **list-of-sections** shape because it supports:
- per-attribute `context` (PDF URLs, table HTML, etc.)
- keeping table values structured without flattening

```json
{
  "brand": "canon",
  "product_type": "camera",
  "generated_at": "2025-12-28T04:17:37.953172+00:00",
  "total_items": 15,
  "items": [
    {
      "product_url": "https://www.usa.canon.com/shop/p/eos-r6-mark-iii",
      "product_slug": "eos-r6-mark-iii",
      "raw_html_path": "data/company_product/canon/raw_html/eos-r6-mark-iii.html",
      "manufacturer_sections": [
        {
          "section_name": "View Full Technical Specs PDF",
          "attributes": [
            {
              "raw_key": "Techs. Specs. Detailed PDF",
              "raw_value": "View Full Details of Technical Specification",
              "context": {
                "pdf_url": "https://s7d1.scene7.com/is/content/canon/EOSR6-Mark3-Spec-Sheetpdf"
              }
            }
          ]
        }
      ],
      "errors": [],
      "completeness": {
        "total_sections": 26,
        "total_attributes": 139,
        "tables_found": 0,
        "pdf_urls_found": 1,
        "needs_pdf": false
      }
    }
  ]
}
```

### 3) Normalization output (DB-ready, typed, canonical)

Normalization emits a list of `spec_records[]`. Each record maps to exactly one `spec_definition.normalized_key`.

Policy:
- **`raw_value` is preserved verbatim** for provenance/debugging.
- **`spec_value` is cleaned deterministically** (whitespace + bullet cleanup) for UI display.
- PDF links are **documents**, not specs: they are surfaced as `documents[]` in normalized output and persisted into `product_document` during the `persist` stage.
- HTML tables are emitted as `table_records[]` and selected tables are converted into `matrix_records[]` + `matrix_cells[]`.
  - Implemented conversions: `still_image_file_size_table`, `playback_display_format_table`, `wifi_security_table`

```json
{
  "brand": "canon",
  "product_type": "camera",
  "generated_at": "2025-12-28T04:17:37.953172+00:00",
  "source_extractions_path": "data/company_product/canon/processed_data/camera/extractions.json",
  "items": [
    {
      "product": {
        "brand_slug": "canon",
        "category_slug": "mirrorless-cameras",
        "product_type": "camera",
        "slug": "eos-r6-mark-iii",
        "manufacturer_url": "https://www.usa.canon.com/shop/p/eos-r6-mark-iii"
      },
      "extraction": {
        "raw_html_path": "data/company_product/canon/raw_html/eos-r6-mark-iii.html",
        "errors": [],
        "completeness": {
          "total_sections": 26,
          "total_attributes": 139,
          "tables_found": 0,
          "pdf_urls_found": 1,
          "needs_pdf": false
        }
      },
      "spec_records": [
        {
          "spec_definition_id": "00000000-0000-0000-0000-000000000000",
          "normalized_key": "effective_pixels",
          "spec_value": "Approx. 32.5 million pixels",
          "raw_value": "Approx. 32.5 million pixels",
          "numeric_value": null,
          "boolean_value": null,
          "unit_used": null,
          "extraction_confidence": 0.9,
          "source": {
            "type": "web",
            "url": "https://www.usa.canon.com/shop/p/eos-r6-mark-iii",
            "section": "Image Sensor",
            "label": "Effective Pixels"
          }
        }
      ],
      "table_records": [
        {
          "section": "Playback",
          "label": "Display Format",
          "raw_value": "[table]",
          "converted_to_matrix": true
        }
      ],
      "matrix_records": [
        {
          "normalized_key": "playback_display_format_table",
          "spec_value": "See product_spec_matrix",
          "raw_value": "HTML table: Display Format (Still Photo vs Movie)",
          "matrix_cells": [
            {
              "dims": { "item": "Grid display" },
              "value_text": {
                "still_photo": "Off / 3×3 / 6×4 / 3×3+diag",
                "movie": "-"
              }
            }
          ]
        }
      ],
      "documents": [
        {
          "document_kind": "technical_specs_pdf",
          "url": "https://s7d1.scene7.com/is/content/canon/EOSR6-Mark3-Spec-Sheetpdf"
        }
      ]
    }
  ]
}
```

### 4) Validation output (quality + what to fix)

```json
{
  "valid": true,
  "quality_score": 0.92,
  "errors": [],
  "warnings": [
    {
      "normalized_key": "max_resolution",
      "issue": "Value seems to describe video Open Gate, not max still resolution",
      "confidence": 0.7
    }
  ],
  "flagged_for_review": [
    {"normalized_key":"focal_length_multiplier","reason":"inferred full-frame crop factor"}
  ]
}
```

### 5) Persistence output (what was written to DB)

```json
{
  "product_slug": "eos-r6-mark-iii",
  "upserts": {
    "spec_definitions_created": 3,
    "product_specs_upserted": 27,
    "product_spec_matrix_rows_upserted": 25
  },
  "conflicts": {
    "product_specs_ignored_due_to_conflict": 0
  }
}
```

---

## Notes (practical)

- **Spec definition IDs are environment-specific**: UUIDs in `normalized.json` are not stable across DB resets.
  - Persist should resolve `spec_definition_id` by `normalized_key` in the current DB.

- **Tables → matrices are intentional**: we only convert tables when we have a canonical matrix key + a deterministic parser.