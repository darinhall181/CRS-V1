-- ─────────────────────────────────────────────────────────────────────────────
-- Catalog RLS + app-level admin role
--
-- Access model:
--   anon        → SELECT on public catalog tables only (marketing pages)
--   authenticated → SELECT on all catalog tables (app features)
--   admin       → full CRUD on all catalog tables (internal team / ops)
--   service_role / pipeline → bypasses RLS entirely (postgres direct connection)
-- ─────────────────────────────────────────────────────────────────────────────

-- ── App role on users ─────────────────────────────────────────────────────────
-- Added here rather than in the productions migration to keep auth concerns
-- together. 'user' is the default for anyone who signs up.

ALTER TABLE users ADD COLUMN IF NOT EXISTS
  app_role text NOT NULL DEFAULT 'user'
  CHECK (app_role IN ('admin', 'user'));

-- ── Admin helper ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
      AND app_role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─────────────────────────────────────────────────────────────────────────────
-- Public catalog tables
-- anon + authenticated: SELECT only
-- admin: full CRUD
-- Tables: brand, product_category, product, product_spec,
--         product_spec_matrix, product_image, product_document
-- ─────────────────────────────────────────────────────────────────────────────

-- ── brand ─────────────────────────────────────────────────────────────────────

ALTER TABLE brand ENABLE ROW LEVEL SECURITY;

CREATE POLICY "brand_read" ON brand FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "brand_admin_all" ON brand
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- ── product_category ──────────────────────────────────────────────────────────

ALTER TABLE product_category ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_category_read" ON product_category FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "product_category_admin_all" ON product_category
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- ── product ───────────────────────────────────────────────────────────────────

ALTER TABLE product ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_read" ON product FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "product_admin_all" ON product
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- ── product_spec ──────────────────────────────────────────────────────────────

ALTER TABLE product_spec ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_spec_read" ON product_spec FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "product_spec_admin_all" ON product_spec
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- ── product_spec_matrix ───────────────────────────────────────────────────────

ALTER TABLE product_spec_matrix ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_spec_matrix_read" ON product_spec_matrix FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "product_spec_matrix_admin_all" ON product_spec_matrix
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- ── product_image ─────────────────────────────────────────────────────────────

ALTER TABLE product_image ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_image_read" ON product_image FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "product_image_admin_all" ON product_image
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- ── product_document ──────────────────────────────────────────────────────────

ALTER TABLE product_document ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_document_read" ON product_document FOR SELECT
  TO anon, authenticated USING (true);

CREATE POLICY "product_document_admin_all" ON product_document
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal pipeline tables
-- anon: no access
-- authenticated: SELECT only
-- admin: full CRUD
-- Tables: spec_section, spec_definition, spec_mapping
-- ─────────────────────────────────────────────────────────────────────────────

-- ── spec_section ──────────────────────────────────────────────────────────────

ALTER TABLE spec_section ENABLE ROW LEVEL SECURITY;

CREATE POLICY "spec_section_read" ON spec_section FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "spec_section_admin_all" ON spec_section
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- ── spec_definition ───────────────────────────────────────────────────────────

ALTER TABLE spec_definition ENABLE ROW LEVEL SECURITY;

CREATE POLICY "spec_definition_read" ON spec_definition FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "spec_definition_admin_all" ON spec_definition
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- ── spec_mapping ──────────────────────────────────────────────────────────────

ALTER TABLE spec_mapping ENABLE ROW LEVEL SECURITY;

CREATE POLICY "spec_mapping_read" ON spec_mapping FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "spec_mapping_admin_all" ON spec_mapping
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());
