-- ─────────────────────────────────────────────────────────────────────────────
-- Kit builder & compatibility checker tables
-- Adds: compatibility_axis, product_compatibility_value, product_relationship,
--       kit_template, kit_template_item, rental_house, rental_house_location,
--       rental_house_inventory, package_item_quote
-- Also: packages.source_kit_template_id backref + RLS on all new tables
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Enums ────────────────────────────────────────────────────────────────────

CREATE TYPE product_relationship_type AS ENUM (
  'requires',
  'recommends',
  'replaces',
  'incompatible_with',
  'optional_upgrade'
);

CREATE TYPE rental_house_type AS ENUM (
  'full_service',
  'specialty',
  'peer_to_peer',
  'manufacturer'
);

-- ── compatibility_axis ────────────────────────────────────────────────────────
-- The 7 axes to seed: lens_mount, sensor_format, rod_system,
-- power_standard, recording_media, signal_output, gear_pitch

CREATE TABLE compatibility_axis (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL,
  slug          text NOT NULL UNIQUE,
  description   text,
  value_type    text NOT NULL DEFAULT 'enum'
                CHECK (value_type IN ('enum', 'range', 'boolean')),
  display_order integer DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE compatibility_axis ENABLE ROW LEVEL SECURITY;

CREATE POLICY "compatibility_axis_read" ON compatibility_axis FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "compatibility_axis_admin_all" ON compatibility_axis
  TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ── product_compatibility_value ───────────────────────────────────────────────
-- is_input = true  → product accepts this value (e.g. camera body accepts PL)
-- is_input = false → product provides this value (e.g. lens has PL mount)
-- A product can have multiple rows per axis (e.g. ALEXA 35: LPL + PL both accepted)

CREATE TABLE product_compatibility_value (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id  uuid NOT NULL REFERENCES product(id) ON DELETE CASCADE,
  axis_id     uuid NOT NULL REFERENCES compatibility_axis(id) ON DELETE CASCADE,
  value       text NOT NULL,
  is_input    boolean DEFAULT true,
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (product_id, axis_id, value)
);

CREATE INDEX ON product_compatibility_value (product_id);
CREATE INDEX ON product_compatibility_value (axis_id);

ALTER TABLE product_compatibility_value ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_compatibility_value_read" ON product_compatibility_value FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "product_compatibility_value_admin_all" ON product_compatibility_value
  TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ── product_relationship ──────────────────────────────────────────────────────
-- Powers "you'll also need..." and "incompatible with" prompts in the kit builder.
-- is_conditional = true means the relationship only applies in certain configurations
-- (e.g. ALEXA 35 requires PL→LPL adapter only if using PL lenses, not LPL-native glass)

CREATE TABLE product_relationship (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_product_id   uuid NOT NULL REFERENCES product(id) ON DELETE CASCADE,
  target_product_id   uuid NOT NULL REFERENCES product(id) ON DELETE CASCADE,
  relationship_type   product_relationship_type NOT NULL,
  is_conditional      boolean DEFAULT false,
  condition_note      text,
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  UNIQUE (source_product_id, target_product_id, relationship_type)
);

CREATE INDEX ON product_relationship (source_product_id);
CREATE INDEX ON product_relationship (target_product_id);

ALTER TABLE product_relationship ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_relationship_read" ON product_relationship FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "product_relationship_admin_all" ON product_relationship
  TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ── kit_template ──────────────────────────────────────────────────────────────
-- Pre-built package starting points, anchored to a hero product (camera body).
-- is_public = true → visible to all authenticated users (curated by Altoscope team)
-- is_public = false → private to the user who created it

CREATE TABLE kit_template (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name               text NOT NULL,
  anchor_product_id  uuid REFERENCES product(id),
  shoot_type         text CHECK (shoot_type IN ('narrative', 'commercial', 'documentary', 'music_video', 'episodic')),
  description        text,
  is_public          boolean DEFAULT false,
  created_by         uuid REFERENCES users(id),
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON kit_template (anchor_product_id);

CREATE TRIGGER kit_template_updated_at
  BEFORE UPDATE ON kit_template
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE kit_template ENABLE ROW LEVEL SECURITY;

-- Public templates visible to all authenticated users; private visible to creator only
CREATE POLICY "kit_template_select" ON kit_template FOR SELECT
  TO authenticated
  USING (is_public = true OR created_by = auth.uid() OR is_admin());

CREATE POLICY "kit_template_insert" ON kit_template FOR INSERT
  TO authenticated WITH CHECK (created_by = auth.uid() OR is_admin());

CREATE POLICY "kit_template_update" ON kit_template FOR UPDATE
  TO authenticated USING (created_by = auth.uid() OR is_admin());

CREATE POLICY "kit_template_delete" ON kit_template FOR DELETE
  TO authenticated USING (created_by = auth.uid() OR is_admin());

-- ── kit_template_item ─────────────────────────────────────────────────────────

CREATE TABLE kit_template_item (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kit_template_id  uuid NOT NULL REFERENCES kit_template(id) ON DELETE CASCADE,
  product_id       uuid NOT NULL REFERENCES product(id),
  quantity         integer NOT NULL DEFAULT 1,
  is_required      boolean DEFAULT true,
  sort_order       integer DEFAULT 0,
  notes            text
);

CREATE INDEX ON kit_template_item (kit_template_id);

ALTER TABLE kit_template_item ENABLE ROW LEVEL SECURITY;

CREATE POLICY "kit_template_item_select" ON kit_template_item FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM kit_template kt
      WHERE kt.id = kit_template_id
        AND (kt.is_public = true OR kt.created_by = auth.uid() OR is_admin())
    )
  );

CREATE POLICY "kit_template_item_write" ON kit_template_item
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM kit_template kt
      WHERE kt.id = kit_template_id
        AND (kt.created_by = auth.uid() OR is_admin())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM kit_template kt
      WHERE kt.id = kit_template_id
        AND (kt.created_by = auth.uid() OR is_admin())
    )
  );

-- ── packages: add source_kit_template_id ─────────────────────────────────────

ALTER TABLE packages
  ADD COLUMN source_kit_template_id uuid REFERENCES kit_template(id);

-- ── rental_house ──────────────────────────────────────────────────────────────
-- Distinct from brand (manufacturer). Some appear in both (Panavision, ARRI Rental).

CREATE TABLE rental_house (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name              text NOT NULL,
  slug              text NOT NULL UNIQUE,
  website_url       text,
  logo_url          text,
  type              rental_house_type NOT NULL DEFAULT 'full_service',
  description       text,
  brand_id          uuid REFERENCES brand(id),
  is_active         boolean DEFAULT true,
  scraping_enabled  boolean DEFAULT true,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER rental_house_updated_at
  BEFORE UPDATE ON rental_house
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE rental_house ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rental_house_read" ON rental_house FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "rental_house_admin_all" ON rental_house
  TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ── rental_house_location ─────────────────────────────────────────────────────
-- Inventory and rates can vary by city (e.g. Keslow LA vs Keslow NY).

CREATE TABLE rental_house_location (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_house_id   uuid NOT NULL REFERENCES rental_house(id) ON DELETE CASCADE,
  city              text NOT NULL,
  state_or_region   text,
  country           text NOT NULL DEFAULT 'US',
  address_line_1    text,
  phone             text,
  email             text,
  is_primary        boolean DEFAULT false,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON rental_house_location (rental_house_id);

ALTER TABLE rental_house_location ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rental_house_location_read" ON rental_house_location FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "rental_house_location_admin_all" ON rental_house_location
  TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ── rental_house_inventory ────────────────────────────────────────────────────
-- Reference rates scraped from rental house websites. Actual quoted rates
-- live on package_item_quote. null location_id = available at all locations.

CREATE TABLE rental_house_inventory (
  id                         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_house_id            uuid NOT NULL REFERENCES rental_house(id) ON DELETE CASCADE,
  product_id                 uuid NOT NULL REFERENCES product(id) ON DELETE CASCADE,
  location_id                uuid REFERENCES rental_house_location(id),
  day_rate                   numeric(10,2),
  week_rate                  numeric(10,2),
  rental_house_product_code  text,
  rental_house_product_url   text,
  quantity_on_hand           integer,
  is_available               boolean DEFAULT true,
  last_scraped_at            timestamptz,
  created_at                 timestamptz NOT NULL DEFAULT now(),
  updated_at                 timestamptz NOT NULL DEFAULT now(),
  UNIQUE (rental_house_id, product_id, location_id)
);

CREATE INDEX ON rental_house_inventory (rental_house_id);
CREATE INDEX ON rental_house_inventory (product_id);

CREATE TRIGGER rental_house_inventory_updated_at
  BEFORE UPDATE ON rental_house_inventory
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE rental_house_inventory ENABLE ROW LEVEL SECURITY;

-- Rate data is sensitive — only authenticated users can see pricing
CREATE POLICY "rental_house_inventory_read" ON rental_house_inventory FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "rental_house_inventory_admin_all" ON rental_house_inventory
  TO authenticated USING (is_admin()) WITH CHECK (is_admin());

-- ── package_item_quote ────────────────────────────────────────────────────────
-- One quote per rental house per package item. Workflow:
--   sent → quote_received (is_available + day_rate populated)
--   → user selects best (is_selected = true)
--   → day_rate_snapshot on package_items updated to match
--   → approved → confirmed

CREATE TABLE package_item_quote (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  package_item_id      uuid NOT NULL REFERENCES package_items(id) ON DELETE CASCADE,
  rental_house_id      uuid NOT NULL REFERENCES rental_house(id),
  location_id          uuid REFERENCES rental_house_location(id),
  day_rate             numeric(10,2),
  week_rate            numeric(10,2),
  is_available         boolean,        -- null = awaiting reply
  is_selected          boolean DEFAULT false,
  rental_house_notes   text,
  quoted_at            timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON package_item_quote (package_item_id);
CREATE INDEX ON package_item_quote (rental_house_id);

CREATE TRIGGER package_item_quote_updated_at
  BEFORE UPDATE ON package_item_quote
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE package_item_quote ENABLE ROW LEVEL SECURITY;

-- Quotes visible to production members (via package → package_item chain)
CREATE POLICY "package_item_quote_select" ON package_item_quote FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM package_items pi
      JOIN packages pk ON pk.id = pi.package_id
      WHERE pi.id = package_item_id
        AND (
          get_production_role(pk.production_id) IS NOT NULL
          OR is_company_admin_for_production(pk.production_id)
          OR is_admin()
        )
    )
  );

-- Coordinators (and admins) can create/update quotes
CREATE POLICY "package_item_quote_write" ON package_item_quote
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM package_items pi
      JOIN packages pk ON pk.id = pi.package_id
      WHERE pi.id = package_item_id
        AND (
          get_production_role(pk.production_id) = 'coordinator'
          OR is_company_admin_for_production(pk.production_id)
          OR is_admin()
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM package_items pi
      JOIN packages pk ON pk.id = pi.package_id
      WHERE pi.id = package_item_id
        AND (
          get_production_role(pk.production_id) = 'coordinator'
          OR is_company_admin_for_production(pk.production_id)
          OR is_admin()
        )
    )
  );

-- ── Seed: 7 core compatibility axes ──────────────────────────────────────────

INSERT INTO compatibility_axis (name, slug, description, value_type, display_order) VALUES
  ('Lens Mount',              'lens_mount',      'Mount standard on camera body or lens — gates all lens↔body pairings', 'enum', 1),
  ('Sensor Format',           'sensor_format',   'Sensor size / image circle coverage required or provided',             'enum', 2),
  ('Rod System',              'rod_system',      'Rod standard for baseplate, mattebox, and follow focus attachment',    'enum', 3),
  ('Power Standard',          'power_standard',  'Battery mount or power connector type',                               'enum', 4),
  ('Recording Media',         'recording_media', 'Proprietary or standard media card/SSD format',                       'enum', 5),
  ('Signal Output',           'signal_output',   'Video output standard for monitors and recorders',                    'enum', 6),
  ('Gear Pitch (FIZ)',        'gear_pitch',       'Follow focus motor gear pitch — must match lens iris/focus gears',    'enum', 7);
