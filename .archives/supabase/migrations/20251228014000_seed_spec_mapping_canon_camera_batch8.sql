-- Seed migration (idempotent): Canon camera mapping batch 8
-- Focus: mop-up of remaining non-folder items (pixels/type ambiguity, low-pass/dust label variants, display sizing).

DO $$
DECLARE
  cat_id UUID;
  s_sensor UUID;
  s_display UUID;
  s_optics UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'mirrorless-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=% not found. Run category seeds first.', 'mirrorless-cameras';
  END IF;

  SELECT id INTO s_sensor  FROM spec_section WHERE section_name='Image Sensor'   AND category_id=cat_id;
  SELECT id INTO s_display FROM spec_section WHERE section_name='Display'        AND category_id=cat_id;
  SELECT id INTO s_optics  FROM spec_section WHERE section_name='Optics & Focus' AND category_id=cat_id;

  -- Add missing definitions (safe to re-run)
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_display, 'Exposure Simulation', 'exposure_simulation', 'text', NULL, cat_id, 1)
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
      -- Pixels label is ambiguous; scope tightly by section
      ('effective_pixels',   '^pixels$',     '^image\\s*sensor$', 85, 'Canon: Image Sensor Pixels -> effective_pixels'),
      ('screen_dots',        '^pixels$',     '^lcd\\s*monitor$',  85, 'Canon: LCD Monitor Pixels (dots) -> screen_dots'),

      -- "Type" label is ambiguous; scope by section
      ('autofocus',          '^type$',       '^autofocus$',       80, 'Canon: Autofocus Type -> autofocus system'),
      ('lcd_type',           '^type$',       '^lcd\\s*monitor$',  80, 'Canon: LCD Monitor Type -> lcd_type'),

      -- Canon label variants
      ('low_pass_filter',    '^low-?pass\\s*filter$', 'image\\s*sensor', 80, 'Canon: Low-pass Filter -> low_pass_filter'),
      ('dust_deletion_feature','^dust\\s*deletion\\s*feature.*self\\s*cleaning\\s*sensor\\s*unit$', 'image\\s*sensor', 80, 'Canon: Dust Deletion Feature (Self Cleaning Sensor Unit) -> dust_deletion_feature'),

      -- LCD Screen label variants
      ('screen_size',        '^size$',       '^lcd\\s*screen$',   75, 'Canon: LCD Screen Size -> screen_size'),
      ('screen_dots',        '^resolution$', '^lcd\\s*screen$',   75, 'Canon: LCD Screen Resolution (dots) -> screen_dots'),
      ('lcd_coating',        '^coatings?$',  '^lcd\\s*screen$',   70, 'Canon: LCD Screen Coatings -> lcd_coating'),

      -- Viewfinder misc (low frequency but clean)
      ('exposure_simulation','^exposure\\s*simulation$', '^viewfinder$', 70, 'Canon: Exposure Simulation')

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


