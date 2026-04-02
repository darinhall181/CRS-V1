# Altoscope

**Altoscope is a workflow SaaS that turns fragmented public camera specs into compatibility-checked, professional RFQs for commercial productions — monetized through repeat planning, not transaction fees.**

---

## What It Does

Commercial producers and production managers spend hours reconciling gear lists from 10 different freelancers across 10 different spreadsheets. A wrong lens mount or missing card reader costs real money on shoot day. Altoscope solves this.

The product is a **Smart List Builder**: a tool that lets producers build production gear kits, run automated compatibility checks (mount, media, power, physical), and export standardized RFQs to rental houses — all from a single source of structured, spec-verified data.

---

## Business Model

### Ideal Customer
**Non-unionized commercial producers / production managers / coordinators** at small production companies (5–15 FTE, $15k–$100k commercial budgets). Primary pain: formatting 10 different gear lists from 10 different freelancers, and the "change order" cycle when incompatible gear shows up on shoot day.

### Revenue Tiers

| Tier | Price | Key Features |
|---|---|---|
| **Solo** | $15–25/mo | DB access, manual list building, basic compatibility checks, exported RFQ |
| **Small Production Co.** | $49–79/mo | Multiple projects, saved kits, full checker system, RFQ links, change tracking |
| **Team / Coordinator-heavy** | $149–199/mo | Multiple users, version history, commenting, audit trail, rental-house collaboration |

### Core Value Proposition
> "Deterministic correctness based on published specs, then real-world intelligence layered in through usage."

Altoscope is explicitly **not** a marketplace, live availability engine, or pricing authority. It sits between producers and rental houses — giving rental houses uniform RFQs and giving producers a verified, error-checked kit before they ever pick up the phone.

---

## Checker System (MVP Features)

1. **Mount Check** — validates that bodies and lenses are physically compatible
2. **Media Check** — confirms card reader compatibility and wired transfer speeds
3. **Power Check** — verifies battery coverage and flags edge cases from manufacturer docs
4. **Physical Check** — validates accessory dimensions, sums payload for gimbals/drones/tripods, totals weight for travel

### Customer Workflow
1. Build a gear list (from scratch, scenario matcher, or LLM Advisor [Beta])
2. Run the Checker System
3. Export formatted PDF or Altoscope link → send to rental house or match to rental houses that carry the gear

---

## Repository Structure

This is a monorepo with two self-contained top-level directories — `web/` for the Next.js app and `pipeline/` for the Python scraping pipeline — plus a shared `supabase/` directory at the root.

```
Altoscope/
├── web/                          # Next.js app
│   ├── src/
│   │   ├── app/                  # App Router routes
│   │   │   ├── (marketing)/      # Route group — public pages (landing page at /)
│   │   │   ├── (app)/            # Route group — product pages
│   │   │   │   ├── compatibility-checker/
│   │   │   │   └── gear/
│   │   │   ├── layout.tsx        # Root layout — Navbar, fonts, <html> wrapper
│   │   │   └── globals.css       # Tailwind CSS variables + base styles
│   │   ├── components/
│   │   │   ├── nav/navbar.tsx    # Top navigation bar
│   │   │   └── ui/               # shadcn/ui component library (Radix-based)
│   │   ├── hooks/                # React custom hooks
│   │   ├── lib/
│   │   │   ├── db/
│   │   │   │   ├── schema.ts     # Drizzle TypeScript table definitions (mirrors DB)
│   │   │   │   ├── queries.ts    # All typed DB query functions
│   │   │   │   └── index.ts      # Drizzle client singleton (connection)
│   │   │   └── utils.ts          # cn() and other shared helpers
│   │   └── types/index.ts        # Re-exports all DB + query types
│   ├── public/                   # Static assets served by Next.js
│   ├── package.json              # Node dependencies + scripts (dev, build, db:*)
│   ├── bun.lock
│   ├── tsconfig.json             # TypeScript config — @/* resolves to ./src/*
│   ├── next.config.mjs           # Next.js config (image domains, standalone output)
│   ├── drizzle.config.ts         # Drizzle Kit config (schema path, DB URL)
│   ├── postcss.config.mjs        # Tailwind CSS PostCSS plugin
│   ├── components.json           # shadcn/ui configuration
│   ├── Dockerfile                # Multi-stage Docker build (deploy only)
│   ├── .dockerignore
│   └── .env.local                # SUPABASE_DB_URL, R2 URL (git-ignored)
│
├── pipeline/                     # Python scraping pipeline (data → DB)
│   ├── src/                      # Python package source ("src layout")
│   │   ├── agents/
│   │   │   └── spec_pipeline/    # 4-stage pipeline: discover → extract → normalize → persist
│   │   │       ├── core/         # Stage implementations (discovery.py, extraction.py, …)
│   │   │       ├── product/      # Brand+category plugins (camera/canon, lens/canon, …)
│   │   │       └── config/       # Per-run configuration objects
│   │   └── services/
│   │       └── spec_mapper.py    # Category-aware rule engine (regex → normalized_key)
│   ├── scripts/
│   │   ├── run.py                # CLI entry point: --brand --product-type --stage
│   │   ├── upload_images_to_r2.py
│   │   └── import_documents_from_extractions.py
│   ├── scripts_env/              # Python venv setup shell scripts
│   ├── tests/                    # Spec analysis files and test data
│   ├── db/                       # Raw SQL reference files (schema.sql, seed.sql)
│   ├── requirements.in           # Direct Python dependencies (pip-tools)
│   ├── requirements.txt          # Pinned lockfile (generated by pip-compile)
│   ├── setup.py                  # Makes pipeline/src/ importable as a package
│   ├── .env                      # SUPABASE_DB_URL + R2 credentials (git-ignored)
│   └── .env.example              # Documented template for new contributors
│
├── supabase/                     # Shared DB — stays at root
│   ├── migrations/               # SQL migration files — authoritative schema
│   └── config.toml               # Supabase local dev configuration
│
├── .archives/legacy-scrapers/    # Old scrapers, kept for reference
├── .gitignore                    # Single root-level gitignore (covers all sub-projects)
└── README.md
```

### Why two `src/` folders?

`web/src/` belongs to **Next.js** (TypeScript). `pipeline/src/` belongs to **Python**. They are independent package systems that never interact. The Python `src/` layout is the [officially recommended structure](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/) — placing source inside `src/` prevents accidental un-installed imports. `setup.py` + `pip install -e .` makes `pipeline/src/` importable throughout the scraping pipeline.

### Route groups `(marketing)` and `(app)`

Parentheses in Next.js folder names create **route groups** — they affect file organization but are *invisible in the URL*. Both `src/app/(marketing)/page.tsx` and `src/app/(app)/compatibility-checker/page.tsx` resolve to `/` and `/compatibility-checker` respectively. The grouping lets each section have a different layout in the future (e.g. marketing pages get no sidebar, app pages get an auth guard) without duplicating code.

### The `@/*` import alias

`tsconfig.json` maps `@/*` → `./src/*`. So `import { db } from "@/lib/db"` resolves to `src/lib/db/index.ts`. This keeps imports clean across the entire Next.js codebase.

---

## How the Database Layer Works

### Three layers, one database

```
supabase/migrations/*.sql      ← 1. Authoritative schema (SQL DDL + seed data)
                                        ↓  applied by: supabase db push
                         PostgreSQL (Supabase)
                                        ↓  read by: Drizzle ORM
src/lib/db/schema.ts           ← 2. TypeScript mirror of the tables
src/lib/db/queries.ts          ← 3. Typed query functions used by the frontend
```

**Layer 1 — Supabase SQL migrations** define what actually exists in Postgres. Every table, column, constraint, and index lives here. Files are applied in timestamp order, making the history immutable and reviewable in git. The spec mapping seed data (hundreds of regex rules) also lives here as SQL `INSERT` statements — keeping data seeds close to schema changes.

**Layer 2 — Drizzle schema** (`schema.ts`) is a TypeScript *reflection* of those tables. Drizzle reads it to generate fully-typed query builders — you get autocomplete on column names, TypeScript errors if you reference a column that doesn't exist, and inferred return types without writing any interfaces by hand.

**Layer 3 — Query functions** (`queries.ts`) wrap Drizzle's query builder into named, reusable async functions (`getProducts`, `getProductBySlug`, `checkCompatibility`, etc.) that server components import directly. No REST API layer needed — Next.js Server Components run on the server and can query the DB directly.

### SQL migrations vs Drizzle migrations — current vs future

| | Current approach | Future approach |
|---|---|---|
| **Schema changes** | Write `.sql` file in `supabase/migrations/`, run `supabase db push` | Define/edit `schema.ts`, run `drizzle-kit generate` (generates SQL), then `drizzle-kit push` |
| **Data seeds** | SQL `INSERT` statements in migration files | Can stay as SQL, or move to TypeScript seed scripts |
| **Queries** | Drizzle ORM in TypeScript | Same — Drizzle ORM in TypeScript |
| **Type safety** | Schema.ts written by hand to match SQL | Schema.ts *is* the source of truth, Drizzle generates SQL from it |

**To transition fully to TypeScript migrations:** the path is to stop writing `.sql` migration files by hand and instead:
1. Edit `src/lib/db/schema.ts` (add/remove tables, columns)
2. Run `npm run db:generate` → Drizzle diffs schema against current DB and writes a `.sql` migration file
3. Run `npm run db:push` → Drizzle applies that migration to the DB

The spec definition seed data (regex mapping rules) is a special case — it's hundreds of rows of carefully tuned data. It can reasonably stay as SQL `INSERT` files even after switching to TypeScript-generated schema migrations.

### Current npm DB scripts

```bash
npm run db:generate   # generates SQL migration from schema.ts changes
npm run db:push       # applies generated migration to DB
npm run db:studio     # opens Drizzle Studio (visual DB browser, like Supabase Studio)
```

---

## Docker: Two Completely Different Purposes

### Supabase Docker (development)

```bash
supabase start
```

Spins up a **local Postgres database** on your Mac inside Docker. This includes: Postgres 15, PostgREST API, GoTrue Auth, Supabase Storage, and Supabase Studio (the web UI at `http://127.0.0.1:54323`). This exists purely for local development so you don't need a cloud database while coding. It has nothing to do with the Next.js app.

### Next.js Dockerfile (deployment)

The `Dockerfile` at the repo root packages the **Next.js app** as a production container for deployment to cloud infrastructure (Railway, Fly.io, AWS ECS, GCP Cloud Run, etc.). It uses a multi-stage build:

1. **deps** — installs `node_modules`
2. **builder** — runs `next build` and produces an optimized `.next/` output
3. **runner** — copies only the minimal standalone build (no `node_modules`, just what Next.js needs to run), resulting in a small final image

This only matters when you deploy somewhere **other than Vercel**. Vercel handles the build and containerization for you automatically — if you deploy to Vercel, you don't need the Dockerfile at all.

**Summary: the two Dockers never interact.** Supabase Docker = your local database. Next.js Docker = your production app container. In production on cloud hosting, your database is Supabase cloud (not Docker), and your app runs from the built Docker image.

---

## Current Status

### Database (Supabase / Postgres)

| Table | Count |
|---|---|
| Brands | 66 |
| Product Categories | 27 |
| Products | 183 (15 cameras + 168 lenses) |
| Spec Definitions | 199 |
| Spec Mapping Rules | 315 |
| Product Specs (mapped rows) | 2,515 |
| Product Images | 4,634 |
| Product Documents (PDFs) | 96 |

### Ingestion Pipeline

| Stage | Cameras | Lenses |
|---|---|---|
| Discovery | ✅ 15 Canon mirrorless | ✅ 168 Canon lenses |
| Extraction (HTML cache-first) | ✅ | ✅ |
| Normalization (DB mapping) | ✅ ~85%+ mapped | ✅ ~69% mapped |
| Persistence (DB upserts) | ✅ | ✅ |

**Spec mapping architecture:**
- `SpecMapperService` is **category-aware**: when normalizing lenses, only lens rules are loaded — preventing camera rules from overriding lens-specific specs.

---

## Tech Stack

| Layer | Technology | Role |
|---|---|---|
| Database | Supabase (Postgres) | Hosted PostgreSQL + auth + storage |
| Schema migrations | Supabase CLI (`supabase db push`) | Applies SQL files in `supabase/migrations/` |
| ORM | Drizzle ORM (TypeScript) | Type-safe queries in Next.js server components |
| Frontend | Next.js 14 (App Router) | Server Components, route handlers, UI |
| UI library | shadcn/ui + Tailwind CSS v4 | Component system |
| Image storage | Cloudflare R2 | Product image CDN (S3-compatible) |
| Scraping pipeline | Python — Playwright, BeautifulSoup4, psycopg2 | `pipeline/` — discovery → extraction → normalization → persistence |
| Deployment (future) | Docker + Railway / Fly.io *or* Vercel | Next.js production hosting |

---

## Local Dev Workflow

### Prerequisites
- Docker Desktop (required for `supabase start`)
- Bun (`brew install bun`)
- Python venv at `~/Documents/VirtualEnvironments/altoscope/`

### 1. Start local Supabase (local DB)
```bash
# Run from repo root
supabase start
# Studio:  http://127.0.0.1:54323
# DB URL:  postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

### 2. Apply migrations to local DB
```bash
# Run from repo root
supabase db push --include-all
```

### 3. Start the Next.js app
```bash
cd web
bun dev
# http://localhost:3000
```

> `web/.env.local` contains `SUPABASE_DB_URL`. Point it at local (`127.0.0.1:54322`) or cloud to switch environments. The cloud DB is always available — no `supabase start` needed for it.

### 4. Run DB scripts
```bash
cd web
bun run db:studio     # visual DB browser (Drizzle Studio)
bun run db:generate   # generate SQL migration from schema.ts changes
bun run db:push       # apply migration to DB
```

### 5. Activate Python environment
```fish
source ~/Documents/VirtualEnvironments/altoscope/bin/activate.fish
```

### 6. Run the scraping pipeline
```bash
cd pipeline

# Individual stages
python3 scripts/run.py --brand canon --product-type lens --stage discovery
python3 scripts/run.py --brand canon --product-type lens --stage extraction
python3 scripts/run.py --brand canon --product-type lens --stage normalize
python3 scripts/run.py --brand canon --product-type lens --stage persist

# Upload product images to Cloudflare R2
python3 scripts/upload_images_to_r2.py
```

### Write to Supabase cloud
Set `SUPABASE_DB_URL` in `pipeline/.env` to the cloud connection string (Project Settings → Database → Connection string, with `sslmode=require`).

> **zsh tip:** If your password contains `!`, use single quotes:
> `export SUPABASE_DB_URL='postgresql://...:<password>@...'`

---

## Next Steps

- **Lens mapping coverage**: resolve remaining ~31% unmapped (cinematic specs: `Scene Object Dimensions at MOD`, `Aspect Ratio`, `Object Image Format`)
- **Canon camera persist refresh**: re-run persist for cameras with latest mapping rules
- **Expand brands**: Sony, Nikon, ARRI, RED
- **Transition to Drizzle migrations**: use `drizzle-kit generate` for new schema changes instead of hand-written SQL
- **User/project schema**: gear lists, saved kits, RFQ outputs, subscription tiers, version history
- **Auth**: Supabase Auth integration in Next.js (middleware-based route protection)
- **PDF parsing**: `product_document` URLs stored; need deterministic parse pass
