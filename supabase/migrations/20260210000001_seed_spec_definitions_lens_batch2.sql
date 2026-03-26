-- Batch 2: additional context patterns for lens spec mappings
-- Covers section name variants found in cinema/broadcast lenses (Main Unit Spec, General, etc.)

DO $$
BEGIN
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (VALUES

    -- Weight appears under Lens, General, Main Unit Spec(s) in cinema lenses
    ('lens_weight', '^weight$',          '^lens$',              88, 'Canon lens: Weight under Lens section'),
    ('lens_weight', '^weight$',          '^general$',           85, 'Canon lens: Weight under General'),
    ('lens_weight', '^weight$',          'main\\s*unit\\s*spec', 85, 'Canon lens: Weight under Main Unit Spec'),
    ('lens_weight', 'approx\\.?\\s*mass','main\\s*unit\\s*spec', 80, 'Canon lens: Approx Mass under Main Unit Spec'),

    -- Lens Construction also appears under Lens and Main Unit Spec
    ('lens_construction', 'lens\\s*construction', '^lens$',              83, 'Canon lens: Lens Construction under Lens'),
    ('lens_construction', 'lens\\s*construction', 'main\\s*unit\\s*spec', 80, 'Canon lens: Lens Construction under Main Unit Spec'),

    -- Zoom Ratio appears across many section names
    ('zoom_ratio', 'zoom\\s*ratio', '^general$',           85, 'Canon lens: Zoom Ratio under General'),
    ('zoom_ratio', 'zoom\\s*ratio', 'main\\s*unit\\s*spec', 82, 'Canon lens: Zoom Ratio under Main Unit Spec'),
    ('zoom_ratio', 'zoom\\s*ratio', 'image\\s*composition', 80, 'Canon lens: Zoom Ratio under Image Composition'),
    ('zoom_ratio', 'zoom\\s*ratio', '^product$',           78, 'Canon lens: Zoom Ratio under Product'),

    -- Dust Cap (accessories - not mapped before)
    ('included_lens_cap', 'dust\\s*cap', 'accessories', 68, 'Canon lens: Dust Cap under Accessories'),

    -- Lens Case variants
    ('included_lens_case', 'lens\\s*case', '^lens$', 68, 'Canon lens: Lens Case under Lens'),

    -- Filter size also under Lens section directly
    ('filter_thread_diameter', 'filter\\s*size(\\s*diameter)?', '^lens$', 88, 'Canon lens: Filter Size under Lens'),

    -- Closest Focusing Distance (cinema lenses use this label instead)
    ('min_focus_distance', 'closest\\s*focus(ing)?\\s*distance', 'main\\s*unit\\s*spec', 82, 'Canon lens: Closest Focusing Distance'),
    ('min_focus_distance', 'minimum\\s*shooting\\s*distance',    'main\\s*unit\\s*spec', 80, 'Canon lens: Min Shooting Distance'),
    ('min_focus_distance', 'mod\\s*from\\s*(image\\s*)?sensor',  'main\\s*unit\\s*spec', 78, 'Canon lens: MOD from sensor'),

    -- Focal Length variants in cinema lenses
    ('focal_length', 'focal\\s*length\\s*(range|&)', 'main\\s*unit\\s*spec', 78, 'Canon lens: Focal Length Range under Main Unit Spec'),

    -- Aperture in cinema lenses uses different labels
    ('lens_aperture_range', 'maximum\\s*relative\\s*aperture', 'main\\s*unit\\s*spec', 82, 'Canon lens: Max Relative Aperture'),
    ('lens_aperture_range', 'maximum\\s*photometric\\s*aperture', 'main\\s*unit\\s*spec', 80, 'Canon lens: Max Photometric Aperture'),
    ('lens_aperture_range', 'f-number',                           'main\\s*unit\\s*spec', 78, 'Canon lens: F-Number under Main Unit Spec'),

    -- Physical dimensions in cinema lenses
    ('lens_dimensions', '^(width|height|length)$',               'main\\s*unit\\s*spec', 78, 'Canon lens: W/H/L under Main Unit Spec'),
    ('lens_dimensions', 'dimensions\\s*\\(w\\s*x\\s*h',          'main\\s*unit\\s*spec', 80, 'Canon lens: WxHxL under Main Unit Spec'),
    ('lens_dimensions', 'outer\\s*dimensions',                    'main\\s*unit\\s*spec', 80, 'Canon lens: Outer Dimensions'),
    ('lens_weight',     'approx\\.?\\s*weight',                   'main\\s*unit\\s*spec', 80, 'Canon lens: Approx Weight')

  ) AS v(normalized_key, extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = v.normalized_key
  WHERE NOT EXISTS (
    SELECT 1 FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;