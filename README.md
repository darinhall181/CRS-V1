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

### Long-term Vision
Starts with scraped public specs → over time, refined with sticky industry expert knowledge and partnerships with rental houses for live inventory availability.

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
| Spec Matrix Cells | 213 |

### Ingestion Pipeline

| Stage | Cameras | Lenses |
|---|---|---|
| Discovery | ✅ 15 Canon mirrorless | ✅ 168 Canon lenses |
| Extraction (HTML cache-first) | ✅ | ✅ |
| Normalization (DB mapping) | ✅ ~85%+ mapped | ✅ ~69% mapped (68.8%) |
| Persistence (DB upserts) | ✅ | ✅ |

**Mapping rules by category:**
- Canon mirrorless cameras: 189 rules across 8 migration batches
- Canon lenses: 126 rules across 5 migration batches (batch1–5)

**Spec mapping architecture:**
- `SpecMapperService` is now **category-aware**: when normalizing lenses, only lens rules are loaded — preventing camera rules from hijacking lens-specific specs (the root cause of prior unmapped issues).

### Key Schema Tables

```
brand                 → product_category → product
spec_section          → spec_definition  → spec_mapping  (the rule engine)
product               → product_spec     (normalized, mapped spec values)
product               → product_spec_matrix  (matrix/table specs, JSONB dims)
product               → product_image
product               → product_document (PDF URLs, download later)
```

### Table → Matrix Conversions (implemented)
- `still_image_file_size_table`
- `playback_display_format_table`
- `wifi_security_table`

---

## Tech Stack

| Layer | Technology |
|---|---|
| Database | Supabase (Postgres) |
| Migrations | Supabase CLI (`supabase db push`) |
| Scraping pipeline | Python — Playwright, BeautifulSoup4, psycopg2 |
| ORM (planned, frontend) | Drizzle ORM (TypeScript) |
| Frontend (planned) | Next.js (Server Components + Route Handlers) |
| Auth (planned) | Supabase Auth |

---

## Local Dev Workflow

### Prerequisites
- Docker (for local Supabase)
- Python venv at `~/Environments/altoscope/`

### Start local Supabase
```bash
supabase start
# Studio: http://127.0.0.1:54323
# DB: postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

### Apply migrations
```bash
supabase db push --include-all
```

### Activate Python environment
```fish
source ~/Environments/altoscope/bin/activate.fish
```

### Run the pipeline
```bash
# Full pipeline (all stages)
python3 backend/scripts/run.py --brand canon --product-type lens --stage discovery
python3 backend/scripts/run.py --brand canon --product-type lens --stage extraction
python3 backend/scripts/run.py --brand canon --product-type lens --stage normalize
python3 backend/scripts/run.py --brand canon --product-type lens --stage persist

# Quick normalize-only (re-runs mapping without re-scraping)
python3 backend/scripts/run.py --brand canon --product-type lens --stage normalize
```

### Write to Supabase cloud
Set `DATABASE_URL` in `backend/.env` to the cloud connection string (Project Settings → Database → Connection string, `sslmode=require`). The pipeline auto-loads it.

> **zsh tip:** If your password contains `!`, use single quotes to avoid `event not found`:
> `export DATABASE_URL='postgresql://...:<password>@db.<ref>.supabase.co:5432/postgres?sslmode=require'`

---

## Next Steps

- **Lens mapping coverage**: resolve remaining ~31% unmapped (mostly cinematic specs needing new `spec_definition` rows: `Scene Object Dimensions at MOD`, `Aspect Ratio`, `Object Image Format`)
- **Canon camera persist refresh**: re-run persist for cameras with latest mapping rules
- **Expand brands**: Sony, Nikon, ARRI, RED
- **PDF download + parsing**: PDF URLs are stored in `product_document`; deterministic parse pass needed
- **Frontend**: Next.js app with Drizzle ORM, Supabase Auth, compatibility checker API routes
- **Drizzle ORM setup**: after schema finalization, generate TypeScript schema from Postgres for frontend queries
- **User/project schema**: gear lists, saved kits, RFQ outputs, subscription tiers, version history
