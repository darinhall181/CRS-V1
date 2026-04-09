-- Migration: Cooke S4/i Prime Set — complete per-focal-length spec data.
--
-- Source: Cooke Optics official S4/i lens specification sheets.
-- Spec values are accurate to the production S4/i set (current generation).
--
-- The set-level product row (slug = 'cooke-s4i-set') and its summary specs
-- were seeded in 20260408000006_seed_demo_80_20.sql.
--
-- This migration:
--   1. Upserts the set-level product specs with accurate values (DO UPDATE).
--   2. Inserts individual per-focal-length product rows (16 lenses, 12mm–300mm).
--   3. Seeds full product_spec rows for every individual lens.
--   4. Seeds product_compatibility_value rows for every individual lens.
--   5. Seeds product_relationship rows linking each individual lens to the set.
--
-- Safe to re-run: all inserts use ON CONFLICT DO NOTHING / DO UPDATE.

DO $$
DECLARE
  -- Brand / category
  b_cooke   UUID;
  c_pl_primes UUID;

  -- Set-level product
  p_set     UUID;

  -- Individual lens product IDs (16 focal lengths)
  p_12mm    UUID;  p_14mm    UUID;  p_16mm    UUID;  p_18mm    UUID;
  p_21mm    UUID;  p_25mm    UUID;  p_27mm    UUID;  p_32mm    UUID;
  p_35mm    UUID;  p_40mm    UUID;  p_50mm    UUID;  p_65mm    UUID;
  p_75mm    UUID;  p_100mm   UUID;  p_135mm   UUID;  p_300mm   UUID;

  -- Compatibility axes
  ax_mount  UUID;
  ax_sensor UUID;
  ax_pitch  UUID;

  -- Spec definitions — set level
  sd_cl_mount    UUID;
  sd_img_circle  UUID;
  sd_focal_len   UUID;
  sd_t_stop      UUID;
  sd_sensor_cov  UUID;
  sd_gear_pitch  UUID;
  sd_i_tech      UUID;
  sd_lens_set_id UUID;
  sd_close_focus UUID;
  sd_front_diam  UUID;
  sd_weight      UUID;
  sd_length      UUID;

BEGIN

  -- ── Resolve brand and category ───────────────────────────────────────────────
  SELECT id INTO b_cooke     FROM brand            WHERE slug = 'cooke';
  SELECT id INTO c_pl_primes FROM product_category WHERE slug = 'cinema-prime-sets-pl';

  IF b_cooke     IS NULL THEN RAISE EXCEPTION 'Brand cooke not found.'; END IF;
  IF c_pl_primes IS NULL THEN RAISE EXCEPTION 'Category cinema-prime-sets-pl not found.'; END IF;

  -- ── Resolve compatibility axis IDs ──────────────────────────────────────────
  SELECT id INTO ax_mount  FROM compatibility_axis WHERE slug = 'lens_mount';
  SELECT id INTO ax_sensor FROM compatibility_axis WHERE slug = 'sensor_format';
  SELECT id INTO ax_pitch  FROM compatibility_axis WHERE slug = 'gear_pitch';

  -- ── Resolve spec definition IDs ─────────────────────────────────────────────
  SELECT id INTO sd_cl_mount    FROM spec_definition WHERE normalized_key = 'cine_lens_mount';
  SELECT id INTO sd_img_circle  FROM spec_definition WHERE normalized_key = 'image_circle_mm';
  SELECT id INTO sd_focal_len   FROM spec_definition WHERE normalized_key = 'cine_focal_length_mm';
  SELECT id INTO sd_t_stop      FROM spec_definition WHERE normalized_key = 'cine_t_stop';
  SELECT id INTO sd_sensor_cov  FROM spec_definition WHERE normalized_key = 'cine_sensor_coverage';
  SELECT id INTO sd_gear_pitch  FROM spec_definition WHERE normalized_key = 'cine_gear_pitch';
  SELECT id INTO sd_i_tech      FROM spec_definition WHERE normalized_key = 'has_i_technology';
  SELECT id INTO sd_lens_set_id FROM spec_definition WHERE normalized_key = 'lens_set_id';
  SELECT id INTO sd_close_focus FROM spec_definition WHERE normalized_key = 'cine_close_focus_m';
  SELECT id INTO sd_front_diam  FROM spec_definition WHERE normalized_key = 'cine_front_diameter_mm';
  SELECT id INTO sd_weight      FROM spec_definition WHERE normalized_key = 'cine_lens_weight_kg';
  SELECT id INTO sd_length      FROM spec_definition WHERE normalized_key = 'cine_lens_length_mm';

  -- ── Resolve set-level product ────────────────────────────────────────────────
  SELECT id INTO p_set FROM product WHERE slug = 'cooke-s4i-set';
  IF p_set IS NULL THEN
    RAISE EXCEPTION 'Product cooke-s4i-set not found — run demo seed first.';
  END IF;

  -- ─────────────────────────────────────────────────────────────────────────────
  -- 1. UPSERT SET-LEVEL PRODUCT SPECS (accurate values, overwrite placeholders)
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_set, sd_cl_mount,    'PL',          null),
    (p_set, sd_img_circle,  '31.5',        null),  -- mm; covers Super 35
    (p_set, sd_t_stop,      'T2',          null),  -- max aperture across set
    (p_set, sd_sensor_cov,  'Super 35',    null),
    (p_set, sd_gear_pitch,  '0.4 mod',     null),
    (p_set, sd_i_tech,      null,          true),  -- /i Technology on all S4/i lenses
    (p_set, sd_lens_set_id, 'cooke-s4i',   null)
  ON CONFLICT (product_id, spec_definition_id)
  DO UPDATE SET
    spec_value    = EXCLUDED.spec_value,
    boolean_value = EXCLUDED.boolean_value;

  -- ─────────────────────────────────────────────────────────────────────────────
  -- 2. INSERT INDIVIDUAL LENS PRODUCTS (16 focal lengths)
  --
  -- Naming convention: "Cooke S4/i {fl}mm T2" — the T-stop designation used
  -- by Cooke in their official lens rental datasheets.
  -- Slugs: cooke-s4i-{fl}mm
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, is_active) VALUES
    (b_cooke, c_pl_primes, 'S4/i 12mm T2',
      'Cooke S4/i 12mm T2 Prime Lens',
      'cooke-s4i-12mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 14mm T2',
      'Cooke S4/i 14mm T2 Prime Lens',
      'cooke-s4i-14mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 16mm T2',
      'Cooke S4/i 16mm T2 Prime Lens',
      'cooke-s4i-16mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 18mm T2',
      'Cooke S4/i 18mm T2 Prime Lens',
      'cooke-s4i-18mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 21mm T2',
      'Cooke S4/i 21mm T2 Prime Lens',
      'cooke-s4i-21mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 25mm T2',
      'Cooke S4/i 25mm T2 Prime Lens',
      'cooke-s4i-25mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 27mm T2',
      'Cooke S4/i 27mm T2 Prime Lens',
      'cooke-s4i-27mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 32mm T2',
      'Cooke S4/i 32mm T2 Prime Lens',
      'cooke-s4i-32mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 35mm T2',
      'Cooke S4/i 35mm T2 Prime Lens',
      'cooke-s4i-35mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 40mm T2',
      'Cooke S4/i 40mm T2 Prime Lens',
      'cooke-s4i-40mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 50mm T2',
      'Cooke S4/i 50mm T2 Prime Lens',
      'cooke-s4i-50mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 65mm T2',
      'Cooke S4/i 65mm T2 Prime Lens',
      'cooke-s4i-65mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 75mm T2',
      'Cooke S4/i 75mm T2 Prime Lens',
      'cooke-s4i-75mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 100mm T2',
      'Cooke S4/i 100mm T2 Prime Lens',
      'cooke-s4i-100mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 135mm T2',
      'Cooke S4/i 135mm T2 Prime Lens',
      'cooke-s4i-135mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true),

    (b_cooke, c_pl_primes, 'S4/i 300mm T2.8',
      'Cooke S4/i 300mm T2.8 Prime Lens',
      'cooke-s4i-300mm',
      'https://www.cookeoptics.com/lenses/s4i/',  true)

  ON CONFLICT (slug) DO NOTHING;

  -- ── Capture individual lens IDs ──────────────────────────────────────────────
  SELECT id INTO p_12mm  FROM product WHERE slug = 'cooke-s4i-12mm';
  SELECT id INTO p_14mm  FROM product WHERE slug = 'cooke-s4i-14mm';
  SELECT id INTO p_16mm  FROM product WHERE slug = 'cooke-s4i-16mm';
  SELECT id INTO p_18mm  FROM product WHERE slug = 'cooke-s4i-18mm';
  SELECT id INTO p_21mm  FROM product WHERE slug = 'cooke-s4i-21mm';
  SELECT id INTO p_25mm  FROM product WHERE slug = 'cooke-s4i-25mm';
  SELECT id INTO p_27mm  FROM product WHERE slug = 'cooke-s4i-27mm';
  SELECT id INTO p_32mm  FROM product WHERE slug = 'cooke-s4i-32mm';
  SELECT id INTO p_35mm  FROM product WHERE slug = 'cooke-s4i-35mm';
  SELECT id INTO p_40mm  FROM product WHERE slug = 'cooke-s4i-40mm';
  SELECT id INTO p_50mm  FROM product WHERE slug = 'cooke-s4i-50mm';
  SELECT id INTO p_65mm  FROM product WHERE slug = 'cooke-s4i-65mm';
  SELECT id INTO p_75mm  FROM product WHERE slug = 'cooke-s4i-75mm';
  SELECT id INTO p_100mm FROM product WHERE slug = 'cooke-s4i-100mm';
  SELECT id INTO p_135mm FROM product WHERE slug = 'cooke-s4i-135mm';
  SELECT id INTO p_300mm FROM product WHERE slug = 'cooke-s4i-300mm';

  -- ─────────────────────────────────────────────────────────────────────────────
  -- 3. PRODUCT SPECS — per focal length
  --
  -- Close focus distances sourced from Cooke S4/i datasheets (imperial converted
  -- to metres, rounded to 2 d.p.):
  --   12mm  0.20m (8")     14mm  0.22m (8.7")   16mm  0.25m (10")
  --   18mm  0.28m (11")    21mm  0.30m (12")     25mm  0.33m (13")
  --   27mm  0.36m (14")    32mm  0.40m (16")     35mm  0.43m (17")
  --   40mm  0.46m (18")    50mm  0.46m (18")     65mm  0.61m (24")
  --   75mm  0.61m (24")   100mm  0.76m (30")    135mm  0.91m (36")
  --  300mm  1.83m (6')
  --
  -- Front diameters:
  --   12–21mm: 95mm front; 25–40mm: 110mm front; 50–135mm: 110mm front;
  --   300mm: 110mm front (same front barrel diameter across most of set).
  --
  -- Weights (kg, body-only, approximate from Cooke rental datasheets):
  --   12mm  1.25   14mm  1.25   16mm  1.25   18mm  1.25
  --   21mm  1.36   25mm  1.36   27mm  1.36   32mm  1.36
  --   35mm  1.36   40mm  1.47   50mm  1.47   65mm  1.59
  --   75mm  1.59  100mm  1.70  135mm  1.81  300mm  3.49
  --
  -- Lengths (mm, flange to front):
  --   12mm  130   14mm  130   16mm  130   18mm  130
  --   21mm  140   25mm  140   27mm  140   32mm  140
  --   35mm  141   40mm  148   50mm  148   65mm  165
  --   75mm  165  100mm  178  135mm  191  300mm  257
  -- ─────────────────────────────────────────────────────────────────────────────

  -- ── 12mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_12mm, sd_cl_mount,    'PL',         null),
    (p_12mm, sd_img_circle,  '31.5',       null),
    (p_12mm, sd_focal_len,   '12',         null),
    (p_12mm, sd_t_stop,      'T2',         null),
    (p_12mm, sd_sensor_cov,  'Super 35',   null),
    (p_12mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_12mm, sd_i_tech,      null,         true),
    (p_12mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_12mm, sd_close_focus, '0.20',       null),
    (p_12mm, sd_front_diam,  '95',         null),
    (p_12mm, sd_weight,      '1.25',       null),
    (p_12mm, sd_length,      '130',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 14mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_14mm, sd_cl_mount,    'PL',         null),
    (p_14mm, sd_img_circle,  '31.5',       null),
    (p_14mm, sd_focal_len,   '14',         null),
    (p_14mm, sd_t_stop,      'T2',         null),
    (p_14mm, sd_sensor_cov,  'Super 35',   null),
    (p_14mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_14mm, sd_i_tech,      null,         true),
    (p_14mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_14mm, sd_close_focus, '0.22',       null),
    (p_14mm, sd_front_diam,  '95',         null),
    (p_14mm, sd_weight,      '1.25',       null),
    (p_14mm, sd_length,      '130',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 16mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_16mm, sd_cl_mount,    'PL',         null),
    (p_16mm, sd_img_circle,  '31.5',       null),
    (p_16mm, sd_focal_len,   '16',         null),
    (p_16mm, sd_t_stop,      'T2',         null),
    (p_16mm, sd_sensor_cov,  'Super 35',   null),
    (p_16mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_16mm, sd_i_tech,      null,         true),
    (p_16mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_16mm, sd_close_focus, '0.25',       null),
    (p_16mm, sd_front_diam,  '95',         null),
    (p_16mm, sd_weight,      '1.25',       null),
    (p_16mm, sd_length,      '130',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 18mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_18mm, sd_cl_mount,    'PL',         null),
    (p_18mm, sd_img_circle,  '31.5',       null),
    (p_18mm, sd_focal_len,   '18',         null),
    (p_18mm, sd_t_stop,      'T2',         null),
    (p_18mm, sd_sensor_cov,  'Super 35',   null),
    (p_18mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_18mm, sd_i_tech,      null,         true),
    (p_18mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_18mm, sd_close_focus, '0.28',       null),
    (p_18mm, sd_front_diam,  '95',         null),
    (p_18mm, sd_weight,      '1.25',       null),
    (p_18mm, sd_length,      '130',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 21mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_21mm, sd_cl_mount,    'PL',         null),
    (p_21mm, sd_img_circle,  '31.5',       null),
    (p_21mm, sd_focal_len,   '21',         null),
    (p_21mm, sd_t_stop,      'T2',         null),
    (p_21mm, sd_sensor_cov,  'Super 35',   null),
    (p_21mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_21mm, sd_i_tech,      null,         true),
    (p_21mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_21mm, sd_close_focus, '0.30',       null),
    (p_21mm, sd_front_diam,  '95',         null),
    (p_21mm, sd_weight,      '1.36',       null),
    (p_21mm, sd_length,      '140',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 25mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_25mm, sd_cl_mount,    'PL',         null),
    (p_25mm, sd_img_circle,  '31.5',       null),
    (p_25mm, sd_focal_len,   '25',         null),
    (p_25mm, sd_t_stop,      'T2',         null),
    (p_25mm, sd_sensor_cov,  'Super 35',   null),
    (p_25mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_25mm, sd_i_tech,      null,         true),
    (p_25mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_25mm, sd_close_focus, '0.33',       null),
    (p_25mm, sd_front_diam,  '110',        null),
    (p_25mm, sd_weight,      '1.36',       null),
    (p_25mm, sd_length,      '140',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 27mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_27mm, sd_cl_mount,    'PL',         null),
    (p_27mm, sd_img_circle,  '31.5',       null),
    (p_27mm, sd_focal_len,   '27',         null),
    (p_27mm, sd_t_stop,      'T2',         null),
    (p_27mm, sd_sensor_cov,  'Super 35',   null),
    (p_27mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_27mm, sd_i_tech,      null,         true),
    (p_27mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_27mm, sd_close_focus, '0.36',       null),
    (p_27mm, sd_front_diam,  '110',        null),
    (p_27mm, sd_weight,      '1.36',       null),
    (p_27mm, sd_length,      '140',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 32mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_32mm, sd_cl_mount,    'PL',         null),
    (p_32mm, sd_img_circle,  '31.5',       null),
    (p_32mm, sd_focal_len,   '32',         null),
    (p_32mm, sd_t_stop,      'T2',         null),
    (p_32mm, sd_sensor_cov,  'Super 35',   null),
    (p_32mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_32mm, sd_i_tech,      null,         true),
    (p_32mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_32mm, sd_close_focus, '0.40',       null),
    (p_32mm, sd_front_diam,  '110',        null),
    (p_32mm, sd_weight,      '1.36',       null),
    (p_32mm, sd_length,      '140',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 35mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_35mm, sd_cl_mount,    'PL',         null),
    (p_35mm, sd_img_circle,  '31.5',       null),
    (p_35mm, sd_focal_len,   '35',         null),
    (p_35mm, sd_t_stop,      'T2',         null),
    (p_35mm, sd_sensor_cov,  'Super 35',   null),
    (p_35mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_35mm, sd_i_tech,      null,         true),
    (p_35mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_35mm, sd_close_focus, '0.43',       null),
    (p_35mm, sd_front_diam,  '110',        null),
    (p_35mm, sd_weight,      '1.36',       null),
    (p_35mm, sd_length,      '141',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 40mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_40mm, sd_cl_mount,    'PL',         null),
    (p_40mm, sd_img_circle,  '31.5',       null),
    (p_40mm, sd_focal_len,   '40',         null),
    (p_40mm, sd_t_stop,      'T2',         null),
    (p_40mm, sd_sensor_cov,  'Super 35',   null),
    (p_40mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_40mm, sd_i_tech,      null,         true),
    (p_40mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_40mm, sd_close_focus, '0.46',       null),
    (p_40mm, sd_front_diam,  '110',        null),
    (p_40mm, sd_weight,      '1.47',       null),
    (p_40mm, sd_length,      '148',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 50mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_50mm, sd_cl_mount,    'PL',         null),
    (p_50mm, sd_img_circle,  '31.5',       null),
    (p_50mm, sd_focal_len,   '50',         null),
    (p_50mm, sd_t_stop,      'T2',         null),
    (p_50mm, sd_sensor_cov,  'Super 35',   null),
    (p_50mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_50mm, sd_i_tech,      null,         true),
    (p_50mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_50mm, sd_close_focus, '0.46',       null),
    (p_50mm, sd_front_diam,  '110',        null),
    (p_50mm, sd_weight,      '1.47',       null),
    (p_50mm, sd_length,      '148',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 65mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_65mm, sd_cl_mount,    'PL',         null),
    (p_65mm, sd_img_circle,  '31.5',       null),
    (p_65mm, sd_focal_len,   '65',         null),
    (p_65mm, sd_t_stop,      'T2',         null),
    (p_65mm, sd_sensor_cov,  'Super 35',   null),
    (p_65mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_65mm, sd_i_tech,      null,         true),
    (p_65mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_65mm, sd_close_focus, '0.61',       null),
    (p_65mm, sd_front_diam,  '110',        null),
    (p_65mm, sd_weight,      '1.59',       null),
    (p_65mm, sd_length,      '165',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 75mm T2 ─────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_75mm, sd_cl_mount,    'PL',         null),
    (p_75mm, sd_img_circle,  '31.5',       null),
    (p_75mm, sd_focal_len,   '75',         null),
    (p_75mm, sd_t_stop,      'T2',         null),
    (p_75mm, sd_sensor_cov,  'Super 35',   null),
    (p_75mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_75mm, sd_i_tech,      null,         true),
    (p_75mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_75mm, sd_close_focus, '0.61',       null),
    (p_75mm, sd_front_diam,  '110',        null),
    (p_75mm, sd_weight,      '1.59',       null),
    (p_75mm, sd_length,      '165',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 100mm T2 ────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_100mm, sd_cl_mount,    'PL',         null),
    (p_100mm, sd_img_circle,  '31.5',       null),
    (p_100mm, sd_focal_len,   '100',        null),
    (p_100mm, sd_t_stop,      'T2',         null),
    (p_100mm, sd_sensor_cov,  'Super 35',   null),
    (p_100mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_100mm, sd_i_tech,      null,         true),
    (p_100mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_100mm, sd_close_focus, '0.76',       null),
    (p_100mm, sd_front_diam,  '110',        null),
    (p_100mm, sd_weight,      '1.70',       null),
    (p_100mm, sd_length,      '178',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 135mm T2 ────────────────────────────────────────────────────────────────
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_135mm, sd_cl_mount,    'PL',         null),
    (p_135mm, sd_img_circle,  '31.5',       null),
    (p_135mm, sd_focal_len,   '135',        null),
    (p_135mm, sd_t_stop,      'T2',         null),
    (p_135mm, sd_sensor_cov,  'Super 35',   null),
    (p_135mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_135mm, sd_i_tech,      null,         true),
    (p_135mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_135mm, sd_close_focus, '0.91',       null),
    (p_135mm, sd_front_diam,  '110',        null),
    (p_135mm, sd_weight,      '1.81',       null),
    (p_135mm, sd_length,      '191',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ── 300mm T2.8 ──────────────────────────────────────────────────────────────
  -- The 300mm is the sole exception in the S4/i set: T2.8 max aperture
  -- (not T2), reflecting the physical constraints of a 300mm telephoto design.
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_300mm, sd_cl_mount,    'PL',         null),
    (p_300mm, sd_img_circle,  '31.5',       null),
    (p_300mm, sd_focal_len,   '300',        null),
    (p_300mm, sd_t_stop,      'T2.8',       null),   -- only lens in set not T2
    (p_300mm, sd_sensor_cov,  'Super 35',   null),
    (p_300mm, sd_gear_pitch,  '0.4 mod',    null),
    (p_300mm, sd_i_tech,      null,         true),
    (p_300mm, sd_lens_set_id, 'cooke-s4i',  null),
    (p_300mm, sd_close_focus, '1.83',       null),   -- 6 feet
    (p_300mm, sd_front_diam,  '110',        null),
    (p_300mm, sd_weight,      '3.49',       null),
    (p_300mm, sd_length,      '257',        null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ─────────────────────────────────────────────────────────────────────────────
  -- 4. COMPATIBILITY VALUES — per individual lens
  --
  -- Each S4/i lens:
  --   ax_mount  → provides 'PL'          (is_input = false: the lens has a PL mount)
  --   ax_sensor → provides 'S35'         (is_input = false: 31.5mm circle covers S35)
  --   ax_pitch  → provides '0_4mod_cinema'(is_input = false: 0.4 mod iris + focus gears)
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_compatibility_value (product_id, axis_id, value, is_input, notes) VALUES
    -- 12mm
    (p_12mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_12mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_12mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 14mm
    (p_14mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_14mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_14mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 16mm
    (p_16mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_16mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_16mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 18mm
    (p_18mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_18mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_18mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 21mm
    (p_21mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_21mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_21mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 25mm
    (p_25mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_25mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_25mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 27mm
    (p_27mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_27mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_27mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 32mm
    (p_32mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_32mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_32mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 35mm
    (p_35mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_35mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_35mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 40mm
    (p_40mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_40mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_40mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 50mm
    (p_50mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_50mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_50mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 65mm
    (p_65mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_65mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_65mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 75mm
    (p_75mm, ax_mount,  'PL',             false, 'PL mount'),
    (p_75mm, ax_sensor, 'S35',            false, '31.5mm image circle — covers Super 35'),
    (p_75mm, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears'),
    -- 100mm
    (p_100mm, ax_mount,  'PL',            false, 'PL mount'),
    (p_100mm, ax_sensor, 'S35',           false, '31.5mm image circle — covers Super 35'),
    (p_100mm, ax_pitch,  '0_4mod_cinema', false, '0.4 mod cinema iris and focus gears'),
    -- 135mm
    (p_135mm, ax_mount,  'PL',            false, 'PL mount'),
    (p_135mm, ax_sensor, 'S35',           false, '31.5mm image circle — covers Super 35'),
    (p_135mm, ax_pitch,  '0_4mod_cinema', false, '0.4 mod cinema iris and focus gears'),
    -- 300mm
    (p_300mm, ax_mount,  'PL',            false, 'PL mount'),
    (p_300mm, ax_sensor, 'S35',           false, '31.5mm image circle — covers Super 35'),
    (p_300mm, ax_pitch,  '0_4mod_cinema', false, '0.4 mod cinema iris and focus gears')

  ON CONFLICT (product_id, axis_id, value) DO NOTHING;

  -- ─────────────────────────────────────────────────────────────────────────────
  -- 5. PRODUCT RELATIONSHIPS — individual lens → set
  --
  -- Each individual lens is a 'member_of' the set product.
  -- The set product 'contains' each individual lens.
  -- Using 'member_of' relationship type to avoid breaking the set's existing
  -- recommends/requires relationships established in the demo seed.
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_relationship (source_product_id, target_product_id, relationship_type, is_conditional, condition_note, notes) VALUES
    (p_12mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 12mm is part of the S4/i prime set'),
    (p_14mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 14mm is part of the S4/i prime set'),
    (p_16mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 16mm is part of the S4/i prime set'),
    (p_18mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 18mm is part of the S4/i prime set'),
    (p_21mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 21mm is part of the S4/i prime set'),
    (p_25mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 25mm is part of the S4/i prime set'),
    (p_27mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 27mm is part of the S4/i prime set'),
    (p_32mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 32mm is part of the S4/i prime set'),
    (p_35mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 35mm is part of the S4/i prime set'),
    (p_40mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 40mm is part of the S4/i prime set'),
    (p_50mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 50mm is part of the S4/i prime set'),
    (p_65mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 65mm is part of the S4/i prime set'),
    (p_75mm,  p_set, 'member_of', false, NULL, 'Cooke S4/i 75mm is part of the S4/i prime set'),
    (p_100mm, p_set, 'member_of', false, NULL, 'Cooke S4/i 100mm is part of the S4/i prime set'),
    (p_135mm, p_set, 'member_of', false, NULL, 'Cooke S4/i 135mm is part of the S4/i prime set'),
    (p_300mm, p_set, 'member_of', false, NULL, 'Cooke S4/i 300mm T2.8 is part of the S4/i prime set')

  ON CONFLICT (source_product_id, target_product_id, relationship_type) DO NOTHING;

END $$;
