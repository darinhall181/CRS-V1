## Spec pipeline implementation plan (core + plugin specializations)

This document is the **master implementation plan** for finishing `backend/src/agents/spec_pipeline/` into a scalable ingestion system.

It is intentionally aligned with:

- the DB-first model in `backend/src/agents/spec_pipeline/format.md`
- the robust Canon crawling patterns in `src/website_scrapers/canon_scraper.py`

This is written for **iteration speed** first, while keeping an obvious path to scaling across **many brands** and **many product types**.

---

## Short “why we changed” note (migration)

We moved away from “6 files per brand per product type” (e.g. `canon_discovery.py`, `canon_extractor.py`, …) because that explodes into hundreds of tiny modules and makes refactors painful.

Instead we use a **hybrid model** + **minimal plugin modules**:

- **Product type first** (cameras vs lenses behave differently)
- **Brand plugins inside that type** (Canon camera ≠ Sony camera)
- **One `plugin.py` per brand+type** (start minimal; split later only if needed)

---

## Guiding principles (non-negotiables)

- **Contract-first**: every stage emits the shapes described in `format.md` (Discovery → Extraction → Normalization → Validation → Persistence).
- **Deterministic extraction first**: HTML/PDF parsing should be tools + parsers. LLMs are reserved for ambiguous mapping and review assistance.
- **DB rules before LLM**: use `spec_mapping` (DB table) to map raw keys → `spec_definition`. LLM proposes new mappings only when no rule matches.
- **Never guess**: if a value cannot be verified from a source artifact, do not fabricate it; emit a TODO/flag with low confidence.
- **Matrix/table specs** must go into `product_spec_matrix` (plus a parent `product_spec` + provenance JSONB).

---

## Folder taxonomy (hybrid model)

### 1) `spec_pipeline/core/` (shared infrastructure)

Core holds stable contracts + shared primitives:

- discovery primitives (pagination, filtering, output shape validation)
- extraction primitives
- registry/loader for “which plugin do I run?”

### 2) `spec_pipeline/product/<type>/<brand>/` (brand+type plugins)

This is where most implementation lives.

Example:

- `spec_pipeline/product/camera/canon/plugin.py`
- `spec_pipeline/product/camera/sony/plugin.py`
- `spec_pipeline/product/lens/canon/plugin.py`

Start minimal: **one file per brand+type**.
When (and only when) the plugin grows too large, split into `discovery.py`, `extractor.py`, etc. inside that brand folder.

### 3) Optional `spec_pipeline/brand/<brand>/` (shared brand helpers)

Only introduce this when you find real cross-type reuse for a brand, e.g.:

- Canon “shop client” / cookie logic shared by camera and lens discovery

---

## Minimal plugin contract (initial)

Each `plugin.py` should export:

- `BRAND_SLUG`: `str`
- `PRODUCT_TYPE`: `str`
- `DISCOVERY_CONFIG`: `DiscoveryConfig` (hardcoded dev config for now)
- optional future exports:
  - `extract(product_url) -> ExtractionOutput`
  - `normalize(extraction) -> NormalizationOutput`
  - `validate(records) -> ValidationOutput`
  - `persist(records) -> PersistenceOutput`

---

## Runner workflow (hardcoded default + CLI overrides)

We support **both**:

- **Hardcoded default**: fastest dev loop (no flags required)
- **CLI overrides**: scalable (same runner can execute any plugin)

Important: runner selection style is **separate** from Supabase migration workflow.
Migrations are for schema/baseline seeds; the runner is for runtime ingestion.

---

## Discovery-only data flow (today)

```mermaid
flowchart TD
  Runner[backend/scripts/run.py] -->|"defaults_or_cli"| Registry[core/registry.py]
  Registry --> Plugin[product/camera/canon/plugin.py]
  Plugin --> DiscoveryCore[core/discovery.py]
  DiscoveryCore --> UrlInventory[data/url_lists/canon_camera_urls.json]
```

---

## Current implementation status (what we built so far)

This section documents the **exact working pipeline** we implemented for Canon mirrorless cameras, including where files are written and how the DB-driven mapping loop improves over time.

### Canon camera plugin entrypoint

- Plugin: `backend/src/agents/spec_pipeline/product/camera/canon/plugin.py`
- It currently supports four runnable stages via `backend/scripts/run.py`:
  - `--stage discovery`
  - `--stage extraction`
  - `--stage normalize`
  - `--stage persist`

### Stage 1: Discovery (URL inventory JSON)

**Code**
- Discovery implementation: `backend/src/agents/spec_pipeline/core/discovery.py`
- Canon plugin config: `DISCOVERY_CONFIG` in `product/camera/canon/plugin.py`
- Registry: `backend/src/agents/spec_pipeline/core/registry.py`

**Filters implemented**
- include `/shop/p/` only
- exclude query strings (`?`) and refurbished
- strip URL fragments (e.g. `#toreviews`) for dedupe
- exclude slug substrings:
  - `kit`
  - `with-cropping-guide-firmware`
  - `with-stop-motion-animation-firmware`

**Output**
- `data/url_lists/canon_camera_urls.json`

**Run**
```bash
python3 backend/scripts/run.py --stage discovery
```

### Stage 2: Extraction (HTML → manufacturer_sections)

**Code**
- Extractor: `backend/src/agents/spec_pipeline/core/extraction.py`
- Canon extraction config: `EXTRACTION_CONFIG` in `product/camera/canon/plugin.py`

**Inputs**
- For Canon, we prefer your on-disk HTML cache:
  - reads `data/company_product/canon/raw_html/{slug}.html`
  - `cache_only=true` means “do not hit the network if missing”

**Outputs**
- Extraction JSON:
  - `data/company_product/canon/processed_data/camera/extractions.json`
- Optional fetched HTML artifact folder (only used if cache fallback is enabled):
  - `data/company_product/canon/processed_data/camera/raw_html/`

**Product images captured**
- Canon product page images are extracted from cached HTML and stored on each extraction item as:
  - `images[]` (list of `{url, kind, sort_order, source, raw_metadata}`)

**PDF links captured**
- If a spec attribute contains a PDF link, extraction stores:
  - `context.pdf_url`

**Completeness heuristics**
- Each item includes `completeness` (sections/attributes/tables/pdf_urls_found + `needs_pdf` flag).
  - This is used to identify products where Canon HTML is incomplete or absent.

**Run**
```bash
python3 backend/scripts/run.py --stage extraction
```

### Product documents: persist PDF URLs as rows (Option B)

We store PDF URLs in a dedicated table so they’re queryable and trackable (download/parse status).

**DB**
- Table: `product_document`
- Migration: `supabase/migrations/20251228000000_add_product_document.sql`
- Schema mirror: `backend/db/schema.sql`

**How PDFs work today (important)**
- We **capture the PDF URL** during extraction as `context.pdf_url`.
- Normalization routes that into `documents[]` (they are assets, not specs).
- Persistence (`--stage persist`) upserts `documents[]` into `product_document`.

Optional/legacy helper:
- `backend/scripts/import_documents_from_extractions.py` (imports PDF URLs from `extractions.json` directly)
  - You generally don't need this anymore if you're running `normalize` + `persist`.

### Stage 3: Normalization + Mapping (DB-driven)

**Code**
- Normalizer: `backend/src/agents/spec_pipeline/core/normalization.py`
- Text cleanup (display-facing): `backend/src/agents/spec_pipeline/core/text_normalizer.py`
- Mapping engine: `backend/src/services/spec_mapper.py`

**Important policies**
- Preserve `raw_value` verbatim for provenance.
- Compute a cleaned `spec_value` for UI display (bullet/spacing normalization).
- Clean obvious HTML artifacts in extracted labels/section names (e.g. `@999br/>`) so unmapped keys don’t fragment into duplicates.
- Do not treat PDF links as specs:
  - they are emitted as `documents[]` in normalized output
  - and persisted into `product_document` via `--stage persist`
- Table placeholders are kept in `table_records[]` and *select tables* are converted into `matrix_records[]`.
- Do not treat product images as specs:
  - they are emitted as `images[]` in normalized output
  - and persisted into `product_image` via `--stage persist`

**Output**
- `data/company_product/canon/processed_data/camera/normalized.json`
- Each product includes `run_summary` counts:
  - mapped/unmapped/tables/documents/images
- Each product also includes:
  - `extraction` (raw_html_path, extraction errors, completeness)
  - `needs_pdf` + `needs_pdf_reasons`
- A PDF queue is generated for manual download:
  - `data/company_product/canon/processed_data/camera/pdf_queue.json`
- An unmapped backlog report is generated for mapping sprints:
  - `data/company_product/canon/processed_data/camera/unmapped_report.json`

#### Table pipeline (implemented): Canon HTML tables → matrix_records

We convert specific Canon HTML tables (where we have a canonical `spec_definition` and a deterministic parser) into `matrix_records[]` + `matrix_cells[]`.

Currently implemented conversions:

1) **Recording System → "File Size"**

- `normalized_key = still_image_file_size_table`
- `matrix_cells[]` dims: `format_group`, `quality`
- `numeric_value` stores file size in MB when the cell is a single numeric (e.g., `8.3`)
- `value_text` preserves the other table columns (`possible_shots`, `max_burst`) and the original file-size cell text

Note: some Canon rows express file size like `27.5 + 8.3`. For v1 we keep the full expression in `value_text.file_size_cell` and set `numeric_value` to the first numeric token (so we never lose information while keeping a usable numeric).

2) **Playback → "Display Format"**

- `normalized_key = playback_display_format_table`
- `matrix_cells[]` dims: `item`
- `value_text` contains `still_photo` and `movie`

3) **Wi‑Fi → "Security"**

- `normalized_key = wifi_security_table`
- `matrix_cells[]` dims: `connection_method`, `authentication`
- `value_text` contains `encryption` and `key_format_and_length`

Each conversion:
- emits a `matrix_records[]` entry in `normalized.json`
- marks the original `table_records[]` entry with `converted_to_matrix=true`
- persists into `product_spec_matrix` via `--stage persist`

**Run**
```bash
export DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
python3 backend/scripts/run.py --stage normalize
```

### HTML inconsistency handling (Canon reality)

Canon’s shop pages are not consistent: some products may have **no `tech-spec-data` block** even though a PDF exists.

We handle this by:

- adding extraction `completeness` metrics (section/attribute counts) + `needs_pdf`
- propagating those fields into normalized output
- generating `pdf_queue.json` when `needs_pdf=true` and a PDF URL exists

This keeps the pipeline moving without blocking on PDF extraction implementation.

### Mapping iteration loop (how unmapped drops over time)

Mappings live in the DB table `spec_mapping`. The workflow is:
- run normalize
- inspect `unmapped_report.json` (or per-product `unmapped[]` in `normalized.json`)
- add context-aware mapping rules as migrations
- reset/apply migrations
- re-run normalize and re-check counts

**Migration we added for Canon camera label variants**
- `supabase/migrations/20251228002000_seed_spec_mapping_canon_camera.sql`

**Note on regex escaping**
- We normalize double-backslashes when compiling regex in Python so the same patterns work when seeded via SQL.

**Additional Canon mapping batches (example)**
- `supabase/migrations/20251228006000_seed_spec_mapping_canon_camera_batch1.sql`
- …
- `supabase/migrations/20251228014000_seed_spec_mapping_canon_camera_batch8.sql`

### Product images: persist image URLs as rows

We store product image URLs in a dedicated table so they’re queryable and trackable (and can support primary vs gallery ordering).

**DB**
- Table: `product_image`
- Migration: `supabase/migrations/20251228015000_add_product_image.sql`
- Schema mirror: `backend/db/schema.sql`

**How images work today**
- We extract `images[]` from Canon HTML (og:image, JSON-LD, fotorama gallery, and Scene7 `<img>` fallbacks).
- Normalization includes `images[]` in `normalized.json`.
- Persistence (`--stage persist`) upserts images into `product_image`.

## Next steps (current roadmap)

- **Mapping coverage sprint**: reduce `unmapped[]` by adding `spec_mapping` rules (as migrations).
- **More Canon tables → matrices**: add matrix specs + deterministic converters table-by-table (high value first).
- **PDF download + parsing (later)**: PDFs are currently stored as URLs in `product_document` (not downloaded/parsed yet).
- **UI integration**: use Supabase Studio/REST against DB tables + views for compare/detail pages.

