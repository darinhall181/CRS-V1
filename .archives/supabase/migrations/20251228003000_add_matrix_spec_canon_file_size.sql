-- Add a matrix spec definition for Canon \"File Size\" table (still images).
-- This enables mapping the HTML table to a canonical spec_definition and later persisting into product_spec_matrix.

DO $$
DECLARE
  cat_id UUID;
  s_storage UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'mirrorless-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=% not found. Run category seeds first.', 'mirrorless-cameras';
  END IF;

  -- Use existing Storage section for camera media-related tables.
  SELECT id INTO s_storage FROM spec_section WHERE section_name='Storage' AND category_id=cat_id;
  IF s_storage IS NULL THEN
    -- Fallback: create if missing
    INSERT INTO spec_section (section_name, category_id, display_order)
    VALUES ('Storage', cat_id, 80)
    ON CONFLICT (section_name, category_id) DO NOTHING;
    SELECT id INTO s_storage FROM spec_section WHERE section_name='Storage' AND category_id=cat_id;
  END IF;

  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance)
  VALUES (s_storage, 'Still Image File Size Table', 'still_image_file_size_table', 'matrix', 'MB', cat_id, 5)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- Map the Canon \"File Size\" label (within Recording System section) to the matrix spec.
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (
    VALUES
      ('file\\s*size', 'recording\\s*system', 95, 'Canon: still image file size table under Recording System')
  ) AS v(extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = 'still_image_file_size_table'
  WHERE NOT EXISTS (
    SELECT 1
    FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;

