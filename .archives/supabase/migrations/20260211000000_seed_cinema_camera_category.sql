-- Migration: cinema-cameras product category, spec sections, definitions, and mapping rules.
-- Derived from ARRI ALEXA LF and Sony Venice 2 spec sheets.
-- Safe to re-run: all inserts use ON CONFLICT DO NOTHING guards.

DO $$
DECLARE
  cameras_id  UUID;
  cat_id      UUID;

  s_general   UUID;
  s_sensor    UUID;
  s_recording UUID;
  s_optics    UUID;
  s_color     UUID;
  s_audio     UUID;
  s_connect   UUID;
  s_physical  UUID;
BEGIN

  -- ----------------------------------------------------------------
  -- 1. Ensure parent 'cameras' category exists
  -- ----------------------------------------------------------------
  SELECT id INTO cameras_id FROM product_category WHERE slug = 'cameras';
  IF cameras_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=cameras not found. Run category seeds first.';
  END IF;

  -- ----------------------------------------------------------------
  -- 2. Add 'cinema-cameras' subcategory
  -- ----------------------------------------------------------------
  INSERT INTO product_category (name, slug, parent_category_id, display_order, icon_name)
  VALUES ('Cinema Cameras', 'cinema-cameras', cameras_id, 20, 'video')
  ON CONFLICT (slug) DO NOTHING;

  SELECT id INTO cat_id FROM product_category WHERE slug = 'cinema-cameras';

  -- ----------------------------------------------------------------
  -- 3. Spec sections
  -- ----------------------------------------------------------------
  INSERT INTO spec_section (section_name, category_id, display_order) VALUES
    ('General',        cat_id,  10),
    ('Image Sensor',   cat_id,  20),
    ('Recording',      cat_id,  30),
    ('Optics & Mount', cat_id,  40),
    ('Color Science',  cat_id,  50),
    ('Audio',          cat_id,  60),
    ('Connectivity',   cat_id,  70),
    ('Physical',       cat_id,  80)
  ON CONFLICT (section_name, category_id) DO NOTHING;

  SELECT id INTO s_general   FROM spec_section WHERE section_name = 'General'        AND category_id = cat_id;
  SELECT id INTO s_sensor    FROM spec_section WHERE section_name = 'Image Sensor'   AND category_id = cat_id;
  SELECT id INTO s_recording FROM spec_section WHERE section_name = 'Recording'      AND category_id = cat_id;
  SELECT id INTO s_optics    FROM spec_section WHERE section_name = 'Optics & Mount' AND category_id = cat_id;
  SELECT id INTO s_color     FROM spec_section WHERE section_name = 'Color Science'  AND category_id = cat_id;
  SELECT id INTO s_audio     FROM spec_section WHERE section_name = 'Audio'          AND category_id = cat_id;
  SELECT id INTO s_connect   FROM spec_section WHERE section_name = 'Connectivity'   AND category_id = cat_id;
  SELECT id INTO s_physical  FROM spec_section WHERE section_name = 'Physical'       AND category_id = cat_id;

  -- ----------------------------------------------------------------
  -- 4. Spec definitions
  -- Keys are prefixed 'cinema_' where they would collide with mirrorless
  -- definitions (e.g. sensor_size, weight) to keep the category-aware
  -- SpecMapperService from cross-contaminating rules.
  -- ----------------------------------------------------------------

  -- General
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_general, 'Camera Type',        'cinema_body_type',       'text',    NULL,  cat_id, 8),
    (s_general, 'Image Processor',    'cinema_image_processor', 'text',    NULL,  cat_id, 6)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Image Sensor
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_sensor, 'Sensor Type',                   'cinema_sensor_type',              'text',    NULL,  cat_id, 9),
    (s_sensor, 'Sensor Size / Format',           'cinema_sensor_size',              'text',    NULL,  cat_id, 10),
    (s_sensor, 'Sensor Dimensions',              'cinema_sensor_dimensions',        'text',    'mm',  cat_id, 8),
    (s_sensor, 'Dynamic Range',                  'cinema_dynamic_range',            'text',    'stops', cat_id, 10),
    (s_sensor, 'Base ISO / EI',                  'cinema_base_iso',                 'text',    NULL,  cat_id, 9),
    (s_sensor, 'Dual Base ISO',                  'dual_base_iso',                   'boolean', NULL,  cat_id, 7),
    (s_sensor, 'Maximum Frame Rate',             'cinema_max_fps',                  'number',  'fps', cat_id, 8),
    (s_sensor, 'Anamorphic De-squeeze Support',  'anamorphic_desqueeze_supported',  'boolean', NULL,  cat_id, 9),
    (s_sensor, 'Anamorphic Squeeze Factors',     'anamorphic_squeeze_factors',      'text',    NULL,  cat_id, 7)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Recording
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_recording, 'Recording Formats',         'cinema_recording_formats',   'text',    NULL, cat_id, 10),
    (s_recording, 'Recording Media',           'cinema_recording_media',     'text',    NULL, cat_id, 9),
    (s_recording, 'Internal Recording',        'cinema_internal_recording',  'boolean', NULL, cat_id, 8),
    (s_recording, 'Max Recording Resolution',  'cinema_max_resolution',      'text',    NULL, cat_id, 9),
    (s_recording, 'Internal ND Filter',        'cinema_internal_nd',         'text',    NULL, cat_id, 8)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Optics & Mount
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_optics, 'Lens Mount',               'cinema_lens_mount',           'text', NULL, cat_id, 10),
    (s_optics, 'Flange Focal Distance',    'cinema_flange_focal_distance', 'text', 'mm', cat_id, 8),
    (s_optics, 'Lens Metadata Support',    'cinema_lens_metadata',        'text', NULL, cat_id, 6)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Color Science
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_color, 'Log Format',          'cinema_log_format',    'text', NULL, cat_id, 10),
    (s_color, 'Color Space',         'cinema_color_space',   'text', NULL, cat_id, 9),
    (s_color, 'Color Output Modes',  'cinema_color_output',  'text', NULL, cat_id, 7),
    (s_color, 'LUT Support',         'cinema_lut_support',   'boolean', NULL, cat_id, 6)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Audio
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_audio, 'Audio Channels',  'cinema_audio_channels', 'number', NULL,  cat_id, 6),
    (s_audio, 'Audio Format',    'cinema_audio_format',   'text',   NULL,  cat_id, 5),
    (s_audio, 'Audio Input',     'cinema_audio_input',    'text',   NULL,  cat_id, 5)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Connectivity
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_connect, 'Timecode I/O',    'cinema_timecode_io',  'boolean', NULL, cat_id, 8),
    (s_connect, 'Genlock / Sync',  'cinema_genlock',      'boolean', NULL, cat_id, 7),
    (s_connect, 'SDI Outputs',     'cinema_sdi_outputs',  'text',    NULL, cat_id, 7),
    (s_connect, 'HDMI',            'cinema_hdmi',         'text',    NULL, cat_id, 5),
    (s_connect, 'Wi-Fi',           'cinema_wifi',         'boolean', NULL, cat_id, 5),
    (s_connect, 'Ethernet',        'cinema_ethernet',     'boolean', NULL, cat_id, 6),
    (s_connect, 'Remote Control',  'cinema_remote',       'text',    NULL, cat_id, 5)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Physical
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_physical, 'Weight',                 'cinema_weight',         'number', 'g',  cat_id, 7),
    (s_physical, 'Dimensions',             'cinema_dimensions',     'text',   NULL, cat_id, 6),
    (s_physical, 'Power Input',            'cinema_power_input',    'text',   NULL, cat_id, 7),
    (s_physical, 'Power Consumption',      'cinema_power_draw',     'text',   'W',  cat_id, 5),
    (s_physical, 'Operating Temperature',  'cinema_operating_temp', 'text',   NULL, cat_id, 4),
    (s_physical, 'Weather Sealed',         'cinema_weather_sealed', 'boolean', NULL, cat_id, 6)
  ON CONFLICT (normalized_key) DO NOTHING;

END $$;


-- ----------------------------------------------------------------
-- 5. Spec mapping rules
-- Regex patterns cover ARRI and Sony spec sheet label conventions.
-- Run in a separate block so section/definition UUIDs are committed.
-- ----------------------------------------------------------------

DO $$
BEGIN
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (VALUES

    -- === General ===
    ('cinema_body_type',
      '(camera\\s*type|type\\b|body\\s*type)',
      '(general|type)',
      70, 'Cinema: body/camera type'),
    ('cinema_image_processor',
      '(image\\s*processor|processor\\b)',
      '(general)',
      65, 'Cinema: image processor'),

    -- === Image Sensor ===
    ('cinema_sensor_type',
      '(sensor\\s*type|cmos\\b|alev\\b|bsi\\s*cmos)',
      '(image\\s*sensor|sensor)',
      85, 'Cinema: sensor technology (ALEV III, BSI CMOS, etc.)'),
    ('cinema_sensor_size',
      '(sensor\\s*(size|format|mode)|imager\\s*(size|format|mode)|format\\b)',
      '(image\\s*sensor|sensor|imager)',
      90, 'Cinema: sensor format (Large Format, Super 35, Full Frame)'),
    ('cinema_sensor_dimensions',
      '(sensor\\s*(maximum\\s*number\\s*of\\s*photosites\\s*and\\s*size|active\\s*image\\s*area|dimensions?)|photosite\\s*pitch)',
      '(image\\s*sensor|sensor)',
      75, 'Cinema: physical sensor dimensions in mm'),
    ('cinema_dynamic_range',
      '(dynamic\\s*range|latitude\\b|stops?\\s*(of\\s*)?(dynamic\\s*range|latitude))',
      '(image\\s*sensor|sensor|dynamic|latitude|general)',
      90, 'Cinema: dynamic range in stops (ARRI 14+, Venice 2 16)'),
    ('cinema_base_iso',
      '(base\\s*(iso|ei|sensitivity)|exposure\\s*index|native\\s*iso)',
      '(image\\s*sensor|sensor|exposure|iso|general)',
      85, 'Cinema: base EI / ISO (single or dual)'),
    ('dual_base_iso',
      '(dual\\s*base\\s*(iso|ei|sensitivity))',
      '(image\\s*sensor|sensor|exposure|iso)',
      80, 'Cinema: dual base ISO flag (Venice 2, ALEXA 35)'),
    ('cinema_max_fps',
      '(max(imum)?\\s*(frame\\s*rate|fps)|sensor\\s*frame\\s*rates?|high\\s*(frame\\s*rate|speed))',
      '(image\\s*sensor|sensor|frame\\s*rate|recording)',
      80, 'Cinema: maximum sensor frame rate'),
    ('anamorphic_desqueeze_supported',
      '(anamorphic\\s*(de-?squeeze|de\\s*squeeze|support|license|mode)|de-?squeeze)',
      '(image\\s*sensor|sensor|anamorphic|recording|lens)',
      85, 'Cinema: in-camera anamorphic de-squeeze support'),
    ('anamorphic_squeeze_factors',
      '(squeeze\\s*(factor|ratio)|lens\\s*squeeze\\s*factors?|anamorphic\\s*(ratio|squeeze\\s*ratio))',
      '(image\\s*sensor|sensor|anamorphic|recording)',
      80, 'Cinema: supported squeeze ratios (1.25, 1.33, 1.5, 1.65, 1.8, 2.0)'),

    -- === Recording ===
    ('cinema_recording_formats',
      '(recording\\s*format|file\\s*(format|container)|codec\\b|arriraw|x-?ocn|prores\\b)',
      '(recording|format|codec)',
      90, 'Cinema: recording codecs/containers (ARRIRAW, X-OCN, ProRes)'),
    ('cinema_recording_media',
      '(recording\\s*media|storage\\s*media|memory\\s*(card|media)|capture\\s*drive|sxr\\b|axs\\b|sxs\\b|cfast)',
      '(recording|media|storage)',
      85, 'Cinema: recording media type (SXR, AXS, CFast)'),
    ('cinema_internal_recording',
      '(internal\\s*recording|on-?board\\s*recording)',
      '(recording|storage)',
      75, 'Cinema: records internally without external recorder'),
    ('cinema_max_resolution',
      '(max(imum)?\\s*(recording\\s*)?resolution|sensor\\s*active\\s*image\\s*area|recording\\s*file\\s*(container|image)\\s*size)',
      '(recording|resolution|image\\s*sensor)',
      85, 'Cinema: maximum recording resolution (4.5K, 6K, 8.6K)'),
    ('cinema_internal_nd',
      '(internal\\s*(nd|neutral\\s*density)|built.?in\\s*nd|(mechanical|motorized|servo)\\s*nd|fsnd|nd\\s*filter)',
      '(recording|optics|nd|filter|general)',
      80, 'Cinema: internal ND filter type and range'),

    -- === Optics & Mount ===
    ('cinema_lens_mount',
      '(lens\\s*mount|mount\\s*type)',
      '(optics|mount|lens)',
      95, 'Cinema: lens mount (LPL, PL, E-mount lever lock)'),
    ('cinema_flange_focal_distance',
      '(flange\\s*(focal\\s*)?(depth|distance)|ffd\\b)',
      '(optics|mount|lens)',
      85, 'Cinema: flange focal distance in mm'),
    ('cinema_lens_metadata',
      '(lens\\s*(data|metadata|information)|lds\\b|cooke\\s*/i|zeiss\\s*extended|lens\\s*bus)',
      '(optics|mount|lens)',
      70, 'Cinema: supported lens metadata protocols (LDS, /i, eXtended Data)'),

    -- === Color Science ===
    ('cinema_log_format',
      '(log\\s*(format|curve|profile|gamma)|log[-\\s]?c\\b|s-?log\\b|c-?log\\b|log\\s*(c[234]?|2|3)\\b)',
      '(color|log|image|recording)',
      90, 'Cinema: log format (ARRI LogC, S-Log3, C-Log2)'),
    ('cinema_color_space',
      '(color\\s*space|colour\\s*space|gamut|wide\\s*gamut|s-?gamut|arri\\s*wide|rec\\.?\\s*2020)',
      '(color|gamut|image)',
      85, 'Cinema: native color space / gamut'),
    ('cinema_color_output',
      '(color\\s*output|colour\\s*output|look\\s*(output|control)|output\\s*color)',
      '(color|output|image)',
      70, 'Cinema: color output modes (Rec 709, Rec 2020, Log C)'),
    ('cinema_lut_support',
      '(lut\\s*(support|import|loading)|look.?up\\s*table|3d\\s*lut|asc\\s*cdl)',
      '(color|lut|workflow)',
      65, 'Cinema: 3D LUT import/support'),

    -- === Audio ===
    ('cinema_audio_channels',
      '(audio\\s*(channels?|recording)|channel\\s*(audio|count)|\\d+\\s*ch(annel)?)',
      '(audio|sound)',
      70, 'Cinema: number of audio channels'),
    ('cinema_audio_format',
      '(audio\\s*(format|encoding|bit\\s*depth)|pcm\\b|linear\\s*pcm|\\d+.?bit\\s*\\d+\\s*k?hz)',
      '(audio|sound)',
      65, 'Cinema: audio encoding format (PCM, 24-bit 48kHz)'),
    ('cinema_audio_input',
      '(audio\\s*input|xlr\\b|mic\\s*in|line\\s*in|\\d+.?pin.*xlr)',
      '(audio|connectivity)',
      60, 'Cinema: audio input connectors (XLR, etc.)'),

    -- === Connectivity ===
    ('cinema_timecode_io',
      '(timecode|ltc\\b|smpte\\s*timecode|tc\\s*in|tc\\s*out)',
      '(connectivity|timecode|interfaces?)',
      85, 'Cinema: LTC/SMPTE timecode I/O'),
    ('cinema_genlock',
      '(genlock|sync\\s*(in|out|i/o)|tri-?level\\s*sync|bb(black\\s*burst)?)',
      '(connectivity|sync|interfaces?)',
      80, 'Cinema: genlock / external sync'),
    ('cinema_sdi_outputs',
      '(sdi\\s*(output|out|mon)|mon\\s*(out|output)|hd-?sdi|3g-?sdi|6g-?sdi|12g-?sdi)',
      '(connectivity|output|interfaces?)',
      80, 'Cinema: SDI monitor outputs'),
    ('cinema_hdmi',
      '(\\bhdmi\\b)',
      '(connectivity|interfaces?)',
      60, 'Cinema: HDMI output'),
    ('cinema_wifi',
      '(wi-?fi|wlan|wireless\\s*(lan|network)|ieee\\s*802\\.11)',
      '(connectivity|wireless)',
      65, 'Cinema: built-in Wi-Fi'),
    ('cinema_ethernet',
      '(ethernet\\b|\\brj-?45\\b|\\blemo.*ethernet|network\\s*(interface|port))',
      '(connectivity|interfaces?)',
      65, 'Cinema: Ethernet port'),
    ('cinema_remote',
      '(remote\\s*control|web\\s*(remote|interface|control)|rcp\\s*control)',
      '(connectivity|remote)',
      55, 'Cinema: remote control options'),

    -- === Physical ===
    ('cinema_weight',
      '(\\bweight\\b)',
      '(physical|body|dimensions)',
      85, 'Cinema: camera body weight'),
    ('cinema_dimensions',
      '(dimensions?|size\\s*\\(h\\s*[x×]\\s*w|measurements?\\s*\\(h)',
      '(physical|body|dimensions)',
      80, 'Cinema: camera body dimensions'),
    ('cinema_power_input',
      '(power\\s*input|power\\s*supply|bat(tery)?\\s*(connector|adapter|input)|input\\s*voltage|v\\s*dc)',
      '(physical|power)',
      80, 'Cinema: power input spec (voltage, connector type)'),
    ('cinema_power_draw',
      '(power\\s*(consumption|draw|dissipation|requirement)|watt(s|age)?\\b)',
      '(physical|power)',
      70, 'Cinema: power consumption in watts'),
    ('cinema_operating_temp',
      '(operating\\s*temperature|temp(erature)?\\s*(range|operating)|working\\s*temperature)',
      '(physical|environmental)',
      55, 'Cinema: operating temperature range'),
    ('cinema_weather_sealed',
      '(dust.{0,10}(sand|splash|moisture|weather|sealed|proof)|splash\\s*proof|weather\\s*sealed|ingress\\s*protection)',
      '(physical|body|environmental)',
      65, 'Cinema: dust/moisture protection')

  ) AS v(normalized_key, extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = v.normalized_key
  WHERE NOT EXISTS (
    SELECT 1 FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;
