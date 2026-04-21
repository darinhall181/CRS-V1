-- Patch Neon schema to match Supabase before data restore.
-- Run this before pg_restore.

-- ── product: add pipeline columns ─────────────────────────────────────────────
ALTER TABLE product
  ADD COLUMN IF NOT EXISTS upc                TEXT,
  ADD COLUMN IF NOT EXISTS announce_date      DATE,
  ADD COLUMN IF NOT EXISTS current_price_usd  NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS thumbnail_url      TEXT,
  ADD COLUMN IF NOT EXISTS source_url         TEXT,
  ADD COLUMN IF NOT EXISTS raw_data           JSONB,
  ADD COLUMN IF NOT EXISTS last_scraped_at    TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS scraping_status    TEXT DEFAULT 'pending';

-- ── product_document: restore full column set ─────────────────────────────────
ALTER TABLE product_document
  ADD COLUMN IF NOT EXISTS brand_slug    TEXT,
  ADD COLUMN IF NOT EXISTS product_type  TEXT,
  ADD COLUMN IF NOT EXISTS product_slug  TEXT,
  ADD COLUMN IF NOT EXISTS title         TEXT,
  ADD COLUMN IF NOT EXISTS source_url    TEXT,
  ADD COLUMN IF NOT EXISTS status        TEXT DEFAULT 'discovered',
  ADD COLUMN IF NOT EXISTS discovered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS downloaded_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS local_path    TEXT,
  ADD COLUMN IF NOT EXISTS raw_metadata  JSONB;

-- ── product_image: add missing columns ────────────────────────────────────────
ALTER TABLE product_image
  ADD COLUMN IF NOT EXISTS source_url TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- ── rental_house_location: add contact_email ──────────────────────────────────
ALTER TABLE rental_house_location
  ADD COLUMN IF NOT EXISTS contact_email TEXT;

-- ── spec_mapping: pipeline regex rules ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS spec_mapping (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  spec_definition_id  UUID NOT NULL REFERENCES spec_definition(id),
  extraction_pattern  TEXT NOT NULL,
  context_pattern     TEXT,
  manufacturer_key    TEXT,
  priority            INTEGER DEFAULT 0,
  notes               TEXT,
  created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_spec_mapping_pattern ON spec_mapping(extraction_pattern);

-- ── product_spec_matrix: tabular/matrix specs ─────────────────────────────────
CREATE TABLE IF NOT EXISTS product_spec_matrix (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id            UUID NOT NULL REFERENCES product(id) ON DELETE CASCADE,
  spec_definition_id    UUID NOT NULL REFERENCES spec_definition(id) ON DELETE CASCADE,
  dims                  JSONB NOT NULL,
  value_text            TEXT,
  numeric_value         NUMERIC,
  unit_used             TEXT,
  width_px              INTEGER,
  height_px             INTEGER,
  is_available          BOOLEAN NOT NULL DEFAULT TRUE,
  is_inexact_proportion BOOLEAN NOT NULL DEFAULT FALSE,
  notes                 TEXT,
  extraction_confidence FLOAT,
  scraped_at            TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(product_id, spec_definition_id, dims)
);
CREATE INDEX IF NOT EXISTS idx_product_spec_matrix_product    ON product_spec_matrix(product_id);
CREATE INDEX IF NOT EXISTS idx_product_spec_matrix_definition ON product_spec_matrix(spec_definition_id);
CREATE INDEX IF NOT EXISTS idx_product_spec_matrix_numeric    ON product_spec_matrix(numeric_value);
CREATE INDEX IF NOT EXISTS idx_product_spec_matrix_dims       ON product_spec_matrix USING GIN (dims);

-- ── enum: add member_of ───────────────────────────────────────────────────────
-- ALTER TYPE ... ADD VALUE cannot run inside a transaction; run standalone.
ALTER TYPE product_relationship_type ADD VALUE IF NOT EXISTS 'member_of';
