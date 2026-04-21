-- Product Documents / Assets
-- Stores discovered PDF URLs (spec sheets, manuals, etc.)

-- Supabase-friendly UUID generator
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS product_document (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Optional FK (can be filled later once product exists)
    product_id UUID REFERENCES product(id) ON DELETE CASCADE,

    -- Helpful denormalized identifiers (useful before product exists)
    brand_slug TEXT,
    product_type TEXT,
    product_slug TEXT,

    document_kind TEXT NOT NULL, -- e.g. 'technical_specs_pdf'
    title TEXT,
    url TEXT NOT NULL,
    source_url TEXT, -- product page where the document link was found

    status TEXT NOT NULL DEFAULT 'discovered', -- discovered, downloaded, parsed, failed
    discovered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    downloaded_at TIMESTAMP WITH TIME ZONE,
    local_path TEXT,

    raw_metadata JSONB,

    CHECK (product_id IS NOT NULL OR product_slug IS NOT NULL),
    UNIQUE (product_slug, document_kind, url)
);

CREATE INDEX IF NOT EXISTS idx_product_document_product_id ON product_document(product_id);
CREATE INDEX IF NOT EXISTS idx_product_document_product_slug ON product_document(product_slug);
CREATE INDEX IF NOT EXISTS idx_product_document_kind ON product_document(document_kind);
CREATE INDEX IF NOT EXISTS idx_product_document_url ON product_document(url);

