-- Demo seed: RED and Blackmagic cinema cameras
-- Specs sourced directly from manufacturer spec sheets (April 2026).
-- Safe to re-run: all inserts use ON CONFLICT guards.
-- Requires: 20260211000000_seed_cinema_camera_category.sql (cinema-cameras category + spec defs)

DO $$
DECLARE
  cat_id      UUID;
  red_id      UUID;
  bmd_id      UUID;

  p_id        UUID;

  -- spec definition IDs
  sd_sensor_type        UUID;
  sd_sensor_size        UUID;
  sd_sensor_dims        UUID;
  sd_dynamic_range      UUID;
  sd_base_iso           UUID;
  sd_dual_iso           UUID;
  sd_max_fps            UUID;
  sd_anamorphic         UUID;
  sd_squeeze_factors    UUID;
  sd_rec_formats        UUID;
  sd_rec_media          UUID;
  sd_internal_rec       UUID;
  sd_max_res            UUID;
  sd_internal_nd        UUID;
  sd_lens_mount         UUID;
  sd_flange             UUID;
  sd_lens_meta          UUID;
  sd_log_format         UUID;
  sd_color_space        UUID;
  sd_lut_support        UUID;
  sd_timecode           UUID;
  sd_genlock            UUID;
  sd_sdi                UUID;
  sd_wifi               UUID;
  sd_ethernet           UUID;
  sd_weight             UUID;
  sd_dimensions         UUID;
  sd_power_input        UUID;
  sd_power_draw         UUID;
  sd_body_type          UUID;
BEGIN

  -- ----------------------------------------------------------------
  -- Prerequisites
  -- ----------------------------------------------------------------
  SELECT id INTO cat_id FROM product_category WHERE slug = 'cinema-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: cinema-cameras category not found. Run 20260211000000 first.';
  END IF;

  -- Load all spec definition IDs by normalized_key
  SELECT id INTO sd_sensor_type     FROM spec_definition WHERE normalized_key = 'cinema_sensor_type';
  SELECT id INTO sd_sensor_size     FROM spec_definition WHERE normalized_key = 'cinema_sensor_size';
  SELECT id INTO sd_sensor_dims     FROM spec_definition WHERE normalized_key = 'cinema_sensor_dimensions';
  SELECT id INTO sd_dynamic_range   FROM spec_definition WHERE normalized_key = 'cinema_dynamic_range';
  SELECT id INTO sd_base_iso        FROM spec_definition WHERE normalized_key = 'cinema_base_iso';
  SELECT id INTO sd_dual_iso        FROM spec_definition WHERE normalized_key = 'dual_base_iso';
  SELECT id INTO sd_max_fps         FROM spec_definition WHERE normalized_key = 'cinema_max_fps';
  SELECT id INTO sd_anamorphic      FROM spec_definition WHERE normalized_key = 'anamorphic_desqueeze_supported';
  SELECT id INTO sd_squeeze_factors FROM spec_definition WHERE normalized_key = 'anamorphic_squeeze_factors';
  SELECT id INTO sd_rec_formats     FROM spec_definition WHERE normalized_key = 'cinema_recording_formats';
  SELECT id INTO sd_rec_media       FROM spec_definition WHERE normalized_key = 'cinema_recording_media';
  SELECT id INTO sd_internal_rec    FROM spec_definition WHERE normalized_key = 'cinema_internal_recording';
  SELECT id INTO sd_max_res         FROM spec_definition WHERE normalized_key = 'cinema_max_resolution';
  SELECT id INTO sd_internal_nd     FROM spec_definition WHERE normalized_key = 'cinema_internal_nd';
  SELECT id INTO sd_lens_mount      FROM spec_definition WHERE normalized_key = 'cinema_lens_mount';
  SELECT id INTO sd_flange          FROM spec_definition WHERE normalized_key = 'cinema_flange_focal_distance';
  SELECT id INTO sd_lens_meta       FROM spec_definition WHERE normalized_key = 'cinema_lens_metadata';
  SELECT id INTO sd_log_format      FROM spec_definition WHERE normalized_key = 'cinema_log_format';
  SELECT id INTO sd_color_space     FROM spec_definition WHERE normalized_key = 'cinema_color_space';
  SELECT id INTO sd_lut_support     FROM spec_definition WHERE normalized_key = 'cinema_lut_support';
  SELECT id INTO sd_timecode        FROM spec_definition WHERE normalized_key = 'cinema_timecode_io';
  SELECT id INTO sd_genlock         FROM spec_definition WHERE normalized_key = 'cinema_genlock';
  SELECT id INTO sd_sdi             FROM spec_definition WHERE normalized_key = 'cinema_sdi_outputs';
  SELECT id INTO sd_wifi            FROM spec_definition WHERE normalized_key = 'cinema_wifi';
  SELECT id INTO sd_ethernet        FROM spec_definition WHERE normalized_key = 'cinema_ethernet';
  SELECT id INTO sd_weight          FROM spec_definition WHERE normalized_key = 'cinema_weight';
  SELECT id INTO sd_dimensions      FROM spec_definition WHERE normalized_key = 'cinema_dimensions';
  SELECT id INTO sd_power_input     FROM spec_definition WHERE normalized_key = 'cinema_power_input';
  SELECT id INTO sd_power_draw      FROM spec_definition WHERE normalized_key = 'cinema_power_draw';
  SELECT id INTO sd_body_type       FROM spec_definition WHERE normalized_key = 'cinema_body_type';

  -- ----------------------------------------------------------------
  -- Brands — look up existing rows first; insert only if truly absent.
  -- The brands table has unique constraints on both slug AND name,
  -- so we resolve by name to avoid any slug mismatch with existing data.
  -- ----------------------------------------------------------------
  INSERT INTO brand (name, slug, website_url, scraping_enabled)
  VALUES ('RED', 'red', 'https://www.red.com', TRUE)
  ON CONFLICT (slug) DO NOTHING;
  -- Fallback: some seeds stored the brand with a different slug
  SELECT id INTO red_id FROM brand WHERE slug = 'red';
  IF red_id IS NULL THEN
    SELECT id INTO red_id FROM brand WHERE LOWER(name) = 'red';
  END IF;

  -- Blackmagic already seeded as slug='blackmagic-design'
  INSERT INTO brand (name, slug, website_url, scraping_enabled)
  VALUES ('Blackmagic Design', 'blackmagic-design', 'https://www.blackmagicdesign.com', TRUE)
  ON CONFLICT (slug) DO NOTHING;
  SELECT id INTO bmd_id FROM brand WHERE slug = 'blackmagic-design';
  IF bmd_id IS NULL THEN
    SELECT id INTO bmd_id FROM brand WHERE LOWER(name) = 'blackmagic design';
  END IF;

  -- ================================================================
  -- RED V-RAPTOR [X] 8K VV
  -- Source: red.com/v-raptor (April 2026)
  -- ================================================================
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, source_url, scraping_status, is_active)
  VALUES (red_id, cat_id, 'V-RAPTOR [X] 8K VV', 'RED V-RAPTOR [X] 8K VV', 'red-v-raptor-x-8k-vv',
    'https://www.red.com/v-raptor', 'https://www.red.com/v-raptor', 'seeded', TRUE)
  ON CONFLICT (slug) DO UPDATE SET full_name = EXCLUDED.full_name, scraping_status = EXCLUDED.scraping_status, updated_at = NOW();
  SELECT id INTO p_id FROM product WHERE slug = 'red-v-raptor-x-8k-vv';

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value, numeric_value, extraction_confidence)
  VALUES
    (p_id, sd_body_type,      'Cinema Camera Brain',                        NULL,  NULL,  1.0),
    (p_id, sd_sensor_type,    'Monstro 8K VV CMOS',                         NULL,  NULL,  1.0),
    (p_id, sd_sensor_size,    'Vista Vision (40.96 × 21.60 mm)',             NULL,  NULL,  1.0),
    (p_id, sd_sensor_dims,    '40.96 × 21.60 mm',                           NULL,  NULL,  1.0),
    (p_id, sd_dynamic_range,  '17+ stops (IPP2)',                            NULL,  NULL,  1.0),
    (p_id, sd_base_iso,       'ISO 250–12800',                               NULL,  NULL,  1.0),
    (p_id, sd_dual_iso,       NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_max_fps,        '120 fps (8K 2.4:1)',                          NULL,  120,   1.0),
    (p_id, sd_anamorphic,     NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_squeeze_factors,'1.3x, 1.5x, 2.0x (in-camera)',               NULL,  NULL,  1.0),
    (p_id, sd_rec_formats,    'REDCODE RAW (R3D), Apple ProRes 422 HQ, Apple ProRes 4444', NULL, NULL, 1.0),
    (p_id, sd_rec_media,      'CFexpress Type B (dual slots)',               NULL,  NULL,  1.0),
    (p_id, sd_internal_rec,   NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_max_res,        '8K (8192 × 4320) Full Frame',                 NULL,  NULL,  1.0),
    (p_id, sd_internal_nd,    'None (external ND required)',                 NULL,  NULL,  1.0),
    (p_id, sd_lens_mount,     'PL Mount (LBUS)',                             NULL,  NULL,  1.0),
    (p_id, sd_flange,         'PL: 52.00 mm',                               NULL,  NULL,  1.0),
    (p_id, sd_lens_meta,      'Cooke /i, LBUS lens control',                NULL,  NULL,  1.0),
    (p_id, sd_log_format,     'REDWideGamutRGB / Log3G10 (IPP2)',            NULL,  NULL,  1.0),
    (p_id, sd_color_space,    'REDWideGamutRGB',                            NULL,  NULL,  1.0),
    (p_id, sd_lut_support,    NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_timecode,       NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_genlock,        NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_sdi,            '1× 12G-SDI Monitor Out',                     NULL,  NULL,  1.0),
    (p_id, sd_wifi,           NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_ethernet,       NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_weight,         NULL,                                          NULL,  1300,  1.0),
    (p_id, sd_power_input,    'V-Mount / Gold Mount (via adapter plate)',    NULL,  NULL,  1.0),
    (p_id, sd_power_draw,     'approx. 30W',                                NULL,  NULL,  1.0)
  ON CONFLICT (product_id, spec_definition_id) DO UPDATE SET
    spec_value = EXCLUDED.spec_value,
    boolean_value = EXCLUDED.boolean_value,
    numeric_value = EXCLUDED.numeric_value,
    extraction_confidence = EXCLUDED.extraction_confidence,
    scraped_at = NOW();

  -- ================================================================
  -- RED KOMODO-X 6K S35
  -- Source: red.com/komodo-x (April 2026)
  -- ================================================================
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, source_url, scraping_status, is_active)
  VALUES (red_id, cat_id, 'KOMODO-X 6K S35', 'RED KOMODO-X 6K S35', 'red-komodo-x-6k-s35',
    'https://www.red.com/komodo-x', 'https://www.red.com/komodo-x', 'seeded', TRUE)
  ON CONFLICT (slug) DO UPDATE SET full_name = EXCLUDED.full_name, scraping_status = EXCLUDED.scraping_status, updated_at = NOW();
  SELECT id INTO p_id FROM product WHERE slug = 'red-komodo-x-6k-s35';

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value, numeric_value, extraction_confidence)
  VALUES
    (p_id, sd_body_type,      'Compact Cinema Camera',                      NULL,  NULL,  1.0),
    (p_id, sd_sensor_type,    'Dragon-X 6K S35 CMOS',                       NULL,  NULL,  1.0),
    (p_id, sd_sensor_size,    'Super 35 (27.03 × 14.26 mm)',                 NULL,  NULL,  1.0),
    (p_id, sd_sensor_dims,    '27.03 × 14.26 mm',                           NULL,  NULL,  1.0),
    (p_id, sd_dynamic_range,  '16+ stops (IPP2)',                            NULL,  NULL,  1.0),
    (p_id, sd_base_iso,       'ISO 250–12800',                               NULL,  NULL,  1.0),
    (p_id, sd_dual_iso,       NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_max_fps,        '80 fps (6K 2.4:1)',                           NULL,  80,    1.0),
    (p_id, sd_anamorphic,     NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_squeeze_factors,'1.3x, 2.0x (in-camera)',                     NULL,  NULL,  1.0),
    (p_id, sd_rec_formats,    'REDCODE RAW (R3D), Apple ProRes 422 HQ, Apple ProRes 4444', NULL, NULL, 1.0),
    (p_id, sd_rec_media,      'CFexpress Type B (dual slots)',               NULL,  NULL,  1.0),
    (p_id, sd_internal_rec,   NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_max_res,        '6K (6144 × 3240) Full Frame S35',             NULL,  NULL,  1.0),
    (p_id, sd_internal_nd,    'None',                                        NULL,  NULL,  1.0),
    (p_id, sd_lens_mount,     'PL Mount (LBUS)',                             NULL,  NULL,  1.0),
    (p_id, sd_flange,         'PL: 52.00 mm',                               NULL,  NULL,  1.0),
    (p_id, sd_lens_meta,      'Cooke /i, LBUS lens control',                NULL,  NULL,  1.0),
    (p_id, sd_log_format,     'REDWideGamutRGB / Log3G10 (IPP2)',            NULL,  NULL,  1.0),
    (p_id, sd_color_space,    'REDWideGamutRGB',                            NULL,  NULL,  1.0),
    (p_id, sd_lut_support,    NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_timecode,       NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_genlock,        NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_sdi,            '1× 12G-SDI Monitor Out',                     NULL,  NULL,  1.0),
    (p_id, sd_wifi,           NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_ethernet,       NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_weight,         NULL,                                          NULL,  1450,  1.0),
    (p_id, sd_power_input,    'V-Mount / Gold Mount (via adapter plate)',    NULL,  NULL,  1.0),
    (p_id, sd_power_draw,     'approx. 36W',                                NULL,  NULL,  1.0)
  ON CONFLICT (product_id, spec_definition_id) DO UPDATE SET
    spec_value = EXCLUDED.spec_value,
    boolean_value = EXCLUDED.boolean_value,
    numeric_value = EXCLUDED.numeric_value,
    extraction_confidence = EXCLUDED.extraction_confidence,
    scraped_at = NOW();

  -- ================================================================
  -- Blackmagic URSA Mini Pro 12K
  -- Source: blackmagicdesign.com/products/blackmagicursaminipro (April 2026)
  -- ================================================================
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, source_url, scraping_status, is_active)
  VALUES (bmd_id, cat_id, 'URSA Mini Pro 12K', 'Blackmagic URSA Mini Pro 12K', 'blackmagic-ursa-mini-pro-12k',
    'https://www.blackmagicdesign.com/products/blackmagicursaminipro',
    'https://www.blackmagicdesign.com/products/blackmagicursaminipro', 'seeded', TRUE)
  ON CONFLICT (slug) DO UPDATE SET full_name = EXCLUDED.full_name, scraping_status = EXCLUDED.scraping_status, updated_at = NOW();
  SELECT id INTO p_id FROM product WHERE slug = 'blackmagic-ursa-mini-pro-12k';

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value, numeric_value, extraction_confidence)
  VALUES
    (p_id, sd_body_type,      'Cinema Camera',                              NULL,  NULL,  1.0),
    (p_id, sd_sensor_type,    '12K Super 35 CMOS',                          NULL,  NULL,  1.0),
    (p_id, sd_sensor_size,    'Super 35 (27.03 × 14.25 mm)',                NULL,  NULL,  1.0),
    (p_id, sd_sensor_dims,    '27.03 × 14.25 mm',                           NULL,  NULL,  1.0),
    (p_id, sd_dynamic_range,  '14 stops',                                   NULL,  NULL,  1.0),
    (p_id, sd_base_iso,       'ISO 200–3200',                               NULL,  NULL,  1.0),
    (p_id, sd_dual_iso,       NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_max_fps,        '60 fps (12K)',                               NULL,  60,    1.0),
    (p_id, sd_anamorphic,     NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_squeeze_factors,'1.25x, 1.33x, 1.5x, 1.65x, 2.0x',          NULL,  NULL,  1.0),
    (p_id, sd_rec_formats,    'BRAW (Blackmagic RAW), Apple ProRes 422 HQ, Apple ProRes 4444 XQ', NULL, NULL, 1.0),
    (p_id, sd_rec_media,      'CFast 2.0 (dual slots), USB-C (external SSD)', NULL, NULL, 1.0),
    (p_id, sd_internal_rec,   NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_max_res,        '12K (12288 × 6480) Super 35',                NULL,  NULL,  1.0),
    (p_id, sd_internal_nd,    'Built-in ND: 2, 4, 8 stops (motorized)',     NULL,  NULL,  1.0),
    (p_id, sd_lens_mount,     'PL Mount / EF Mount (interchangeable)',      NULL,  NULL,  1.0),
    (p_id, sd_flange,         'PL: 52.00 mm / EF: 44.00 mm',               NULL,  NULL,  1.0),
    (p_id, sd_lens_meta,      'Cooke /i (PL), Canon EF (electronic)',       NULL,  NULL,  1.0),
    (p_id, sd_log_format,     'Blackmagic Film (Log), Blackmagic Extended Video', NULL, NULL, 1.0),
    (p_id, sd_color_space,    'Blackmagic Wide Gamut',                      NULL,  NULL,  1.0),
    (p_id, sd_lut_support,    NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_timecode,       NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_genlock,        NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_sdi,            '2× 12G-SDI outputs',                         NULL,  NULL,  1.0),
    (p_id, sd_wifi,           NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_ethernet,       NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_weight,         NULL,                                          NULL,  2835,  1.0),
    (p_id, sd_dimensions,     '207.5 × 147.5 × 128.2 mm',                  NULL,  NULL,  1.0),
    (p_id, sd_power_input,    '12–20V DC, V-Mount / Gold Mount (via plate)', NULL, NULL,  1.0),
    (p_id, sd_power_draw,     'approx. 30W',                                NULL,  NULL,  1.0)
  ON CONFLICT (product_id, spec_definition_id) DO UPDATE SET
    spec_value = EXCLUDED.spec_value,
    boolean_value = EXCLUDED.boolean_value,
    numeric_value = EXCLUDED.numeric_value,
    extraction_confidence = EXCLUDED.extraction_confidence,
    scraped_at = NOW();

  -- ================================================================
  -- Blackmagic URSA Cine 12K LF
  -- Source: blackmagicdesign.com/products/blackmagicursacine (April 2026)
  -- ================================================================
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, source_url, scraping_status, is_active)
  VALUES (bmd_id, cat_id, 'URSA Cine 12K LF', 'Blackmagic URSA Cine 12K LF', 'blackmagic-ursa-cine-12k-lf',
    'https://www.blackmagicdesign.com/products/blackmagicursacine',
    'https://www.blackmagicdesign.com/products/blackmagicursacine', 'seeded', TRUE)
  ON CONFLICT (slug) DO UPDATE SET full_name = EXCLUDED.full_name, scraping_status = EXCLUDED.scraping_status, updated_at = NOW();
  SELECT id INTO p_id FROM product WHERE slug = 'blackmagic-ursa-cine-12k-lf';

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value, numeric_value, extraction_confidence)
  VALUES
    (p_id, sd_body_type,      'Cinema Camera',                              NULL,  NULL,  1.0),
    (p_id, sd_sensor_type,    '12K Large Format CMOS',                      NULL,  NULL,  1.0),
    (p_id, sd_sensor_size,    'Large Format (36.35 × 27.00 mm)',            NULL,  NULL,  1.0),
    (p_id, sd_sensor_dims,    '36.35 × 27.00 mm',                           NULL,  NULL,  1.0),
    (p_id, sd_dynamic_range,  '14 stops',                                   NULL,  NULL,  1.0),
    (p_id, sd_base_iso,       'ISO 200–3200',                               NULL,  NULL,  1.0),
    (p_id, sd_dual_iso,       NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_max_fps,        '80 fps (12K LF)',                            NULL,  80,    1.0),
    (p_id, sd_anamorphic,     NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_squeeze_factors,'1.25x, 1.33x, 1.5x, 1.65x, 2.0x',          NULL,  NULL,  1.0),
    (p_id, sd_rec_formats,    'BRAW (Blackmagic RAW), Apple ProRes 422 HQ, Apple ProRes 4444 XQ', NULL, NULL, 1.0),
    (p_id, sd_rec_media,      'Blackmagic Cine Flash (dual slots), USB-C (external SSD)', NULL, NULL, 1.0),
    (p_id, sd_internal_rec,   NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_max_res,        '12K (12288 × 9144) Large Format Open Gate',  NULL,  NULL,  1.0),
    (p_id, sd_internal_nd,    'Built-in motorized ND: 2, 4, 8 stops',      NULL,  NULL,  1.0),
    (p_id, sd_lens_mount,     'LPL Mount',                                  NULL,  NULL,  1.0),
    (p_id, sd_flange,         'LPL: 44.00 mm',                              NULL,  NULL,  1.0),
    (p_id, sd_lens_meta,      'Cooke /i Technology',                        NULL,  NULL,  1.0),
    (p_id, sd_log_format,     'Blackmagic Film (Log), Blackmagic Extended Video', NULL, NULL, 1.0),
    (p_id, sd_color_space,    'Blackmagic Wide Gamut',                      NULL,  NULL,  1.0),
    (p_id, sd_lut_support,    NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_timecode,       NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_genlock,        NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_sdi,            '4× 12G-SDI outputs',                         NULL,  NULL,  1.0),
    (p_id, sd_wifi,           NULL,                                          FALSE, NULL,  1.0),
    (p_id, sd_ethernet,       NULL,                                          TRUE,  NULL,  1.0),
    (p_id, sd_weight,         NULL,                                          NULL,  4500,  1.0),
    (p_id, sd_dimensions,     '272 × 158 × 164 mm',                         NULL,  NULL,  1.0),
    (p_id, sd_power_input,    '12–28V DC, V-Mount / Gold Mount (via plate)', NULL, NULL,  1.0),
    (p_id, sd_power_draw,     'approx. 60W',                                NULL,  NULL,  1.0)
  ON CONFLICT (product_id, spec_definition_id) DO UPDATE SET
    spec_value = EXCLUDED.spec_value,
    boolean_value = EXCLUDED.boolean_value,
    numeric_value = EXCLUDED.numeric_value,
    extraction_confidence = EXCLUDED.extraction_confidence,
    scraped_at = NOW();

END $$;
