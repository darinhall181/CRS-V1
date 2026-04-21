-- Seed migration (idempotent): Tier-1/Tier-2 spec taxonomy + mapping rules
-- This is intended for Supabase Cloud (runs via `supabase db push`).
-- It is safe to re-run: uses ON CONFLICT / WHERE NOT EXISTS guards.

DO $$
DECLARE
  cat_id UUID;

  s_general UUID;
  s_sensor UUID;
  s_image UUID;
  s_optics UUID;
  s_display UUID;
  s_photo UUID;
  s_video UUID;
  s_storage UUID;
  s_connect UUID;
  s_physical UUID;
  s_other UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'mirrorless-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=% not found. Run category seeds first.', 'mirrorless-cameras';
  END IF;

  -- Sections (attribution groups)
  INSERT INTO spec_section (section_name, category_id, display_order) VALUES
    ('General',              cat_id,  10),
    ('Image Sensor',         cat_id,  20),
    ('Image',                cat_id,  30),
    ('Optics & Focus',       cat_id,  40),
    ('Display',              cat_id,  50),
    ('Photography Features', cat_id,  60),
    ('Videography Features', cat_id,  70),
    ('Storage',              cat_id,  80),
    ('Connectivity',         cat_id,  90),
    ('Physical',             cat_id, 100),
    ('Other Features',       cat_id, 110)
  ON CONFLICT (section_name, category_id) DO NOTHING;

  SELECT id INTO s_general  FROM spec_section WHERE section_name='General'              AND category_id=cat_id;
  SELECT id INTO s_sensor   FROM spec_section WHERE section_name='Image Sensor'         AND category_id=cat_id;
  SELECT id INTO s_image    FROM spec_section WHERE section_name='Image'                AND category_id=cat_id;
  SELECT id INTO s_optics   FROM spec_section WHERE section_name='Optics & Focus'       AND category_id=cat_id;
  SELECT id INTO s_display  FROM spec_section WHERE section_name='Display'              AND category_id=cat_id;
  SELECT id INTO s_photo    FROM spec_section WHERE section_name='Photography Features' AND category_id=cat_id;
  SELECT id INTO s_video    FROM spec_section WHERE section_name='Videography Features' AND category_id=cat_id;
  SELECT id INTO s_storage  FROM spec_section WHERE section_name='Storage'              AND category_id=cat_id;
  SELECT id INTO s_connect  FROM spec_section WHERE section_name='Connectivity'         AND category_id=cat_id;
  SELECT id INTO s_physical FROM spec_section WHERE section_name='Physical'             AND category_id=cat_id;
  SELECT id INTO s_other    FROM spec_section WHERE section_name='Other Features'       AND category_id=cat_id;

  -- General
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_general, 'Price',           'price',           'number', 'USD', cat_id, 9),
    (s_general, 'Body Type',       'body_type',       'text',   NULL,  cat_id, 7),
    (s_general, 'Image Processor', 'image_processor', 'text',   NULL,  cat_id, 7)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Image Sensor
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_sensor, 'Resolution',       'max_resolution',   'text',   NULL,  cat_id, 8),
    (s_sensor, 'Image Ratio',      'image_ratio',      'text',   NULL,  cat_id, 6),
    (s_sensor, 'Effective Pixels', 'effective_pixels', 'number', 'MP',  cat_id, 10),
    (s_sensor, 'Sensor Size',      'sensor_size',      'text',   NULL,  cat_id, 9),
    (s_sensor, 'Sensor Type',      'sensor_type',      'text',   NULL,  cat_id, 9)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Image
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_image, 'Boosted ISO',                     'boosted_iso',                     'range',  'ISO',   cat_id, 7),
    (s_image, 'Custom White Balance',            'custom_white_balance',            'boolean', NULL,   cat_id, 5),
    (s_image, 'Image Stabilization',             'image_stabilization',             'text',    NULL,   cat_id, 7),
    (s_image, 'CIPA Image Stabilization Rating', 'cipa_image_stabilization_rating', 'number',  'stops', cat_id, 6),
    (s_image, 'Uncompressed Format',             'uncompressed_format',             'text',    NULL,   cat_id, 5)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Optics & Focus
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_optics, 'Autofocus',              'autofocus',     'text',   NULL, cat_id, 7),
    (s_optics, 'Number of Focus Points', 'focus_points',  'number', NULL, cat_id, 6),
    (s_optics, 'Lens Mount',             'lens_mount',    'text',   NULL, cat_id, 10)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Display
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_display, 'Articulated LCD',           'articulated_lcd',         'boolean', NULL,   cat_id, 6),
    (s_display, 'Screen Size',              'screen_size',             'number',  'in',   cat_id, 6),
    (s_display, 'Screen Dots',              'screen_dots',             'number',  'dots', cat_id, 5),
    (s_display, 'Touch Screen',             'touch_screen',            'boolean', NULL,   cat_id, 6),
    (s_display, 'Live View',                'live_view',               'boolean', NULL,   cat_id, 4),
    (s_display, 'Viewfinder Type',          'viewfinder_type',         'text',    NULL,   cat_id, 6),
    (s_display, 'Viewfinder Coverage',      'viewfinder_coverage',     'text',    NULL,   cat_id, 5),
    (s_display, 'Viewfinder Magnification', 'viewfinder_magnification','number',  'x',    cat_id, 5),
    (s_display, 'Viewfinder Resolution',    'viewfinder_resolution',   'number',  'dots', cat_id, 4)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Photography Features
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_photo, 'Minimum Shutter Speed',             'min_shutter_speed',             'text',    NULL, cat_id, 5),
    (s_photo, 'Maximum Shutter Speed',             'max_shutter_speed',             'text',    NULL, cat_id, 7),
    (s_photo, 'Maximum Shutter Speed (Electronic)','max_shutter_speed_electronic',  'text',    NULL, cat_id, 7),
    (s_photo, 'Aperture Priority',                 'aperture_priority',             'boolean', NULL, cat_id, 4),
    (s_photo, 'Shutter Priority',                  'shutter_priority',              'boolean', NULL, cat_id, 4),
    (s_photo, 'Manual Exposure Mode',              'manual_exposure_mode',          'boolean', NULL, cat_id, 5),
    (s_photo, 'Built-in Flash',                    'built_in_flash',                'boolean', NULL, cat_id, 5),
    (s_photo, 'Continuous Drive',                  'continuous_drive',              'text',    NULL, cat_id, 6),
    (s_photo, 'Self-timer',                        'self_timer',                    'text',    NULL, cat_id, 4),
    (s_photo, 'Metering Modes',                    'metering_modes',                'list',    NULL, cat_id, 5),
    (s_photo, 'Exposure Compensation',             'exposure_compensation',         'text',    NULL, cat_id, 6),
    (s_photo, 'WB Bracketing',                     'wb_bracketing',                 'boolean', NULL, cat_id, 3)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Videography Features
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_video, 'Video Format', 'video_format', 'text', NULL, cat_id, 6),
    (s_video, 'Video Modes',  'video_modes',  'text', NULL, cat_id, 6),
    (s_video, 'Microphone',   'built_in_microphone', 'boolean', NULL, cat_id, 4),
    (s_video, 'Speaker',      'built_in_speaker',    'boolean', NULL, cat_id, 4)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Storage
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_storage, 'Storage Types', 'storage_types', 'list', NULL, cat_id, 7)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Connectivity
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_connect, 'USB',             'usb',             'text',    NULL, cat_id, 6),
    (s_connect, 'USB Charging',    'usb_charging',    'boolean', NULL, cat_id, 5),
    (s_connect, 'HDMI',            'hdmi',            'text',    NULL, cat_id, 5),
    (s_connect, 'Microphone Port', 'microphone_port', 'boolean', NULL, cat_id, 5),
    (s_connect, 'Headphone Port',  'headphone_port',  'boolean', NULL, cat_id, 5),
    (s_connect, 'Wireless',        'wireless',        'text',    NULL, cat_id, 6),
    (s_connect, 'Wireless Notes',  'wireless_notes',  'text',    NULL, cat_id, 3),
    (s_connect, 'Remote Control',  'remote_control',  'text',    NULL, cat_id, 4)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Physical
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_physical, 'Environmentally Sealed',        'environmentally_sealed', 'boolean', NULL,   cat_id, 5),
    (s_physical, 'Battery',                      'battery',                'text',    NULL,   cat_id, 6),
    (s_physical, 'Battery Description',          'battery_description',    'text',    NULL,   cat_id, 3),
    (s_physical, 'Battery Life (CIPA)',          'battery_life_cipa',      'number',  'shots', cat_id, 6),
    (s_physical, 'Weight (Including Batteries)', 'weight',                 'number',  'g',     cat_id, 7),
    (s_physical, 'Dimensions',                   'dimensions',             'text',    NULL,   cat_id, 6)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Other Features
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_other, 'Timelapse Recording', 'timelapse_recording', 'boolean', NULL, cat_id, 4),
    (s_other, 'GPS',                 'gps',                 'boolean', NULL, cat_id, 4)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Mapping rules (regex + optional context). Avoid exact duplicates via WHERE NOT EXISTS.
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT
    sd.id,
    v.extraction_pattern,
    v.context_pattern,
    v.priority,
    v.notes
  FROM (
    VALUES
      ('price',                 '(price|msrp|list\\s*price|suggested\\s*retail)',                     '(general|pricing)',  90, 'Tier-1: price/MSRP'),
      ('body_type',             '(body\\s*type|camera\\s*type|type\\b)',                              '(general)',          70, 'Tier-1: body/camera type'),
      ('image_processor',       '(image\\s*processor|processor|digic\\s*x|bionz|expeed)',             '(general|image)',    70, 'Tier-1: processor'),

      ('max_resolution',        '(max(imum)?\\s*resolution|recording\\s*pixels|image\\s*size)',       '(image\\s*sensor|image\\s*quality|still\\s*images?)', 70, 'Tier-1: resolution/recording pixels'),
      ('image_ratio',           '(image\\s*ratio|aspect\\s*ratio)',                                   '(image\\s*sensor|image|still\\s*images?)',            60, 'Tier-1: aspect ratio'),
      ('effective_pixels',      '(effective\\s*pixels?|megapixels?|\\bmp\\b)',                        '(image\\s*sensor)', 95, 'Tier-1: effective pixels'),
      ('sensor_size',           '(sensor\\s*size|format\\b|full[-\\s]?frame|aps[-\\s]?c|micro\\s*four\\s*thirds|mft)', '(image\\s*sensor)', 85, 'Tier-1: sensor format/size'),
      ('sensor_type',           '(sensor\\s*type|cmos|ccd|stacked\\s*cmos|bs(i)?\\s*cmos)',           '(image\\s*sensor)', 80, 'Tier-1: sensor technology'),

      ('boosted_iso',           '(boosted\\s*iso|expanded\\s*iso|iso\\s*expand|extended\\s*iso)',     '(image|iso|exposure)', 70, 'Tier-2: expanded ISO'),
      ('custom_white_balance',  '(custom\\s*white\\s*balance|custom\\s*wb\\b)',                       '(white\\s*balance|image)', 60, 'Tier-2: custom WB'),
      ('image_stabilization',   '(image\\s*stabilization|ibis|in-?body\\s*is|stabiliser|stabilizer)', '(image|stabilization)', 70, 'Tier-2: stabilization'),
      ('cipa_image_stabilization_rating','(cipa.*(stops?|steps?)|shake\\s*correction.*stops?)',       '(image|stabilization)', 60, 'Tier-2: CIPA rating'),
      ('uncompressed_format',   '(uncompressed\\s*format|uncompressed\\s*raw|raw\\s*\\(uncompressed\\))','(image|recording|file)', 50, 'Tier-2: uncompressed'),

      ('autofocus',             '(autofocus|auto\\s*focus|af\\b)',                                    '(optics|focus|autofocus)', 70, 'Tier-1: AF'),
      ('focus_points',          '(focus\\s*points?|af\\s*points?)',                                   '(optics|focus|autofocus)', 70, 'Tier-1: AF points'),
      ('lens_mount',            '(lens\\s*mount|mount\\b)',                                            '(mount|optics|lens)',       95, 'Tier-1: mount'),

      ('articulated_lcd',       '(articulated\\s*lcd|vari-?angle|fully\\s*articulated)',              '(display|lcd|screen)', 70, 'Tier-1: articulated'),
      ('screen_size',           '(screen\\s*size|lcd\\s*size|monitor\\s*size)',                       '(display|lcd|screen)', 70, 'Tier-1: screen size'),
      ('screen_dots',           '(screen\\s*dots|lcd\\s*dots|monitor\\s*dots|dot\\s*count)',          '(display|lcd|screen)', 70, 'Tier-1: screen dots'),
      ('touch_screen',          '(touch\\s*screen|touch\\s*panel|touch\\s*operation)',                '(display|lcd|screen)', 65, 'Tier-1: touch'),
      ('live_view',             '(live\\s*view)',                                                     '(display|shooting)',  55, 'Tier-2: live view'),
      ('viewfinder_type',       '(viewfinder\\s*type|electronic\\s*viewfinder|evf\\b|optical\\s*viewfinder|ovf\\b)', '(viewfinder|display)', 70, 'Tier-1: VF type'),
      ('viewfinder_coverage',   '(viewfinder\\s*coverage|coverage\\s*\\(viewfinder\\))',             '(viewfinder|display)', 65, 'Tier-2: VF coverage'),
      ('viewfinder_magnification','(viewfinder\\s*magnification|magnification\\s*\\(viewfinder\\))', '(viewfinder|display)', 65, 'Tier-2: VF magnification'),
      ('viewfinder_resolution', '(viewfinder\\s*resolution|evf\\s*dots|viewfinder\\s*dots)',         '(viewfinder|display)', 60, 'Tier-2: VF dots'),

      ('min_shutter_speed',     '(min(imum)?\\s*shutter\\s*speed|slowest\\s*shutter)',                '(shutter|exposure|photography)', 60, 'Tier-2: min shutter'),
      ('max_shutter_speed_electronic','(max(imum)?\\s*shutter\\s*speed.*electronic|electronic\\s*shutter.*max)', '(shutter|exposure|photography)', 80, 'Tier-1: max shutter (electronic)'),
      ('max_shutter_speed',     '(max(imum)?\\s*shutter\\s*speed|fastest\\s*shutter)',                '(shutter|exposure|photography)', 70, 'Tier-1: max shutter'),
      ('aperture_priority',     '(aperture\\s*priority|\\bav\\b)',                                    '(exposure|shooting\\s*modes?)', 55, 'Tier-2: Av'),
      ('shutter_priority',      '(shutter\\s*priority|\\btv\\b|\\bs\\s*mode\\b)',                     '(exposure|shooting\\s*modes?)', 55, 'Tier-2: Tv/S'),
      ('manual_exposure_mode',  '(manual\\s*exposure|\\bm\\s*mode\\b)',                               '(exposure|shooting\\s*modes?)', 60, 'Tier-1: M mode'),
      ('built_in_flash',        '(built-?in\\s*flash|pop-?up\\s*flash)',                              '(flash|photography)', 60, 'Tier-2: flash'),
      ('continuous_drive',      '(continuous\\s*drive|burst\\s*mode|continuous\\s*shooting)',         '(drive|shooting)', 60, 'Tier-2: drive'),
      ('self_timer',            '(self-?timer|timer\\s*shooting)',                                    '(drive|shooting)', 50, 'Tier-2: timer'),
      ('metering_modes',        '(metering\\s*modes?|metering\\s*method)',                            '(metering|exposure)', 55, 'Tier-2: metering'),
      ('exposure_compensation', '(exposure\\s*compensation|ev\\s*compensation)',                      '(exposure|metering)', 65, 'Tier-1: exp comp'),
      ('wb_bracketing',         '(wb\\s*bracketing|white\\s*balance\\s*bracketing)',                  '(white\\s*balance|bracketing)', 45, 'Tier-2: WB bracketing'),

      ('video_format',          '(video\\s*format|movie\\s*format|recording\\s*format)',              '(video|movie)', 60, 'Tier-1: video format'),
      ('video_modes',           '(video\\s*modes?|movie\\s*modes?|recording\\s*modes?)',              '(video|movie)', 55, 'Tier-1: video modes'),
      ('built_in_microphone',   '(microphone\\b|built-?in\\s*mic)',                                   '(audio|video)', 50, 'Tier-2: mic'),
      ('built_in_speaker',      '(speaker\\b|built-?in\\s*speaker)',                                  '(audio|video)', 50, 'Tier-2: speaker'),

      ('storage_types',         '(storage\\s*types?|recording\\s*media|memory\\s*card|card\\s*slots?)','(storage|recording)', 80, 'Tier-1: storage'),

      ('usb',                   '(\\busb\\b|usb-?c|usb\\s*terminal)',                                 '(connectivity|interface)', 70, 'Tier-1: USB'),
      ('usb_charging',          '(usb\\s*charging|usb\\s*power\\s*delivery|usb\\s*pd\\b)',            '(connectivity|power)', 60, 'Tier-2: USB charging'),
      ('hdmi',                  '(\\bhdmi\\b)',                                                       '(connectivity|interface)', 60, 'Tier-2: HDMI'),
      ('microphone_port',       '(microphone\\s*port|mic\\s*terminal|\\bmic\\s*in\\b)',               '(connectivity|audio)', 60, 'Tier-2: mic port'),
      ('headphone_port',        '(headphone\\s*port|headphone\\s*terminal|\\bphones\\b)',             '(connectivity|audio)', 60, 'Tier-2: headphone'),
      ('wireless',              '(wireless|wi-?fi|bluetooth|wlan)',                                   '(connectivity|wireless)', 70, 'Tier-1: wireless'),
      ('wireless_notes',        '(wireless\\s*notes?|wireless\\s*functions?|network\\s*notes?)',      '(connectivity|wireless)', 40, 'Tier-2: wireless notes'),
      ('remote_control',        '(remote\\s*control|remote\\s*shooting|tethered\\s*shooting)',        '(connectivity)', 45, 'Tier-2: remote'),

      ('environmentally_sealed','(weather\\s*sealed|environmentally\\s*sealed|dust\\s*sealed|splash\\s*proof)', '(physical|body)', 60, 'Tier-2: sealing'),
      ('battery',               '(battery\\b|battery\\s*type|battery\\s*pack)',                       '(power|battery|physical)', 70, 'Tier-1: battery'),
      ('battery_description',   '(battery\\s*description|battery\\s*details)',                        '(power|battery|physical)', 40, 'Tier-2: battery details'),
      ('battery_life_cipa',     '(battery\\s*life.*cipa|cipa\\s*shots|shots\\s*\\(cipa\\))',           '(power|battery|physical)', 70, 'Tier-1: battery life'),
      ('weight',                '(\\bweight\\b|weight\\s*\\(including\\s*batter(y|ies)\\)|weight\\s*\\(with\\s*battery\\))', '(physical|body)', 80, 'Tier-1: weight'),
      ('dimensions',            '(dimensions|size\\s*\\(w\\s*x\\s*h\\s*x\\s*d\\)|width\\s*x\\s*height\\s*x\\s*depth)', '(physical|body)', 80, 'Tier-1: dimensions'),

      ('timelapse_recording',   '(time-?lapse|interval\\s*timer\\s*shooting)',                         '(other|shooting|movie)', 50, 'Tier-2: timelapse'),
      ('gps',                   '(\\bgps\\b|geotag|geotagging)',                                       '(connectivity|other)',  55, 'Tier-2: GPS')
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

-- ------------------------------------------------------------
-- Tier-1/Tier-2 mapping rules (spec_mapping)
-- Goal: cover common label variants with regex + optional section context.
-- NOTE: spec_mapping has no uniqueness constraints; this block tries to be idempotent by avoiding exact duplicates.
-- ------------------------------------------------------------

DO $$
BEGIN
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT
    sd.id,
    v.extraction_pattern,
    v.context_pattern,
    v.priority,
    v.notes
  FROM (
    VALUES
      -- General
      ('price',                 '(price|msrp|list\\s*price|suggested\\s*retail)',                     '(general|pricing)',  90, 'Tier-1: price/MSRP'),
      ('body_type',             '(body\\s*type|camera\\s*type|type\\b)',                              '(general)',          70, 'Tier-1: body/camera type'),
      ('image_processor',       '(image\\s*processor|processor|digic\\s*x|bionz|expeed)',             '(general|image)',    70, 'Tier-1: processor (brand-specific values)'),

      -- Image Sensor
      ('max_resolution',        '(max(imum)?\\s*resolution|recording\\s*pixels|image\\s*size)',       '(image\\s*sensor|image\\s*quality|still\\s*images?)', 70, 'Tier-1: resolution / recording pixels label'),
      ('image_ratio',           '(image\\s*ratio|aspect\\s*ratio)',                                   '(image\\s*sensor|image|still\\s*images?)',            60, 'Tier-1: aspect ratio'),
      ('effective_pixels',      '(effective\\s*pixels?|megapixels?|\\bmp\\b)',                        '(image\\s*sensor)', 95, 'Tier-1: effective pixels'),
      ('sensor_size',           '(sensor\\s*size|format\\b|full[-\\s]?frame|aps[-\\s]?c|micro\\s*four\\s*thirds|mft)', '(image\\s*sensor)', 85, 'Tier-1: sensor format/size'),
      ('sensor_type',           '(sensor\\s*type|cmos|ccd|stacked\\s*cmos|bs(i)?\\s*cmos)',           '(image\\s*sensor)', 80, 'Tier-1: sensor technology'),

      -- Image
      ('boosted_iso',           '(boosted\\s*iso|expanded\\s*iso|iso\\s*expand|extended\\s*iso)',     '(image|iso|exposure)', 70, 'Tier-2: expanded ISO range'),
      ('custom_white_balance',  '(custom\\s*white\\s*balance|custom\\s*wb\\b)',                       '(white\\s*balance|image)', 60, 'Tier-2: custom WB'),
      ('image_stabilization',   '(image\\s*stabilization|ibis|in-?body\\s*is|stabiliser|stabilizer)', '(image|stabilization)', 70, 'Tier-2: stabilization presence/type'),
      ('cipa_image_stabilization_rating','(cipa.*(stops?|steps?)|shake\\s*correction.*stops?)',       '(image|stabilization)', 60, 'Tier-2: CIPA stabilization rating (stops)'),
      ('uncompressed_format',   '(uncompressed\\s*format|uncompressed\\s*raw|raw\\s*\\(uncompressed\\))','(image|recording|file)', 50, 'Tier-2: uncompressed format'),

      -- Optics & Focus
      ('autofocus',             '(autofocus|auto\\s*focus|af\\b)',                                    '(optics|focus|autofocus)', 70, 'Tier-1: AF system'),
      ('focus_points',          '(focus\\s*points?|af\\s*points?)',                                   '(optics|focus|autofocus)', 70, 'Tier-1: AF point count'),
      ('lens_mount',            '(lens\\s*mount|mount\\b)',                                            '(mount|optics|lens)',       95, 'Tier-1: lens mount'),

      -- Display
      ('articulated_lcd',       '(articulated\\s*lcd|vari-?angle|fully\\s*articulated)',              '(display|lcd|screen)', 70, 'Tier-1: articulated screen'),
      ('screen_size',           '(screen\\s*size|lcd\\s*size|monitor\\s*size)',                       '(display|lcd|screen)', 70, 'Tier-1: screen size'),
      ('screen_dots',           '(screen\\s*dots|lcd\\s*dots|monitor\\s*dots|dot\\s*count)',          '(display|lcd|screen)', 70, 'Tier-1: screen resolution/dots'),
      ('touch_screen',          '(touch\\s*screen|touch\\s*panel|touch\\s*operation)',                '(display|lcd|screen)', 65, 'Tier-1: touch'),
      ('live_view',             '(live\\s*view)',                                                     '(display|shooting)',  55, 'Tier-2: live view'),
      ('viewfinder_type',       '(viewfinder\\s*type|electronic\\s*viewfinder|evf\\b|optical\\s*viewfinder|ovf\\b)', '(viewfinder|display)', 70, 'Tier-1: viewfinder type'),
      ('viewfinder_coverage',   '(viewfinder\\s*coverage|coverage\\s*\\(viewfinder\\))',             '(viewfinder|display)', 65, 'Tier-2: VF coverage'),
      ('viewfinder_magnification','(viewfinder\\s*magnification|magnification\\s*\\(viewfinder\\))', '(viewfinder|display)', 65, 'Tier-2: VF magnification'),
      ('viewfinder_resolution', '(viewfinder\\s*resolution|evf\\s*dots|viewfinder\\s*dots)',         '(viewfinder|display)', 60, 'Tier-2: VF dots'),

      -- Photography Features
      ('min_shutter_speed',     '(min(imum)?\\s*shutter\\s*speed|slowest\\s*shutter)',                '(shutter|exposure|photography)', 60, 'Tier-2: min shutter'),
      ('max_shutter_speed_electronic','(max(imum)?\\s*shutter\\s*speed.*electronic|electronic\\s*shutter.*max)', '(shutter|exposure|photography)', 80, 'Tier-1: max shutter (electronic)'),
      ('max_shutter_speed',     '(max(imum)?\\s*shutter\\s*speed|fastest\\s*shutter)',                '(shutter|exposure|photography)', 70, 'Tier-1: max shutter'),
      ('aperture_priority',     '(aperture\\s*priority|\\bav\\b)',                                    '(exposure|shooting\\s*modes?)', 55, 'Tier-2: Av mode'),
      ('shutter_priority',      '(shutter\\s*priority|\\btv\\b|\\bs\\s*mode\\b)',                     '(exposure|shooting\\s*modes?)', 55, 'Tier-2: Tv/S mode'),
      ('manual_exposure_mode',  '(manual\\s*exposure|\\bm\\s*mode\\b)',                               '(exposure|shooting\\s*modes?)', 60, 'Tier-1: Manual mode'),
      ('built_in_flash',        '(built-?in\\s*flash|pop-?up\\s*flash)',                              '(flash|photography)', 60, 'Tier-2: built-in flash'),
      ('continuous_drive',      '(continuous\\s*drive|burst\\s*mode|continuous\\s*shooting)',         '(drive|shooting)', 60, 'Tier-2: drive/burst'),
      ('self_timer',            '(self-?timer|timer\\s*shooting)',                                    '(drive|shooting)', 50, 'Tier-2: self timer'),
      ('metering_modes',        '(metering\\s*modes?|metering\\s*method)',                            '(metering|exposure)', 55, 'Tier-2: metering modes'),
      ('exposure_compensation', '(exposure\\s*compensation|ev\\s*compensation)',                      '(exposure|metering)', 65, 'Tier-1: exposure comp'),
      ('wb_bracketing',         '(wb\\s*bracketing|white\\s*balance\\s*bracketing)',                  '(white\\s*balance|bracketing)', 45, 'Tier-2: WB bracketing'),

      -- Videography Features
      ('video_format',          '(video\\s*format|movie\\s*format|recording\\s*format)',              '(video|movie)', 60, 'Tier-1: video encoding/container'),
      ('video_modes',           '(video\\s*modes?|movie\\s*modes?|recording\\s*modes?)',              '(video|movie)', 55, 'Tier-1: video modes'),
      ('built_in_microphone',   '(microphone\\b|built-?in\\s*mic)',                                   '(audio|video)', 50, 'Tier-2: mic'),
      ('built_in_speaker',      '(speaker\\b|built-?in\\s*speaker)',                                  '(audio|video)', 50, 'Tier-2: speaker'),

      -- Storage
      ('storage_types',         '(storage\\s*types?|recording\\s*media|memory\\s*card|card\\s*slots?)','(storage|recording)', 80, 'Tier-1: storage media'),

      -- Connectivity
      ('usb',                   '(\\busb\\b|usb-?c|usb\\s*terminal)',                                 '(connectivity|interface)', 70, 'Tier-1: USB'),
      ('usb_charging',          '(usb\\s*charging|usb\\s*power\\s*delivery|usb\\s*pd\\b)',            '(connectivity|power)', 60, 'Tier-2: USB charging'),
      ('hdmi',                  '(\\bhdmi\\b)',                                                       '(connectivity|interface)', 60, 'Tier-2: HDMI'),
      ('microphone_port',       '(microphone\\s*port|mic\\s*terminal|\\bmic\\s*in\\b)',               '(connectivity|audio)', 60, 'Tier-2: mic in'),
      ('headphone_port',        '(headphone\\s*port|headphone\\s*terminal|\\bphones\\b)',             '(connectivity|audio)', 60, 'Tier-2: headphone out'),
      ('wireless',              '(wireless|wi-?fi|bluetooth|wlan)',                                   '(connectivity|wireless)', 70, 'Tier-1: wireless'),
      ('wireless_notes',        '(wireless\\s*notes?|wireless\\s*functions?|network\\s*notes?)',      '(connectivity|wireless)', 40, 'Tier-2: wireless notes'),
      ('remote_control',        '(remote\\s*control|remote\\s*shooting|tethered\\s*shooting)',        '(connectivity)', 45, 'Tier-2: remote control'),

      -- Physical
      ('environmentally_sealed','(weather\\s*sealed|environmentally\\s*sealed|dust\\s*sealed|splash\\s*proof)', '(physical|body)', 60, 'Tier-2: sealing'),
      ('battery',              '(battery\\b|battery\\s*type|battery\\s*pack)',                        '(power|battery|physical)', 70, 'Tier-1: battery type'),
      ('battery_description',  '(battery\\s*description|battery\\s*details)',                         '(power|battery|physical)', 40, 'Tier-2: battery description'),
      ('battery_life_cipa',    '(battery\\s*life.*cipa|cipa\\s*shots|shots\\s*\\(cipa\\))',            '(power|battery|physical)', 70, 'Tier-1: battery life (CIPA)'),
      ('weight',               '(\\bweight\\b|weight\\s*\\(including\\s*batter(y|ies)\\)|weight\\s*\\(with\\s*battery\\))', '(physical|body)', 80, 'Tier-1: weight'),
      ('dimensions',           '(dimensions|size\\s*\\(w\\s*x\\s*h\\s*x\\s*d\\)|width\\s*x\\s*height\\s*x\\s*depth)', '(physical|body)', 80, 'Tier-1: dimensions'),

      -- Other Features
      ('timelapse_recording',  '(time-?lapse|interval\\s*timer\\s*shooting)',                         '(other|shooting|movie)', 50, 'Tier-2: timelapse'),
      ('gps',                  '(\\bgps\\b|geotag|geotagging)',                                       '(connectivity|other)',  55, 'Tier-2: GPS/geotagging')
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


-- ------------------------------------------------------------
-- Tier-1 and Tier-2 Attributes
-- ------------------------------------------------------------

DO $$
DECLARE
  cat_id UUID;

  s_general UUID;
  s_sensor UUID;
  s_image UUID;
  s_optics UUID;
  s_display UUID;
  s_photo UUID;
  s_video UUID;
  s_storage UUID;
  s_connect UUID;
  s_physical UUID;
  s_other UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'mirrorless-cameras';

  -- Sections (attribution groups)
  INSERT INTO spec_section (section_name, category_id, display_order) VALUES
    ('General',              cat_id,  10),
    ('Image Sensor',         cat_id,  20),
    ('Image',                cat_id,  30),
    ('Optics & Focus',       cat_id,  40),
    ('Display',              cat_id,  50),
    ('Photography Features', cat_id,  60),
    ('Videography Features', cat_id,  70),
    ('Storage',              cat_id,  80),
    ('Connectivity',         cat_id,  90),
    ('Physical',             cat_id, 100),
    ('Other Features',       cat_id, 110)
  ON CONFLICT (section_name, category_id) DO NOTHING;

  SELECT id INTO s_general  FROM spec_section WHERE section_name='General'              AND category_id=cat_id;
  SELECT id INTO s_sensor   FROM spec_section WHERE section_name='Image Sensor'         AND category_id=cat_id;
  SELECT id INTO s_image    FROM spec_section WHERE section_name='Image'                AND category_id=cat_id;
  SELECT id INTO s_optics   FROM spec_section WHERE section_name='Optics & Focus'       AND category_id=cat_id;
  SELECT id INTO s_display  FROM spec_section WHERE section_name='Display'              AND category_id=cat_id;
  SELECT id INTO s_photo    FROM spec_section WHERE section_name='Photography Features' AND category_id=cat_id;
  SELECT id INTO s_video    FROM spec_section WHERE section_name='Videography Features' AND category_id=cat_id;
  SELECT id INTO s_storage  FROM spec_section WHERE section_name='Storage'              AND category_id=cat_id;
  SELECT id INTO s_connect  FROM spec_section WHERE section_name='Connectivity'         AND category_id=cat_id;
  SELECT id INTO s_physical FROM spec_section WHERE section_name='Physical'             AND category_id=cat_id;
  SELECT id INTO s_other    FROM spec_section WHERE section_name='Other Features'       AND category_id=cat_id;

  -- General
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_general, 'Price',           'price',           'number', 'USD', cat_id, 9),
    (s_general, 'Body Type',       'body_type',       'text',   NULL,  cat_id, 7),
    (s_general, 'Image Processor', 'image_processor', 'text',   NULL,  cat_id, 7)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Image Sensor
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_sensor, 'Resolution',      'max_resolution',   'text',   NULL,  cat_id, 8),
    (s_sensor, 'Image Ratio',     'image_ratio',      'text',   NULL,  cat_id, 6),
    (s_sensor, 'Effective Pixels','effective_pixels', 'number', 'MP',  cat_id, 10),
    (s_sensor, 'Sensor Size',     'sensor_size',      'text',   NULL,  cat_id, 9),
    (s_sensor, 'Sensor Type',     'sensor_type',      'text',   NULL,  cat_id, 9)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Image
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_image, 'Boosted ISO',                    'boosted_iso',                    'range', 'ISO',   cat_id, 7),
    (s_image, 'Custom White Balance',           'custom_white_balance',           'boolean', NULL,  cat_id, 5),
    (s_image, 'Image Stabilization',            'image_stabilization',            'text',   NULL,   cat_id, 7),
    (s_image, 'CIPA Image Stabilization Rating','cipa_image_stabilization_rating','number', 'stops',cat_id, 6),
    (s_image, 'Uncompressed Format',            'uncompressed_format',            'text',   NULL,   cat_id, 5)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Optics & Focus
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_optics, 'Autofocus',               'autofocus',              'text',   NULL, cat_id, 7),
    (s_optics, 'Number of Focus Points',  'focus_points',           'number', NULL, cat_id, 6),
    (s_optics, 'Lens Mount',              'lens_mount',             'text',   NULL, cat_id, 10)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Display
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_display, 'Articulated LCD',           'articulated_lcd',        'boolean', NULL,  cat_id, 6),
    (s_display, 'Screen Size',              'screen_size',            'number',  'in',  cat_id, 6),
    (s_display, 'Screen Dots',              'screen_dots',            'number',  'dots',cat_id, 5),
    (s_display, 'Touch Screen',             'touch_screen',           'boolean', NULL,  cat_id, 6),
    (s_display, 'Live View',                'live_view',              'boolean', NULL,  cat_id, 4),
    (s_display, 'Viewfinder Type',          'viewfinder_type',        'text',    NULL,  cat_id, 6),
    (s_display, 'Viewfinder Coverage',      'viewfinder_coverage',    'text',    NULL,  cat_id, 5),
    (s_display, 'Viewfinder Magnification', 'viewfinder_magnification','number', 'x',   cat_id, 5),
    (s_display, 'Viewfinder Resolution',    'viewfinder_resolution',  'number',  'dots',cat_id, 4)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Photography Features
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_photo, 'Minimum Shutter Speed',            'min_shutter_speed',            'text', NULL, cat_id, 5),
    (s_photo, 'Maximum Shutter Speed',            'max_shutter_speed',            'text', NULL, cat_id, 7),
    (s_photo, 'Maximum Shutter Speed (Electronic)','max_shutter_speed_electronic','text', NULL, cat_id, 7),
    (s_photo, 'Aperture Priority',                'aperture_priority',            'boolean', NULL, cat_id, 4),
    (s_photo, 'Shutter Priority',                 'shutter_priority',             'boolean', NULL, cat_id, 4),
    (s_photo, 'Manual Exposure Mode',             'manual_exposure_mode',         'boolean', NULL, cat_id, 5),
    (s_photo, 'Built-in Flash',                   'built_in_flash',               'boolean', NULL, cat_id, 5),
    (s_photo, 'Continuous Drive',                 'continuous_drive',             'text',    NULL, cat_id, 6),
    (s_photo, 'Self-timer',                       'self_timer',                   'text',    NULL, cat_id, 4),
    (s_photo, 'Metering Modes',                   'metering_modes',               'list',    NULL, cat_id, 5),
    (s_photo, 'Exposure Compensation',            'exposure_compensation',        'text',    NULL, cat_id, 6),
    (s_photo, 'WB Bracketing',                    'wb_bracketing',                'boolean', NULL, cat_id, 3)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Videography Features
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_video, 'Video Format',   'video_format',        'text', NULL, cat_id, 6),
    (s_video, 'Video Modes',    'video_modes',         'text', NULL, cat_id, 6),
    (s_video, 'Microphone',     'built_in_microphone', 'boolean', NULL, cat_id, 4),
    (s_video, 'Speaker',        'built_in_speaker',    'boolean', NULL, cat_id, 4)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Storage
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_storage, 'Storage Types', 'storage_types', 'list', NULL, cat_id, 7)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Connectivity
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_connect, 'USB',             'usb',            'text',    NULL, cat_id, 6),
    (s_connect, 'USB Charging',    'usb_charging',   'boolean', NULL, cat_id, 5),
    (s_connect, 'HDMI',            'hdmi',           'text',    NULL, cat_id, 5),
    (s_connect, 'Microphone Port', 'microphone_port','boolean', NULL, cat_id, 5),
    (s_connect, 'Headphone Port',  'headphone_port', 'boolean', NULL, cat_id, 5),
    (s_connect, 'Wireless',        'wireless',       'text',    NULL, cat_id, 6),
    (s_connect, 'Wireless Notes',  'wireless_notes', 'text',    NULL, cat_id, 3),
    (s_connect, 'Remote Control',  'remote_control', 'text',    NULL, cat_id, 4)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Physical
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_physical, 'Environmentally Sealed', 'environmentally_sealed', 'boolean', NULL, cat_id, 5),
    (s_physical, 'Battery',                'battery',                'text',    NULL, cat_id, 6),
    (s_physical, 'Battery Description',    'battery_description',    'text',    NULL, cat_id, 3),
    (s_physical, 'Battery Life (CIPA)',    'battery_life_cipa',      'number',  'shots', cat_id, 6),
    (s_physical, 'Weight (Including Batteries)', 'weight',           'number',  'g',  cat_id, 7),
    (s_physical, 'Dimensions',             'dimensions',             'text',    NULL, cat_id, 6)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Other Features
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_other, 'Timelapse Recording', 'timelapse_recording', 'boolean', NULL, cat_id, 4),
    (s_other, 'GPS',                 'gps',                 'boolean', NULL, cat_id, 4)
  ON CONFLICT (normalized_key) DO NOTHING;

END $$;