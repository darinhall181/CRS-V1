-- Migration: ARRI cinema-camera spec definitions and mapping rules.
--
-- Two parts:
--   1. Widen context_pattern on existing rules whose patterns are correct but
--      whose context strings are too narrow for ARRI's flat "Technical
--      Specifications" section (everything in one section, no sub-headings).
--      The spec_mapper now also tries raw_key as context fallback, so adding
--      the label word to the context is sufficient.
--
--   2. New spec_definitions (+ mapping rules) for ARRI labels that have no
--      existing definition at all.
--
-- Safe to re-run: all inserts use ON CONFLICT DO NOTHING; updates are idempotent.

-- ─────────────────────────────────────────────────────────────────────────────
-- PART 1 – Widen context_pattern on existing cinema-cameras mapping rules
-- ─────────────────────────────────────────────────────────────────────────────

-- cinema_weight  ("Weight" doesn't contain physical/body/dimensions)
UPDATE spec_mapping
SET    context_pattern = '(physical|body|dimensions|weight)'
WHERE  spec_definition_id = (SELECT id FROM spec_definition WHERE normalized_key = 'cinema_weight')
  AND  context_pattern = '(physical|body|dimensions)';

-- cinema_dimensions  ("Measurements (HxWxL)" — add measurements)
UPDATE spec_mapping
SET    context_pattern = '(physical|body|dimensions|measurements)'
WHERE  spec_definition_id = (SELECT id FROM spec_definition WHERE normalized_key = 'cinema_dimensions')
  AND  context_pattern = '(physical|body|dimensions)';

-- cinema_operating_temp  ("Operating Temperature" — add operating|temperature)
UPDATE spec_mapping
SET    context_pattern = '(physical|environmental|operating|temperature)'
WHERE  spec_definition_id = (SELECT id FROM spec_definition WHERE normalized_key = 'cinema_operating_temp')
  AND  context_pattern = '(physical|environmental)';

-- cinema_flange_focal_distance  ("Flange Focal Depth" — add flange|focal|depth)
UPDATE spec_mapping
SET    context_pattern = '(optics|mount|lens|flange|focal|depth)'
WHERE  spec_definition_id = (SELECT id FROM spec_definition WHERE normalized_key = 'cinema_flange_focal_distance')
  AND  context_pattern = '(optics|mount|lens)';

-- anamorphic_squeeze_factors  ("Lens Squeeze Factors" — add lens|squeeze)
UPDATE spec_mapping
SET    context_pattern = '(image\s*sensor|sensor|anamorphic|recording|lens|squeeze)'
WHERE  spec_definition_id = (SELECT id FROM spec_definition WHERE normalized_key = 'anamorphic_squeeze_factors')
  AND  context_pattern = '(image\\s*sensor|sensor|anamorphic|recording)';

-- cinema_sensor_dimensions  ("Photosite Pitch" — add photosite)
UPDATE spec_mapping
SET    context_pattern = '(image\s*sensor|sensor|photosite)'
WHERE  spec_definition_id = (SELECT id FROM spec_definition WHERE normalized_key = 'cinema_sensor_dimensions')
  AND  context_pattern = '(image\\s*sensor|sensor)';


-- ─────────────────────────────────────────────────────────────────────────────
-- PART 2 – New spec_definitions and mapping rules
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  cat_id      UUID;

  s_general   UUID;
  s_sensor    UUID;
  s_recording UUID;
  s_optics    UUID;
  s_color     UUID;
  s_audio     UUID;
  s_connect   UUID;
  s_physical  UUID;
  s_viewfinder UUID;
BEGIN

  SELECT id INTO cat_id FROM product_category WHERE slug = 'cinema-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'cinema-cameras category not found';
  END IF;

  -- Existing sections
  SELECT id INTO s_general   FROM spec_section WHERE section_name = 'General'        AND category_id = cat_id;
  SELECT id INTO s_sensor    FROM spec_section WHERE section_name = 'Image Sensor'   AND category_id = cat_id;
  SELECT id INTO s_recording FROM spec_section WHERE section_name = 'Recording'      AND category_id = cat_id;
  SELECT id INTO s_optics    FROM spec_section WHERE section_name = 'Optics & Mount' AND category_id = cat_id;
  SELECT id INTO s_color     FROM spec_section WHERE section_name = 'Color Science'  AND category_id = cat_id;
  SELECT id INTO s_audio     FROM spec_section WHERE section_name = 'Audio'          AND category_id = cat_id;
  SELECT id INTO s_connect   FROM spec_section WHERE section_name = 'Connectivity'   AND category_id = cat_id;
  SELECT id INTO s_physical  FROM spec_section WHERE section_name = 'Physical'       AND category_id = cat_id;

  -- New section: Display & Viewfinder
  INSERT INTO spec_section (section_name, category_id, display_order)
  VALUES ('Display & Viewfinder', cat_id, 45)
  ON CONFLICT (section_name, category_id) DO NOTHING;
  SELECT id INTO s_viewfinder FROM spec_section WHERE section_name = 'Display & Viewfinder' AND category_id = cat_id;

  -- ── General ──────────────────────────────────────────────────────────────
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_general, 'Software Licenses',       'cinema_software_licenses',  'text', NULL, cat_id, 5),
    (s_general, 'Exposure & Focus Tools',  'cinema_exposure_tools',     'text', NULL, cat_id, 6)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- ── Image Sensor ─────────────────────────────────────────────────────────
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_sensor, 'Photosite Pitch',    'cinema_photosite_pitch', 'text', 'μm', cat_id, 6),
    (s_sensor, 'Shutter',            'cinema_shutter',         'text', NULL, cat_id, 7),
    (s_sensor, 'White Balance',      'cinema_white_balance',   'text', NULL, cat_id, 6)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- ── Recording ────────────────────────────────────────────────────────────
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_recording, 'Recording Frame Rates',     'cinema_recording_frame_rates',  'text', 'fps', cat_id, 8),
    (s_recording, 'Recording Modes',           'cinema_recording_modes',        'text', NULL,  cat_id, 7),
    (s_recording, 'Recording Resolutions',     'cinema_recording_resolutions',  'text', NULL,  cat_id, 8),
    (s_recording, 'Optical Filters',           'cinema_filters',                'text', NULL,  cat_id, 8)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- ── Display & Viewfinder ─────────────────────────────────────────────────
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_viewfinder, 'Viewfinder Technology',       'cinema_viewfinder_type',       'text', NULL, cat_id, 7),
    (s_viewfinder, 'Viewfinder Resolution',       'cinema_viewfinder_resolution', 'text', NULL, cat_id, 6),
    (s_viewfinder, 'Viewfinder Diopter Range',    'cinema_viewfinder_diopter',    'text', NULL, cat_id, 5)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- ── Color Science ────────────────────────────────────────────────────────
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_color, 'Look Control',   'cinema_look_control',  'text', NULL, cat_id, 7),
    (s_color, 'White Balance',  'cinema_white_balance', 'text', NULL, cat_id, 6)  -- already inserted above; ON CONFLICT absorbs
  ON CONFLICT (normalized_key) DO NOTHING;

  -- ── Audio ─────────────────────────────────────────────────────────────────
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_audio, 'Audio Output', 'cinema_audio_output', 'text', NULL, cat_id, 5)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- ── Connectivity ─────────────────────────────────────────────────────────
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_connect, 'Image Outputs',         'cinema_image_outputs',        'text', NULL, cat_id, 8),
    (s_connect, 'Physical Interfaces',   'cinema_interfaces',           'text', NULL, cat_id, 7),
    (s_connect, 'Wireless Interfaces',   'cinema_wireless_interfaces',  'text', NULL, cat_id, 6)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- ── Physical ─────────────────────────────────────────────────────────────
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_physical, 'Power Outputs',         'cinema_power_outputs',   'text', NULL, cat_id, 6),
    (s_physical, 'Storage Temperature',   'cinema_storage_temp',    'text', NULL, cat_id, 4),
    (s_physical, 'Sound Level',           'cinema_sound_level',     'text', 'dB', cat_id, 4)
  ON CONFLICT (normalized_key) DO NOTHING;

END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- Mapping rules for the new definitions
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (VALUES

    -- General
    ('cinema_software_licenses',
      '(software\s*(license|key|option)|license\s*(key|pack)|firmware\s*option)',
      '(general|license|software)',
      60, 'Cinema: optional software licenses / feature keys'),
    ('cinema_exposure_tools',
      '(exposure\s*(and\s*focus\s*)?tools?|false\s*color|zebra|waveform|peaking|focus\s*assist)',
      '(general|image|exposure|focus)',
      60, 'Cinema: on-board exposure and focus assist tools'),

    -- Image Sensor
    ('cinema_photosite_pitch',
      '(photosite\s*pitch|pixel\s*pitch|cell\s*pitch)',
      '(image\s*sensor|sensor|photosite|pitch)',
      70, 'Cinema: photosite / pixel pitch in μm'),
    ('cinema_shutter',
      '(\bshutter\b)',
      '(image\s*sensor|sensor|shutter|recording)',
      75, 'Cinema: shutter type and range (degrees / time)'),
    ('cinema_white_balance',
      '(white\s*balance|color\s*temperature\s*range|colour\s*temperature)',
      '(image\s*sensor|sensor|color|colour|white)',
      70, 'Cinema: white balance range and modes'),

    -- Recording
    ('cinema_recording_frame_rates',
      '(recording\s*frame\s*rates?|capture\s*frame\s*rates?)',
      '(recording|frame\s*rate|capture)',
      80, 'Cinema: per-format recording frame rate range'),
    ('cinema_recording_modes',
      '(recording\s*modes?|capture\s*modes?|pre.?rec(ord)?|intervalometer|stop\s*motion)',
      '(recording|capture|modes?)',
      75, 'Cinema: recording mode options (real-time, pre-rec, intervalometer, stop-motion)'),
    ('cinema_recording_resolutions',
      '(recording\s*file\s*(image\s*content|container|size)|per.?format\s*resolution)',
      '(recording|resolution|format)',
      78, 'Cinema: per-format recording resolution table'),
    ('cinema_filters',
      '(\bfilters?\b(?!\s*type))',
      '(recording|optics|nd|filter|general|filters)',
      72, 'Cinema: optical filter suite (ND, LP, UV, IR)'),

    -- Display & Viewfinder
    ('cinema_viewfinder_type',
      '(viewfinder\s*(technology|type)|evf\s*type|oled\s*viewfinder|lcd\s*(monitor|viewfinder))',
      '(viewfinder|display|evf|monitor)',
      70, 'Cinema: viewfinder/monitor technology (OLED, LCD)'),
    ('cinema_viewfinder_resolution',
      '(viewfinder\s*resolution|evf\s*resolution)',
      '(viewfinder|display|evf|resolution)',
      68, 'Cinema: viewfinder panel resolution in pixels'),
    ('cinema_viewfinder_diopter',
      '(diopter|dioptric\s*adjustment)',
      '(viewfinder|display|evf|diopter)',
      65, 'Cinema: viewfinder diopter adjustment range'),

    -- Color Science
    ('cinema_look_control',
      '(look\s*control|3d\s*lut|asc\s*cdl|look\s*file|alf\b|look\s*management)',
      '(color|look|lut|workflow)',
      72, 'Cinema: in-camera look management (3D LUT, ASC CDL, look files)'),

    -- Audio
    ('cinema_audio_output',
      '(audio\s*output|headphone\s*(output|jack)|monitor\s*out.*audio|line\s*out)',
      '(audio|sound|output)',
      62, 'Cinema: audio monitor/headphone output'),

    -- Connectivity
    ('cinema_image_outputs',
      '(image\s*output|video\s*output|mon(itor)?\s*out(?!put\s*channel))',
      '(connectivity|output|interfaces?|image)',
      75, 'Cinema: all video/image outputs (SDI, HDMI, proprietary)'),
    ('cinema_interfaces',
      '(\binterfaces?\b)',
      '(connectivity|interfaces?|connectors?)',
      65, 'Cinema: all physical I/O connectors (catch-all)'),
    ('cinema_wireless_interfaces',
      '(wireless\s*interfaces?|wi.?fi.*bluetooth|bluetooth.*wi.?fi)',
      '(connectivity|wireless|interfaces?)',
      70, 'Cinema: wireless I/O (Wi-Fi + Bluetooth combined)'),

    -- Physical
    ('cinema_power_outputs',
      '(power\s*outputs?|accessory\s*power|12v\s*out|24v\s*out)',
      '(physical|power|output)',
      68, 'Cinema: accessory power output connectors'),
    ('cinema_storage_temp',
      '(storage\s*temperature|storage\s*temp)',
      '(physical|environmental|storage|temperature)',
      50, 'Cinema: storage temperature range'),
    ('cinema_sound_level',
      '(sound\s*level|noise\s*level|db\s*\(?a\)?|acoustic\s*noise)',
      '(physical|environmental|sound|noise)',
      52, 'Cinema: camera body sound/noise level in dB(A)')

  ) AS v(normalized_key, extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = v.normalized_key
  WHERE NOT EXISTS (
    SELECT 1 FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;
