-- ─────────────────────────────────────────────────────────────────────────────
-- Section 8: 80/20 demo seed set
-- 3 camera bodies, 2 lens sets, 1 zoom, 6 accessories = 12 items
-- Touches all 7 compatibility axes + seeds product_relationship + kit_template
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  -- Brands
  b_arri     UUID; b_sony     UUID; b_red      UUID;
  b_cooke    UUID; b_zeiss    UUID; b_ang      UUID;
  b_smallhd  UUID; b_teradek  UUID; b_anton    UUID;

  -- Categories
  c_cinema_cam   UUID; c_pl_primes  UUID; c_lpl_primes UUID;
  c_zoom         UUID; c_on_board   UUID; c_wireless   UUID;
  c_fiz          UUID; c_matte      UUID; c_gold_batt  UUID;
  c_cine_adapt   UUID;

  -- Products
  p_alexa35   UUID; p_venice2   UUID; p_raptor   UUID;
  p_cooke_s4  UUID; p_zeiss_sp  UUID; p_ang_zoom UUID;
  p_smallhd7  UUID; p_bolt4k    UUID; p_wcu4     UUID;
  p_mb20      UUID; p_cine90    UUID; p_pllpl    UUID;

  -- Axes
  ax_mount    UUID; ax_sensor   UUID; ax_rod     UUID;
  ax_power    UUID; ax_media    UUID; ax_signal  UUID;
  ax_pitch    UUID;

  -- Spec definitions (cameras)
  sd_sensor_size  UUID; sd_dynamic_range UUID; sd_lens_mount UUID;
  sd_rec_formats  UUID; sd_rec_media     UUID; sd_power_in   UUID;
  sd_base_iso     UUID;

  -- Spec definitions (lenses)
  sd_cl_mount     UUID; sd_image_circle  UUID; sd_focal_len  UUID;
  sd_t_stop       UUID; sd_sensor_cov    UUID; sd_gear_pitch UUID;
  sd_i_tech       UUID; sd_lens_set_id   UUID; sd_zoom_ratio UUID;

  -- Kit template
  kt_alexa35 UUID;

BEGIN

  -- ── Resolve brand IDs ───────────────────────────────────────────────────────
  SELECT id INTO b_arri    FROM brand WHERE slug = 'arri';
  SELECT id INTO b_sony    FROM brand WHERE slug = 'sony';
  SELECT id INTO b_red     FROM brand WHERE slug = 'red';
  SELECT id INTO b_cooke   FROM brand WHERE slug = 'cooke';
  SELECT id INTO b_zeiss   FROM brand WHERE slug = 'zeiss';
  SELECT id INTO b_ang     FROM brand WHERE slug = 'angenieux';
  SELECT id INTO b_smallhd FROM brand WHERE slug = 'smallhd';
  SELECT id INTO b_teradek FROM brand WHERE slug = 'teradek';
  SELECT id INTO b_anton   FROM brand WHERE slug = 'anton-bauer';

  -- ── Resolve category IDs ────────────────────────────────────────────────────
  SELECT id INTO c_cinema_cam  FROM product_category WHERE slug = 'cinema-cameras';
  SELECT id INTO c_pl_primes   FROM product_category WHERE slug = 'cinema-prime-sets-pl';
  SELECT id INTO c_lpl_primes  FROM product_category WHERE slug = 'cinema-prime-sets-lpl';
  SELECT id INTO c_zoom        FROM product_category WHERE slug = 'cinema-zoom-lenses';
  SELECT id INTO c_on_board    FROM product_category WHERE slug = 'on-board-monitors';
  SELECT id INTO c_wireless    FROM product_category WHERE slug = 'wireless-video';
  SELECT id INTO c_fiz         FROM product_category WHERE slug = 'follow-focus-fiz';
  SELECT id INTO c_matte       FROM product_category WHERE slug = 'matte-boxes';
  SELECT id INTO c_gold_batt   FROM product_category WHERE slug = 'batteries-gold-mount';
  SELECT id INTO c_cine_adapt  FROM product_category WHERE slug = 'cinema-lens-adapters';

  -- ── Resolve compatibility axis IDs ──────────────────────────────────────────
  SELECT id INTO ax_mount   FROM compatibility_axis WHERE slug = 'lens_mount';
  SELECT id INTO ax_sensor  FROM compatibility_axis WHERE slug = 'sensor_format';
  SELECT id INTO ax_rod     FROM compatibility_axis WHERE slug = 'rod_system';
  SELECT id INTO ax_power   FROM compatibility_axis WHERE slug = 'power_standard';
  SELECT id INTO ax_media   FROM compatibility_axis WHERE slug = 'recording_media';
  SELECT id INTO ax_signal  FROM compatibility_axis WHERE slug = 'signal_output';
  SELECT id INTO ax_pitch   FROM compatibility_axis WHERE slug = 'gear_pitch';

  -- ── Resolve spec definition IDs — cameras ───────────────────────────────────
  SELECT id INTO sd_sensor_size   FROM spec_definition WHERE normalized_key = 'cinema_sensor_size';
  SELECT id INTO sd_dynamic_range FROM spec_definition WHERE normalized_key = 'cinema_dynamic_range';
  SELECT id INTO sd_lens_mount    FROM spec_definition WHERE normalized_key = 'cinema_lens_mount';
  SELECT id INTO sd_rec_formats   FROM spec_definition WHERE normalized_key = 'cinema_recording_formats';
  SELECT id INTO sd_rec_media     FROM spec_definition WHERE normalized_key = 'cinema_recording_media';
  SELECT id INTO sd_power_in      FROM spec_definition WHERE normalized_key = 'cinema_power_input';
  SELECT id INTO sd_base_iso      FROM spec_definition WHERE normalized_key = 'cinema_base_iso';

  -- ── Resolve spec definition IDs — lenses ────────────────────────────────────
  SELECT id INTO sd_cl_mount    FROM spec_definition WHERE normalized_key = 'cine_lens_mount';
  SELECT id INTO sd_image_circle FROM spec_definition WHERE normalized_key = 'image_circle_mm';
  SELECT id INTO sd_focal_len   FROM spec_definition WHERE normalized_key = 'cine_focal_length_mm';
  SELECT id INTO sd_t_stop      FROM spec_definition WHERE normalized_key = 'cine_t_stop';
  SELECT id INTO sd_sensor_cov  FROM spec_definition WHERE normalized_key = 'cine_sensor_coverage';
  SELECT id INTO sd_gear_pitch  FROM spec_definition WHERE normalized_key = 'cine_gear_pitch';
  SELECT id INTO sd_i_tech      FROM spec_definition WHERE normalized_key = 'has_i_technology';
  SELECT id INTO sd_lens_set_id FROM spec_definition WHERE normalized_key = 'lens_set_id';
  SELECT id INTO sd_zoom_ratio  FROM spec_definition WHERE normalized_key = 'cine_zoom_ratio';

  -- ─────────────────────────────────────────────────────────────────────────────
  -- 1. PRODUCTS
  -- ─────────────────────────────────────────────────────────────────────────────

  -- Camera bodies
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, is_active) VALUES
    (b_arri, c_cinema_cam, 'ALEXA 35',      'ARRI ALEXA 35',          'arri-alexa-35',       'https://www.arri.com/en/camera-systems/cameras/alexa-35',           true),
    (b_sony, c_cinema_cam, 'VENICE 2',      'Sony VENICE 2',          'sony-venice-2',       'https://www.sony.com/en/articles/venice-2',                         true),
    (b_red,  c_cinema_cam, 'V-RAPTOR 8K VV','RED V-RAPTOR 8K VV',     'red-v-raptor-8k-vv',  'https://www.red.com/v-raptor',                                      true)
  ON CONFLICT (slug) DO NOTHING;

  -- Lens sets
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, is_active) VALUES
    (b_cooke, c_pl_primes,  'S4/i Set',           'Cooke S4/i Prime Set (PL)',         'cooke-s4i-set',           'https://www.cookeoptics.com/lenses/s4i/',              true),
    (b_zeiss, c_lpl_primes, 'Supreme Prime Set',  'Zeiss Supreme Prime Set (PL/LPL)',  'zeiss-supreme-prime-set', 'https://www.zeiss.com/consumer-products/us/cinematography/supreme-prime-lenses.html', true),
    (b_ang,   c_zoom,       'Optimo 24-290mm',    'Angenieux Optimo 24-290mm T2.8',    'angenieux-optimo-24-290', 'https://www.angenieux.com/optimo-24-290',              true)
  ON CONFLICT (slug) DO NOTHING;

  -- Accessories
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, is_active) VALUES
    (b_smallhd,  c_on_board,   'Cine 7 (Bolt 6 RX)',  'SmallHD Cine 7 with Bolt 6 RX',        'smallhd-cine-7',         'https://smallhd.com/products/cine-7-bolt-6-rx',            true),
    (b_teradek,  c_wireless,   'Bolt 4K LT 750',       'Teradek Bolt 4K LT 750 TX/RX',         'teradek-bolt-4k-lt-750', 'https://teradek.com/products/bolt-4k-lt-750',               true),
    (b_arri,     c_fiz,        'WCU-4',                'ARRI WCU-4 Wireless Compact Unit',      'arri-wcu-4',             'https://www.arri.com/en/accessories/camera-control/wcu-4',  true),
    (b_arri,     c_matte,      'MB-20 II',             'ARRI MB-20 II Matte Box',               'arri-mb-20-ii',          'https://www.arri.com/en/accessories/matte-boxes',           true),
    (b_anton,    c_gold_batt,  'CINE 90',              'Anton Bauer CINE 90 Gold Mount Battery','anton-bauer-cine-90',    'https://www.antonbauer.com',                                true),
    (b_arri,     c_cine_adapt, 'PL to LPL Adapter',   'ARRI PL to LPL Lens Adapter',           'arri-pl-lpl-adapter',    'https://www.arri.com/en/camera-systems/lenses/arri-pl-to-lpl-adapter', true)
  ON CONFLICT (slug) DO NOTHING;

  -- ── Capture product IDs ──────────────────────────────────────────────────────
  SELECT id INTO p_alexa35  FROM product WHERE slug = 'arri-alexa-35';
  SELECT id INTO p_venice2  FROM product WHERE slug = 'sony-venice-2';
  SELECT id INTO p_raptor   FROM product WHERE slug = 'red-v-raptor-8k-vv';
  SELECT id INTO p_cooke_s4 FROM product WHERE slug = 'cooke-s4i-set';
  SELECT id INTO p_zeiss_sp FROM product WHERE slug = 'zeiss-supreme-prime-set';
  SELECT id INTO p_ang_zoom FROM product WHERE slug = 'angenieux-optimo-24-290';
  SELECT id INTO p_smallhd7 FROM product WHERE slug = 'smallhd-cine-7';
  SELECT id INTO p_bolt4k   FROM product WHERE slug = 'teradek-bolt-4k-lt-750';
  SELECT id INTO p_wcu4     FROM product WHERE slug = 'arri-wcu-4';
  SELECT id INTO p_mb20     FROM product WHERE slug = 'arri-mb-20-ii';
  SELECT id INTO p_cine90   FROM product WHERE slug = 'anton-bauer-cine-90';
  SELECT id INTO p_pllpl    FROM product WHERE slug = 'arri-pl-lpl-adapter';

  -- ─────────────────────────────────────────────────────────────────────────────
  -- 2. PRODUCT SPECS (key specs for camera bodies and lens sets)
  -- ─────────────────────────────────────────────────────────────────────────────

  -- ARRI ALEXA 35
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value) VALUES
    (p_alexa35, sd_sensor_size,   'Super 35 / 4.6K (4608 × 3164)'),
    (p_alexa35, sd_dynamic_range, '17 stops'),
    (p_alexa35, sd_lens_mount,    'LPL (PL via included adapter)'),
    (p_alexa35, sd_rec_formats,   'ARRIRAW, Apple ProRes (4444 XQ, 4444, 422 HQ, 422, 422 LT, 422 Proxy)'),
    (p_alexa35, sd_rec_media,     'CFexpress Type B (Mag System)'),
    (p_alexa35, sd_power_in,      'Gold Mount (24V DC, Anton Bauer)'),
    (p_alexa35, sd_base_iso,      '800 / 3200 (Dual Native)')
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- Sony VENICE 2
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value) VALUES
    (p_venice2, sd_sensor_size,   'Full Frame / 8.6K (8640 × 5760)'),
    (p_venice2, sd_dynamic_range, '16 stops'),
    (p_venice2, sd_lens_mount,    'Native E-Mount lever lock (PL via CBK-3610XS)'),
    (p_venice2, sd_rec_formats,   'X-OCN ST/LT/XT, Apple ProRes 4444/422 HQ'),
    (p_venice2, sd_rec_media,     'SxS Pro+, AXS-R7 (via extension unit)'),
    (p_venice2, sd_power_in,      'BP-GL95B / V-Mount / Gold Mount (via adapter)'),
    (p_venice2, sd_base_iso,      '800 / 3200 (Dual Native)')
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- RED V-RAPTOR 8K VV
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value) VALUES
    (p_raptor, sd_sensor_size,   'Vista Vision / 8K (8192 × 4320)'),
    (p_raptor, sd_dynamic_range, '17+ stops (REDCODE RAW)'),
    (p_raptor, sd_lens_mount,    'PL'),
    (p_raptor, sd_rec_formats,   'REDCODE RAW, Apple ProRes, Avid DNxHR'),
    (p_raptor, sd_rec_media,     'REDMAG 1TB SSD'),
    (p_raptor, sd_power_in,      'V-Mount (DSMC Battery Grip)'),
    (p_raptor, sd_base_iso,      '250 / 1600 (Dual Native)')
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- Cooke S4/i Set (PL)
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_cooke_s4, sd_cl_mount,     'PL',          null),
    (p_cooke_s4, sd_image_circle, '31.5',        null),
    (p_cooke_s4, sd_t_stop,       'T2',          null),
    (p_cooke_s4, sd_sensor_cov,   'Super 35',    null),
    (p_cooke_s4, sd_gear_pitch,   '0.4 mod',     null),
    (p_cooke_s4, sd_i_tech,       null,          true),
    (p_cooke_s4, sd_lens_set_id,  'cooke-s4i',   null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- Zeiss Supreme Prime Set (PL / LPL)
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value) VALUES
    (p_zeiss_sp, sd_cl_mount,     'PL / LPL',       null),
    (p_zeiss_sp, sd_image_circle, '46.31',           null),
    (p_zeiss_sp, sd_t_stop,       'T1.5',            null),
    (p_zeiss_sp, sd_sensor_cov,   'Full Frame',      null),
    (p_zeiss_sp, sd_gear_pitch,   '0.4 mod',         null),
    (p_zeiss_sp, sd_i_tech,       null,              false),
    (p_zeiss_sp, sd_lens_set_id,  'zeiss-supreme-prime', null)
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- Angenieux Optimo 24-290mm
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value) VALUES
    (p_ang_zoom, sd_cl_mount,    'PL'),
    (p_ang_zoom, sd_t_stop,      'T2.8'),
    (p_ang_zoom, sd_sensor_cov,  'Super 35'),
    (p_ang_zoom, sd_gear_pitch,  '0.4 mod'),
    (p_ang_zoom, sd_zoom_ratio,  '12:1')
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- ─────────────────────────────────────────────────────────────────────────────
  -- 3. PRODUCT COMPATIBILITY VALUES (all 7 axes)
  --
  -- is_input = true  → product ACCEPTS / requires this value
  -- is_input = false → product PROVIDES / outputs this value
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_compatibility_value (product_id, axis_id, value, is_input, notes) VALUES

    -- ── ARRI ALEXA 35 ──────────────────────────────────────────────────────────
    (p_alexa35, ax_mount,  'LPL',           true,  'Native LPL mount'),
    (p_alexa35, ax_mount,  'PL',            true,  'PL via included LPL-to-PL adapter'),
    (p_alexa35, ax_sensor, 'S35',           false, 'Super 35 4.6K sensor'),
    (p_alexa35, ax_rod,    '15mm_lws',      true,  '15mm LWS via baseplate'),
    (p_alexa35, ax_rod,    '19mm_studio',   true,  '19mm studio via ARRI baseplate'),
    (p_alexa35, ax_power,  'gold_mount',    true,  'Anton Bauer Gold Mount (24V DC)'),
    (p_alexa35, ax_media,  'cfexpress_b',   true,  'CFexpress Type B in ALEXA 35 Mag'),
    (p_alexa35, ax_signal, '3g_sdi',        false, 'MON OUT — 3G-SDI'),
    (p_alexa35, ax_signal, '12g_sdi',       false, 'MON OUT — up to 12G-SDI'),

    -- ── Sony VENICE 2 ──────────────────────────────────────────────────────────
    (p_venice2, ax_mount,  'E-Mount',       true,  'Native E-Mount lever lock'),
    (p_venice2, ax_mount,  'PL',            true,  'PL via CBK-3610XS or LA-FZB2 adapter'),
    (p_venice2, ax_sensor, 'FF',            false, 'Full Frame 8.6K'),
    (p_venice2, ax_rod,    '15mm_lws',      true,  NULL),
    (p_venice2, ax_rod,    '19mm_studio',   true,  NULL),
    (p_venice2, ax_power,  'v_mount',       true,  'V-Mount via BP-GL95B or adapter'),
    (p_venice2, ax_power,  'gold_mount',    true,  'Gold Mount via adapter plate'),
    (p_venice2, ax_media,  'sxs',           true,  'SxS Pro+ cards (built-in)'),
    (p_venice2, ax_signal, '3g_sdi',        false, NULL),
    (p_venice2, ax_signal, '12g_sdi',       false, '4× 3G-SDI = 12G equivalent'),

    -- ── RED V-RAPTOR 8K VV ─────────────────────────────────────────────────────
    (p_raptor, ax_mount,  'PL',            true,  'PL mount (native)'),
    (p_raptor, ax_sensor, 'FF',            false, 'Vista Vision — wider than S35, close to FF'),
    (p_raptor, ax_rod,    '15mm_lws',      true,  'Via baseplate'),
    (p_raptor, ax_power,  'v_mount',       true,  'DSMC Battery Grip — V-Mount'),
    (p_raptor, ax_media,  'redmag',        true,  'REDMAG 1TB SSD (proprietary)'),
    (p_raptor, ax_signal, '12g_sdi',       false, '12G-SDI monitor output'),

    -- ── Cooke S4/i Prime Set (PL) ──────────────────────────────────────────────
    (p_cooke_s4, ax_mount,  'PL',           false, 'PL mount — provides PL'),
    (p_cooke_s4, ax_sensor, 'S35',          false, '31.5mm image circle — covers Super 35'),
    (p_cooke_s4, ax_pitch,  '0_4mod_cinema',false, 'Standard 0.4 mod cinema iris and focus gears'),

    -- ── Zeiss Supreme Prime Set (PL / LPL) ────────────────────────────────────
    (p_zeiss_sp, ax_mount,  'PL',           false, 'PL mount version'),
    (p_zeiss_sp, ax_mount,  'LPL',          false, 'LPL mount version'),
    (p_zeiss_sp, ax_sensor, 'FF',           false, '46.31mm image circle — covers Full Frame'),
    (p_zeiss_sp, ax_pitch,  '0_4mod_cinema',false, '0.4 mod cinema gears'),

    -- ── Angenieux Optimo 24-290mm ──────────────────────────────────────────────
    (p_ang_zoom, ax_mount,  'PL',           false, 'PL mount'),
    (p_ang_zoom, ax_sensor, 'S35',          false, 'Covers Super 35'),
    (p_ang_zoom, ax_pitch,  '0_4mod_cinema',false, '0.4 mod cinema gears'),

    -- ── SmallHD Cine 7 ─────────────────────────────────────────────────────────
    (p_smallhd7, ax_power,  'gold_mount',   true,  'Gold Mount plate on back'),
    (p_smallhd7, ax_power,  'v_mount',      true,  'V-Mount plate (with adapter)'),
    (p_smallhd7, ax_signal, '3g_sdi',       true,  '3G-SDI input'),
    (p_smallhd7, ax_signal, 'hdmi_2_0',     true,  'HDMI input'),

    -- ── Teradek Bolt 4K LT 750 ─────────────────────────────────────────────────
    (p_bolt4k, ax_power,  'gold_mount',    true,  'Gold Mount on TX and RX'),
    (p_bolt4k, ax_power,  'v_mount',       true,  'V-Mount with adapter'),
    (p_bolt4k, ax_power,  'd_tap',         true,  'D-Tap cable power'),
    (p_bolt4k, ax_signal, '3g_sdi',        true,  'SDI input on TX / output on RX'),
    (p_bolt4k, ax_signal, 'hdmi_2_0',      true,  'HDMI input on TX / output on RX'),

    -- ── ARRI WCU-4 ─────────────────────────────────────────────────────────────
    (p_wcu4, ax_pitch, '0_4mod_cinema',   true,  'Drives 0.4 mod cinema lens gears'),
    (p_wcu4, ax_rod,   '15mm_lws',        true,  '15mm LWS rod mount for motor'),
    (p_wcu4, ax_rod,   '19mm_studio',     true,  '19mm studio rod mount for motor'),

    -- ── ARRI MB-20 II ──────────────────────────────────────────────────────────
    (p_mb20, ax_rod, '15mm_lws',          true,  '15mm LWS rod mount'),
    (p_mb20, ax_rod, '19mm_studio',       true,  '19mm studio rod mount'),

    -- ── Anton Bauer CINE 90 ────────────────────────────────────────────────────
    (p_cine90, ax_power, 'gold_mount',    false, 'Provides Gold Mount power'),

    -- ── ARRI PL to LPL Adapter ────────────────────────────────────────────────
    -- Camera side: presents LPL to the camera body (the camera accepts LPL)
    -- Lens side: accepts PL lenses (the lens provides PL)
    (p_pllpl, ax_mount, 'LPL',            false, 'Camera-side — presents LPL to LPL camera'),
    (p_pllpl, ax_mount, 'PL',             true,  'Lens-side — accepts PL lenses')

  ON CONFLICT (product_id, axis_id, value) DO NOTHING;

  -- ─────────────────────────────────────────────────────────────────────────────
  -- 4. PRODUCT RELATIONSHIPS
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO product_relationship (source_product_id, target_product_id, relationship_type, is_conditional, condition_note, notes) VALUES

    -- ALEXA 35 kit essentials
    (p_alexa35, p_pllpl,    'requires',   true,  'Only when using PL-mount lenses — LPL glass attaches natively',
                                                   'ARRI includes one PL-to-LPL adapter in the ALEXA 35 box'),
    (p_alexa35, p_cine90,   'recommends', false,  NULL,
                                                   'Gold Mount is the standard power solution for ALEXA 35'),
    (p_alexa35, p_mb20,     'recommends', false,  NULL,
                                                   'MB-20 II is the matched matte box for ARRI bodies'),
    (p_alexa35, p_wcu4,     'recommends', false,  NULL,
                                                   'WCU-4 integrates natively with ALEXA camera bus (no cable required)'),
    (p_alexa35, p_cooke_s4, 'recommends', false,  NULL,
                                                   'Cooke S4/i is the most-rented PL prime set for ALEXA 35 S35 work'),
    (p_alexa35, p_zeiss_sp, 'recommends', false,  NULL,
                                                   'Zeiss Supreme Primes cover FF and S35 — ideal for open-gate on ALEXA 35'),

    -- VENICE 2 kit
    (p_venice2, p_zeiss_sp, 'recommends', false,  NULL,
                                                   'Supreme Primes cover full frame — the natural FF lens choice for VENICE 2'),
    (p_venice2, p_pllpl,    'requires',   true,  'Only when using PL lenses via CBK-3610XS adapter',
                                                   'VENICE 2 native mount is E-Mount; PL requires Sony adapter unit'),

    -- RED V-RAPTOR
    (p_raptor,  p_cooke_s4, 'recommends', false,  NULL,
                                                   'Cooke S4/i is the standard PL prime choice for RED bodies'),
    (p_raptor,  p_wcu4,     'recommends', false,  NULL,
                                                   'WCU-4 works on any PL-body build with 15mm rods'),

    -- Wireless pairing — TX needs RX
    (p_bolt4k,  p_smallhd7, 'recommends', false,  NULL,
                                                   'SmallHD Cine 7 has integrated Bolt 6 RX — the natural director monitor pairing'),

    -- Lens → FIZ compatibility
    (p_cooke_s4, p_wcu4,   'recommends', false,  NULL,
                                                   'Cooke S4/i 0.4 mod gears work directly with WCU-4 motors'),
    (p_zeiss_sp, p_wcu4,   'recommends', false,  NULL,
                                                   'Zeiss Supreme 0.4 mod gears work directly with WCU-4'),
    (p_ang_zoom, p_wcu4,   'recommends', false,  NULL,
                                                   'Optimo 24-290 requires FIZ — WCU-4 is the standard choice on ARRI builds')

  ON CONFLICT (source_product_id, target_product_id, relationship_type) DO NOTHING;

  -- ─────────────────────────────────────────────────────────────────────────────
  -- 5. KIT TEMPLATE — "ALEXA 35 Standard Narrative Kit"
  -- ─────────────────────────────────────────────────────────────────────────────

  INSERT INTO kit_template (name, anchor_product_id, shoot_type, description, is_public)
  VALUES (
    'ALEXA 35 — Standard Narrative Kit',
    p_alexa35,
    'narrative',
    'Full S35 narrative package anchored on the ARRI ALEXA 35. Cooke S4/i primes, ARRI WCU-4 FIZ, MB-20 II matte box, Anton Bauer Gold Mount power, and SmallHD Cine 7 director monitor with Teradek wireless. Touches all 7 compatibility axes.',
    true
  )
  ON CONFLICT DO NOTHING
  RETURNING id INTO kt_alexa35;

  -- Capture ID if it already existed (RETURNING only works on the INSERT path)
  IF kt_alexa35 IS NULL THEN
    SELECT id INTO kt_alexa35 FROM kit_template WHERE name = 'ALEXA 35 — Standard Narrative Kit';
  END IF;

  INSERT INTO kit_template_item (kit_template_id, product_id, quantity, is_required, sort_order, notes) VALUES
    -- Camera body (anchor — listed first for UI display)
    (kt_alexa35, p_alexa35,  1, true,  10, NULL),
    -- Power — required to run anything
    (kt_alexa35, p_cine90,   2, true,  20, '2× batteries recommended for a full shoot day'),
    -- Lenses
    (kt_alexa35, p_cooke_s4, 1, false, 30, 'S4/i full set — most-rented PL prime for S35'),
    (kt_alexa35, p_ang_zoom, 1, false, 40, 'Optimo 24-290 as the production zoom'),
    -- Adapter (conditional on using PL lenses)
    (kt_alexa35, p_pllpl,    1, false, 50, 'Required if using PL lenses — ARRI includes one in box'),
    -- Support & control
    (kt_alexa35, p_mb20,     1, true,  60, NULL),
    (kt_alexa35, p_wcu4,     1, false, 70, 'Recommended — integrates via ALEXA camera bus'),
    -- Village
    (kt_alexa35, p_smallhd7, 1, false, 80, 'Director / DIT monitor'),
    (kt_alexa35, p_bolt4k,   1, false, 90, 'Wireless TX/RX for director monitor')
  ON CONFLICT DO NOTHING;

END $$;
