-- ─────────────────────────────────────────────────────────────────────────────
-- Section 6g: Cinema lens spec definitions + mapping rules
-- Targets the cinema-lenses category (and subcategories share the same sections).
-- Keys prefixed 'cine_lens_' where they would collide with photo lens keys.
-- ON CONFLICT DO NOTHING — safe to re-run.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  cat_id      UUID;
  s_identity  UUID;
  s_optical   UUID;
  s_physical  UUID;
  s_metadata  UUID;
BEGIN

  SELECT id INTO cat_id FROM product_category WHERE slug = 'cinema-lenses';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: cinema-lenses category not found.';
  END IF;

  -- ── Spec sections ──────────────────────────────────────────────────────────

  INSERT INTO spec_section (section_name, category_id, display_order) VALUES
    ('Lens Identity',    cat_id, 10),
    ('Optical',          cat_id, 20),
    ('Physical',         cat_id, 30),
    ('Metadata & Electronics', cat_id, 40)
  ON CONFLICT (section_name, category_id) DO NOTHING;

  SELECT id INTO s_identity FROM spec_section WHERE section_name = 'Lens Identity'           AND category_id = cat_id;
  SELECT id INTO s_optical  FROM spec_section WHERE section_name = 'Optical'                 AND category_id = cat_id;
  SELECT id INTO s_physical FROM spec_section WHERE section_name = 'Physical'                AND category_id = cat_id;
  SELECT id INTO s_metadata FROM spec_section WHERE section_name = 'Metadata & Electronics' AND category_id = cat_id;

  -- ── Spec definitions ───────────────────────────────────────────────────────

  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES

    -- Identity (importance 9-10: drives compatibility checker)
    (s_identity, 'Lens Mount',         'cine_lens_mount',       'text',    NULL,    cat_id, 10),
    (s_identity, 'Image Circle',        'image_circle_mm',       'numeric', 'mm',    cat_id, 10),
    (s_identity, 'Focal Length',        'cine_focal_length_mm',  'numeric', 'mm',    cat_id, 9),
    (s_identity, 'T-Stop',             'cine_t_stop',           'numeric', 'T',     cat_id, 9),
    (s_identity, 'Sensor Coverage',    'cine_sensor_coverage',  'text',    NULL,    cat_id, 9),
    (s_identity, 'Lens Set',           'lens_set_id',           'text',    NULL,    cat_id, 8),

    -- Optical
    (s_optical,  'Close Focus Distance','cine_close_focus_m',   'numeric', 'm',     cat_id, 6),
    (s_optical,  'Front Diameter',      'cine_front_diameter_mm','numeric','mm',    cat_id, 7),
    (s_optical,  'Iris Gear Pitch',     'cine_gear_pitch',       'text',   'mod',   cat_id, 7),
    (s_optical,  'Focus Gear Pitch',    'cine_focus_gear_pitch', 'text',   'mod',   cat_id, 6),
    (s_optical,  'Zoom Ratio',          'cine_zoom_ratio',       'text',   NULL,    cat_id, 7),
    (s_optical,  'Anamorphic Factor',   'cine_anamorphic_factor','text',   NULL,    cat_id, 8),

    -- Physical
    (s_physical, 'Weight',             'cine_lens_weight_kg',   'numeric', 'kg',    cat_id, 6),
    (s_physical, 'Length',             'cine_lens_length_mm',   'numeric', 'mm',    cat_id, 5),

    -- Metadata & electronics
    (s_metadata, '/i Technology',      'has_i_technology',      'boolean', NULL,    cat_id, 6),
    (s_metadata, 'eXtended Data (LDS)','has_lds_metadata',      'boolean', NULL,    cat_id, 6),
    (s_metadata, 'Electronic Iris',    'has_electronic_iris',   'boolean', NULL,    cat_id, 5)

  ON CONFLICT (normalized_key) DO NOTHING;

END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Spec mapping rules for cinema lens labels
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (VALUES

    ('cine_lens_mount',
      '(lens\\s*mount|mount\\s*type|pl\\s*mount|lpl\\s*mount|ef\\s*mount|e.mount)',
      '(mount|lens|compatibility)',
      95, 'Cinema lens: mount type (PL, LPL, EF, E-Mount)'),

    ('image_circle_mm',
      '(image\\s*circle|covering\\s*power|image\\s*diameter|coverage\\s*circle)',
      '(optical|image\\s*circle|coverage|sensor)',
      90, 'Cinema lens: image circle diameter in mm'),

    ('cine_focal_length_mm',
      '(focal\\s*length\\b)',
      '(lens|optical|specifications?)',
      90, 'Cinema lens: focal length in mm'),

    ('cine_t_stop',
      '(t.?stop|t-?aperture|maximum\\s*aperture|speed)',
      '(optical|aperture|speed|lens)',
      90, 'Cinema lens: maximum T-stop'),

    ('cine_sensor_coverage',
      '(sensor\\s*(coverage|format|compatibility)|covering\\s*(super\\s*35|large\\s*format|full\\s*frame)|format\\s*(coverage|compatibility))',
      '(optical|coverage|sensor|compatibility)',
      85, 'Cinema lens: sensor format coverage (S35, LF, FF)'),

    ('lens_set_id',
      '(lens\\s*set|series\\s*name|product\\s*(family|series|line)|set\\s*(name|identifier))',
      '(general|lens|series|family)',
      70, 'Cinema lens: product family/set identifier (Cooke S4/i, Zeiss Supreme, etc.)'),

    ('cine_close_focus_m',
      '(close\\s*focus|minimum\\s*object\\s*distance|mod\\b|closest\\s*focus(ing)?)',
      '(focusing|optical|specifications?)',
      80, 'Cinema lens: minimum focus distance in metres'),

    ('cine_front_diameter_mm',
      '(front\\s*(diameter|element|clear\\s*aperture)|barrel\\s*diameter)',
      '(physical|exterior|optical)',
      80, 'Cinema lens: front barrel diameter in mm'),

    ('cine_gear_pitch',
      '(iris\\s*gear|gear\\s*pitch|aperture\\s*gear|0\\.4\\s*mod|0\\.8\\s*mod)',
      '(optical|iris|gear|mechanical)',
      85, 'Cinema lens: iris gear pitch (0.4 mod cinema standard)'),

    ('cine_focus_gear_pitch',
      '(focus\\s*gear|focus\\s*ring\\s*gear|0\\.4\\s*mod\\s*focus)',
      '(focusing|gear|mechanical)',
      80, 'Cinema lens: focus ring gear pitch'),

    ('cine_zoom_ratio',
      '(zoom\\s*ratio|\\d+(\\.\\d+)?\\s*[xX]\\s*zoom)',
      '(optical|zoom)',
      75, 'Cinema zoom: zoom ratio (e.g. 12:1)'),

    ('cine_anamorphic_factor',
      '(anamorphic\\s*(factor|ratio|squeeze)|squeeze\\s*(ratio|factor)|a\\s*[12]\\.0)',
      '(optical|anamorphic)',
      85, 'Anamorphic lens: squeeze factor (1.33x, 1.5x, 2x)'),

    ('cine_lens_weight_kg',
      '(\\bweight\\b)',
      '(physical|specifications?)',
      80, 'Cinema lens: weight in kg'),

    ('cine_lens_length_mm',
      '(\\blength\\b|overall\\s*length)',
      '(physical|dimensions?|specifications?)',
      75, 'Cinema lens: barrel length in mm'),

    ('has_i_technology',
      '(/i\\s*technology|cooke\\s*/i|i/i\\s*metadata|intelligent\\s*lens\\s*interface)',
      '(metadata|electronics|lens|connectivity)',
      85, 'Cinema lens: Cooke /i Technology metadata protocol'),

    ('has_lds_metadata',
      '(lds\\b|lens\\s*data\\s*system|extended\\s*data|zeiss\\s*extended|arri\\s*lds)',
      '(metadata|electronics|lens|connectivity)',
      80, 'Cinema lens: LDS / eXtended Data metadata'),

    ('has_electronic_iris',
      '(electronic\\s*iris|motorized\\s*aperture|e-?iris|iris\\s*motor)',
      '(electronics|iris|aperture)',
      75, 'Cinema lens: electronic iris control')

  ) AS v(normalized_key, extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = v.normalized_key
  WHERE NOT EXISTS (
    SELECT 1 FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;
