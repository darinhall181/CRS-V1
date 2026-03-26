-- Batch 4: fill remaining gaps found after batch3 normalization pass
-- Fixes too-short regex ranges and adds missing context variants.

DO $$
BEGIN
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (VALUES

    -- === Aperture Blades under Lens and Main Unit Spec ===
    -- Existing rule only covers optical_design context
    ('aperture_blades', 'aperture\\s*blades?',              '^lens$',                 82, 'Canon lens: Aperture Blades under Lens'),
    ('aperture_blades', 'aperture\\s*blades?',              'main\\s*unit\\s*spec',   80, 'Canon lens: Aperture Blades under Main Unit Spec'),

    -- === Special Elements under Lens and Main Unit Spec ===
    -- Existing rule only covers optical_design context
    ('lens_special_elements', 'special\\s*(lens\\s*)?elements?', '^lens$',            82, 'Canon lens: Special Elements under Lens'),
    ('lens_special_elements', 'special\\s*(lens\\s*)?elements?', 'main\\s*unit\\s*spec', 80, 'Canon lens: Special Elements under Main Unit Spec'),

    -- === Dimensions under Main Unit Spec (singular, not covered by batch3) ===
    -- batch3 covered physical_attributes and main_unit_specs (plural) but missed singular
    ('lens_dimensions', '^dimensions$',                     'main\\s*unit\\s*spec',   83, 'Canon lens: Dimensions under Main Unit Spec'),

    -- === Minimum Overall Length ===
    ('lens_dimensions', 'min(imum)?\\s*overall\\s*length',  '^lens$',                 78, 'Canon lens: Minimum Overall Length under Lens'),
    ('lens_dimensions', 'min(imum)?\\s*overall\\s*length',  'main\\s*unit\\s*spec',   76, 'Canon lens: Minimum Overall Length under Main Unit Spec'),

    -- === Front Diameter → filter thread diameter ===
    -- Cinema lenses list the front element diameter separately
    ('filter_thread_diameter', 'front\\s*diameter',         'main\\s*unit\\s*spec',   78, 'Canon lens: Front Diameter under Main Unit Spec'),
    ('filter_thread_diameter', 'front\\s*diameter',         '^general$',              75, 'Canon lens: Front Diameter under General'),
    ('filter_thread_diameter', 'front\\s*diameter',         'physical\\s*attributes', 75, 'Canon lens: Front Diameter under Physical Attributes'),
    ('filter_thread_diameter', 'front\\s*diameter',         'main\\s*unit\\s*specs',  75, 'Canon lens: Front Diameter under Main Unit Specs'),

    -- === Max. Diameter x Length, Weight (batch3 regex too short: used .{0,10}) ===
    -- "Max. Diameter x Length, Weight" has ~14 chars between "diameter" and "weight"
    ('lens_weight', 'max\\.?\\s*diameter.{0,25}weight',     'main\\s*unit\\s*spec',   80, 'Canon lens: Max Diameter+Length+Weight under Main Unit Spec'),
    ('lens_weight', 'max\\.?\\s*diameter.{0,25}weight',     'physical\\s*attributes', 78, 'Canon lens: Max Diameter+Length+Weight under Physical Attributes'),

    -- === Maximum Relative Aperture under Optical Brightness (cinema) ===
    ('lens_aperture_range', 'maximum\\s*relative\\s*aperture', 'optical\\s*brightness', 82, 'Canon lens: Max Relative Aperture under Optical Brightness'),
    ('lens_aperture_range', 'maximum\\s*photometric\\s*aperture', 'optical\\s*brightness', 80, 'Canon lens: Max Photometric Aperture under Optical Brightness'),

    -- === Focusing Method → focus drive system ===
    ('focus_drive_system', 'focus(ing)?\\s*method',         'main\\s*unit\\s*specs',  82, 'Canon lens: Focusing Method under Main Unit Specs'),
    ('focus_drive_system', 'focus(ing)?\\s*method',         'autofocus',              80, 'Canon lens: Focusing Method under Autofocus'),
    ('focus_drive_system', 'focus(ing)?\\s*method',         'main\\s*unit\\s*spec',   78, 'Canon lens: Focusing Method under Main Unit Spec'),

    -- === MOD From Front of Lens → min focus distance ===
    -- Different from "MOD from image sensor" but the closest existing definition
    ('min_focus_distance', 'mod\\s*from\\s*front',          'scene\\s*composition',   76, 'Canon lens: MOD from Front under Scene Composition'),
    ('min_focus_distance', 'mod\\s*from\\s*front',          'main\\s*unit\\s*spec',   74, 'Canon lens: MOD from Front under Main Unit Spec'),

    -- === Iris Ring → lens control ring (cinema manual iris control) ===
    ('lens_control_ring', 'iris\\s*ring',                   'exterior\\s*design',     78, 'Canon lens: Iris Ring under Exterior Design'),
    ('lens_control_ring', 'iris\\s*ring',                   'main\\s*unit\\s*spec',   75, 'Canon lens: Iris Ring under Main Unit Spec')

  ) AS v(normalized_key, extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = v.normalized_key
  WHERE NOT EXISTS (
    SELECT 1 FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;
