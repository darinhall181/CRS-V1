-- Seed migration (idempotent): minimal product_category prerequisites
-- Ensures 'cameras' and 'mirrorless-cameras' exist before spec taxonomy seeds.

DO $$
DECLARE
  cameras_id UUID;
BEGIN
  -- Root: Cameras
  INSERT INTO product_category (name, slug, display_order, icon_name)
  VALUES ('Cameras', 'cameras', 10, 'camera')
  ON CONFLICT (slug) DO NOTHING;

  SELECT id INTO cameras_id FROM product_category WHERE slug = 'cameras';

  -- Subcategory: Mirrorless Cameras
  INSERT INTO product_category (name, slug, parent_category_id, display_order)
  VALUES ('Mirrorless Cameras', 'mirrorless-cameras', cameras_id, 10)
  ON CONFLICT (slug) DO NOTHING;
END $$;

