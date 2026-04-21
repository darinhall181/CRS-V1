-- ─────────────────────────────────────────────────────────────────────────────
-- Zeiss Supreme Prime Set — scraped spec seed
-- Source: https://www.zeiss.com/consumer-products/us/cinematography/supreme-prime-lenses.html
-- Key specs confirmed from Zeiss published data (April 2026)
--
-- Focal lengths available: 15, 18, 21, 25, 29, 35, 40, 50, 65, 85, 100, 135, 150, 200mm
-- Image circle:  46.31 mm (covers Full Frame / Large Format)
-- T-stop:        T1.5 (all focal lengths)
-- Mount:         PL and LPL (ordered separately per focal length)
-- Front diam.:   95 mm (consistent across all focal lengths)
-- Iris gear:     0.4 mod (cinema standard)
-- Focus gear:    0.4 mod (cinema standard)
-- eXtended Data: YES — Zeiss eXtended Data protocol (LDS-based metadata over /i contact)
-- /i Technology: NO  — Zeiss proprietary, not Cooke /i
-- Weight (50mm): ~1.6 kg (varies slightly; 1.4–1.9 kg across the set)
-- Close focus:   varies by focal length; 50mm = 0.38 m minimum object distance
--
-- The product row (slug = 'zeiss-supreme-prime-set') is already seeded in
-- 20260408000006_seed_demo_80_20.sql. This migration UPSERTs the full spec set
-- and compatibility values, extending that demo row with scraped detail.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  p_id UUID;

  -- Compatibility axes
  ax_mount  UUID;
  ax_sensor UUID;
  ax_pitch  UUID;

  -- Spec definitions
  sd_cl_mount      UUID;
  sd_image_circle  UUID;
  sd_focal_len     UUID;
  sd_t_stop        UUID;
  sd_sensor_cov    UUID;
  sd_gear_pitch    UUID;
  sd_focus_gear    UUID;
  sd_i_tech        UUID;
  sd_lds           UUID;
  sd_lens_set_id   UUID;
  sd_close_focus   UUID;
  sd_front_diam    UUID;
  sd_weight        UUID;

BEGIN

  -- ── Resolve product ─────────────────────────────────────────────────────────
  SELECT id INTO p_id FROM product WHERE slug = 'zeiss-supreme-prime-set';
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product zeiss-supreme-prime-set not found. '
                    'Run 20260408000006_seed_demo_80_20.sql first.';
  END IF;

  -- ── Resolve compatibility axes ──────────────────────────────────────────────
  SELECT id INTO ax_mount  FROM compatibility_axis WHERE slug = 'lens_mount';
  SELECT id INTO ax_sensor FROM compatibility_axis WHERE slug = 'sensor_format';
  SELECT id INTO ax_pitch  FROM compatibility_axis WHERE slug = 'gear_pitch';

  -- ── Resolve spec definitions ────────────────────────────────────────────────
  SELECT id INTO sd_cl_mount     FROM spec_definition WHERE normalized_key = 'cine_lens_mount';
  SELECT id INTO sd_image_circle FROM spec_definition WHERE normalized_key = 'image_circle_mm';
  SELECT id INTO sd_focal_len    FROM spec_definition WHERE normalized_key = 'cine_focal_length_mm';
  SELECT id INTO sd_t_stop       FROM spec_definition WHERE normalized_key = 'cine_t_stop';
  SELECT id INTO sd_sensor_cov   FROM spec_definition WHERE normalized_key = 'cine_sensor_coverage';
  SELECT id INTO sd_gear_pitch   FROM spec_definition WHERE normalized_key = 'cine_gear_pitch';
  SELECT id INTO sd_focus_gear   FROM spec_definition WHERE normalized_key = 'cine_focus_gear_pitch';
  SELECT id INTO sd_i_tech       FROM spec_definition WHERE normalized_key = 'has_i_technology';
  SELECT id INTO sd_lds          FROM spec_definition WHERE normalized_key = 'has_lds_metadata';
  SELECT id INTO sd_lens_set_id  FROM spec_definition WHERE normalized_key = 'lens_set_id';
  SELECT id INTO sd_close_focus  FROM spec_definition WHERE normalized_key = 'cine_close_focus_m';
  SELECT id INTO sd_front_diam   FROM spec_definition WHERE normalized_key = 'cine_front_diameter_mm';
  SELECT id INTO sd_weight       FROM spec_definition WHERE normalized_key = 'cine_lens_weight_kg';

  -- ─────────────────────────────────────────────────────────────────────────────
  -- PRODUCT SPECS
  -- Scraped / confirmed from Zeiss Supreme Prime product page and datasheet.
  --
  -- image_circle_mm  = 46.31  — published by Zeiss; covers Full Frame 43.1mm
  --                             diagonal with headroom (LPL spec)
  -- cine_t_stop      = 1.5    — uniform T1.5 across all focal lengths
  -- cine_close_focus_m = 0.38 — 50mm representative value (MOD 0.38m);
  --                             shorter focal lengths are closer (15mm = 0.3m)
  -- cine_front_diameter_mm = 95 — all Supreme Primes share a 95mm front
  -- cine_lens_weight_kg = 1.6  — 50mm T1.5; full set ranges 1.4–1.9 kg
  -- has_lds_metadata  = true   — Zeiss eXtended Data (metadata contacts over
  --                              the /i pin on PL; LDS on LPL mount)
  -- has_i_technology  = false  — NOT Cooke /i; Zeiss uses their own protocol
  -- cine_focal_length_mm = '15, 18, 21, 25, 29, 35, 40, 50, 65, 85, 100, 135,
  --                          150, 200' — full set as of 2024 lineup
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_id, sd_cl_mount,     'PL / LPL',                                                         null),
    (p_id, sd_image_circle, '46.31',                                                             null),
    (p_id, sd_t_stop,       '1.5',                                                               null),
    (p_id, sd_sensor_cov,   'Full Frame',                                                        null),
    (p_id, sd_gear_pitch,   '0.4 mod',                                                           null),
    (p_id, sd_focus_gear,   '0.4 mod',                                                           null),
    (p_id, sd_lens_set_id,  'zeiss-supreme-prime',                                               null),
    (p_id, sd_focal_len,    '15, 18, 21, 25, 29, 35, 40, 50, 65, 85, 100, 135, 150, 200',       null),
    (p_id, sd_close_focus,  '0.38',                                                              null),
    (p_id, sd_front_diam,   '95',                                                                null),
    (p_id, sd_weight,       '1.6',                                                               null),
    (p_id, sd_i_tech,       null,                                                                false),
    (p_id, sd_lds,          null,                                                                true)
  ON CONFLICT (product_id, spec_definition_id)
  DO UPDATE SET
    spec_value    = EXCLUDED.spec_value,
    boolean_value = EXCLUDED.boolean_value;

  -- ─────────────────────────────────────────────────────────────────────────────
  -- COMPATIBILITY VALUES
  --
  -- Supreme Primes are available in both PL and LPL barrel versions (ordered
  -- separately per focal length). They cover Full Frame (46.31mm image circle)
  -- and therefore also cover Super 35 (31.5mm diagonal). All use standard
  -- 0.4 mod cinema iris and focus gears.
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_compatibility_value (product_id, axis_id, value, is_input, notes) VALUES
    (p_id, ax_mount,  'PL',             false, 'PL mount version available (ordered per focal length)'),
    (p_id, ax_mount,  'LPL',            false, 'LPL mount version available (ordered per focal length)'),
    (p_id, ax_sensor, 'FF',             false, '46.31mm image circle — covers Full Frame / Large Format'),
    (p_id, ax_sensor, 'S35',            false, '46.31mm image circle also covers Super 35 (31.5mm diagonal)'),
    (p_id, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema iris and focus gears (standard)')
  ON CONFLICT (product_id, axis_id, value) DO NOTHING;

END $$;
