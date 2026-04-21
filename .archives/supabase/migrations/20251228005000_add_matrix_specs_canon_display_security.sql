-- Add matrix spec definitions + mappings for Canon tables:
-- - Playback > Display Format
-- - Wi‑Fi > Security

DO $$
DECLARE
  cat_id UUID;
  s_playback UUID;
  s_wifi UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'mirrorless-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=% not found. Run category seeds first.', 'mirrorless-cameras';
  END IF;

  -- Sections (create if missing)
  SELECT id INTO s_playback FROM spec_section WHERE section_name='Playback' AND category_id=cat_id;
  IF s_playback IS NULL THEN
    INSERT INTO spec_section (section_name, category_id, display_order)
    VALUES ('Playback', cat_id, 70)
    ON CONFLICT (section_name, category_id) DO NOTHING;
    SELECT id INTO s_playback FROM spec_section WHERE section_name='Playback' AND category_id=cat_id;
  END IF;

  SELECT id INTO s_wifi FROM spec_section WHERE section_name='Wi-Fi' AND category_id=cat_id;
  IF s_wifi IS NULL THEN
    -- Canon sometimes uses Wi‑Fi®; we use the plain "Wi-Fi" section name for canonical grouping.
    INSERT INTO spec_section (section_name, category_id, display_order)
    VALUES ('Wi-Fi', cat_id, 75)
    ON CONFLICT (section_name, category_id) DO NOTHING;
    SELECT id INTO s_wifi FROM spec_section WHERE section_name='Wi-Fi' AND category_id=cat_id;
  END IF;

  -- Matrix spec definitions
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance)
  VALUES (s_playback, 'Playback Display Format Table', 'playback_display_format_table', 'matrix', NULL, cat_id, 3)
  ON CONFLICT (normalized_key) DO NOTHING;

  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance)
  VALUES (s_wifi, 'Wi-Fi Security Table', 'wifi_security_table', 'matrix', NULL, cat_id, 3)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Mappings (tables come through as raw_value="[table]" so we map by label+section)
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (
    VALUES
      ('display\\s*format', 'playback', 90, 'Canon: Playback > Display Format table'),
      ('security', 'wi\\s*[-\\u00ae]?\\s*fi', 90, 'Canon: Wi-Fi > Security table')
  ) AS v(extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON (
    (sd.normalized_key = 'playback_display_format_table' AND v.extraction_pattern = 'display\\s*format')
    OR (sd.normalized_key = 'wifi_security_table' AND v.extraction_pattern = 'security')
  )
  WHERE NOT EXISTS (
    SELECT 1
    FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;

