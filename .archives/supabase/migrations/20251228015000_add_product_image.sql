-- Product Images / Assets
-- Stores discovered product image URLs (gallery, primary, etc.)

-- Supabase-friendly UUID generator
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS product_image (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id UUID REFERENCES product(id) ON DELETE CASCADE NOT NULL,

    url TEXT NOT NULL,
    kind TEXT,        -- e.g. 'primary', 'gallery', 'thumbnail'
    sort_order INTEGER,

    source_url TEXT,  -- product page where the image link was found
    raw_metadata JSONB,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE (product_id, url)
);

CREATE INDEX IF NOT EXISTS idx_product_image_product_id ON product_image(product_id);
CREATE INDEX IF NOT EXISTS idx_product_image_kind ON product_image(kind);
CREATE INDEX IF NOT EXISTS idx_product_image_url ON product_image(url);


