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

### Database (Neon + Drizzle)
The database is Neon Postgres, managed through Drizzle from `www/`:
```bash
bun run db:generate   # Generate SQL migration from schema.ts changes
bun run db:push       # Apply to the Neon branch in DATABASE_URL
bun run db:studio     # Drizzle Studio (visual DB browser)
```
The `supabase/` folder is **historical only** (pre-Neon migrations kept for reference).
Do not add new migrations there, and local Supabase Docker tooling is no longer used.

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
- Schema changes: edit `www/src/lib/db/schema.ts` first, then `bun run db:generate` to produce the migration and `bun run db:push` to apply it to Neon

### DB Source of Truth (decided 2026-08-08)

```
www/src/lib/db/schema.ts     ← AUTHORITATIVE table definitions (Drizzle)
        ↓ drizzle-kit generate → migrations applied to Neon via db:push
        ↓ queried by
www/src/lib/db/queries.ts    ← Typed async functions used by Server Components
```

`schema.ts` is the single source of truth; migrations are generated from it, never
hand-written first. `supabase/migrations/` predates the Neon move and is historical
reference only — the live Neon schema may already be ahead of it.

## Environment Variables

- `www/.env.local`: `DATABASE_URL` (Neon Postgres) + Better Auth vars
- `pipeline/.env`: `DATABASE_URL` (Neon Postgres) + Cloudflare R2 credentials (see `pipeline/.env.example`)
- `SUPABASE_DB_URL` is deprecated — the database moved from Supabase to Neon. The `supabase/` folder is historical only; `www/src/lib/db/schema.ts` is the authoritative schema (see DB Source of Truth above).

## Key Dependencies

**Frontend**: Next.js 14, Bun, Drizzle ORM (postgres.js), Tailwind CSS v4, shadcn/ui (Radix), React Hook Form + Zod, Sonner (toasts)

**Pipeline**: Playwright (scraping), BeautifulSoup4 (HTML parsing), psycopg2-binary (Postgres), boto3 (Cloudflare R2 / S3-compatible), pip-tools

**Path alias**: `@/*` → `www/src/*`
