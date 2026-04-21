-- Seed migration (idempotent): Canon camera mapping batch 7
-- Focus: remaining high-value non-folder items after agreeing to skip folder/file-structure metadata.

DO $$
DECLARE
  cat_id UUID;
  s_sensor UUID;
  s_optics UUID;
  s_video UUID;
  s_connect UUID;
  s_image UUID;
  s_display UUID;
  s_other UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'mirrorless-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=% not found. Run category seeds first.', 'mirrorless-cameras';
  END IF;

  SELECT id INTO s_sensor  FROM spec_section WHERE section_name='Image Sensor'         AND category_id=cat_id;
  SELECT id INTO s_optics  FROM spec_section WHERE section_name='Optics & Focus'       AND category_id=cat_id;
  SELECT id INTO s_video   FROM spec_section WHERE section_name='Videography Features' AND category_id=cat_id;
  SELECT id INTO s_connect FROM spec_section WHERE section_name='Connectivity'         AND category_id=cat_id;
  SELECT id INTO s_image   FROM spec_section WHERE section_name='Image'                AND category_id=cat_id;
  SELECT id INTO s_display FROM spec_section WHERE section_name='Display'              AND category_id=cat_id;
  SELECT id INTO s_other   FROM spec_section WHERE section_name='Other Features'       AND category_id=cat_id;

  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_optics,  'Focus Mode Switch',                    'focus_mode_switch',                    'text', NULL, cat_id, 1),
    (s_optics,  'Focusing Brightness Range (Movie)',    'focusing_brightness_range_movie',      'text', NULL, cat_id, 1),
    (s_connect, 'Cloud RAW Processing (image.canon)',   'cloud_raw_processing_image_canon',     'text', NULL, cat_id, 0),

    (s_display, 'Grid Display',                         'grid_display',                         'text', NULL, cat_id, 1),
    (s_image,   'Movie Digital IS',                     'movie_digital_is',                     'text', NULL, cat_id, 1),
    (s_other,   'HDR Mode',                             'hdr_mode',                             'text', NULL, cat_id, 1)
  ON CONFLICT (normalized_key) DO NOTHING;

  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT
    sd.id,
    v.extraction_pattern,
    v.context_pattern,
    v.priority,
    v.notes
  FROM (
    VALUES
      -- Autofocus
      ('focus_mode_switch',                 '^focus\\s*mode\\s*switch$',                      '^autofocus$', 75, 'Canon: focus mode switch'),
      -- Handle both clean and mangled label variants (the @999br/> artifact)
      ('focusing_brightness_range_movie',   '^focusing\\s*brightness\\s*range.*movie\\s*recording\\)?$', '^autofocus$', 80, 'Canon: focusing brightness range (movie recording)'),
      ('focusing_brightness_range_movie',   '^focusing\\s*brightness\\s*range\\s*\\(in\\s*movie\\s*recording\\)$', '^autofocus$', 80, 'Canon: focusing brightness range (in movie recording)'),

      -- Wi‑Fi feature (kept as text; low importance)
      ('cloud_raw_processing_image_canon',  '^cloud\\s*raw\\s*image\\s*processing\\s*via\\s*image\\.canon', 'wi-?fi', 60, 'Canon: Cloud RAW processing via image.canon'),

      -- Grid display appears under Viewfinder and Live View Functions
      ('grid_display',                      '^grid\\s*display$',                               '(viewfinder|live\\s*view\\s*functions)', 70, 'Canon: grid display'),

      -- Movie Digital IS appears in multiple sections
      ('movie_digital_is',                  '^movie\\s*digital\\s*is$',                         '(image\\s*stabilization|video\\s*shooting)', 70, 'Canon: Movie Digital IS'),

      -- HDR mode
      ('hdr_mode',                          '^hdr\\s*mode$',                                   '^hdr\\s*shooting$', 70, 'Canon: HDR mode')

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


