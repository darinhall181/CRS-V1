# Official-Document Pipeline — Design

*2026-07-30 · Companion to `pipeline/data/doc_targets/manufacturer_doc_portals.json`*

## Goal

Build a continuously running system that collects **official manufacturer documents** (tech data sheets, manuals, mount/compatibility notes), classifies them by authority, extracts checker-relevant fields with provenance, and embeds the long tail for retrieval. The Zeiss Supreme brochure is the motivating example: its spec table has aperture/close-focus/weight but **no image circle, mount, flange depth, or Extended Data details** — the fields the compatibility checker actually needs. Those live in tech data sheets and manuals buried in support portals, not on product pages.

## Current state (what already exists)

- `pipeline/src/agents/spec_pipeline/` — plugin-per-brand, 4 stages: discovery → extraction → normalize → persist. Playwright, HTML caching, polite delays.
- `product_document` table (schema.sql:151) — already tracks PDFs with `status: discovered → downloaded → parsed`, dedupe on `(product_slug, document_kind, url)`.
- `scripts/import_documents_from_extractions.py` — harvests PDF URLs found incidentally on product pages.
- **Missing:** dedicated portal-level doc discovery, downloader, classifier, PDF extraction, embeddings (no pgvector), CI scheduling (no `.github/workflows`; all plugins run `headless=False`).

## Architecture (hybrid)

```
GitHub Actions (nightly)                     Cowork scheduled task (weekly)
┌─────────────────────────────┐              ┌─────────────────────────────┐
│ 1. doc_discovery            │              │ Reads repo + doc inventory  │
│    portals → candidate URLs │              │ • triage: misclassified?    │
│ 2. doc_fetch                │   commits/   │ • gap report vs checker     │
│    download, sha256, store  │──artifacts──▶│   fields per product        │
│ 3. doc_classify (LLM)       │              │ • proposes new portal seeds │
│ 4. doc_extract (LLM+tables) │              │ • flags marketing-vs-tech   │
│ 5. embed → pgvector         │              │   conflicts for review      │
└─────────────────────────────┘              └─────────────────────────────┘
```

The scraper and heavy fetching stay in your infra (Actions cron in this repo). The scheduled Claude task does judgment work only — review, gap analysis, target proposals — and writes reports back (e.g. `docs/reports/doc-triage-YYYY-MM-DD.md`) so the loop is inspectable.

## Stage details

### 1. doc_discovery (new stage, parallel to product discovery)
Seed from `manufacturer_doc_portals.json`. Per portal: fetch `sitemap.xml` first (often lists every PDF for free), then crawl the portal page with Playwright. Emit candidate docs `{url, anchor_text, portal, brand_slug}` into `product_document` with `status='discovered'`. Anchor text + URL heuristics pre-filter (skip press releases, sustainability reports).

### 2. doc_fetch
Download to R2 (you already push images there) under `docs/{brand}/{sha256}.pdf`. Dedupe by content hash — the same PDF appears at many URLs. Record `page_count`, `pdf_date` from metadata. Re-check known URLs monthly for revisions (manufacturers silently replace PDFs; keep both versions).

### 3. doc_classify
LLM pass over first ~3 pages + last ~3 pages (where tech tables live, per the Zeiss brochure). Output: `doc_type` (tech_data_sheet | dimensional_drawing | user_manual | mount_compat_note | firmware_notes | white_paper | brochure | other), `authority` (1–4, defined in the seed file), `products_covered` (list of product_slugs — one manual often covers many models, e.g. Blackmagic), `fields_present` (does it contain image_circle? flange? power draw?). Store in `raw_metadata`.

### 4. doc_extract
Only authority 1–2 docs. Table-aware extraction (pdfplumber/camelot for lattice tables, LLM for prose claims like "no vignetting above 21mm on full frame"). Writes to `product_spec` with **provenance**: add `source_document_id UUID REFERENCES product_document(id)` and `source_page INT` to `product_spec`. When a PDF value conflicts with a scraped-HTML value, PDF authority 1 wins; log the conflict instead of overwriting silently — that conflict log *is* your marketing-vs-truth dataset for later.

### 5. embed
Enable pgvector in Supabase. Chunk by page (tables kept whole), embed authority 1–3 docs fully, brochures too (tagged authority 4 so retrieval can discount them). Every chunk carries `{document_id, page, brand_slug, products_covered, doc_type, authority}`. This is the retrieval layer behind checker explanations ("why does this pairing need an adapter?") and the LLM Advisor.

## Extraction schema — derived from the checker, not from the PDFs

Work backwards from the four MVP checks:

| Check | Fields to extract |
|---|---|
| Mount | mount(s), flange focal depth, native vs adapted, adapter requirements |
| Media | media types, slot count, min card spec, reader/transfer interface |
| Power | input voltage range, power draw (W), plate type (V/Gold), accessory power outs |
| Physical | weight, dimensions, front diameter, filter thread, image circle, sensor dimensions per mode, close focus |
| Metadata (implied by mockup) | protocol support: LDS-1/LDS-2, /i–/i3, eXtended Data; FIZ unit mapping availability |

Everything outside this table is not schema — it's embedding material. Resist schema sprawl.

## Scheduling

**GitHub Actions** (`.github/workflows/doc-pipeline.yml`): nightly cron, matrix over brands, stages 1–2 always, 3–5 on new/changed hashes only. Needs `xvfb-run` or a `headless=True` override flag added to configs (all 15 plugins currently hardcode `headless=False`). Secrets: `DATABASE_URL`, R2 keys, `ANTHROPIC_API_KEY` for classify/extract.

**Cowork weekly task**: connects this repo folder, reads the week's new `product_document` rows + triage seed file, produces the gap report and proposed seed changes as a PR-able diff. This can be set up in ~5 minutes once the Actions side emits its first inventory.

## Rollout

1. **Week 1–2:** doc_discovery + doc_fetch for the priority-1 brands (ARRI, RED, Sony, Zeiss, Cooke, Angenieux, Preston, Anton Bauer). Get the corpus flowing; no parsing yet.
2. **Week 3–4:** doc_classify + the provenance columns. Start the weekly Cowork triage task here — human-in-the-loop while classification tunes.
3. **Month 2:** doc_extract for mount/flange/image-circle fields (the pairing-resolver needs these first). Backfill `product_spec` provenance.
4. **Month 2–3:** pgvector + embeddings; wire retrieval into checker explanations.
5. **Later:** conflict-resolution pass (marketing vs tech data) using the conflict log accumulated since stage 4.

## Local end-to-end test (stages 1–2, implemented)

Scripts: `pipeline/scripts/doc_discovery.py` + `pipeline/scripts/doc_fetch.py`.

```fish
source ~/Documents/VirtualEnvironments/altoscope/bin/activate.fish
cd ~/code/Altoscope/pipeline

# 1. Discover — ARRI first (best portal). Writes inventory JSON; --no-db to test without Supabase.
python3 scripts/doc_discovery.py --brand arri --no-db
#    → data/doc_targets/discovered/arri_docs.json

# 2. Fetch a small sample — local disk only, no R2, no DB:
python3 scripts/doc_fetch.py --brand arri --limit 3 --no-r2 --no-db
#    → <repo>/data/documents/arri/{sha16}_{name}.pdf  (= ~/Documents/CRS_Database/documents/arri/)
#    → <repo>/data/documents/manifest.json            (url→sha ledger, dedupe)

# 3. Full flow once 1–2 look right (uses SUPABASE_DB_URL + R2 vars from pipeline/.env):
python3 scripts/doc_discovery.py --brand arri
python3 scripts/doc_fetch.py --brand arri
#    → R2: docs/arri/{sha16}_{name}.pdf   → product_document rows status='downloaded'
```

Storage: local under the `data/` symlink (CRS_Database — big PDFs never touch git), canonical copy in R2 (`docs/{brand}/…` in the same bucket as images, immutable cache headers, sha-prefixed names so revised PDFs get new keys). `R2_PUBLIC_URL/docs/...` becomes the user-facing citation link later.

Notes: portal-discovered docs insert with `product_slug='_unmapped'` + `document_kind='unclassified_pdf'` (schema CHECK requires a slug; classification reassigns real products later). `doc_fetch` verifies `%PDF` magic bytes, dedupes by sha256 across URLs, and is fully idempotent — re-runs skip everything already in the manifest/R2.

## Etiquette / risk

Respect robots.txt and keep the existing delay/long-break patterns; identify with a real UA + contact email; cache and hash-dedupe so re-runs are near-zero-fetch; prefer sitemaps over crawling. Manufacturer PDFs are public documents — storing them internally for extraction is normal practice, but don't republish them wholesale in-product; surface extracted facts with citations/links to the source instead.
