# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What Altoscope Is

A workflow SaaS that scrapes manufacturer camera/lens specs, normalizes them into a structured database, and provides compatibility checking (mount, media, power, physical) to help commercial productions reconcile fragmented gear lists and generate RFQs.

## Repository Structure

```
Altoscope/
├── www/         ← Next.js 14 frontend (App Router, Drizzle ORM, shadcn/ui)
├── pipeline/    ← Python scraping pipeline (discover → extract → normalize → persist)
├── supabase/    ← SQL migrations and local dev config
└── data/        ← Symlink to ~/Documents/CRS_Database (HTML cache, JSON output, images)
```

## Commands

### Frontend (www/)
```bash
bun dev               # Start dev server at localhost:3000
bun run build         # Production build
bun run lint          # ESLint

# Drizzle ORM
bun run db:generate   # Generate migration from schema.ts changes
bun run db:push       # Apply migration to DB
bun run db:studio     # Open Drizzle Studio (visual DB browser)
```

### Pipeline (pipeline/)
```bash
# Activate venv first
source ~/Documents/VirtualEnvironments/altoscope/bin/activate.fish

# Install deps
pip-compile requirements.in   # Regenerate pinned requirements.txt
pip install -r requirements.txt
pip install -e .              # Install pipeline package in editable mode

# Run pipeline stages
python3 scripts/run.py --brand canon --product-type camera --stage discovery
python3 scripts/run.py --brand canon --product-type camera --stage extraction
python3 scripts/run.py --brand canon --product-type camera --stage normalize
python3 scripts/run.py --brand canon --product-type camera --stage persist

# Utilities
python3 scripts/upload_images_to_r2.py
python3 scripts/import_documents_from_extractions.py
```

### Database (Supabase)
```bash
supabase start               # Start local Postgres + Studio in Docker
supabase db push --include-all  # Apply all migrations
supabase stop
# Studio UI: http://127.0.0.1:54323
```

## Architecture

### Frontend Data Flow

Next.js Server Components call Drizzle query functions directly (no REST API layer):

```
www/src/lib/db/schema.ts     ← TypeScript ORM table definitions (mirrors Supabase SQL)
www/src/lib/db/queries.ts    ← Typed async query functions (getProducts, checkCompatibility, etc.)
www/src/types/index.ts       ← Re-exports query return types
www/src/app/(app)/*/page.tsx ← Server components import from queries.ts directly
```

Route groups: `(marketing)/` for public pages, `(app)/` for product features. Both are invisible in URLs.

Pattern for interactive pages: a Server Component page (loads data via queries.ts) hands off to a `*-client.tsx` Client Component (handles interactivity).

### Pipeline: 4-Stage Architecture

Each stage is idempotent and produces JSON consumed by the next:

1. **Discovery** (`core/discovery.py`) — Playwright crawl of listing pages → product URL list
2. **Extraction** (`core/extraction.py`) — Fetch each product page (HTML cache-first) → raw labeled specs JSON
3. **Normalization** (`core/normalization.py`) — Regex rules from DB map raw labels → `normalized_key`
4. **Persistence** (`core/persistence.py`) — Upsert normalized data into Supabase (never DELETE)

**Plugin system**: Each brand+category combination is a plugin at `src/agents/spec_pipeline/product/{category}/{brand}/plugin.py`. The registry loads plugins dynamically via `load_plugin(brand, product_type)`. Add new brands without touching core stages.

**Spec mapping**: `SpecMapperService` loads regex rules from the `spec_mapping` table filtered by `category_slug`. Rules map raw spec labels (e.g., `"Image Sensor"`) to `normalized_key` values (e.g., `"effective_pixels"`). ~315 rules currently seed via SQL migrations.

### Database Schema Conventions

- UUID primary keys for relations; text slugs for URLs and human lookups
- `product_spec` stores both `spec_value` (normalized) and `raw_value` (verbatim from website)
- Matrix/tabular specs use `product_spec_matrix` with a `dims` JSONB column for row/column identifiers
- `is_active` boolean for soft deletes
- Schema changes: write SQL in `supabase/migrations/` with timestamp prefix (e.g., `20260101000000_description.sql`)

### Three-Layer DB Pattern

```
supabase/migrations/*.sql    ← Authoritative SQL schema (DDL + seed data)
        ↓ mirrored in
www/src/lib/db/schema.ts     ← Drizzle TypeScript table definitions
        ↓ queried by
www/src/lib/db/queries.ts    ← Typed async functions used by Server Components
```

When changing the DB schema: update the SQL migration first, then update `schema.ts` to match.

## Environment Variables

- `www/.env.local`: `SUPABASE_DB_URL` (points to local `127.0.0.1:54322` or cloud)
- `pipeline/.env`: `SUPABASE_DB_URL` + Cloudflare R2 credentials (see `pipeline/.env.example`)

## Key Dependencies

**Frontend**: Next.js 14, Bun, Drizzle ORM (postgres.js), Tailwind CSS v4, shadcn/ui (Radix), React Hook Form + Zod, Sonner (toasts)

**Pipeline**: Playwright (scraping), BeautifulSoup4 (HTML parsing), psycopg2-binary (Postgres), boto3 (Cloudflare R2 / S3-compatible), pip-tools

**Path alias**: `@/*` → `www/src/*`
