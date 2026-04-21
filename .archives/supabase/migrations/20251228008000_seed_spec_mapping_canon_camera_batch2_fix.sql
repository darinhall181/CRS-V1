-- Fix migration (idempotent): Canon camera mapping batch 2
-- Why: editing an already-applied migration does not re-run it; this file re-seeds any missing
-- spec_definitions + spec_mapping rules introduced in batch2.

DO $$
DECLARE
  cat_id UUID;
  s_connect UUID;
  s_display UUID;
  s_optics UUID;
  s_image UUID;
  s_other UUID;
  s_physical UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'mirrorless-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=% not found. Run category seeds first.', 'mirrorless-cameras';
  END IF;

  SELECT id INTO s_connect  FROM spec_section WHERE section_name='Connectivity'   AND category_id=cat_id;
  SELECT id INTO s_display  FROM spec_section WHERE section_name='Display'        AND category_id=cat_id;
  SELECT id INTO s_optics   FROM spec_section WHERE section_name='Optics & Focus' AND category_id=cat_id;
  SELECT id INTO s_image    FROM spec_section WHERE section_name='Image'          AND category_id=cat_id;
  SELECT id INTO s_physical FROM spec_section WHERE section_name='Physical'       AND category_id=cat_id;
  SELECT id INTO s_other    FROM spec_section WHERE section_name='Other Features' AND category_id=cat_id;

  -- Ensure missing definitions exist (safe to re-run)
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_connect, 'Headphone Terminal',              'headphone_terminal',             'text', NULL, cat_id, 2),
    (s_connect, 'Wi‑Fi Standards Compliance',      'wifi_standards_compliance',      'text', NULL, cat_id, 3),
    (s_connect, 'Wi‑Fi Transmission Method',       'wifi_transmission_method',       'text', NULL, cat_id, 2),
    (s_connect, 'Wi‑Fi Frequency (Central)',       'wifi_frequency_central',         'text', NULL, cat_id, 2),
    (s_connect, 'Bluetooth Standards Compliance',  'bluetooth_standards_compliance', 'text', NULL, cat_id, 2),
    (s_connect, 'Bluetooth Transmission Method',   'bluetooth_transmission_method',  'text', NULL, cat_id, 1),
    (s_connect, 'Wi‑Fi Smartphone Support',        'wifi_smartphone_support',        'text', NULL, cat_id, 1),
    (s_connect, 'Wi‑Fi EOS Utility Support',       'wifi_eos_utility_support',       'text', NULL, cat_id, 1),
    (s_connect, 'Wi‑Fi Printer Support',           'wifi_printer_support',           'text', NULL, cat_id, 1),
    (s_connect, 'Wi‑Fi Web Service Support',       'wifi_web_service_support',       'text', NULL, cat_id, 1),

    (s_display, 'LCD Coverage',                    'lcd_coverage',                   'text', NULL, cat_id, 1),
    (s_display, 'LCD Brightness Control',          'lcd_brightness_control',         'text', NULL, cat_id, 1),
    (s_display, 'LCD Coating',                     'lcd_coating',                    'text', NULL, cat_id, 1),
    (s_display, 'Interface Languages',             'interface_languages',            'text', NULL, cat_id, 1),

    (s_optics,  'Focus Method',                    'focus_method',                   'text', NULL, cat_id, 2),

    (s_image,   'RAW + JPEG/HEIF Simultaneous Recording', 'raw_jpeg_heif_simultaneous_recording', 'text', NULL, cat_id, 2),
    (s_image,   'Color Space',                     'color_space',                    'text', NULL, cat_id, 2),

    (s_physical,'Working Temperature Range',       'working_temperature_range',      'text', NULL, cat_id, 1),

    (s_other,   'Histogram',                       'histogram',                      'text', NULL, cat_id, 1),
    (s_other,   'Quick Control Function',          'quick_control_function',         'text', NULL, cat_id, 1)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Re-seed mapping rules (safe to re-run)
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT
    sd.id,
    v.extraction_pattern,
    v.context_pattern,
    v.priority,
    v.notes
  FROM (
    VALUES
      ('wifi_transmission_method',        '^transmission\\s*method$',                       'wi-?fi',     80, 'Canon: Wi‑Fi Transmission Method under Wi‑Fi section'),
      ('bluetooth_transmission_method',   '^transmission\\s*method$',                       'bluetooth',  80, 'Canon: Bluetooth Transmission Method under Bluetooth section'),
      ('wifi_standards_compliance',       '^standards\\s*compliance$',                      'wi-?fi',     80, 'Canon: Wi‑Fi Standards Compliance'),
      ('bluetooth_standards_compliance',  '^standards\\s*compliance$',                      'bluetooth',  80, 'Canon: Bluetooth Standards Compliance'),
      ('wifi_frequency_central',          '^transition\\s*frequency\\s*\\(central\\s*frequency\\)$', 'wi-?fi', 75, 'Canon: Wi‑Fi frequency (central)'),
      ('wifi_smartphone_support',         '^communication\\s*with\\s*a\\s*smartphone$',      'wi-?fi',     70, 'Canon: Wi‑Fi smartphone support label'),
      ('wifi_eos_utility_support',        '^remote\\s*operation\\s*using\\s*eos\\s*utility$', 'wi-?fi',    70, 'Canon: Wi‑Fi EOS Utility support label'),
      ('wifi_printer_support',            '^print\\s*from\\s*wi-?fi\\W*printers$',           'wi-?fi',     70, 'Canon: Wi‑Fi printer support label'),
      ('wifi_web_service_support',        '^send\\s*images\\s*to\\s*a\\s*web\\s*service$',   'wi-?fi',     70, 'Canon: Wi‑Fi web service support label'),

      ('lcd_coverage',                    '^coverage$',                                     '^lcd\\s*(screen|monitor)$', 75, 'Canon: LCD coverage'),
      ('lcd_brightness_control',          '^brightness\\s*control$',                         '^lcd\\s*(screen|monitor)$', 75, 'Canon: LCD brightness control'),
      ('interface_languages',             '^interface\\s*languages$',                         '^lcd\\s*(screen|monitor)$', 75, 'Canon: UI language list'),
      ('screen_dots',                     '^dots$',                                          '^lcd\\s*(screen|monitor)$', 80, 'Canon: LCD dots label variant -> screen_dots'),
      ('lcd_coating',                     '^coating$',                                       '^lcd\\s*(screen|monitor)$', 70, 'Canon: LCD coating'),

      ('headphone_terminal',              '^headphone\\s*terminal$',                          '(interface|external\\s*interface)', 75, 'Canon: headphone terminal details'),

      ('focus_method',                    '^focus\\s*method$',                                '^autofocus$', 75, 'Canon: Focus Method under Autofocus'),

      ('histogram',                       '^histogram$',                                      '^playback$', 70, 'Canon: Histogram under Playback'),
      ('quick_control_function',          '^function$',                                       '^quick\\s*control\\s*function$', 70, 'Canon: Quick Control Function'),

      ('working_temperature_range',        '^working\\s*temperature\\s*range$',               '(operating\\s*environment|working\\s*conditions)', 70, 'Canon: working temperature range'),

      ('raw_jpeg_heif_simultaneous_recording', '^raw\\s*\\+\\s*jpe?g\\s*/\\s*heif\\s*simultaneous\\s*recording$', '^recording\\s*system$', 75, 'Canon: RAW+JPEG/HEIF simultaneous recording'),
      ('color_space',                     '^color\\s*space$',                                 '^recording\\s*system$', 75, 'Canon: Color Space under Recording System')

  ) AS v(normalized_key, extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = v.normalized_key
  WHERE NOT EXISTS (
    SELECT 1
    FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;


