-- ─────────────────────────────────────────────────────────────────────────────
-- Productions schema: companies, productions, packages, RLS
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Enums ────────────────────────────────────────────────────────────────────

CREATE TYPE company_role AS ENUM ('owner', 'admin', 'member');
CREATE TYPE production_role AS ENUM ('dp', 'coordinator', 'producer');
CREATE TYPE production_status AS ENUM ('draft', 'active', 'wrapped', 'archived');
CREATE TYPE package_item_status AS ENUM ('draft', 'sent', 'quote_received', 'approved', 'confirmed', 'unavailable', 'over_budget');

-- ── Shared updated_at trigger function ───────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ── users (extends auth.users) ───────────────────────────────────────────────

CREATE TABLE users (
  id                     uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name              text,
  avatar_url             text,
  experience_level       text CHECK (experience_level IN ('guided', 'standard', 'pro')),
  default_production_role production_role,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can read and update their own row only
CREATE POLICY "users_select_own" ON users FOR SELECT USING (id = auth.uid());
CREATE POLICY "users_update_own" ON users FOR UPDATE USING (id = auth.uid());
-- Insert is handled by the signup trigger below
CREATE POLICY "users_insert_own" ON users FOR INSERT WITH CHECK (id = auth.uid());

-- Auto-create a users row on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ── companies ────────────────────────────────────────────────────────────────

CREATE TABLE companies (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name           text NOT NULL,
  slug           text UNIQUE,
  logo_url       text,
  billing_email  text,
  plan           text NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'pro', 'enterprise')),
  created_by     uuid NOT NULL REFERENCES users(id),
  created_at     timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- ── company_members ──────────────────────────────────────────────────────────

CREATE TABLE company_members (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id  uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role        company_role NOT NULL,
  invited_by  uuid REFERENCES users(id),
  joined_at   timestamptz,
  UNIQUE (company_id, user_id)
);

CREATE INDEX ON company_members (company_id);
CREATE INDEX ON company_members (user_id);

ALTER TABLE company_members ENABLE ROW LEVEL SECURITY;

-- ── productions ──────────────────────────────────────────────────────────────

CREATE TABLE productions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name          text NOT NULL,
  shoot_type    text CHECK (shoot_type IN ('narrative', 'commercial', 'documentary', 'music_video')),
  shoot_days    integer,
  start_date    date,
  end_date      date,
  total_budget  numeric(12,2),
  status        production_status NOT NULL DEFAULT 'draft',
  created_by    uuid NOT NULL REFERENCES users(id),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON productions (company_id);

CREATE TRIGGER productions_updated_at
  BEFORE UPDATE ON productions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE productions ENABLE ROW LEVEL SECURITY;

-- ── production_members ───────────────────────────────────────────────────────

CREATE TABLE production_members (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  production_id  uuid NOT NULL REFERENCES productions(id) ON DELETE CASCADE,
  user_id        uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role           production_role NOT NULL,
  invited_by     uuid REFERENCES users(id),
  joined_at      timestamptz,
  UNIQUE (production_id, user_id)
);

CREATE INDEX ON production_members (production_id);
CREATE INDEX ON production_members (user_id);

ALTER TABLE production_members ENABLE ROW LEVEL SECURITY;

-- ── packages ─────────────────────────────────────────────────────────────────

CREATE TABLE packages (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  production_id  uuid NOT NULL REFERENCES productions(id) ON DELETE CASCADE,
  name           text NOT NULL,
  created_by     uuid REFERENCES users(id),
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON packages (production_id);

CREATE TRIGGER packages_updated_at
  BEFORE UPDATE ON packages
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE packages ENABLE ROW LEVEL SECURITY;

-- ── package_items ────────────────────────────────────────────────────────────

CREATE TABLE package_items (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  package_id          uuid NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  gear_id             uuid REFERENCES product(id),
  quantity            integer NOT NULL DEFAULT 1,
  day_rate_snapshot   numeric(10,2),
  status              package_item_status NOT NULL DEFAULT 'draft',
  notes               text,
  added_by            uuid REFERENCES users(id),
  approved_by         uuid REFERENCES users(id),
  approved_at         timestamptz,
  sort_order          integer,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON package_items (package_id);

ALTER TABLE package_items ENABLE ROW LEVEL SECURITY;

-- ── invitations ──────────────────────────────────────────────────────────────

CREATE TABLE invitations (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email            text NOT NULL,
  company_id       uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  production_id    uuid REFERENCES productions(id) ON DELETE CASCADE,
  company_role     company_role,
  production_role  production_role,
  token            text UNIQUE NOT NULL DEFAULT replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', ''),
  invited_by       uuid REFERENCES users(id),
  expires_at       timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  accepted_at      timestamptz
);

CREATE INDEX ON invitations (token);
CREATE INDEX ON invitations (email);

ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- RLS helper functions
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_company_role(p_company_id uuid)
RETURNS company_role AS $$
  SELECT role FROM company_members
  WHERE company_id = p_company_id
    AND user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_production_role(p_production_id uuid)
RETURNS production_role AS $$
  SELECT role FROM production_members
  WHERE production_id = p_production_id
    AND user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_company_admin_for_production(p_production_id uuid)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM productions p
    JOIN company_members cm ON cm.company_id = p.company_id
    WHERE p.id = p_production_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─────────────────────────────────────────────────────────────────────────────
-- RLS policies
-- ─────────────────────────────────────────────────────────────────────────────

-- companies: members see their own company
CREATE POLICY "companies_select" ON companies FOR SELECT
  USING (get_company_role(id) IS NOT NULL);

-- companies: only owner/admin can update
CREATE POLICY "companies_update" ON companies FOR UPDATE
  USING (get_company_role(id) IN ('owner', 'admin'));

-- companies: any authenticated user can create (they become owner via trigger below)
CREATE POLICY "companies_insert" ON companies FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Auto-assign creator as owner when a company is created
CREATE OR REPLACE FUNCTION handle_new_company()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO company_members (company_id, user_id, role, joined_at)
  VALUES (NEW.id, NEW.created_by, 'owner', now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_company_created
  AFTER INSERT ON companies
  FOR EACH ROW EXECUTE FUNCTION handle_new_company();

-- company_members: members see own company roster
CREATE POLICY "company_members_select" ON company_members FOR SELECT
  USING (get_company_role(company_id) IS NOT NULL);

-- company_members: owner or admin can insert/update/delete
CREATE POLICY "company_members_insert" ON company_members FOR INSERT
  WITH CHECK (get_company_role(company_id) IN ('owner', 'admin'));

CREATE POLICY "company_members_update" ON company_members FOR UPDATE
  USING (get_company_role(company_id) IN ('owner', 'admin'));

CREATE POLICY "company_members_delete" ON company_members FOR DELETE
  USING (get_company_role(company_id) IN ('owner', 'admin'));

-- productions: select — production member OR company admin/owner
CREATE POLICY "productions_select" ON productions FOR SELECT
  USING (
    get_production_role(id) IS NOT NULL
    OR is_company_admin_for_production(id)
  );

-- productions: insert — any company member
CREATE POLICY "productions_insert" ON productions FOR INSERT
  WITH CHECK (get_company_role(company_id) IS NOT NULL);

-- Auto-assign creator as producer on new production
CREATE OR REPLACE FUNCTION handle_new_production()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO production_members (production_id, user_id, role, joined_at)
  VALUES (NEW.id, NEW.created_by, 'producer', now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_production_created
  AFTER INSERT ON productions
  FOR EACH ROW EXECUTE FUNCTION handle_new_production();

-- productions: update — producer on production OR company admin/owner
CREATE POLICY "productions_update" ON productions FOR UPDATE
  USING (
    get_production_role(id) = 'producer'
    OR is_company_admin_for_production(id)
  );

-- productions: delete — company admin/owner only
CREATE POLICY "productions_delete" ON productions FOR DELETE
  USING (is_company_admin_for_production(id));

-- production_members: any production member can see roster
CREATE POLICY "production_members_select" ON production_members FOR SELECT
  USING (
    get_production_role(production_id) IS NOT NULL
    OR is_company_admin_for_production(production_id)
  );

-- production_members: producer or company admin can manage roster
CREATE POLICY "production_members_insert" ON production_members FOR INSERT
  WITH CHECK (
    get_production_role(production_id) = 'producer'
    OR is_company_admin_for_production(production_id)
  );

CREATE POLICY "production_members_delete" ON production_members FOR DELETE
  USING (
    get_production_role(production_id) = 'producer'
    OR is_company_admin_for_production(production_id)
  );

-- packages: select — any production member
CREATE POLICY "packages_select" ON packages FOR SELECT
  USING (
    get_production_role(production_id) IS NOT NULL
    OR is_company_admin_for_production(production_id)
  );

-- packages: insert/update — DP only
CREATE POLICY "packages_insert" ON packages FOR INSERT
  WITH CHECK (get_production_role(production_id) = 'dp');

CREATE POLICY "packages_update" ON packages FOR UPDATE
  USING (get_production_role(production_id) = 'dp');

-- package_items: select — any production member (via package)
CREATE POLICY "package_items_select" ON package_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM packages pk
      WHERE pk.id = package_id
        AND (
          get_production_role(pk.production_id) IS NOT NULL
          OR is_company_admin_for_production(pk.production_id)
        )
    )
  );

-- package_items: insert — DP only
CREATE POLICY "package_items_insert" ON package_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM packages pk
      WHERE pk.id = package_id
        AND get_production_role(pk.production_id) = 'dp'
    )
  );

-- package_items: update — DP or coordinator
-- (enforce column-level split in app layer: updateItemGear() vs updateItemStatus())
CREATE POLICY "package_items_update" ON package_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM packages pk
      WHERE pk.id = package_id
        AND get_production_role(pk.production_id) IN ('dp', 'coordinator')
    )
  );

-- package_items: delete — DP only
CREATE POLICY "package_items_delete" ON package_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM packages pk
      WHERE pk.id = package_id
        AND get_production_role(pk.production_id) = 'dp'
    )
  );

-- invitations: invited_by user or company admin can see
CREATE POLICY "invitations_select" ON invitations FOR SELECT
  USING (
    invited_by = auth.uid()
    OR get_company_role(company_id) IN ('owner', 'admin')
  );

-- invitations: company admin can create
CREATE POLICY "invitations_insert" ON invitations FOR INSERT
  WITH CHECK (get_company_role(company_id) IN ('owner', 'admin'));

-- invitations: company admin can delete (revoke)
CREATE POLICY "invitations_delete" ON invitations FOR DELETE
  USING (get_company_role(company_id) IN ('owner', 'admin'));
