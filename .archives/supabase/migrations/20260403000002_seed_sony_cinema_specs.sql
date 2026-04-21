-- Migration: Sony cinema-camera spec definitions and mapping rules.
--
-- Three parts:
--   1. Widen context_pattern on existing rules where the extraction pattern
--      is fine but Sony's single flat "Specifications" section means the
--      context fallback (raw_key) doesn't hit the required terms.
--
--   2. New mapping rows for existing spec_definitions covering Sony-specific
--      label wording (e.g. "ISO Sensitivity", "DC Input", "Imaging Device",
--      "HD MONI Output", "Mass", "Gamma Curve", etc.).
--
--   3. New spec_definitions (pixel count, gain, proxy recording) that have
--      no existing definition and appear in at least one Sony camera.
--
-- Safe to re-run: all inserts use ON CONFLICT / WHERE NOT EXISTS guards;
-- updates include the WHERE clause to match only the current pattern value.

-- ─────────────────────────────────────────────────────────────────────────────
-- PART 1 – Widen context_pattern on existing cinema-cameras mapping rules
-- ─────────────────────────────────────────────────────────────────────────────

-- cinema_hdmi  ("HDMI Output" – context fallback doesn't hit connectivity)
UPDATE spec_mapping
SET    context_pattern = '(connectivity|interfaces?|hdmi|output)'
WHERE  spec_definition_id = (SELECT id FROM spec_definition WHERE normalized_key = 'cinema_hdmi')
  AND  context_pattern = '(connectivity|interfaces?)';

-- cinema_genlock  ("Genlock Input", "Genlock input/Ref output")
UPDATE spec_mapping
SET    context_pattern = '(connectivity|sync|interfaces?|genlock|ref)'
WHERE  spec_definition_id = (SELECT id FROM spec_definition WHERE normalized_key = 'cinema_genlock')
  AND  context_pattern = '(connectivity|sync|interfaces?)';

-- cinema_timecode_io  ("TC/UB", "TC input/TC output")
UPDATE spec_mapping
SET    context_pattern = '(connectivity|timecode|interfaces?|tc|ub)'
WHERE  spec_definition_id = (SELECT id FROM spec_definition WHERE normalized_key = 'cinema_timecode_io')
  AND  context_pattern = '(connectivity|timecode|interfaces?)';

-- cinema_recording_media  ("Memory card slot" – label contains 'memory card'
--   which the extraction pattern already catches, but context fails via fallback)
UPDATE spec_mapping
SET    context_pattern = '(recording|media|storage|memory|card)'
WHERE  spec_definition_id = (SELECT id FROM spec_definition WHERE normalized_key = 'cinema_recording_media')
  AND  context_pattern = '(recording|media|storage)';


-- ─────────────────────────────────────────────────────────────────────────────
-- PART 2 – New mapping rows for existing spec_definitions
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (VALUES

    -- ── Image Sensor ─────────────────────────────────────────────────────────

    -- "ISO Sensitivity" (context passes via 'iso' in raw_key; pattern misses)
    ('cinema_base_iso',
      'iso\s*sensitivity',
      '(image\s*sensor|sensor|exposure|iso|general)',
      83, 'Sony: ISO Sensitivity label for base EI/ISO'),

    -- "Imaging Device" → sensor type (single-chip CMOS imager, etc.)
    ('cinema_sensor_type',
      'imaging\s*device\b(?!\s*(size|pixel))',
      '(image\s*sensor|sensor|imaging|device)',
      83, 'Sony: Imaging Device label for sensor technology'),

    -- "Imaging Device Size" → sensor format
    ('cinema_sensor_size',
      'imaging\s*device\s*size',
      '(sensor|imaging|device)',
      88, 'Sony: Imaging Device Size label for sensor format'),

    -- ── Recording ────────────────────────────────────────────────────────────

    -- "Select FPS" → per-format frame rate table
    ('cinema_recording_frame_rates',
      'select\s*fps|\bfps\s*select',
      '(recording|fps|frame\s*rate|capture|select)',
      78, 'Sony: Select FPS per-format frame rate label'),

    -- "Video compression" → recording codec/format
    ('cinema_recording_formats',
      'video\s*compression',
      '(recording|compression|codec|video|format)',
      78, 'Sony: Video compression label for recording format'),

    -- "Slow & Quick Motion (S&Q)" → recording mode
    ('cinema_recording_modes',
      'slow\s*(&|and)\s*quick|s\s*&\s*q\s*motion|slow\s*motion\b|quick\s*motion',
      '(recording|capture|modes?|slow|motion)',
      73, 'Sony: Slow & Quick Motion (S&Q) recording mode label'),

    -- "Proxy recording" mapped here as a mode option (new full def added in Part 3)
    -- (handled via new spec_definition cinema_proxy_recording below)

    -- ── Power ────────────────────────────────────────────────────────────────

    -- "DC Input", "Battery DC Input" → power input
    ('cinema_power_input',
      'battery\s*dc\s*input|(?<!\w)dc\s*input',
      '(physical|power|dc|battery|input)',
      78, 'Sony: DC Input / Battery DC Input power connector labels'),

    -- "Battery" standalone → power input
    ('cinema_power_input',
      '\bbattery\b',
      '(physical|power|battery)',
      70, 'Sony/generic: standalone Battery label for power input'),

    -- "DC Output" → accessory power output
    -- (context passes via 'output' in raw_key; extraction pattern misses)
    ('cinema_power_outputs',
      '\bdc\s*out(put)?\b',
      '(physical|power|output|dc)',
      66, 'Sony: DC Output label for accessory power output'),

    -- ── Connectivity ─────────────────────────────────────────────────────────

    -- "HD MONI Output" → SDI/image monitor output
    ('cinema_image_outputs',
      'hd[\s\-]*moni|moni\s*out(put)?',
      '(connectivity|output|interfaces?|moni|sdi)',
      73, 'Sony: HD MONI Output label for SDI monitor output'),

    -- "Remote", "Remote terminal" → remote control connector
    -- (context already passes via 'remote' in raw_key; pattern too strict)
    ('cinema_remote',
      '\bremote\b',
      '(connectivity|remote)',
      53, 'Sony/generic: standalone Remote or Remote terminal label'),

    -- "Network", "LAN terminal" → Ethernet
    ('cinema_ethernet',
      '\bnetwork\b|\blan\b|\blan\s*terminal\b',
      '(connectivity|network|interfaces?|lan|ethernet)',
      63, 'Sony: Network / LAN terminal label for Ethernet port'),

    -- "TC/UB", "TC input/TC output" → timecode I/O
    ('cinema_timecode_io',
      'tc\s*/\s*ub|tc\s*(input|output)',
      '(connectivity|timecode|interfaces?|tc|ub)',
      83, 'Sony: TC/UB and TC input / TC output labels'),

    -- "VF" → viewfinder connector (physical, not the viewfinder type)
    ('cinema_interfaces',
      '\bvf\b',
      '(connectivity|interfaces?|vf|viewfinder|connector)',
      40, 'Sony: VF connector label (viewfinder physical pin connector)'),

    -- "AUX" (BNC timecode output on Venice)
    ('cinema_interfaces',
      '\baux\b',
      '(connectivity|interfaces?|aux)',
      40, 'Sony: AUX connector label'),

    -- "USB"
    ('cinema_interfaces',
      '\busb\b',
      '(connectivity|interfaces?|usb)',
      45, 'Sony: USB host interface label'),

    -- "Lens" (physical 12-pin lens communication bus connector)
    ('cinema_interfaces',
      'lens\s*(connector|bus|port|pin)|\blens\b',
      '(connectivity|interfaces?|connector|pin)',
      38, 'Sony: Lens connector physical interface (low priority, avoids lens_mount)'),

    -- ── Audio ─────────────────────────────────────────────────────────────────

    -- "Speaker Output", "Speaker"
    ('cinema_audio_output',
      '\bspeaker\s*(output|out|terminal)?\b',
      '(audio|sound|output|speaker)',
      60, 'Sony: Speaker Output / Speaker labels for audio output'),

    -- "Headphone terminal"
    ('cinema_audio_output',
      'headphone\s*(output|jack|terminal)',
      '(audio|sound|output|headphone)',
      62, 'Sony: Headphone terminal label for audio output'),

    -- "Microphone"
    ('cinema_audio_input',
      '\bmicrophone\b|\bmic\b(?!\s*in)',
      '(audio|sound|microphone|mic)',
      58, 'Sony: Microphone label for audio input'),

    -- ── Color Science ────────────────────────────────────────────────────────

    -- "Gamma Curve" → log/color format
    ('cinema_log_format',
      'gamma\s*(curve|profile)',
      '(color|log|gamma|image)',
      78, 'Sony: Gamma Curve label for log/color format'),

    -- ── Physical ────────────────────────────────────────────────────────────

    -- "Mass", "Mass (without lens...)", "Body only", "Body only (oz.)"
    ('cinema_weight',
      '\bmass\b|body\s*only',
      '(physical|body|dimensions|weight|mass)',
      83, 'Sony: Mass / Body only weight labels'),

    -- ── Display & Viewfinder ─────────────────────────────────────────────────

    -- "Number of dots (total)" → LCD/EVF resolution (Burano LCD dot count)
    ('cinema_viewfinder_resolution',
      'number\s*of\s*dots|dot\s*count|(total\s*)?dots\b',
      '(viewfinder|display|evf|resolution|dots|panel)',
      66, 'Sony: Number of dots (total) for LCD/EVF resolution'),

    -- "Touch panel" / "With LCD screen"
    ('cinema_viewfinder_type',
      'touch\s*panel|lcd\s*touch|touch\s*screen|with\s*lcd\s*screen',
      '(viewfinder|display|evf|touch|panel|lcd)',
      65, 'Sony: Touch panel / LCD screen label for display type'),

    -- ── Optics / Lens ─────────────────────────────────────────────────────────

    -- "Lens compensation" → lens correction feature (part of lens metadata support)
    ('cinema_lens_metadata',
      'lens\s*compensation',
      '(optics|mount|lens|compensation)',
      65, 'Sony: Lens compensation / correction feature'),

    -- ── General / Exposure ───────────────────────────────────────────────────

    -- "Recognition target (Movies)" → exposure/focus assist tools
    ('cinema_exposure_tools',
      'recognition\s*target|subject\s*recognition',
      '(general|image|exposure|focus|recognition)',
      58, 'Sony: Recognition target (Movies) AI subject recognition label')

  ) AS v(normalized_key, extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = v.normalized_key
  WHERE NOT EXISTS (
    SELECT 1 FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- PART 3 – New spec_definitions and mapping rules
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  cat_id      UUID;
  s_sensor    UUID;
  s_recording UUID;
BEGIN

  SELECT id INTO cat_id FROM product_category WHERE slug = 'cinema-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'cinema-cameras category not found';
  END IF;

  SELECT id INTO s_sensor    FROM spec_section WHERE section_name = 'Image Sensor' AND category_id = cat_id;
  SELECT id INTO s_recording FROM spec_section WHERE section_name = 'Recording'    AND category_id = cat_id;

  -- ── Image Sensor ─────────────────────────────────────────────────────────

  -- Total/effective pixel count (Venice "50.0 M (Total)", Burano effective pixel count)
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance)
  VALUES (s_sensor, 'Pixel Count', 'cinema_pixel_count', 'text', 'MP', cat_id, 7)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Gain control (Burano: ISO-based exposure gain for Cinema EI workflow)
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance)
  VALUES (s_sensor, 'Gain Control', 'cinema_gain', 'text', NULL, cat_id, 7)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- ── Recording ────────────────────────────────────────────────────────────

  -- Proxy recording capability (Burano: simultaneous proxy record)
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance)
  VALUES (s_recording, 'Proxy Recording', 'cinema_proxy_recording', 'text', NULL, cat_id, 7)
  ON CONFLICT (normalized_key) DO NOTHING;

END $$;


-- Mapping rules for the new definitions
DO $$
BEGIN
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (VALUES

    -- cinema_pixel_count
    ('cinema_pixel_count',
      'imaging\s*device\s*pixel\s*count|number\s*of\s*pixels\s*\(?(effective|total)\)?|total\s*pixels?\b|effective\s*pixels?\b',
      '(image\s*sensor|sensor|pixels?|imaging|count)',
      78, 'Cinema: imaging device / effective / total pixel count'),

    -- cinema_gain
    ('cinema_gain',
      'gain\s*(control|setting|mode|range)?',
      '(image\s*sensor|sensor|exposure|gain|iso)',
      75, 'Cinema: gain control for EI/ISO exposure setting'),

    -- cinema_proxy_recording
    ('cinema_proxy_recording',
      'proxy\s*record(ing)?',
      '(recording|proxy|media|format)',
      75, 'Cinema: proxy recording mode or capability')

  ) AS v(normalized_key, extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = v.normalized_key
  WHERE NOT EXISTS (
    SELECT 1 FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;
