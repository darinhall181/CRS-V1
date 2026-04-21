-- Seed migration (idempotent): Canon camera mapping coverage for Canon section headings.
-- Goal: reduce `unmapped` from HTML extractions by adding context-specific label variants.

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
      -- Canon uses section "Type" for many Tier-1 fields.
      ('body_type',        '^type$',                               '^type$',              90, 'Canon: body type label under Type section'),
      ('image_processor',  'image\\s*processor|digic',             '^type$',              90, 'Canon: image processor under Type section'),
      ('storage_types',    'recording\\s*media|card\\s*slots?|memory\\s*card', '^type$', 90, 'Canon: recording media under Type section'),
      ('lens_mount',       'lens\\s*mount|mount$',                 '^type$',              95, 'Canon: lens mount under Type section'),

      -- Canon Image Sensor section: key \"Type\" is sensor type; also uses \"Screen Size\" for sensor dimensions.
      ('sensor_type',      '^type$',                               'image\\s*sensor',      95, 'Canon: sensor type label under Image Sensor section'),
      ('sensor_size',      'sensor\\s*size|screen\\s*size',        'image\\s*sensor',      90, 'Canon: sensor size label variants under Image Sensor'),
      ('effective_pixels', 'effective\\s*pixels?',                 'image\\s*sensor',      95, 'Canon: effective pixels (space variant)'),

      -- Viewfinder section: Canon uses short labels.
      ('viewfinder_type',          '^type$',          'viewfinder', 85, 'Canon: viewfinder type label \"Type\" under Viewfinder'),
      ('viewfinder_coverage',      '^coverage$',      'viewfinder', 80, 'Canon: viewfinder coverage label \"Coverage\"'),
      ('viewfinder_magnification', '^magnification$', 'viewfinder', 80, 'Canon: viewfinder magnification label \"Magnification\"'),

      -- Connectivity section: Canon label \"Transmission Method\" maps to wireless.
      ('wireless', 'transmission\\s*method|wi-?fi|bluetooth', '(connectivity|communication)', 80, 'Canon: transmission method / wireless'),

      -- Power Source section: Canon uses \"Battery\".
      ('battery', '^battery$', '(power\\s*source|power)', 80, 'Canon: battery label under Power Source')

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

