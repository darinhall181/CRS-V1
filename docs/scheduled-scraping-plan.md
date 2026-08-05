# Scheduled Scraping — Planning Doc

*2026-07-30 · Future work; frontend is the current focus. Companion to `pdf-doc-pipeline-design.md`.*

## Problem

Spec data is ~6 months stale. New bodies/lenses (Canon, Sony, Nikon, ARRI, RED, Zeiss, …) don't enter the DB until someone manually re-runs the pipeline. The goal is a recurring loop that (a) detects new products within a week of a manufacturer publishing them, (b) refreshes changed spec pages, and (c) reports what it did so drift is visible instead of silent.

## Cadence design (tiered — don't re-scrape everything weekly)

| Tier | What | Cadence | Cost |
|---|---|---|---|
| 1 | **Discovery diff** — run discovery stage per brand, diff against committed `url_lists/*.json` | Weekly | Cheap: a few listing pages per brand |
| 2 | **New-product ingest** — extraction → normalize → persist for URLs that appeared in the diff | Weekly (triggered by tier 1 hits) | Small: only new products |
| 3 | **Change re-scrape** — re-fetch known product pages, hash-compare against `raw_html` cache, re-extract only changed pages | Biweekly, rotating brands (e.g. cameras week A, lenses week B) | Moderate |
| 4 | **Full re-scrape** — cache-busting full run per brand | Quarterly, one brand per week rotation | High; also catches page-structure changes that break extraction |
| 5 | **Doc pipeline** (doc_discovery + doc_fetch) | Nightly or weekly | Cheap after first run (sha dedupe) |

## New-product detection mechanics

Discovery already writes canonical URL lists. The scheduled job:

1. Runs `--stage discovery` per brand.
2. Diffs output vs the committed copy of `data/url_lists/{brand}_{type}_urls.json`.
3. New URLs → run extraction/normalize/persist for just those; commit the updated url_list in the same run (the repo becomes the ledger of "what we know exists" — free history via git log).
4. Removed URLs → don't delete (persistence never DELETEs); flag as possibly discontinued → `is_active` review list.

Announcement-page watching (brand newsroom/press RSS) is a cheaper early-warning complement, but product-listing diffs are the source of truth — press pages announce; listing pages confirm scrapeability.

## Change detection for existing products

- Re-fetch product page → sha256 of normalized HTML (strip scripts/nonces/timestamps before hashing, or diffs are all noise) → compare against cache.
- Changed → re-extract → normalize → persist (upserts already idempotent). `product_spec.scraped_at` gives per-spec freshness.
- Add a `freshness` view: products by `max(scraped_at)`, surfaced in an internal page or the weekly report. Staleness becomes measurable instead of vibes.

## CI prerequisites (the actual work when this gets picked up)

1. **Headless flag.** All 15 plugin configs hardcode `headless=False`. Add env override (`ALTOSCOPE_HEADLESS=1`) read in `ExtractionConfig`/discovery, so laptop behavior is unchanged and CI forces headless.
2. **Datacenter-IP blocking — the main risk.** Some manufacturer sites (Canon and Sony especially) throttle or block GitHub's runner IPs. Mitigations, in order of preference:
   - **Self-hosted runner on the Mac** — your existing residential IP + a machine that already runs the pipeline; Actions is then only the scheduler. Easiest and likely sufficient.
   - Playwright stealth args + realistic UA + the existing delay/long-break settings.
   - Residential proxy for specific hostile brands only (cost; last resort).
   Decide per brand empirically: run tier 1 from CI first, note which brands 403.
3. **Secrets:** `SUPABASE_DB_URL`, R2 keys, `ANTHROPIC_API_KEY` (doc classify, later).
4. **Artifacts:** HTML cache is too big for git — cache dir per run via `actions/cache` keyed by brand, or keep cache only on the self-hosted runner (simplest). Only `url_lists/*.json` diffs get committed.
5. **Failure isolation:** matrix job per brand (`fail-fast: false`) so one broken site doesn't kill the run; per-brand timeout ~30 min.

## Draft workflow (reference — don't add until CI prerequisites are done)

```yaml
# .github/workflows/spec-pipeline.yml
name: spec-pipeline
on:
  schedule:
    - cron: "0 6 * * 1"        # Mondays 06:00 UTC — tier 1+2
    - cron: "0 6 8,22 * *"     # 8th + 22nd — tier 3 rotation
  workflow_dispatch:            # manual runs with brand input
jobs:
  scrape:
    runs-on: [self-hosted, macOS]   # or ubuntu-latest + xvfb, see prerequisites
    strategy:
      fail-fast: false
      matrix:
        include:
          - {brand: arri, type: camera}
          - {brand: red, type: camera}
          - {brand: sony, type: camera}
          - {brand: canon, type: camera}
          - {brand: blackmagic, type: camera}
          - {brand: zeiss, type: lens}
          - {brand: cooke, type: lens}
          - {brand: angenieux, type: lens}
    env:
      ALTOSCOPE_HEADLESS: "1"
      SUPABASE_DB_URL: ${{ secrets.SUPABASE_DB_URL }}
    steps:
      - uses: actions/checkout@v4
      - run: pip install -r pipeline/requirements.txt && pip install -e pipeline
      - run: python3 pipeline/scripts/run.py --brand ${{ matrix.brand }} --product-type ${{ matrix.type }} --stage discovery
      - run: python3 pipeline/scripts/scheduled/diff_and_ingest.py --brand ${{ matrix.brand }} --product-type ${{ matrix.type }}
        # ^ to build: diff url_lists, run extract/normalize/persist for new URLs, emit summary JSON
      - uses: actions/upload-artifact@v4
        with: {name: "summary-${{ matrix.brand }}", path: pipeline/data/run_summaries/}
  report:
    needs: scrape
    if: always()
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
      - run: python3 .github/scripts/weekly_report.py   # aggregates summaries → GitHub issue / email
```

**To build when picked up:** `diff_and_ingest.py` (thin orchestrator over existing stages, ~100 lines), `weekly_report.py`, the headless env override, and the freshness SQL view. Everything else already exists.

## Reporting loop

Each run emits a summary JSON (new products, changed pages, failures, per-brand durations). The report job aggregates into one weekly digest: a GitHub issue on the repo, or — nicer — a **Cowork scheduled task** that reads the artifacts/DB weekly and produces a triage report (this pairs with the doc-pipeline triage task already planned; one weekly "state of the database" brief covering both specs and docs).

## Coverage gaps to close (new plugins, when data work resumes)

Current plugins: cameras — canon, sony, red, arri, blackmagic; lenses — zeiss, cooke, angenieux, canon. Missing, roughly in order of rental-world importance:

1. **Nikon** (camera — you named it; no plugin exists yet)
2. Panasonic (camera — Lumix/Varicam), Fujifilm (camera)
3. Sony, Sigma, Fujinon, Leitz, Tokina (lens)
4. Accessory categories (FIZ, monitors, batteries, gimbals) — likely doc-pipeline-first rather than page-scrape-first, since their truth lives in manuals/matrices

## Sequencing (relative to "frontend first")

1. **Now:** nothing to build. This doc + the doc-pipeline scripts sit ready.
2. **First step back on data (half a day):** headless override + run the existing pipeline manually per brand once to catch up the 6-month gap. That's also the empirical test of which brands block CI IPs.
3. **Next (1–2 days):** `diff_and_ingest.py` + the workflow above on a weekly cron.
4. **Then:** tier 3 change detection, freshness view, weekly report, doc-pipeline nightly job.
5. **Ongoing:** one new brand plugin at a time (Nikon first).
