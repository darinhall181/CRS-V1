-- Demo seed: Canon Cinema EOS cameras
-- Covers EOS C80, EOS C70, EOS C300 Mark III, EOS C500 Mark II.
-- Specs sourced from Canon USA spec sheets (April 2026).
-- Safe to re-run: all inserts use ON CONFLICT guards.
-- Requires: 20260211000000_seed_cinema_camera_category.sql

DO $$
DECLARE
  cat_id  UUID;
  can_id  UUID;
  p_id    UUID;

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

  SELECT id INTO cat_id FROM product_category WHERE slug = 'cinema-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'cinema-cameras category not found. Run 20260211000000 first.';
  END IF;

  SELECT id INTO can_id FROM brand WHERE slug = 'canon';
  IF can_id IS NULL THEN
    RAISE EXCEPTION 'canon brand not found';
  END IF;

  -- Load spec definition IDs
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

  -- ================================================================
  -- EOS C80
  -- Source: usa.canon.com/shop/p/eos-c80 (April 2026)
  -- ================================================================
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, source_url, scraping_status, is_active)
  VALUES (can_id, cat_id, 'EOS C80', 'Canon EOS C80', 'canon-eos-c80',
    'https://www.usa.canon.com/shop/p/eos-c80',
    'https://www.usa.canon.com/shop/p/eos-c80', 'seeded', TRUE)
  ON CONFLICT (slug) DO UPDATE SET full_name = EXCLUDED.full_name, scraping_status = EXCLUDED.scraping_status, updated_at = NOW();
  SELECT id INTO p_id FROM product WHERE slug = 'canon-eos-c80';

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value, numeric_value, extraction_confidence)
  VALUES
    (p_id, sd_body_type,      'Cinema Camera',                              NULL,  NULL,   1.0),
    (p_id, sd_sensor_type,    'Super 35mm CMOS (Dual Pixel CMOS AF)',       NULL,  NULL,   1.0),
    (p_id, sd_sensor_size,    'Super 35 (26.2 × 13.8 mm)',                  NULL,  NULL,   1.0),
    (p_id, sd_sensor_dims,    '26.2 × 13.8 mm',                             NULL,  NULL,   1.0),
    (p_id, sd_dynamic_range,  '16 stops',                                   NULL,  NULL,   1.0),
    (p_id, sd_base_iso,       'ISO 100–102400 (Low: 800, High: 12800)',     NULL,  NULL,   1.0),
    (p_id, sd_dual_iso,       NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_max_fps,        '120 fps (4K)',                               NULL,  120,    1.0),
    (p_id, sd_anamorphic,     NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_squeeze_factors,'1.3x, 1.5x, 2.0x (in-camera)',              NULL,  NULL,   1.0),
    (p_id, sd_rec_formats,    'Cinema RAW Light, XF-AVC (H.265/H.264), MP4', NULL, NULL,  1.0),
    (p_id, sd_rec_media,      'CFexpress Type A (dual slots), SD/SDHC/SDXC', NULL, NULL,  1.0),
    (p_id, sd_internal_rec,   NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_max_res,        '4K (4096 × 2160) Cinema RAW Light',          NULL,  NULL,   1.0),
    (p_id, sd_internal_nd,    'Built-in: 2, 4, 6, 8 stops (4-step ND)',    NULL,  NULL,   1.0),
    (p_id, sd_lens_mount,     'RF Mount',                                   NULL,  NULL,   1.0),
    (p_id, sd_flange,         'RF: 20.00 mm',                               NULL,  NULL,   1.0),
    (p_id, sd_lens_meta,      'RF lens electronic communication',           NULL,  NULL,   1.0),
    (p_id, sd_log_format,     'Canon Log 2, Canon Log 3',                   NULL,  NULL,   1.0),
    (p_id, sd_color_space,    'Cinema Gamut, BT.2020, BT.709',              NULL,  NULL,   1.0),
    (p_id, sd_lut_support,    NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_timecode,       NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_genlock,        NULL,                                          FALSE, NULL,   1.0),
    (p_id, sd_sdi,            '2× 12G-SDI outputs',                         NULL,  NULL,   1.0),
    (p_id, sd_wifi,           NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_ethernet,       NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_weight,         NULL,                                          NULL,  1620,   1.0),
    (p_id, sd_dimensions,     '158 × 148 × 154 mm',                         NULL,  NULL,   1.0),
    (p_id, sd_power_input,    'BP-A60N / BP-A30N battery, DC 8.4V',        NULL,  NULL,   1.0),
    (p_id, sd_power_draw,     'approx. 21W',                               NULL,  NULL,   1.0)
  ON CONFLICT (product_id, spec_definition_id) DO UPDATE SET
    spec_value = EXCLUDED.spec_value,
    boolean_value = EXCLUDED.boolean_value,
    numeric_value = EXCLUDED.numeric_value,
    extraction_confidence = EXCLUDED.extraction_confidence,
    scraped_at = NOW();

  -- ================================================================
  -- EOS C70
  -- Source: usa.canon.com/shop/p/eos-c70 (April 2026)
  -- ================================================================
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, source_url, scraping_status, is_active)
  VALUES (can_id, cat_id, 'EOS C70', 'Canon EOS C70', 'canon-eos-c70',
    'https://www.usa.canon.com/shop/p/eos-c70',
    'https://www.usa.canon.com/shop/p/eos-c70', 'seeded', TRUE)
  ON CONFLICT (slug) DO UPDATE SET full_name = EXCLUDED.full_name, scraping_status = EXCLUDED.scraping_status, updated_at = NOW();
  SELECT id INTO p_id FROM product WHERE slug = 'canon-eos-c70';

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value, numeric_value, extraction_confidence)
  VALUES
    (p_id, sd_body_type,      'Cinema Camera',                              NULL,  NULL,   1.0),
    (p_id, sd_sensor_type,    'Super 35mm DGO CMOS (Dual Gain Output)',     NULL,  NULL,   1.0),
    (p_id, sd_sensor_size,    'Super 35 (26.2 × 13.8 mm)',                  NULL,  NULL,   1.0),
    (p_id, sd_sensor_dims,    '26.2 × 13.8 mm',                             NULL,  NULL,   1.0),
    (p_id, sd_dynamic_range,  '16 stops (Dual Gain Output)',                NULL,  NULL,   1.0),
    (p_id, sd_base_iso,       'ISO 100–102400 (Low: 800, High: 12800 DGO)', NULL,  NULL,   1.0),
    (p_id, sd_dual_iso,       NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_max_fps,        '120 fps (4K)',                               NULL,  120,    1.0),
    (p_id, sd_anamorphic,     NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_squeeze_factors,'1.3x, 1.5x, 2.0x (in-camera)',              NULL,  NULL,   1.0),
    (p_id, sd_rec_formats,    'Cinema RAW Light, XF-AVC (H.265/H.264), MP4', NULL, NULL,  1.0),
    (p_id, sd_rec_media,      'CFexpress Type A (dual slots), SD/SDHC/SDXC', NULL, NULL,  1.0),
    (p_id, sd_internal_rec,   NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_max_res,        '4K (4096 × 2160) Cinema RAW Light',          NULL,  NULL,   1.0),
    (p_id, sd_internal_nd,    'Built-in: 2, 4, 6, 8 stops (4-step ND)',    NULL,  NULL,   1.0),
    (p_id, sd_lens_mount,     'RF Mount',                                   NULL,  NULL,   1.0),
    (p_id, sd_flange,         'RF: 20.00 mm',                               NULL,  NULL,   1.0),
    (p_id, sd_lens_meta,      'RF lens electronic communication',           NULL,  NULL,   1.0),
    (p_id, sd_log_format,     'Canon Log 2, Canon Log 3',                   NULL,  NULL,   1.0),
    (p_id, sd_color_space,    'Cinema Gamut, BT.2020, BT.709',              NULL,  NULL,   1.0),
    (p_id, sd_lut_support,    NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_timecode,       NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_genlock,        NULL,                                          FALSE, NULL,   1.0),
    (p_id, sd_sdi,            'None (HDMI 2.0 output only)',                NULL,  NULL,   1.0),
    (p_id, sd_wifi,           NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_ethernet,       NULL,                                          FALSE, NULL,   1.0),
    (p_id, sd_weight,         NULL,                                          NULL,  1535,   1.0),
    (p_id, sd_dimensions,     '160 × 127 × 152 mm',                         NULL,  NULL,   1.0),
    (p_id, sd_power_input,    'BP-A60N / BP-A30N battery, DC 8.4V',        NULL,  NULL,   1.0),
    (p_id, sd_power_draw,     'approx. 19W',                               NULL,  NULL,   1.0)
  ON CONFLICT (product_id, spec_definition_id) DO UPDATE SET
    spec_value = EXCLUDED.spec_value,
    boolean_value = EXCLUDED.boolean_value,
    numeric_value = EXCLUDED.numeric_value,
    extraction_confidence = EXCLUDED.extraction_confidence,
    scraped_at = NOW();

  -- ================================================================
  -- EOS C300 Mark III
  -- Source: usa.canon.com/shop/p/eos-c300-mark-iii (April 2026)
  -- ================================================================
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, source_url, scraping_status, is_active)
  VALUES (can_id, cat_id, 'EOS C300 Mark III', 'Canon EOS C300 Mark III', 'canon-eos-c300-mark-iii',
    'https://www.usa.canon.com/shop/p/eos-c300-mark-iii',
    'https://www.usa.canon.com/shop/p/eos-c300-mark-iii', 'seeded', TRUE)
  ON CONFLICT (slug) DO UPDATE SET full_name = EXCLUDED.full_name, scraping_status = EXCLUDED.scraping_status, updated_at = NOW();
  SELECT id INTO p_id FROM product WHERE slug = 'canon-eos-c300-mark-iii';

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value, numeric_value, extraction_confidence)
  VALUES
    (p_id, sd_body_type,      'Cinema Camera',                              NULL,  NULL,   1.0),
    (p_id, sd_sensor_type,    'Super 35mm DGO CMOS (Dual Gain Output)',     NULL,  NULL,   1.0),
    (p_id, sd_sensor_size,    'Super 35 (26.2 × 13.8 mm)',                  NULL,  NULL,   1.0),
    (p_id, sd_sensor_dims,    '26.2 × 13.8 mm',                             NULL,  NULL,   1.0),
    (p_id, sd_dynamic_range,  '16 stops (Dual Gain Output)',                NULL,  NULL,   1.0),
    (p_id, sd_base_iso,       'ISO 100–102400 (Low: 800, High: 12800 DGO)', NULL,  NULL,   1.0),
    (p_id, sd_dual_iso,       NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_max_fps,        '120 fps (4K)',                               NULL,  120,    1.0),
    (p_id, sd_anamorphic,     NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_squeeze_factors,'1.3x, 2.0x (in-camera)',                    NULL,  NULL,   1.0),
    (p_id, sd_rec_formats,    'Cinema RAW Light, XF-AVC (H.265/H.264)',    NULL,  NULL,   1.0),
    (p_id, sd_rec_media,      'CFexpress Type B (dual slots), CFast 2.0',  NULL,  NULL,   1.0),
    (p_id, sd_internal_rec,   NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_max_res,        '4K (4096 × 2160) Cinema RAW Light',          NULL,  NULL,   1.0),
    (p_id, sd_internal_nd,    'Built-in: 2, 4, 6, 8 stops (4-step ND)',    NULL,  NULL,   1.0),
    (p_id, sd_lens_mount,     'PL Mount / EF Mount (interchangeable)',      NULL,  NULL,   1.0),
    (p_id, sd_flange,         'PL: 52.00 mm / EF: 44.00 mm',              NULL,  NULL,   1.0),
    (p_id, sd_lens_meta,      'Cooke /i (PL), Canon EF (electronic)',       NULL,  NULL,   1.0),
    (p_id, sd_log_format,     'Canon Log 2, Canon Log 3',                   NULL,  NULL,   1.0),
    (p_id, sd_color_space,    'Cinema Gamut, BT.2020, BT.709',              NULL,  NULL,   1.0),
    (p_id, sd_lut_support,    NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_timecode,       NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_genlock,        NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_sdi,            '2× 12G-SDI outputs',                         NULL,  NULL,   1.0),
    (p_id, sd_wifi,           NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_ethernet,       NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_weight,         NULL,                                          NULL,  2500,   1.0),
    (p_id, sd_dimensions,     '146 × 162 × 183 mm',                         NULL,  NULL,   1.0),
    (p_id, sd_power_input,    'BP-A60N / BP-A30N battery, DC 8.4V',        NULL,  NULL,   1.0),
    (p_id, sd_power_draw,     'approx. 23W',                               NULL,  NULL,   1.0)
  ON CONFLICT (product_id, spec_definition_id) DO UPDATE SET
    spec_value = EXCLUDED.spec_value,
    boolean_value = EXCLUDED.boolean_value,
    numeric_value = EXCLUDED.numeric_value,
    extraction_confidence = EXCLUDED.extraction_confidence,
    scraped_at = NOW();

  -- ================================================================
  -- EOS C500 Mark II
  -- Source: usa.canon.com/shop/p/eos-c500-mark-ii (April 2026)
  -- ================================================================
  INSERT INTO product (brand_id, category_id, model, full_name, slug, manufacturer_url, source_url, scraping_status, is_active)
  VALUES (can_id, cat_id, 'EOS C500 Mark II', 'Canon EOS C500 Mark II', 'canon-eos-c500-mark-ii',
    'https://www.usa.canon.com/shop/p/eos-c500-mark-ii',
    'https://www.usa.canon.com/shop/p/eos-c500-mark-ii', 'seeded', TRUE)
  ON CONFLICT (slug) DO UPDATE SET full_name = EXCLUDED.full_name, scraping_status = EXCLUDED.scraping_status, updated_at = NOW();
  SELECT id INTO p_id FROM product WHERE slug = 'canon-eos-c500-mark-ii';

  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, boolean_value, numeric_value, extraction_confidence)
  VALUES
    (p_id, sd_body_type,      'Cinema Camera',                              NULL,  NULL,   1.0),
    (p_id, sd_sensor_type,    'Full Frame CMOS (5.9K)',                     NULL,  NULL,   1.0),
    (p_id, sd_sensor_size,    'Full Frame (38.1 × 20.1 mm)',               NULL,  NULL,   1.0),
    (p_id, sd_sensor_dims,    '38.1 × 20.1 mm',                             NULL,  NULL,   1.0),
    (p_id, sd_dynamic_range,  '15 stops',                                   NULL,  NULL,   1.0),
    (p_id, sd_base_iso,       'ISO 100–102400',                             NULL,  NULL,   1.0),
    (p_id, sd_dual_iso,       NULL,                                          FALSE, NULL,   1.0),
    (p_id, sd_max_fps,        '60 fps (5.9K FF) / 120 fps (4K crop)',       NULL,  120,    1.0),
    (p_id, sd_anamorphic,     NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_squeeze_factors,'1.3x, 2.0x (in-camera)',                    NULL,  NULL,   1.0),
    (p_id, sd_rec_formats,    'Cinema RAW Light, XF-AVC (H.265/H.264)',    NULL,  NULL,   1.0),
    (p_id, sd_rec_media,      'CFexpress Type B (dual slots), CFast 2.0',  NULL,  NULL,   1.0),
    (p_id, sd_internal_rec,   NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_max_res,        '5.9K (5952 × 3140) Cinema RAW Light',       NULL,  NULL,   1.0),
    (p_id, sd_internal_nd,    'Built-in: 2, 4, 6, 8 stops (4-step ND)',    NULL,  NULL,   1.0),
    (p_id, sd_lens_mount,     'PL Mount / EF Mount / EF Cinema Lock (interchangeable)', NULL, NULL, 1.0),
    (p_id, sd_flange,         'PL: 52.00 mm / EF: 44.00 mm',              NULL,  NULL,   1.0),
    (p_id, sd_lens_meta,      'Cooke /i (PL), Canon EF (electronic)',       NULL,  NULL,   1.0),
    (p_id, sd_log_format,     'Canon Log 2, Canon Log 3',                   NULL,  NULL,   1.0),
    (p_id, sd_color_space,    'Cinema Gamut, BT.2020, BT.709',              NULL,  NULL,   1.0),
    (p_id, sd_lut_support,    NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_timecode,       NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_genlock,        NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_sdi,            '2× 12G-SDI outputs',                         NULL,  NULL,   1.0),
    (p_id, sd_wifi,           NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_ethernet,       NULL,                                          TRUE,  NULL,   1.0),
    (p_id, sd_weight,         NULL,                                          NULL,  2910,   1.0),
    (p_id, sd_dimensions,     '146 × 171 × 183 mm',                         NULL,  NULL,   1.0),
    (p_id, sd_power_input,    'BP-A60N / BP-A30N battery, DC 8.4V',        NULL,  NULL,   1.0),
    (p_id, sd_power_draw,     'approx. 23W',                               NULL,  NULL,   1.0)
  ON CONFLICT (product_id, spec_definition_id) DO UPDATE SET
    spec_value = EXCLUDED.spec_value,
    boolean_value = EXCLUDED.boolean_value,
    numeric_value = EXCLUDED.numeric_value,
    extraction_confidence = EXCLUDED.extraction_confidence,
    scraped_at = NOW();

END $$;
