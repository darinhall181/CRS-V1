-- Init schema (copied from backend/db/schema.sql)

-- ------------------------------------------------------------
-- Product Specification Schema
-- This schema is designed to store product specifications for a variety of products.
-- ------------------------------------------------------------

-- Supabase-friendly UUID generator
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Brands Table
CREATE TABLE IF NOT EXISTS brand (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    website_url TEXT,
    logo_url TEXT,
    scraping_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Product Categories Table
CREATE TABLE IF NOT EXISTS product_category (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    parent_category_id UUID REFERENCES product_category(id),
    display_order INTEGER DEFAULT 0,
    icon_name TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Spec Sections (Groups like "Image Sensor", "Focus")
CREATE TABLE IF NOT EXISTS spec_section (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_name TEXT NOT NULL,
    category_id UUID REFERENCES product_category(id), -- Optional link to category
    display_order INTEGER DEFAULT 0,
    parent_section_id UUID REFERENCES spec_section(id),
    UNIQUE(section_name, category_id)
);

-- Spec Definitions (Master taxonomy like "Effective Pixels")
CREATE TABLE IF NOT EXISTS spec_definition (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_id UUID REFERENCES spec_section(id),
    display_name TEXT NOT NULL, -- The canonical name
    normalized_key TEXT NOT NULL UNIQUE, -- For programmatic access (e.g., effective_pixels)
    data_type TEXT DEFAULT 'text', -- 'text', 'number', 'boolean', 'range', 'list'
    unit TEXT, -- Default unit (e.g. 'MP', 'mm', 'g')
    category_id UUID REFERENCES product_category(id), -- Optional: restrict spec to category
    description TEXT,
    importance INTEGER DEFAULT 0 -- For sorting/highlighting (0-10)
);

-- Spec Mappings (Translation layer)
CREATE TABLE IF NOT EXISTS spec_mapping (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    spec_definition_id UUID REFERENCES spec_definition(id) NOT NULL,
    extraction_pattern TEXT NOT NULL, -- Regex or string match
    context_pattern TEXT, -- Regex for section context (e.g. "Focus")
    manufacturer_key TEXT, -- If specific to a brand (e.g. Canon calls it X)
    priority INTEGER DEFAULT 0, -- Higher wins
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Products Table
CREATE TABLE IF NOT EXISTS product (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id UUID REFERENCES brand(id) NOT NULL,
    category_id UUID REFERENCES product_category(id) NOT NULL,
    model TEXT NOT NULL,
    full_name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    sku TEXT,
    upc TEXT,
    announce_date DATE,
    msrp_usd NUMERIC(10, 2),
    current_price_usd NUMERIC(10, 2),
    primary_image_url TEXT,
    thumbnail_url TEXT,
    manufacturer_url TEXT,
    
    -- Scraping Metadata
    source_url TEXT,
    raw_data JSONB, -- Full scrape dump
    last_scraped_at TIMESTAMP WITH TIME ZONE,
    scraping_status TEXT DEFAULT 'pending', -- pending, success, failed
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Product Specs (Normalized Data)
CREATE TABLE IF NOT EXISTS product_spec (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES product(id) ON DELETE CASCADE NOT NULL,
    spec_definition_id UUID REFERENCES spec_definition(id) NOT NULL,
    
    -- Values
    spec_value TEXT, -- The cleaned text value
    raw_value TEXT, -- The original extracted string (verbatim; may not be valid JSON)
    raw_value_jsonb JSONB, -- Optional structured extraction/provenance (always valid JSON)
    
    -- Structured Values for Filtering
    numeric_value NUMERIC,
    min_value NUMERIC,
    max_value NUMERIC,
    unit_used TEXT,
    boolean_value BOOLEAN,
    
    extraction_confidence FLOAT,
    scraped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(product_id, spec_definition_id)
);

-- Product Spec Matrix (Tabular/Matrix Specs)
-- Stores "cell" values for specs that are naturally tables (e.g., recording pixels matrix).
CREATE TABLE IF NOT EXISTS product_spec_matrix (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES product(id) ON DELETE CASCADE NOT NULL,
    spec_definition_id UUID REFERENCES spec_definition(id) ON DELETE CASCADE NOT NULL,

    -- Dimensions for tabular specs (unbounded; store whatever keys you need)
    -- Example:
    -- {"media_type":"JPEG/HEIF","image_size":"L","aspect_ratio":"3:2"}
    dims JSONB NOT NULL,

    -- Values (keep a small "universal" set; add spec-specific tables later if needed)
    value_text TEXT,        -- e.g. "Not available"
    numeric_value NUMERIC,  -- e.g. megapixels or other numeric cell value
    unit_used TEXT,         -- e.g. "MP"
    width_px INTEGER,       -- e.g. 6960
    height_px INTEGER,      -- e.g. 4640

    -- Metadata
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    is_inexact_proportion BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    extraction_confidence FLOAT,
    scraped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(product_id, spec_definition_id, dims)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_product_brand ON product(brand_id);
CREATE INDEX IF NOT EXISTS idx_product_category ON product(category_id);
CREATE INDEX IF NOT EXISTS idx_product_slug ON product(slug);
CREATE INDEX IF NOT EXISTS idx_product_raw_data ON product USING GIN (raw_data);

CREATE INDEX IF NOT EXISTS idx_product_spec_product ON product_spec(product_id);
CREATE INDEX IF NOT EXISTS idx_product_spec_definition ON product_spec(spec_definition_id);
CREATE INDEX IF NOT EXISTS idx_product_spec_numeric ON product_spec(numeric_value);
CREATE INDEX IF NOT EXISTS idx_spec_mapping_pattern ON spec_mapping(extraction_pattern);

CREATE INDEX IF NOT EXISTS idx_product_spec_matrix_product ON product_spec_matrix(product_id);
CREATE INDEX IF NOT EXISTS idx_product_spec_matrix_definition ON product_spec_matrix(spec_definition_id);
CREATE INDEX IF NOT EXISTS idx_product_spec_matrix_numeric ON product_spec_matrix(numeric_value);
CREATE INDEX IF NOT EXISTS idx_product_spec_matrix_dims ON product_spec_matrix USING GIN (dims);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'update_product_updated_at'
    ) THEN
        CREATE TRIGGER update_product_updated_at
            BEFORE UPDATE ON product
            FOR EACH ROW
            EXECUTE PROCEDURE update_updated_at_column();
    END IF;
END $$;

-- ------------------------------------------------------------
-- Other Schemas
-- Any other schemas that will be used in the future
-- Most likely will be used for user data, product reviews, etc.
-- ------------------------------------------------------------
