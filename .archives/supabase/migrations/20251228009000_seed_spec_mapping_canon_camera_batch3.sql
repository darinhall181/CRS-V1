-- Seed migration (idempotent): Canon camera mapping batch 3
-- Focus: highest-frequency remaining Canon labels after batches 1-2 (viewfinder, flash, video, Bluetooth).

DO $$
DECLARE
  cat_id UUID;
  s_connect UUID;
  s_display UUID;
  s_image UUID;
  s_photo UUID;
  s_video UUID;
  s_other UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'mirrorless-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=% not found. Run category seeds first.', 'mirrorless-cameras';
  END IF;

  SELECT id INTO s_connect FROM spec_section WHERE section_name='Connectivity'         AND category_id=cat_id;
  SELECT id INTO s_display FROM spec_section WHERE section_name='Display'              AND category_id=cat_id;
  SELECT id INTO s_image   FROM spec_section WHERE section_name='Image'                AND category_id=cat_id;
  SELECT id INTO s_photo   FROM spec_section WHERE section_name='Photography Features' AND category_id=cat_id;
  SELECT id INTO s_video   FROM spec_section WHERE section_name='Videography Features' AND category_id=cat_id;
  SELECT id INTO s_other   FROM spec_section WHERE section_name='Other Features'       AND category_id=cat_id;

  -- Add missing definitions (safe to re-run)
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_photo,   'Continuous Flash Control',        'continuous_flash_control',        'text', NULL, cat_id, 1),
    (s_photo,   'Accessory Shoe',                 'accessory_shoe',                 'text', NULL, cat_id, 1),

    (s_display, 'Viewfinder Magnification/Angle of View', 'viewfinder_magnification_angle_of_view', 'text', NULL, cat_id, 1),
    (s_display, 'Viewfinder Dioptric Adjustment Range',   'viewfinder_dioptric_adjustment_range',   'text', NULL, cat_id, 1),
    (s_display, 'Viewfinder Information',          'viewfinder_information',          'text', NULL, cat_id, 1),

    (s_image,   'Still Photo IS',                 'still_photo_is',                 'text', NULL, cat_id, 1),

    (s_video,   'Time Code',                      'time_code',                      'text', NULL, cat_id, 2),

    (s_connect, 'Bluetooth Pairing',              'bluetooth_pairing',              'text', NULL, cat_id, 1),
    (s_connect, 'Wi‑Fi Connection Method',        'wifi_connection_method',         'text', NULL, cat_id, 1),

    (s_other,   'Compatible Printers',            'compatible_printers',            'text', NULL, cat_id, 1)
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
      -- External Speedlite
      ('continuous_flash_control',        '^continuous\\s*flash\\s*control$',      '^external\\s*speedlite$', 75, 'Canon: Continuous flash control'),
      ('accessory_shoe',                 '^accessory\\s*shoe$',                    '^external\\s*speedlite$', 75, 'Canon: Accessory shoe'),

      -- Viewfinder
      ('viewfinder_magnification_angle_of_view', '^magnification\\s*/\\s*angle\\s*of\\s*view$', '^viewfinder$', 75, 'Canon: Magnification / Angle of View'),
      ('viewfinder_dioptric_adjustment_range',   '^dioptric\\s*adjustment\\s*range$',           '^viewfinder$', 75, 'Canon: Dioptric adjustment range'),
      ('viewfinder_information',                 '^viewfinder\\s*information$',                 '^viewfinder$', 70, 'Canon: Viewfinder information (long list)'),

      -- Direct Printing
      ('compatible_printers',                   '^compatible\\s*printers$',                    '^direct\\s*printing$', 70, 'Canon: Compatible printers (often Not supported)'),

      -- Image Stabilization (IS mode)
      ('still_photo_is',                        '^still\\s*photo\\s*is$',                       '^image\\s*stabilization\\s*\\(is\\s*mode\\)$', 70, 'Canon: Still Photo IS'),

      -- Video Shooting
      ('time_code',                              '^time\\s*code$',                               '^video\\s*shooting$', 75, 'Canon: Time Code'),
      -- Map existing Tier-1 definition, but section is Video Shooting (Canon), not exposure/metering.
      ('exposure_compensation',                  '^exposure\\s*compensation$',                   '^video\\s*shooting$', 80, 'Canon: Exposure compensation under Video Shooting'),

      -- LCD Screen
      ('touch_screen',                           '^touch[-\\s]*screen\\s*operation$',            '^lcd\\s*screen$', 80, 'Canon: Touch-screen Operation under LCD Screen'),

      -- Bluetooth / Wi‑Fi
      ('bluetooth_pairing',                      '^bluetooth\\s*pairing$',                       'bluetooth', 75, 'Canon: Bluetooth Pairing'),
      ('wifi_connection_method',                 '^connection\\s*method$',                        'wi-?fi', 75, 'Canon: Wi‑Fi Connection Method')

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


