# Supabase

Local Supabase instance for Altoscope. Migrations live in `migrations/`, applied in timestamp order.

```
supabase start               # Start local Postgres + Studio in Docker
supabase db push --include-all  # Apply all migrations
supabase stop
# Studio: http://127.0.0.1:54323
# DB:     postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

---

## Schema overview

### Catalog layer
Scraper-populated, read-only from the app's perspective. Powers the gear browser, spec display, and compatibility checker.

```
brand
  └── product                     (one brand → many products)
        ├── product_spec           (one normalized spec value per spec_definition)
        ├── product_spec_matrix    (tabular specs, e.g. recording pixel grid)
        ├── product_image          (gallery images, R2-hosted)
        ├── product_document       (PDFs, spec sheets)
        ├── product_compatibility_value  (per-axis compatibility values)
        └── product_relationship   (requires / recommends / incompatible_with links)

product_category                  (hierarchical — parent_category_id self-ref)
spec_section                      (display groups, e.g. "Image Sensor", "Focus")
  └── spec_definition             (master taxonomy — normalized_key is the canonical identifier)
        └── spec_mapping          (regex rules that map raw scraped labels → normalized_key)

compatibility_axis                (the 7 standardized compatibility dimensions)
```

**How a spec gets from a manufacturer page into the DB:**
1. **Discovery** — Playwright crawls brand listing pages → saves product URLs
2. **Extraction** — Fetches each product page (HTML cache-first) → raw `{label: value}` JSON
3. **Normalization** — `spec_mapping` regex rules match raw labels → `normalized_key` (e.g. `"Image Sensor"` → `effective_pixels`)
4. **Persistence** — Upserts into `product_spec` / `product_spec_matrix`; never DELETEs

**Key design decisions:**
- `product_spec` stores both `spec_value` (cleaned) and `raw_value` (verbatim from website) — raw is kept for debugging normalization misses
- `product_spec_matrix` uses a `dims` JSONB column for row/column identifiers (e.g. `{"media_type":"RAW","codec":"CinemaDNG"}`) making the matrix schema-free
- `spec_mapping` rules are regex-based and brand-scoped via `manufacturer_key` — add new brands by seeding new rows, no code changes needed
- The pipeline connects directly as the `postgres` user and bypasses RLS entirely

### Compatibility & kit builder layer (added 20260408)
Powers the "Is this lens compatible with this camera?" checker and the kit builder's suggested accessories.

```
compatibility_axis                (7 axes: lens_mount, sensor_format, rod_system,
  └── product_compatibility_value  power_standard, recording_media, signal_output, gear_pitch)

product_relationship              (requires / recommends / incompatible_with / replaces)

kit_template                      (pre-built package starting points, anchored to a camera body)
  └── kit_template_item           (products in the template, required vs. optional)
```

**The 7 compatibility axes:**
| Slug | What it governs |
|---|---|
| `lens_mount` | PL / LPL / EF / RF / E-Mount — gates all lens↔body pairings |
| `sensor_format` | S35 / LF / FF / MF / ULF — determines if lens covers sensor without vignette |
| `rod_system` | 15mm LWS / 19mm studio — mattebox, follow focus, baseplate compatibility |
| `power_standard` | Gold Mount / V-Mount / D-Tap / NP-F — camera + accessory power chain |
| `recording_media` | CFexpress B / SxS / REDMAG / cFast2 — what media cards go in the kit |
| `signal_output` | 3G-SDI / 12G-SDI / HDMI 2.0 / RAW out — monitor + recorder compatibility |
| `gear_pitch` | 0.4 mod cinema / 0.8 mod DSLR — follow focus motor clamp compatibility |

**`is_input` on `product_compatibility_value`:** `true` means the product *accepts* that value (e.g. a camera body accepts PL mount lenses). `false` means it *provides* that value (e.g. a lens has a PL mount). A product can have multiple rows per axis — the ALEXA 35 accepts both LPL and PL.

### Rental house layer (added 20260408)
Tracks which rental houses carry which gear, at what reference rates, and records quotes per production package item.

```
rental_house
  └── rental_house_location       (city-level; rates/inventory can vary by location)
  └── rental_house_inventory      (which products they carry + scraped reference rates)

package_item_quote                (actual quoted rates per item per rental house)
```

**Quote workflow:** `package_items.status` drives the flow: `draft` → `sent` (RFQ dispatched) → `quote_received` (rental house replies, quotes populated) → `approved` (best quote selected, `day_rate_snapshot` updated) → `confirmed`. Multiple quotes can exist per item — always get at least 3 quotes; rates for the same item vary 15–30% between houses.

### Productions layer (added 20260408)
Multi-tenant workflow layer for productions, gear packages, and RLS-enforced role access.

```
companies
  └── company_members      (user ↔ company, company_role)
  └── productions
        └── production_members  (user ↔ production, production_role)
        └── packages
              └── package_items  (references product catalog)

users                      (extends auth.users 1:1)
invitations                (pending email invites, token-based)
```

**Enums**
- `company_role`: `owner` | `admin` | `member`
- `production_role`: `dp` | `coordinator` | `producer`
- `production_status`: `draft` | `active` | `wrapped` | `archived`
- `package_item_status`: `draft` | `sent` | `quote_received` | `approved` | `confirmed` | `unavailable` | `over_budget`

---

## Access control & RLS

### App roles
`users.app_role` is either `'admin'` or `'user'` (default). Admins are internal team members who need write access to the catalog. Promote a user with:

```sql
UPDATE users SET app_role = 'admin' WHERE id = '<user-uuid>';
```

The `is_admin()` helper function checks this and is reused in every catalog policy.

### How access is layered

| Role | Who | Catalog tables | Compatibility / kit | Rental house | Pipeline tables | Productions tables |
|---|---|---|---|---|---|---|
| `anon` | Unauthenticated | SELECT only | SELECT only | SELECT only | no access | no access |
| `authenticated / user` | Signed-in users | SELECT only | SELECT only | SELECT only | SELECT only | per production/company role |
| `authenticated / admin` | Internal team | full CRUD | full CRUD | full CRUD | full CRUD | full CRUD |
| `service_role` / pipeline | Python scraper, direct DB | bypasses RLS | bypasses RLS | bypasses RLS | bypasses RLS | bypasses RLS |

**Catalog tables** (brand, product_category, product, product_spec, product_spec_matrix, product_image, product_document, compatibility_axis, product_compatibility_value, product_relationship) are readable by `anon` — the public gear browser doesn't require a login.

**Rental house inventory** is `authenticated`-only (pricing data shouldn't be publicly indexed).

**Pipeline tables** (spec_section, spec_definition, spec_mapping) are `authenticated`-only reads — internal normalization data, not needed by unauthenticated visitors.

**Kit templates** — `is_public = true` templates are readable by all authenticated users. Private templates are visible only to their creator. Admins see all.

**Productions tables** (companies, productions, packages, package_item_quote, etc.) use the two-layer membership model described below. No anonymous access.

### Why the pipeline bypasses RLS
The Python pipeline connects via `SUPABASE_DB_URL` as the `postgres` superuser — a direct psycopg2 connection, not through PostgREST. RLS only applies to connections using the `anon` or `authenticated` JWT roles via the Supabase API. The pipeline doesn't use the API, so RLS is irrelevant to it. The same is true for Drizzle ORM in the Next.js app when it uses the direct DB URL.

---

## Design notes

### Two-layer membership model
The most important design decision. Every user has a company role and independently a production role — these are completely separate. A freelance DP might be a `member` of your company but a `dp` on three different productions simultaneously. You can be a company `admin` but have no role on a specific production at all. This is why visibility rules need both checks: `get_production_role(id) IS NOT NULL OR is_company_admin_for_production(id)`. Neither check alone is sufficient.

### The three RLS helper functions
`get_company_role()`, `get_production_role()`, and `is_company_admin_for_production()` do the heavy lifting. Rather than writing complex joins inside every policy, these are defined once and reused everywhere. They're marked `SECURITY DEFINER` so they bypass RLS when called from within a policy — without that, you get infinite recursion as the policy calls a function that triggers the same policy.

### day_rate_snapshot on package_items
Gear catalog prices change over time. If `package_items` referenced the catalog rate directly, a package built last month would silently show today's prices. Snapshotting the rate at the moment a DP adds an item means budget calculations are always historically accurate, regardless of what happens to the catalog later.

### The one thing RLS can't fully handle
The `package_items` UPDATE policy allows both `dp` and `coordinator` to write. But a DP should only edit gear fields (`gear_id`, `quantity`, `day_rate_snapshot`, `notes`) while a coordinator should only edit status fields (`status`, `approved_by`, `approved_at`). Postgres RLS can restrict which rows each role touches — restricting which columns on the same row requires application logic. Enforce this boundary in two separate server actions: `updateItemGear()` checks for `dp` role, `updateItemStatus()` checks for `coordinator` role.

---

## Auto-triggers

| Trigger | Table | Behavior |
|---|---|---|
| `on_auth_user_created` | `auth.users` | Creates a `users` row on signup |
| `on_company_created` | `companies` | Inserts `created_by` as `owner` in `company_members` |
| `on_production_created` | `productions` | Inserts `created_by` as `producer` in `production_members` |
| `set_updated_at` | `users`, `productions`, `packages` | Maintains `updated_at` on every row update |

---

## Permission matrix

| Action | Scope | Owner | Admin | Member/Producer | DP | Coordinator |
|---|---|:---:|:---:|:---:|:---:|:---:|
| See all company productions | Company | ✓ | ✓ | — | — | — |
| Create a production | Company | ✓ | ✓ | ✓ | — | — |
| Delete a production | Company | ✓ | ✓ | — | — | — |
| Invite members to company | Company | ✓ | ✓ | — | — | — |
| See assigned production | Production | ✓ | ✓ | ✓ | ✓ | ✓ |
| Edit production metadata | Production | ✓ | ✓ | ✓ | — | — |
| Create / rename packages | Production | — | — | — | ✓ | — |
| Add / remove gear items | Production | — | — | — | ✓ | — |
| Approve / flag items | Production | — | — | — | — | ✓ |
| See budget breakdown | Production | ✓ | ✓ | ✓ | read | ✓ |
| Route quote to rental house | Production | — | — | — | — | ✓ |
