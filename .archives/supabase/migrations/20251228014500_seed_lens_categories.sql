-- Seed migration (idempotent): lens product categories
-- Ensures 'lenses' and lens subcategories exist before lens spec taxonomy seeds.

DO $$
DECLARE
  lenses_id UUID;
BEGIN
  -- Root: Lenses
  INSERT INTO product_category (name, slug, display_order, icon_name)
  VALUES ('Lenses', 'lenses', 20, 'aperture')
  ON CONFLICT (slug) DO NOTHING;

  SELECT id INTO lenses_id FROM product_category WHERE slug = 'lenses';

  -- Subcategories: Lens types
  INSERT INTO product_category (name, slug, parent_category_id, display_order) VALUES
    ('Mirrorless Lenses', 'mirrorless-lenses', lenses_id, 10),
    ('DSLR Lenses', 'dslr-lenses', lenses_id, 20),
    ('Cinema Lenses', 'cinema-lenses', lenses_id, 30),
    ('Rangefinder Lenses', 'rangefinder-lenses', lenses_id, 40),
    ('Lens Adapters', 'lens-adapters', lenses_id, 50),
    ('Teleconverters', 'teleconverters', lenses_id, 60),
    ('Lens Filters', 'lens-filters', lenses_id, 70)
  ON CONFLICT (slug) DO NOTHING;
END $$;