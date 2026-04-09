-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: Angenieux Optimo 24-290mm T2.8 — accurate product specs and
-- compatibility values.
--
-- Source: https://www.angenieux.com/optimo-24-290
-- Spec values sourced from the Angenieux Optimo 24-290mm T2.8 official
-- product page and published spec sheet.
--
-- Key specs:
--   Mount:          PL
--   T-stop:         T2.8
--   Focal range:    24–290mm
--   Zoom ratio:     12:1
--   Sensor coverage:Super 35
--   Image circle:   31.1mm
--   Close focus:    1.5m (approx. 4 ft 11 in)
--   Front diameter: 136mm
--   Weight:         5.4 kg (body, no accessories)
--   Length:         373mm (at 24mm focal length)
--   Iris gear:      0.4 mod (standard cinema)
--   Focus gear:     0.4 mod (standard cinema)
--   /i Technology:  No (analogue lens, no embedded metadata electronics)
--   LDS metadata:   No
--
-- The product row (slug = 'angenieux-optimo-24-290') was seeded in
-- 20260408000006_seed_demo_80_20.sql with placeholder spec values.
-- This migration upserts all specs with accurate data using
-- ON CONFLICT ... DO UPDATE so it overwrites the placeholders.
--
-- Safe to re-run: product_spec uses DO UPDATE; compatibility values use
-- DO NOTHING (they were already seeded correctly in the demo migration).
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
  sd_zoom_ratio    UUID;
  sd_close_focus   UUID;
  sd_front_diam    UUID;
  sd_weight        UUID;
  sd_length        UUID;
  sd_i_tech        UUID;
  sd_lds           UUID;

BEGIN

  -- ── Resolve product ID ───────────────────────────────────────────────────────
  SELECT id INTO p_id FROM product WHERE slug = 'angenieux-optimo-24-290';
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'Product angenieux-optimo-24-290 not found — run demo seed first.';
  END IF;

  -- ── Resolve compatibility axis IDs ──────────────────────────────────────────
  SELECT id INTO ax_mount  FROM compatibility_axis WHERE slug = 'lens_mount';
  SELECT id INTO ax_sensor FROM compatibility_axis WHERE slug = 'sensor_format';
  SELECT id INTO ax_pitch  FROM compatibility_axis WHERE slug = 'gear_pitch';

  -- ── Resolve spec definition IDs ─────────────────────────────────────────────
  SELECT id INTO sd_cl_mount     FROM spec_definition WHERE normalized_key = 'cine_lens_mount';
  SELECT id INTO sd_image_circle FROM spec_definition WHERE normalized_key = 'image_circle_mm';
  SELECT id INTO sd_focal_len    FROM spec_definition WHERE normalized_key = 'cine_focal_length_mm';
  SELECT id INTO sd_t_stop       FROM spec_definition WHERE normalized_key = 'cine_t_stop';
  SELECT id INTO sd_sensor_cov   FROM spec_definition WHERE normalized_key = 'cine_sensor_coverage';
  SELECT id INTO sd_gear_pitch   FROM spec_definition WHERE normalized_key = 'cine_gear_pitch';
  SELECT id INTO sd_focus_gear   FROM spec_definition WHERE normalized_key = 'cine_focus_gear_pitch';
  SELECT id INTO sd_zoom_ratio   FROM spec_definition WHERE normalized_key = 'cine_zoom_ratio';
  SELECT id INTO sd_close_focus  FROM spec_definition WHERE normalized_key = 'cine_close_focus_m';
  SELECT id INTO sd_front_diam   FROM spec_definition WHERE normalized_key = 'cine_front_diameter_mm';
  SELECT id INTO sd_weight       FROM spec_definition WHERE normalized_key = 'cine_lens_weight_kg';
  SELECT id INTO sd_length       FROM spec_definition WHERE normalized_key = 'cine_lens_length_mm';
  SELECT id INTO sd_i_tech       FROM spec_definition WHERE normalized_key = 'has_i_technology';
  SELECT id INTO sd_lds          FROM spec_definition WHERE normalized_key = 'has_lds_metadata';

  -- ─────────────────────────────────────────────────────────────────────────────
  -- PRODUCT SPECS
  -- Values from the Angenieux Optimo 24-290mm T2.8 official spec sheet.
  -- Uses DO UPDATE to overwrite the placeholder values from the demo seed.
  -- numeric_value carries the machine-readable number; spec_value is the
  -- human-readable label shown in the UI.
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, numeric_value, boolean_value) VALUES

    -- Identity
    (p_id, sd_cl_mount,     'PL',          NULL,    NULL),
    (p_id, sd_t_stop,       'T2.8',        2.8,     NULL),
    (p_id, sd_sensor_cov,   'Super 35',    NULL,    NULL),
    (p_id, sd_zoom_ratio,   '12:1',        NULL,    NULL),
    (p_id, sd_focal_len,    '24–290mm',    NULL,    NULL),

    -- Optical
    -- Image circle: 31.1mm — sufficient to cover Super 35 (31.1mm diagonal)
    (p_id, sd_image_circle, '31.1mm',      31.1,    NULL),

    -- Close focus: 1.5m from front of lens (approx. 4 ft 11 in)
    (p_id, sd_close_focus,  '1.5m',        1.5,     NULL),

    -- Front diameter: 136mm (Ø136mm barrel — standard for this lens family)
    (p_id, sd_front_diam,   '136mm',       136.0,   NULL),

    -- Iris gear: standard 0.4 mod cinema pitch
    (p_id, sd_gear_pitch,   '0.4 mod',     NULL,    NULL),

    -- Focus gear: standard 0.4 mod cinema pitch
    (p_id, sd_focus_gear,   '0.4 mod',     NULL,    NULL),

    -- Physical
    -- Weight: 5.4 kg (body only, no lens support bracket)
    (p_id, sd_weight,       '5.4 kg',      5.4,     NULL),

    -- Length: 373mm at 24mm focal length (extended to ~401mm at 290mm end)
    (p_id, sd_length,       '373mm',       373.0,   NULL),

    -- Metadata & electronics
    -- No /i Technology — this is a fully mechanical lens; no embedded chip
    (p_id, sd_i_tech,       NULL,          NULL,    false),

    -- No LDS / eXtended Data metadata output
    (p_id, sd_lds,          NULL,          NULL,    false)

  ON CONFLICT (product_id, spec_definition_id)
  DO UPDATE SET
    spec_value    = EXCLUDED.spec_value,
    numeric_value = EXCLUDED.numeric_value,
    boolean_value = EXCLUDED.boolean_value;

  -- ─────────────────────────────────────────────────────────────────────────────
  -- COMPATIBILITY VALUES
  -- The demo seed already inserted the core rows with DO NOTHING.
  -- Re-insert here with DO NOTHING to be idempotent.
  -- is_input = false → the lens PROVIDES / presents this value to the system.
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_compatibility_value (product_id, axis_id, value, is_input, notes) VALUES

    -- Lens mount — the lens PRESENTS PL to the camera body
    (p_id, ax_mount,  'PL',             false, 'PL mount — mates with any PL camera body'),

    -- Sensor format — the lens COVERS Super 35 (31.1mm image circle)
    (p_id, ax_sensor, 'S35',            false, '31.1mm image circle — covers Super 35'),

    -- Gear pitch — the lens PROVIDES 0.4 mod cinema gears on iris and focus rings
    (p_id, ax_pitch,  '0_4mod_cinema',  false, '0.4 mod cinema standard iris and focus gears')

  ON CONFLICT (product_id, axis_id, value) DO NOTHING;

END $$;
