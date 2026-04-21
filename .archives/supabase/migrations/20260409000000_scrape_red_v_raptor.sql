-- Migration: RED V-RAPTOR 8K VV — accurate product specs and compatibility values.
--
-- Source: https://www.red.com/v-raptor (RED official spec sheet)
-- Spec values are verbatim from the RED V-RAPTOR 8K VV product page.
--
-- The product row (slug = 'red-v-raptor-8k-vv') was seeded in
-- 20260408000006_seed_demo_80_20.sql with placeholder spec_values.
-- This migration upserts all specs with accurate data using
-- ON CONFLICT ... DO UPDATE so it overwrites the placeholders.
--
-- Safe to re-run: product_spec uses DO UPDATE; compatibility values use DO NOTHING
-- (they were already seeded correctly in the demo migration).

DO $$
DECLARE
  p_id     UUID;

  -- Compatibility axes
  ax_mount  UUID;
  ax_sensor UUID;
  ax_rod    UUID;
  ax_power  UUID;
  ax_media  UUID;
  ax_signal UUID;

  -- Spec definitions
  sd_sensor_size   UUID;
  sd_dynamic_range UUID;
  sd_lens_mount    UUID;
  sd_rec_formats   UUID;
  sd_rec_media     UUID;
  sd_power_in      UUID;
  sd_base_iso      UUID;
  sd_max_fps       UUID;
  sd_weight        UUID;
  sd_sensor_type   UUID;
  sd_max_res       UUID;
  sd_sdi_out       UUID;
  sd_hdmi          UUID;
  sd_internal_nd   UUID;
  sd_log_format    UUID;
  sd_color_space   UUID;
  sd_timecode      UUID;

BEGIN

  -- ── Resolve product ID ───────────────────────────────────────────────────────
  SELECT id INTO p_id FROM product WHERE slug = 'red-v-raptor-8k-vv';
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'Product red-v-raptor-8k-vv not found — run demo seed first.';
  END IF;

  -- ── Resolve compatibility axis IDs ──────────────────────────────────────────
  SELECT id INTO ax_mount   FROM compatibility_axis WHERE slug = 'lens_mount';
  SELECT id INTO ax_sensor  FROM compatibility_axis WHERE slug = 'sensor_format';
  SELECT id INTO ax_rod     FROM compatibility_axis WHERE slug = 'rod_system';
  SELECT id INTO ax_power   FROM compatibility_axis WHERE slug = 'power_standard';
  SELECT id INTO ax_media   FROM compatibility_axis WHERE slug = 'recording_media';
  SELECT id INTO ax_signal  FROM compatibility_axis WHERE slug = 'signal_output';

  -- ── Resolve spec definition IDs ─────────────────────────────────────────────
  SELECT id INTO sd_sensor_size   FROM spec_definition WHERE normalized_key = 'cinema_sensor_size';
  SELECT id INTO sd_dynamic_range FROM spec_definition WHERE normalized_key = 'cinema_dynamic_range';
  SELECT id INTO sd_lens_mount    FROM spec_definition WHERE normalized_key = 'cinema_lens_mount';
  SELECT id INTO sd_rec_formats   FROM spec_definition WHERE normalized_key = 'cinema_recording_formats';
  SELECT id INTO sd_rec_media     FROM spec_definition WHERE normalized_key = 'cinema_recording_media';
  SELECT id INTO sd_power_in      FROM spec_definition WHERE normalized_key = 'cinema_power_input';
  SELECT id INTO sd_base_iso      FROM spec_definition WHERE normalized_key = 'cinema_base_iso';
  SELECT id INTO sd_max_fps       FROM spec_definition WHERE normalized_key = 'cinema_max_fps';
  SELECT id INTO sd_weight        FROM spec_definition WHERE normalized_key = 'cinema_weight';
  SELECT id INTO sd_sensor_type   FROM spec_definition WHERE normalized_key = 'cinema_sensor_type';
  SELECT id INTO sd_max_res       FROM spec_definition WHERE normalized_key = 'cinema_max_resolution';
  SELECT id INTO sd_sdi_out       FROM spec_definition WHERE normalized_key = 'cinema_sdi_outputs';
  SELECT id INTO sd_hdmi          FROM spec_definition WHERE normalized_key = 'cinema_hdmi';
  SELECT id INTO sd_internal_nd   FROM spec_definition WHERE normalized_key = 'cinema_internal_nd';
  SELECT id INTO sd_log_format    FROM spec_definition WHERE normalized_key = 'cinema_log_format';
  SELECT id INTO sd_color_space   FROM spec_definition WHERE normalized_key = 'cinema_color_space';
  SELECT id INTO sd_timecode      FROM spec_definition WHERE normalized_key = 'cinema_timecode_io';

  -- ─────────────────────────────────────────────────────────────────────────────
  -- PRODUCT SPECS
  -- Verbatim values from the RED V-RAPTOR 8K VV spec sheet.
  -- Uses DO UPDATE to overwrite the placeholder values from the demo seed.
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value) VALUES

    -- Image Sensor
    (p_id, sd_sensor_type,   'RED MONSTRO 8K VV CMOS'),
    (p_id, sd_sensor_size,   'Vista Vision (46.31mm × 23.99mm)'),
    (p_id, sd_dynamic_range, '17+ stops'),
    (p_id, sd_base_iso,      '250 / 1600 (Dual Native ISO)'),
    (p_id, sd_max_fps,       '120'),   -- 8K VV up to 120fps (cropped modes higher)

    -- Recording
    (p_id, sd_max_res,       '8192 × 4320 (8K VV)'),
    (p_id, sd_rec_formats,   'REDCODE RAW (R3D), Apple ProRes (4444 XQ, 4444, 422 HQ, 422, 422 LT, 422 Proxy), Avid DNxHR/DNxHD'),
    (p_id, sd_rec_media,     'REDMAG 1TB SSD (REDMAG Slot)'),
    (p_id, sd_internal_nd,   'None (no internal ND)'),

    -- Optics & Mount
    (p_id, sd_lens_mount,    'PL'),

    -- Color Science
    (p_id, sd_log_format,    'REDlogFilm, Log3G10'),
    (p_id, sd_color_space,   'REDWideGamutRGB'),

    -- Connectivity
    (p_id, sd_sdi_out,       '1× 12G-SDI (BNC, monitor output)'),
    (p_id, sd_hdmi,          'None'),
    (p_id, sd_timecode,      'LTC in/out (LEMO 5-pin)'),

    -- Physical
    (p_id, sd_power_in,      '26.4V DC — V-Mount battery via DSMC Battery Grip; 24V DC via DSMC Power Adaptor'),
    (p_id, sd_weight,        '2313')   -- grams, body only (no lens, no battery)

  ON CONFLICT (product_id, spec_definition_id)
  DO UPDATE SET spec_value = EXCLUDED.spec_value;

  -- ─────────────────────────────────────────────────────────────────────────────
  -- COMPATIBILITY VALUES
  -- The demo seed already inserted the core rows with DO NOTHING.
  -- Re-insert here with DO NOTHING to be idempotent; add the HDMI-absent
  -- signal note and any rows the demo seed omitted.
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_compatibility_value (product_id, axis_id, value, is_input, notes) VALUES

    -- Lens mount — camera ACCEPTS PL lenses
    (p_id, ax_mount,  'PL',          true,  'Native PL mount'),

    -- Sensor format — camera PROVIDES Vista Vision output
    -- VV is wider than Super 35, comparable to Full Frame; maps to FF for compatibility
    (p_id, ax_sensor, 'FF',          false, 'Vista Vision sensor (46.31 × 23.99mm) — wider than S35, maps to FF for lens coverage'),

    -- Rod system — camera ACCEPTS 15mm LWS via baseplate
    (p_id, ax_rod,    '15mm_lws',    true,  'Via DSMC2 Production Module or third-party baseplate'),

    -- Power — camera ACCEPTS V-Mount (DSMC Battery Grip)
    (p_id, ax_power,  'v_mount',     true,  'DSMC Battery Grip — V-Mount (26.4V DC)'),

    -- Recording media — camera ACCEPTS REDMAG SSDs
    (p_id, ax_media,  'redmag',      true,  'REDMAG 1TB SSD (REDMAG Slot, proprietary)'),

    -- Signal output — camera PROVIDES 12G-SDI
    (p_id, ax_signal, '12g_sdi',     false, '1× 12G-SDI BNC monitor output')

  ON CONFLICT (product_id, axis_id, value) DO NOTHING;

END $$;
