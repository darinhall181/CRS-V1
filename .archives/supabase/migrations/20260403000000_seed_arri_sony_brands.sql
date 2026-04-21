-- Migration: seed brand rows for ARRI and Sony.
-- The cinema-cameras product_category and its spec_definitions already exist
-- (see 20260211000000_seed_cinema_camera_category.sql).
-- Safe to re-run: uses ON CONFLICT DO NOTHING guards.

DO $$
BEGIN
  INSERT INTO brand (name, slug, website_url, scraping_enabled)
  VALUES
    ('ARRI',  'arri',  'https://www.arri.com',            TRUE),
    ('Sony',  'sony',  'https://pro.sony/ue_US',          TRUE)
  ON CONFLICT (slug) DO NOTHING;
END $$;
