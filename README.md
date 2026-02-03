# Altoscope

Altoscope is a workflow SaaS designed to streamline the research, discovery, and acquisition of professional camera equipment for commercial productions. By leveraging the industry's most robust and user-friendly database of gear specifications, Altoscope turns fragmented public specs into actionable, compatibility-checked RFQs. We empower visual creators to move beyond simple comparison, enabling them to make informed decisions and build validated production kits with confidence. 

## Current progress

- **Normalized Postgres/Supabase schema** for gear specs:
  - `brand`, `product_category`, `product`, `spec_section`, `spec_definition`, `spec_mapping`, `product_spec`
  - matrix/table specs in `product_spec_matrix` (`dims` is JSONB)
  - PDFs tracked in `product_document` (URLs stored; download/parse later)
- **End-to-end ingestion pipeline (Canon mirrorless cameras)**:
  - discovery → extraction (cache-first) → normalization (DB mapping + text cleanup) → persistence (DB upserts)
  - currently ingests **15 Canon mirrorless cameras** from `https://www.usa.canon.com/shop/cameras/mirrorless-cameras`
- **Table → matrix conversions implemented** (persisted into `product_spec_matrix`):
  - `still_image_file_size_table`
  - `playback_display_format_table`
  - `wifi_security_table`
- **UI-friendly SQL views** exist to support frontend payloads and grids (see Supabase migrations).

## Local dev workflow (high level)

- Start local Supabase + Studio:
  - `supabase start` (requires Docker)
  - Studio runs at `http://127.0.0.1:54323`
- Apply migrations locally:
  - `supabase db push --local`
- Note: `supabase db push` applies **schema migrations only** (it does not copy scraped data).
- Run the pipeline (Canon defaults):
  - `python3 backend/scripts/run.py --stage discovery`
  - `python3 backend/scripts/run.py --stage extraction`
  - `DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres" python3 backend/scripts/run.py --stage normalize`
  - `DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres" python3 backend/scripts/run.py --stage persist`

## Persisting to Supabase cloud (data, not migrations)

To write scraped products/specs into **Supabase cloud**, set `DATABASE_URL` to the cloud Postgres connection string (Project Settings → Database → Connection string, use `sslmode=require`).

- With storing `DATABASE_URL` in `.env`, `backend/scripts/run.py` will auto-load it (it checks `.env` / `.env.local` in repo root and `backend/`).
- zsh tip: if your password contains `!`, wrap the whole URL in **single quotes** to avoid `event not found`:
  - `export DATABASE_URL='postgresql://...:p@ssw0rd\!@db.<ref>.supabase.co:5432/postgres?sslmode=require'`

Then run:

- `python3 backend/scripts/run.py --stage persist`

## Next steps

- **Mapping coverage sprint**: reduce `unmapped[]` by adding `spec_mapping` rules as migrations.
- **More table→matrix converters** for high-value Canon tables, then expand brand coverage.
- **PDF download + parsing** : currently storing PDF URLs, planniong to parse deterministically later.
- **Possible agentic structure changing**: considering migrating to n8n with Typescript integration after 100% defined schema for spec attributes
