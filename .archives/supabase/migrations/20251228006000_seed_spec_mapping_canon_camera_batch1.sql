-- Seed migration (idempotent): Canon camera mapping batch 1 (UI-top specs)
-- Focus: add missing spec_definitions + Canon section-scoped mapping rules.

DO $$
DECLARE
  cat_id UUID;

  s_general UUID;
  s_sensor UUID;
  s_image UUID;
  s_optics UUID;
  s_display UUID;
  s_photo UUID;
  s_physical UUID;
  s_other UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'mirrorless-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=% not found. Run category seeds first.', 'mirrorless-cameras';
  END IF;

  -- Reuse existing section taxonomy from seed.sql
  SELECT id INTO s_general  FROM spec_section WHERE section_name='General'              AND category_id=cat_id;
  SELECT id INTO s_sensor   FROM spec_section WHERE section_name='Image Sensor'         AND category_id=cat_id;
  SELECT id INTO s_image    FROM spec_section WHERE section_name='Image'                AND category_id=cat_id;
  SELECT id INTO s_optics   FROM spec_section WHERE section_name='Optics & Focus'       AND category_id=cat_id;
  SELECT id INTO s_display  FROM spec_section WHERE section_name='Display'              AND category_id=cat_id;
  SELECT id INTO s_photo    FROM spec_section WHERE section_name='Photography Features' AND category_id=cat_id;
  SELECT id INTO s_physical FROM spec_section WHERE section_name='Physical'             AND category_id=cat_id;
  SELECT id INTO s_other    FROM spec_section WHERE section_name='Other Features'       AND category_id=cat_id;

  -- Add missing definitions (safe to re-run)
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_optics,  'Compatible Lenses',          'compatible_lenses',          'text',   NULL,  cat_id, 7),

    (s_sensor,  'Color Filter System',        'color_filter_system',        'text',   NULL,  cat_id, 3),
    (s_sensor,  'Total Pixels',               'total_pixels',               'number', 'MP',  cat_id, 3),
    (s_sensor,  'Low Pass Filter',            'low_pass_filter',            'text',   NULL,  cat_id, 2),
    (s_sensor,  'Dust Deletion Feature',      'dust_deletion_feature',      'text',   NULL,  cat_id, 2),

    (s_image,   'Recording Format',           'recording_format',           'text',   NULL,  cat_id, 3),
    (s_image,   'Image Format',               'image_format',               'text',   NULL,  cat_id, 3),
    (s_image,   'File Numbering',             'file_numbering',             'text',   NULL,  cat_id, 2),
    (s_image,   'Picture Style',              'picture_style',              'text',   NULL,  cat_id, 3),
    (s_image,   'White Balance Settings',     'white_balance_settings',     'text',   NULL,  cat_id, 3),
    (s_image,   'Auto White Balance',         'auto_white_balance',         'text',   NULL,  cat_id, 2),
    (s_image,   'White Balance Shift',        'white_balance_shift',        'text',   NULL,  cat_id, 2),

    (s_display, 'LCD Type',                   'lcd_type',                   'text',   NULL,  cat_id, 3),
    (s_display, 'Viewfinder Eye Point',       'viewfinder_eye_point',       'text',   NULL,  cat_id, 2),

    (s_photo,   'Metering Range',             'metering_range',             'text',   NULL,  cat_id, 2),
    (s_photo,   'AE Lock',                    'ae_lock',                    'text',   NULL,  cat_id, 2),
    (s_photo,   'Shutter Type',               'shutter_type',               'text',   NULL,  cat_id, 3),
    (s_photo,   'Shutter Speeds',             'shutter_speeds',             'text',   NULL,  cat_id, 3),
    (s_photo,   'X-sync Speed',               'x_sync_speed',               'text',   NULL,  cat_id, 2),
    (s_photo,   'Shutter Release',            'shutter_release',            'text',   NULL,  cat_id, 1),
    (s_photo,   'Flash Exposure Compensation','flash_exposure_compensation','text',   NULL,  cat_id, 2),
    (s_photo,   'E-TTL Balance',              'e_ttl_balance',              'text',   NULL,  cat_id, 1),

    (s_physical,'Start-up Time',              'startup_time',               'text',   NULL,  cat_id, 1),

    (s_other,   'Highlight Alert',            'highlight_alert',            'text',   NULL,  cat_id, 1),
    (s_other,   'Protection',                 'protection',                 'text',   NULL,  cat_id, 1),
    (s_other,   'Erase',                      'erase',                      'text',   NULL,  cat_id, 1),
    (s_other,   'DPOF',                       'dpof',                       'text',   NULL,  cat_id, 1)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Canon section-scoped mapping rules (idempotent)
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT
    sd.id,
    v.extraction_pattern,
    v.context_pattern,
    v.priority,
    v.notes
  FROM (
    VALUES
      -- Type section
      ('compatible_lenses',           '^compatible\\s*lenses$',                 '^type$',                        90, 'Canon: Compatible Lenses under Type'),

      -- Image Sensor section
      ('color_filter_system',         '^color\\s*filter\\s*system$',            'image\\s*sensor',                80, 'Canon: Color Filter System under Image Sensor'),
      ('total_pixels',                '^total\\s*pixels$',                      'image\\s*sensor',                80, 'Canon: Total Pixels under Image Sensor'),
      ('low_pass_filter',             '^low\\s*pass\\s*filter$',                'image\\s*sensor',                75, 'Canon: Low Pass Filter under Image Sensor'),
      ('dust_deletion_feature',       '^dust\\s*deletion\\s*feature$',          'image\\s*sensor',                75, 'Canon: Dust Deletion Feature under Image Sensor'),

      -- Recording System section
      ('recording_format',            '^recording\\s*format$',                  '^recording\\s*system$',          80, 'Canon: Recording Format under Recording System'),
      ('image_format',                '^image\\s*format$',                      '^recording\\s*system$',          80, 'Canon: Image Format under Recording System'),
      ('file_numbering',              '^file\\s*numbering$',                    '^recording\\s*system$',          75, 'Canon: File Numbering under Recording System'),
      ('picture_style',               '^picture\\s*style$',                     '^recording\\s*system$',          75, 'Canon: Picture Style under Recording System'),

      -- White Balance section
      ('white_balance_settings',      '^settings$',                             '^white\\s*balance$',             75, 'Canon: WB Settings under White Balance'),
      ('auto_white_balance',          '^auto\\s*white\\s*balance$',             '^white\\s*balance$',             70, 'Canon: Auto White Balance under White Balance'),
      ('white_balance_shift',         '^white\\s*balance\\s*shift$',            '^white\\s*balance$',             70, 'Canon: WB Shift under White Balance'),

      -- Display / playback
      ('lcd_type',                    '^type$',                                 '^lcd\\s*screen$',                75, 'Canon: LCD Screen Type'),
      ('viewfinder_eye_point',        '^eye\\s*point$',                          '^viewfinder$',                   70, 'Canon: Viewfinder Eye Point'),
      ('highlight_alert',             '^highlight\\s*alert$',                    '^playback$',                     70, 'Canon: Highlight Alert under Playback'),

      -- Exposure / shutter / flash
      ('metering_range',              '^metering\\s*range$',                     '^exposure\\s*control$',          70, 'Canon: Metering Range under Exposure Control'),
      ('ae_lock',                     '^ae\\s*lock$',                            '^exposure\\s*control$',          70, 'Canon: AE Lock under Exposure Control'),
      ('shutter_type',                '^type$',                                  '^shutter$',                      70, 'Canon: Shutter Type'),
      ('shutter_speeds',              '^shutter\\s*speeds?$',                    '^shutter$',                      70, 'Canon: Shutter Speeds'),
      ('x_sync_speed',                'x-?sync\\s*speed',                        '^shutter$',                      70, 'Canon: X-sync Speed'),
      ('shutter_release',             '^shutter\\s*release$',                    '^shutter$',                      65, 'Canon: Shutter Release'),
      ('self_timer',                  '^self\\s*timer$',                         '^shutter$',                      65, 'Canon: Self Timer under Shutter'),
      ('flash_exposure_compensation', '^flash\\s*exposure\\s*compensation$',     '^external\\s*speedlite$',        65, 'Canon: Flash Exposure Compensation'),
      ('e_ttl_balance',               'e-?ttl\\s*balance',                        '^external\\s*speedlite$',        60, 'Canon: E-TTL balance'),

      -- Physical / power
      ('startup_time',                'start-?up\\s*time',                       '^power\\s*source$',              60, 'Canon: Start-up Time under Power Source'),
      ('dimensions',                  '^dimensions(\\b|\\s*\\()','dimensions\\s*and\\s*weight',          85, 'Canon: Dimensions (W x H x D) under Dimensions and Weight'),
      ('weight',                      '^weight$',                                'dimensions\\s*and\\s*weight',    85, 'Canon: Weight under Dimensions and Weight'),

      -- Other
      ('protection',                  '^protection$',                            'image\\s*protection\\s*and\\s*erase', 60, 'Canon: Protection under Image Protection and Erase'),
      ('erase',                       '^erase$',                                 'image\\s*protection\\s*and\\s*erase', 60, 'Canon: Erase under Image Protection and Erase'),
      ('dpof',                        '^dpof$',                                  'dpof',                           60, 'Canon: DPOF under DPOF section')

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


