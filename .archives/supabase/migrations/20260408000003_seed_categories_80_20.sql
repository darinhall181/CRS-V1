-- ─────────────────────────────────────────────────────────────────────────────
-- Section 6f: Full product category hierarchy for the 80/20 kit builder
-- Adds granular lens subcategories and the full Accessories tree.
-- All inserts are ON CONFLICT DO NOTHING — safe to re-run.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  cameras_id       UUID;
  lenses_id        UUID;
  cinema_lens_id   UUID;
  accessories_id   UUID;
  monitors_id      UUID;
  support_id       UUID;
  power_id         UUID;
BEGIN

  -- ── Resolve existing parents ─────────────────────────────────────────────

  SELECT id INTO cameras_id     FROM product_category WHERE slug = 'cameras';
  SELECT id INTO lenses_id      FROM product_category WHERE slug = 'lenses';
  SELECT id INTO cinema_lens_id FROM product_category WHERE slug = 'cinema-lenses';

  IF cameras_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: cameras category not found. Run prior seeds first.';
  END IF;
  IF lenses_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: lenses category not found. Run 20251228014500 first.';
  END IF;
  IF cinema_lens_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: cinema-lenses category not found.';
  END IF;

  -- ── Lens subcategories (under cinema-lenses) ──────────────────────────────
  -- Granular splits needed for spec definitions and compatibility axis seeding.

  INSERT INTO product_category (name, slug, parent_category_id, display_order, icon_name) VALUES
    ('Cinema Prime Sets (PL)',  'cinema-prime-sets-pl',   cinema_lens_id, 10, 'circle'),
    ('Cinema Prime Sets (LPL)', 'cinema-prime-sets-lpl',  cinema_lens_id, 20, 'circle'),
    ('Cinema Zoom Lenses',      'cinema-zoom-lenses',     cinema_lens_id, 30, 'zoom-in'),
    ('Anamorphic Lenses',       'anamorphic-lenses',      cinema_lens_id, 40, 'maximize'),
    ('Lens Adapters & Mounts',  'cinema-lens-adapters',   cinema_lens_id, 50, 'link')
  ON CONFLICT (slug) DO NOTHING;

  -- ── Accessories (new top-level) ───────────────────────────────────────────

  INSERT INTO product_category (name, slug, display_order, icon_name)
  VALUES ('Accessories', 'accessories', 30, 'package')
  ON CONFLICT (slug) DO NOTHING;

  SELECT id INTO accessories_id FROM product_category WHERE slug = 'accessories';

  -- Monitors & Displays
  INSERT INTO product_category (name, slug, parent_category_id, display_order, icon_name)
  VALUES ('Monitors & Displays', 'monitors-displays', accessories_id, 10, 'monitor')
  ON CONFLICT (slug) DO NOTHING;

  SELECT id INTO monitors_id FROM product_category WHERE slug = 'monitors-displays';

  INSERT INTO product_category (name, slug, parent_category_id, display_order) VALUES
    ('On-Board Monitors',   'on-board-monitors',   monitors_id, 10),
    ('Director''s Monitors','directors-monitors',  monitors_id, 20)
  ON CONFLICT (slug) DO NOTHING;

  -- Wireless Video
  INSERT INTO product_category (name, slug, parent_category_id, display_order, icon_name)
  VALUES ('Wireless Video', 'wireless-video', accessories_id, 20, 'wifi')
  ON CONFLICT (slug) DO NOTHING;

  -- Follow Focus & FIZ
  INSERT INTO product_category (name, slug, parent_category_id, display_order, icon_name)
  VALUES ('Follow Focus & FIZ', 'follow-focus-fiz', accessories_id, 30, 'settings')
  ON CONFLICT (slug) DO NOTHING;

  -- Matte Boxes
  INSERT INTO product_category (name, slug, parent_category_id, display_order, icon_name)
  VALUES ('Matte Boxes', 'matte-boxes', accessories_id, 40, 'square')
  ON CONFLICT (slug) DO NOTHING;

  -- Camera Support
  INSERT INTO product_category (name, slug, parent_category_id, display_order, icon_name)
  VALUES ('Camera Support', 'camera-support', accessories_id, 50, 'sliders')
  ON CONFLICT (slug) DO NOTHING;

  SELECT id INTO support_id FROM product_category WHERE slug = 'camera-support';

  INSERT INTO product_category (name, slug, parent_category_id, display_order) VALUES
    ('Fluid Heads',         'fluid-heads',       support_id, 10),
    ('Tripods & Legs',      'tripods-legs',       support_id, 20),
    ('Baseplates & Rails',  'baseplates-rails',   support_id, 30)
  ON CONFLICT (slug) DO NOTHING;

  -- Power & Batteries
  INSERT INTO product_category (name, slug, parent_category_id, display_order, icon_name)
  VALUES ('Power & Batteries', 'power-batteries', accessories_id, 60, 'battery')
  ON CONFLICT (slug) DO NOTHING;

  SELECT id INTO power_id FROM product_category WHERE slug = 'power-batteries';

  INSERT INTO product_category (name, slug, parent_category_id, display_order) VALUES
    ('Camera Batteries (Gold Mount)', 'batteries-gold-mount', power_id, 10),
    ('Camera Batteries (V-Mount)',    'batteries-v-mount',    power_id, 20),
    ('Battery Adapters & Plates',     'battery-adapters',     power_id, 30)
  ON CONFLICT (slug) DO NOTHING;

  -- Recording Media
  INSERT INTO product_category (name, slug, parent_category_id, display_order, icon_name)
  VALUES ('Recording Media', 'recording-media', accessories_id, 70, 'hard-drive')
  ON CONFLICT (slug) DO NOTHING;

  -- Camera Cages & Rigging
  INSERT INTO product_category (name, slug, parent_category_id, display_order, icon_name)
  VALUES ('Camera Cages & Rigging', 'camera-cages-rigging', accessories_id, 80, 'grid')
  ON CONFLICT (slug) DO NOTHING;

END $$;
