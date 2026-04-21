-- Migration: Blackmagic URSA Mini Pro 12K — accurate product specs and compatibility values.
--
-- Source: Blackmagic Design official spec sheet (https://www.blackmagicdesign.com/products/blackmagicursaminipro)
-- Spec values reflect the URSA Mini Pro 12K as shipped; EF and PL mount variants
-- share the same sensor/recording specs — mount differences are captured in
-- product_compatibility_value (both accepted) and in the lens_mount spec_value.
--
-- This migration:
--   1. Inserts the product row (slug = 'blackmagic-ursa-mini-pro-12k')
--   2. Upserts all product_spec rows with accurate values
--   3. Inserts product_compatibility_value rows for all relevant axes
--
-- Safe to re-run: product INSERT uses ON CONFLICT DO NOTHING;
-- product_spec uses ON CONFLICT ... DO UPDATE; compatibility values use DO NOTHING.

DO $$
DECLARE
  b_id     UUID;
  cat_id   UUID;
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
  sd_sensor_type   UUID;
  sd_dynamic_range UUID;
  sd_lens_mount    UUID;
  sd_rec_formats   UUID;
  sd_rec_media     UUID;
  sd_power_in      UUID;
  sd_base_iso      UUID;
  sd_max_fps       UUID;
  sd_weight        UUID;
  sd_max_res       UUID;
  sd_sdi_out       UUID;
  sd_hdmi          UUID;
  sd_internal_nd   UUID;
  sd_log_format    UUID;
  sd_color_space   UUID;
  sd_timecode      UUID;
  sd_audio_input   UUID;
  sd_audio_fmt     UUID;
  sd_audio_ch      UUID;
  sd_dimensions    UUID;

BEGIN

  -- ── Resolve brand ID ────────────────────────────────────────────────────────
  SELECT id INTO b_id FROM brand WHERE slug = 'blackmagic' OR name = 'Blackmagic Design' LIMIT 1;
  IF b_id IS NULL THEN
    RAISE EXCEPTION 'Brand Blackmagic Design not found in brand table.';
  END IF;

  -- ── Resolve category ID ─────────────────────────────────────────────────────
  SELECT id INTO cat_id FROM product_category WHERE slug = 'cinema-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Category cinema-cameras not found — run cinema category seed first (20260211000000).';
  END IF;

  -- ── Upsert product row ──────────────────────────────────────────────────────
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, is_active)
  VALUES (
    b_id,
    cat_id,
    'URSA Mini Pro 12K',
    'Blackmagic URSA Mini Pro 12K',
    'blackmagic-ursa-mini-pro-12k',
    'https://www.blackmagicdesign.com/products/blackmagicursaminipro',
    true
  )
  ON CONFLICT (slug) DO NOTHING;

  SELECT id INTO p_id FROM product WHERE slug = 'blackmagic-ursa-mini-pro-12k';
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'Product insert failed for blackmagic-ursa-mini-pro-12k.';
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
  SELECT id INTO sd_sensor_type   FROM spec_definition WHERE normalized_key = 'cinema_sensor_type';
  SELECT id INTO sd_dynamic_range FROM spec_definition WHERE normalized_key = 'cinema_dynamic_range';
  SELECT id INTO sd_lens_mount    FROM spec_definition WHERE normalized_key = 'cinema_lens_mount';
  SELECT id INTO sd_rec_formats   FROM spec_definition WHERE normalized_key = 'cinema_recording_formats';
  SELECT id INTO sd_rec_media     FROM spec_definition WHERE normalized_key = 'cinema_recording_media';
  SELECT id INTO sd_power_in      FROM spec_definition WHERE normalized_key = 'cinema_power_input';
  SELECT id INTO sd_base_iso      FROM spec_definition WHERE normalized_key = 'cinema_base_iso';
  SELECT id INTO sd_max_fps       FROM spec_definition WHERE normalized_key = 'cinema_max_fps';
  SELECT id INTO sd_weight        FROM spec_definition WHERE normalized_key = 'cinema_weight';
  SELECT id INTO sd_max_res       FROM spec_definition WHERE normalized_key = 'cinema_max_resolution';
  SELECT id INTO sd_sdi_out       FROM spec_definition WHERE normalized_key = 'cinema_sdi_outputs';
  SELECT id INTO sd_hdmi          FROM spec_definition WHERE normalized_key = 'cinema_hdmi';
  SELECT id INTO sd_internal_nd   FROM spec_definition WHERE normalized_key = 'cinema_internal_nd';
  SELECT id INTO sd_log_format    FROM spec_definition WHERE normalized_key = 'cinema_log_format';
  SELECT id INTO sd_color_space   FROM spec_definition WHERE normalized_key = 'cinema_color_space';
  SELECT id INTO sd_timecode      FROM spec_definition WHERE normalized_key = 'cinema_timecode_io';
  SELECT id INTO sd_audio_input   FROM spec_definition WHERE normalized_key = 'cinema_audio_input';
  SELECT id INTO sd_audio_fmt     FROM spec_definition WHERE normalized_key = 'cinema_audio_format';
  SELECT id INTO sd_audio_ch      FROM spec_definition WHERE normalized_key = 'cinema_audio_channels';
  SELECT id INTO sd_dimensions    FROM spec_definition WHERE normalized_key = 'cinema_dimensions';

  -- ─────────────────────────────────────────────────────────────────────────────
  -- PRODUCT SPECS
  -- Verbatim / closely paraphrased from the Blackmagic URSA Mini Pro 12K
  -- official spec sheet. Values reflect the base EF/PL interchangeable-mount
  -- body. Where the spec differs by mount or media config, the more common
  -- production value is listed with a parenthetical qualifier.
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value) VALUES

    -- Image Sensor
    -- Super 35+ sensor; Blackmagic calls it "Super 35" in their docs.
    -- Physical dimensions: 27.03 × 14.25 mm (diagonal ≈ 30.6 mm).
    (p_id, sd_sensor_type,   'Blackmagic Design custom 12K CMOS'),
    (p_id, sd_sensor_size,   'Super 35+ (27.03mm × 14.25mm)'),
    (p_id, sd_dynamic_range, '13 stops'),
    (p_id, sd_base_iso,      '400 (ISO 200–3200 range; no dual native ISO)'),
    -- Maximum fps at full 12K; higher fps available at reduced resolution.
    -- 12K 17:9 up to 60fps; 8K up to 75fps; lower resolutions higher still.
    (p_id, sd_max_fps,       '60'),   -- 12K (full resolution)

    -- Recording
    (p_id, sd_max_res,       '12288 × 6480 (12K)'),
    -- BRAW = Blackmagic RAW; ProRes = Apple ProRes variants
    (p_id, sd_rec_formats,
      'Blackmagic RAW (BRAW 3:1, 5:1, 8:1, 12:1 — constant bitrate; 3:1, 5:1, 8:1, 12:1 — constant quality), '
      'Apple ProRes (4444 XQ, 4444, 422 HQ, 422, 422 LT, 422 Proxy)'),
    -- CFast 2.0 is the primary high-speed media slot; USB-C SSD supported simultaneously.
    -- The URSA Mini Pro 12K has 1× CFast 2.0 + 1× SD card + 1× USB-C expansion.
    (p_id, sd_rec_media,
      'CFast 2.0 card (slot 1), SD/UHS-II card (slot 2), USB-C SSD (expansion port)'),
    -- No internal ND; optional ND filter stage available via URSA Mini Shoulder Kit or third-party.
    (p_id, sd_internal_nd,   'None (no built-in internal ND filter)'),

    -- Optics & Mount
    -- The URSA Mini Pro 12K ships with a PL mount installed and includes an EF mount adapter.
    -- Both PL and EF are first-class supported mounts — listed here as primary.
    (p_id, sd_lens_mount,    'PL (included), EF (included adapter), B4 (optional adapter), F (optional adapter)'),

    -- Color Science
    (p_id, sd_log_format,    'Blackmagic Design Film (Generation 5)'),
    (p_id, sd_color_space,   'Blackmagic Wide Gamut'),

    -- Connectivity
    -- 1× 12G-SDI output (BNC) for monitoring; no second SDI output.
    (p_id, sd_sdi_out,       '1× 12G-SDI output (BNC)'),
    -- Mini HDMI Type A output for monitoring.
    (p_id, sd_hdmi,          '1× Mini HDMI Type A output'),
    -- SMPTE LTC timecode via 3.5mm jack (I/O, bidirectional).
    (p_id, sd_timecode,      'SMPTE LTC in/out (3.5mm jack)'),

    -- Audio
    -- 2× mini XLR inputs (analog), phantom power selectable per channel.
    (p_id, sd_audio_input,   '2× mini XLR (3-pin) — mic/line switchable, 48V phantom power'),
    (p_id, sd_audio_fmt,     'Uncompressed 24-bit 48kHz PCM'),
    (p_id, sd_audio_ch,      '4'),  -- 4 channels (2 analog + 2 embedded from SDI/HDMI input)

    -- Physical
    -- Body weight without lens, battery, or media: ~2650 g (manufacturer spec ~2.6 kg).
    (p_id, sd_weight,        '2650'),  -- grams, body only
    -- H × W × D (approximate from official drawings): 148.0 × 212.4 × 175.8 mm
    (p_id, sd_dimensions,    '148.0 × 212.4 × 175.8 mm (H × W × D, body only)'),
    -- Power: LP-E6 battery (body native, 2× slot), OR external 12V–20V DC via Anton Bauer
    -- Gold Mount plate (sold separately). The URSA Mini Pro 12K ships with an LP-E6
    -- battery compartment; Gold Mount is the industry standard accessory plate.
    (p_id, sd_power_in,
      '12–20V DC via 4-pin XLR, or 2× Canon LP-E6 internal batteries, or Anton Bauer Gold Mount plate (optional)')

  ON CONFLICT (product_id, spec_definition_id)
  DO UPDATE SET spec_value = EXCLUDED.spec_value;

  -- ─────────────────────────────────────────────────────────────────────────────
  -- COMPATIBILITY VALUES
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_compatibility_value (product_id, axis_id, value, is_input, notes) VALUES

    -- ── Lens mount — camera ACCEPTS PL and EF lenses ───────────────────────────
    -- PL is installed at the factory and is the primary cinema mount.
    (p_id, ax_mount,  'PL',           true,  'Native PL mount (installed at factory; swappable)'),
    -- EF adapter is included in the box; no optical elements — native electronic control.
    (p_id, ax_mount,  'EF',           true,  'Interchangeable EF mount adapter (included in box)'),

    -- ── Sensor format — camera PROVIDES Super 35 image area ────────────────────
    -- 27.03 × 14.25 mm is within the Super 35 envelope; maps to S35.
    (p_id, ax_sensor, 'S35',          false, 'Super 35+ sensor (27.03 × 14.25mm) — covers S35 lens image circles'),

    -- ── Rod system — camera ACCEPTS 15mm LWS via third-party baseplate ─────────
    (p_id, ax_rod,    '15mm_lws',     true,  'Via URSA Mini Shoulder Kit or any 15mm LWS baseplate'),

    -- ── Power — camera ACCEPTS LP-E6 (internal) AND Gold Mount (external plate) ─
    -- LP-E6 is the built-in battery solution (2× internal).
    (p_id, ax_power,  'lp_e6',        true,  '2× Canon LP-E6 internal battery slots (native)'),
    -- Gold Mount plate attaches to the rear of the camera body via the standard
    -- Blackmagic camera power adapter plates (sold separately by Anton Bauer et al.).
    (p_id, ax_power,  'gold_mount',   true,  'Anton Bauer Gold Mount plate (optional, rear-mount accessory)'),
    -- V-Mount plate is also supported via compatible adapter plates.
    (p_id, ax_power,  'v_mount',      true,  'V-Mount plate (optional, via compatible adapter plate)'),
    -- 12V–20V DC via 4-pin XLR (on-body connector) accepts Anton Bauer D-Tap / 12V brick.
    (p_id, ax_power,  'd_tap',        true,  '12–20V DC via 4-pin XLR (D-Tap compatible power adapters)'),

    -- ── Recording media — camera ACCEPTS CFast 2.0, SD, and USB-C SSD ─────────
    (p_id, ax_media,  'cfast_2',      true,  'CFast 2.0 (slot 1) — primary high-speed recording media'),
    (p_id, ax_media,  'usb_c_ssd',    true,  'USB-C SSD (expansion port) — simultaneous record / backup'),

    -- ── Signal output — camera PROVIDES 12G-SDI and HDMI ──────────────────────
    (p_id, ax_signal, '12g_sdi',      false, '1× 12G-SDI BNC monitor output'),
    (p_id, ax_signal, 'hdmi_2_0',     false, '1× Mini HDMI Type A output (up to 4K 60p monitoring)')

  ON CONFLICT (product_id, axis_id, value) DO NOTHING;

END $$;
