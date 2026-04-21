-- Fix cinema-lenses spec_mapping rules for Zeiss/Cooke compatibility.
--
-- Problems addressed:
--  1. Context patterns like (physical|specifications?) never match Zeiss section
--     headings which use the focal-length model name (e.g. "CP.3 15mm/T2.9").
--     Solution: clear context_pattern for cinema-lens rules that don't need it,
--     and add "aperture" as an alias inside the cine_t_stop label pattern.
--  2. "Aperture" is a common cinema-lens label for T-stop but the old pattern
--     only matched "T-stop", "T-aperture", "maximum aperture", "speed".
--  3. No spec_definition existed for horizontal angle of view.
--
-- Safe to re-run (uses ON CONFLICT / WHERE NOT EXISTS guards).

DO $$
DECLARE
  cat_id    UUID;
  sec_id    UUID;
  sd_aov_id UUID;
BEGIN

  SELECT id INTO cat_id FROM product_category WHERE slug = 'cinema-lenses';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'cinema-lenses category not found';
  END IF;

  -- ----------------------------------------------------------------
  -- 1. Relax context_pattern for rules that fail on Zeiss-style sections
  --    (sections named after focal-length models, not generic headings).
  --    We NULL out context for the specs that are unambiguous by label alone,
  --    and broaden the pattern for specs that need a slight label fix.
  -- ----------------------------------------------------------------

  -- cine_t_stop: add plain "aperture" to the pattern; drop restrictive context
  UPDATE spec_mapping sm
  SET
    extraction_pattern = '(\\bt.?stop\\b|t-?aperture|maximum\\s*aperture|\\baperture\\b|\\bspeed\\b)',
    context_pattern    = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'cine_t_stop'
    AND sd.category_id    = cat_id;

  -- cine_close_focus_m: drop context (Zeiss calls it "Close Focus N")
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'cine_close_focus_m'
    AND sd.category_id    = cat_id;

  -- cine_lens_length_mm: drop context (Zeiss calls it "Length N")
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'cine_lens_length_mm'
    AND sd.category_id    = cat_id;

  -- cine_lens_weight_kg: drop context (Zeiss calls it "Weight")
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'cine_lens_weight_kg'
    AND sd.category_id    = cat_id;

  -- cine_front_diameter_mm: drop context (Zeiss/Cooke use "Front Diameter" / "Front diameter")
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'cine_front_diameter_mm'
    AND sd.category_id    = cat_id;

  -- cine_focal_length_mm: drop context
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'cine_focal_length_mm'
    AND sd.category_id    = cat_id;

  -- image_circle_mm: drop context
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'image_circle_mm'
    AND sd.category_id    = cat_id;

  -- cine_lens_mount: drop context
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'cine_lens_mount'
    AND sd.category_id    = cat_id;

  -- cine_sensor_coverage: drop context
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'cine_sensor_coverage'
    AND sd.category_id    = cat_id;

  -- cine_anamorphic_factor: drop context
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'cine_anamorphic_factor'
    AND sd.category_id    = cat_id;

  -- has_i_technology: drop context
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'has_i_technology'
    AND sd.category_id    = cat_id;

  -- has_lds_metadata: drop context
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'has_lds_metadata'
    AND sd.category_id    = cat_id;

  -- lens_set_id: drop context
  UPDATE spec_mapping sm
  SET context_pattern = NULL
  FROM spec_definition sd
  WHERE sm.spec_definition_id = sd.id
    AND sd.normalized_key = 'lens_set_id'
    AND sd.category_id    = cat_id;

  -- ----------------------------------------------------------------
  -- 2. Add new spec_definition: cine_horizontal_aov
  --    Zeiss publishes "Horizontal angle of view" per sensor format.
  --    Store as text (e.g. "110.5°") since each format variant
  --    becomes a separate raw attribute anyway.
  -- ----------------------------------------------------------------

  -- Reuse or find the "Optics" section for cinema-lenses
  SELECT id INTO sec_id
  FROM spec_section
  WHERE section_name = 'Optics' AND category_id = cat_id;

  -- Fallback: create section if not yet present
  IF sec_id IS NULL THEN
    INSERT INTO spec_section (section_name, category_id, display_order)
    VALUES ('Optics', cat_id, 20)
    ON CONFLICT (section_name, category_id) DO NOTHING;
    SELECT id INTO sec_id
    FROM spec_section
    WHERE section_name = 'Optics' AND category_id = cat_id;
  END IF;

  INSERT INTO spec_definition
    (section_id, display_name, normalized_key, data_type, unit, category_id, importance)
  VALUES
    (sec_id, 'Horizontal Angle of View', 'cine_horizontal_aov', 'text', 'degrees', cat_id, 5)
  ON CONFLICT (normalized_key) DO NOTHING;
  SELECT id INTO sd_aov_id FROM spec_definition WHERE normalized_key = 'cine_horizontal_aov';

  -- Mapping rule for angle of view (no context needed — label is distinctive)
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT
    sd_aov_id,
    '(horizontal\\s*angle\\s*of\\s*view|h\\.?\\s*fov|hfov|angle\\s*of\\s*view)',
    NULL,
    72,
    'Zeiss/Cooke: horizontal angle of view (per sensor format)'
  WHERE NOT EXISTS (
    SELECT 1 FROM spec_mapping WHERE spec_definition_id = sd_aov_id
  );

END $$;
