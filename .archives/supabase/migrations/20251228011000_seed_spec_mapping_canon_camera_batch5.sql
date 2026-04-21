-- Seed migration (idempotent): Canon camera mapping batch 5
-- Focus: next highest-frequency labels (ports, Wi‑Fi standards label variant, video focusing, HDR, customization).

DO $$
DECLARE
  cat_id UUID;
  s_sensor UUID;
  s_image UUID;
  s_display UUID;
  s_optics UUID;
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
  SELECT id INTO s_video    FROM spec_section WHERE section_name='Videography Features' AND category_id=cat_id;
  SELECT id INTO s_connect  FROM spec_section WHERE section_name='Connectivity'         AND category_id=cat_id;
  SELECT id INTO s_physical FROM spec_section WHERE section_name='Physical'             AND category_id=cat_id;
  SELECT id INTO s_other    FROM spec_section WHERE section_name='Other Features'       AND category_id=cat_id;

  -- Add missing definitions (safe to re-run)
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    -- Video calls / streaming
    (s_video,   'USB Video Class (UVC)',                 'usb_video_class_uvc',               'text', NULL, cat_id, 1),

    -- Customization
    (s_other,   'Customizable Dials',                    'customizable_dials',                'text', NULL, cat_id, 1),
    (s_other,   'Available Functions',                   'available_functions',               'text', NULL, cat_id, 1),

    -- Ports / terminals (Canon uses Interface section labels)
    (s_connect, 'Microphone Terminal',                   'microphone_terminal',               'text', NULL, cat_id, 1),
    (s_connect, 'Remote Control Terminal',               'remote_control_terminal',           'text', NULL, cat_id, 1),
    (s_connect, 'Video Out Terminal',                    'video_out_terminal',                'text', NULL, cat_id, 1),

    -- Video / live view focusing
    (s_video,   'Focusing (Video/Live View)',            'focusing_video',                    'text', NULL, cat_id, 1),

    -- Image sensor
    (s_sensor,  'Pixel Size',                            'pixel_size',                        'text', NULL, cat_id, 1),

    -- Autofocus
    (s_optics,  'Focusing Brightness Range (Movie)',     'focusing_brightness_range_movie',   'text', NULL, cat_id, 1),
    (s_optics,  'Subject to Detect',                     'subject_to_detect',                 'text', NULL, cat_id, 1),

    -- HDR / recording system details
    (s_other,   'HDR Shooting (HDR PQ)',                 'hdr_shooting_hdr_pq',               'text', NULL, cat_id, 1),
    (s_image,   'HDR Mode Continuous Shooting',          'hdr_mode_continuous_shooting',      'text', NULL, cat_id, 1),
    (s_image,   'Advanced Shooting Operations',          'advanced_shooting_operations',      'text', NULL, cat_id, 1),

    -- Exposure control
    (s_other,   'Exposure Modes',                        'exposure_modes',                    'text', NULL, cat_id, 1),

    -- Flash compatibility
    (s_other,   'Compatible E‑TTL Speedlites',           'compatible_e_ttl_speedlites',       'text', NULL, cat_id, 1)
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
      -- Video Calls / Streaming
      ('usb_video_class_uvc',                 '^usb\\s*video\\s*class\\s*\\(uvc\\)$',          '^video\\s*calls\\s*/\\s*streaming$', 80, 'Canon: UVC label'),

      -- Customization (scope strictly to avoid the weird context bleed seen in report)
      ('customizable_dials',                  '^customizable\\s*dials$',                        '^customization$', 80, 'Canon: customizable dials'),
      ('available_functions',                 '^available\\s*functions$',                        '^customization$', 70, 'Canon: available functions'),

      -- Interface / External Interface (ports)
      ('microphone_terminal',                 '^microphone\\s*terminal$',                        '(interface|external\\s*interface)', 80, 'Canon: microphone terminal (port details)'),
      ('remote_control_terminal',             '^remote\\s*control\\s*terminal$',                 '(interface|external\\s*interface)', 80, 'Canon: remote control terminal'),
      ('video_out_terminal',                  '^video\\s*out\\s*terminal$',                      '^interface$', 80, 'Canon: video out terminal'),

      -- Video Shooting / Live View Functions
      ('focusing_video',                      '^focusing$',                                     '(video\\s*shooting|live\\s*view\\s*functions)', 75, 'Canon: focusing (video/live view)'),

      -- Image sensor
      ('pixel_size',                          '^pixel\\s*size$',                                 '^image\\s*sensor$', 75, 'Canon: pixel size under Image Sensor'),

      -- Autofocus
      ('focusing_brightness_range_movie',     '^focusing\\s*brightness\\s*range\\s*\\(movie\\s*recording\\)$', '^autofocus$', 75, 'Canon: focusing brightness range (movie recording)'),
      ('subject_to_detect',                   '^subject\\s*to\\s*detect$',                        '^autofocus$', 70, 'Canon: subject to detect'),

      -- HDR
      ('hdr_shooting_hdr_pq',                 '^hdr\\s*shooting\\s*\\(hdr\\s*pq\\)$',            '^hdr\\s*shooting$', 75, 'Canon: HDR shooting (HDR PQ)'),
      ('hdr_mode_continuous_shooting',        '^hdr\\s*mode-?continuous\\s*shooting$',            '^recording\\s*system$', 70, 'Canon: HDR mode continuous shooting'),

      -- Recording system misc
      ('advanced_shooting_operations',        '^advanced\\s*shooting\\s*operations$',            '^recording\\s*system$', 70, 'Canon: advanced shooting operations'),

      -- Exposure control
      ('exposure_modes',                      '^exposure\\s*modes$',                              '^exposure\\s*control$', 75, 'Canon: exposure modes'),

      -- Wi‑Fi standards label variant: map into existing `wifi_standards_compliance`
      ('wifi_standards_compliance',           '^supporting\\s*standards$',                        'wi-?fi', 80, 'Canon: Supporting Standards under Wi‑Fi'),

      -- Flash compatibility
      ('compatible_e_ttl_speedlites',         '^compatible\\s*e-?ttl\\s*speedlites$',             '^external\\s*speedlite$', 70, 'Canon: compatible E‑TTL speedlites')

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


