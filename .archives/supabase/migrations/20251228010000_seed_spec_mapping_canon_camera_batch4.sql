-- Seed migration (idempotent): Canon camera mapping batch 4
-- Focus: next highest-frequency Canon labels (environment, autofocus, video, customization, HDR).

DO $$
DECLARE
  cat_id UUID;
  s_sensor UUID;
  s_image UUID;
  s_optics UUID;
  s_display UUID;
  s_photo UUID;
  s_video UUID;
  s_connect UUID;
  s_physical UUID;
  s_other UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'mirrorless-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=% not found. Run category seeds first.', 'mirrorless-cameras';
  END IF;

  SELECT id INTO s_sensor   FROM spec_section WHERE section_name='Image Sensor'         AND category_id=cat_id;
  SELECT id INTO s_image    FROM spec_section WHERE section_name='Image'                AND category_id=cat_id;
  SELECT id INTO s_optics   FROM spec_section WHERE section_name='Optics & Focus'       AND category_id=cat_id;
  SELECT id INTO s_display  FROM spec_section WHERE section_name='Display'              AND category_id=cat_id;
  SELECT id INTO s_photo    FROM spec_section WHERE section_name='Photography Features' AND category_id=cat_id;
  SELECT id INTO s_video    FROM spec_section WHERE section_name='Videography Features' AND category_id=cat_id;
  SELECT id INTO s_connect  FROM spec_section WHERE section_name='Connectivity'         AND category_id=cat_id;
  SELECT id INTO s_physical FROM spec_section WHERE section_name='Physical'             AND category_id=cat_id;
  SELECT id INTO s_other    FROM spec_section WHERE section_name='Other Features'       AND category_id=cat_id;

  -- Add missing definitions (safe to re-run)
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    -- Operating environment / conditions
    (s_physical, 'Working Humidity',                        'working_humidity',                        'text', NULL, cat_id, 1),

    -- Image sensor
    (s_sensor,   'Pixel Unit',                              'pixel_unit',                              'text', NULL, cat_id, 1),

    -- Autofocus / detection capabilities
    (s_optics,   'Focusing Brightness Range (Still Photo)', 'focusing_brightness_range_still',         'text', NULL, cat_id, 1),
    (s_optics,   'Eye Detection',                            'eye_detection',                           'text', NULL, cat_id, 1),
    (s_optics,   'Available Subject Detection',              'available_subject_detection',             'text', NULL, cat_id, 1),

    -- Video
    (s_video,    'Video AF',                                 'video_af',                                'text', NULL, cat_id, 1),
    (s_video,    'Movie Pre-recording',                      'movie_pre_recording',                     'text', NULL, cat_id, 1),

    -- UI / customization
    (s_other,    'Quick Control Screen',                     'quick_control_screen',                    'text', NULL, cat_id, 1),
    (s_other,    'Available Functions',                      'available_functions',                     'text', NULL, cat_id, 1),

    -- HDR
    (s_other,    'Continuous HDR Shooting (Still Images)',   'continuous_hdr_shooting_still_images',    'text', NULL, cat_id, 1)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Canon mapping rules (section-scoped) (safe to re-run)
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT
    sd.id,
    v.extraction_pattern,
    v.context_pattern,
    v.priority,
    v.notes
  FROM (
    VALUES
      -- Operating environment / working conditions
      ('working_humidity',                         '^working\\s*humidity(\\s*range)?$',            '(operating\\s*environment|working\\s*conditions)', 75, 'Canon: working humidity'),
      -- (not in top10 right now, but pairs with humidity)
      ('working_temperature_range',                '^working\\s*temperature\\s*range$',            '(operating\\s*environment|working\\s*conditions)', 75, 'Canon: working temperature'),

      -- Image Sensor
      ('pixel_unit',                               '^pixel\\s*unit$',                               '^image\\s*sensor$', 75, 'Canon: pixel unit under Image Sensor'),

      -- Autofocus
      ('focusing_brightness_range_still',          '^focusing\\s*brightness\\s*range\\s*\\(still\\s*photo\\s*shooting\\)$', '^autofocus$', 75, 'Canon: focusing brightness range (still photo shooting)'),
      ('eye_detection',                            '^eye\\s*detection$',                            '^autofocus$', 75, 'Canon: eye detection'),
      ('available_subject_detection',              '^available\\s*subject\\s*detection$',           '^autofocus$', 75, 'Canon: available subject detection'),

      -- Video Shooting
      ('video_af',                                 '^video\\s*af$',                                 '^video\\s*shooting$', 75, 'Canon: video AF'),
      ('movie_pre_recording',                      '^movie\\s*pre-?recording\\s*\\(on/off\\)$',      '^video\\s*shooting$', 75, 'Canon: movie pre-recording'),

      -- Quick Control / customization
      ('quick_control_screen',                     '^quick\\s*control\\s*screen$',                  '^quick\\s*control\\s*function$', 75, 'Canon: quick control screen'),
      ('available_functions',                      '^available\\s*functions$',                       '^customization$', 75, 'Canon: available functions under Customization'),

      -- HDR
      ('continuous_hdr_shooting_still_images',     '^continuous\\s*hdr\\s*shooting\\s*\\(still\\s*images\\)$', '^hdr\\s*shooting$', 75, 'Canon: continuous HDR shooting (still images)')

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


