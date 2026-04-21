-- Batch 3: mapping rules for cinema/broadcast lens section variants
-- Covers Physical Attributes, Image Composition, Exterior Design sections
-- and angular/diagonal angle of view label variants.

DO $$
BEGIN
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (VALUES

    -- === Angle of View ===
    -- Cinema lenses use "Angular Field of View" and "Diagonal Angle of View"
    -- under Main Unit Spec / Image Composition instead of plain "Angle of view"
    ('angle_of_view', 'angular\\s*(field\\s*of\\s*)?view',  'main\\s*unit\\s*spec',   85, 'Canon lens: Angular (Field of) View under Main Unit Spec'),
    ('angle_of_view', 'angular\\s*(field\\s*of\\s*)?view',  'image\\s*composition',   83, 'Canon lens: Angular (Field of) View under Image Composition'),
    ('angle_of_view', 'diagonal\\s*angle\\s*of\\s*view',    'main\\s*unit\\s*spec',   82, 'Canon lens: Diagonal Angle of View under Main Unit Spec'),
    ('angle_of_view', 'diagonal\\s*angle\\s*of\\s*view',    'image\\s*composition',   80, 'Canon lens: Diagonal Angle of View under Image Composition'),
    ('angle_of_view', 'angle\\s*of\\s*view',                'main\\s*unit\\s*spec',   80, 'Canon lens: Angle of View under Main Unit Spec'),
    ('angle_of_view', 'angle\\s*of\\s*view',                'image\\s*composition',   78, 'Canon lens: Angle of View under Image Composition'),

    -- === Focal Length under Image Composition (cinema lenses) ===
    ('focal_length', 'focal\\s*length(\\s*range)?',         'image\\s*composition',   82, 'Canon lens: Focal Length (Range) under Image Composition'),

    -- === Weight under Physical Attributes / Physical Specifications ===
    ('lens_weight', '^weight$',                             'physical\\s*attributes', 85, 'Canon lens: Weight under Physical Attributes'),
    ('lens_weight', '^weight$',                             'physical\\s*spec',       82, 'Canon lens: Weight under Physical Spec(ifications)'),
    ('lens_weight', 'max\\.?\\s*diameter.{0,10}weight',     'main\\s*unit\\s*spec',   80, 'Canon lens: Max. Diameter x Length, Weight under Main Unit Spec'),
    ('lens_weight', 'max\\.?\\s*diameter.{0,10}weight',     'physical\\s*attributes', 78, 'Canon lens: Max. Diameter x Length, Weight under Physical Attributes'),

    -- === Dimensions under Physical Attributes / Main Unit Specs (plural) ===
    ('lens_dimensions', '^dimensions$',                     'physical\\s*attributes', 85, 'Canon lens: Dimensions under Physical Attributes'),
    ('lens_dimensions', '^dimensions$',                     'main\\s*unit\\s*specs',  83, 'Canon lens: Dimensions under Main Unit Specs'),
    ('lens_dimensions', '^(width|height|length)$',          'physical\\s*attributes', 78, 'Canon lens: W/H/L under Physical Attributes'),

    -- === Dust / Weather Sealing under Exterior Design ===
    -- Current rule requires context ^lens$; cinema lenses put this under Exterior Design
    ('lens_weather_sealing', 'dust.{0,10}weather',          'exterior\\s*design',     82, 'Canon lens: Dust/Weather under Exterior Design'),
    ('lens_weather_sealing', 'dust.{0,10}weather',          'main\\s*unit\\s*spec',   80, 'Canon lens: Dust/Weather under Main Unit Spec'),

    -- === Max Magnification under Image Composition ===
    ('max_magnification', 'max(imum)?\\s*magnification',    'image\\s*composition',   82, 'Canon lens: Max Magnification under Image Composition'),
    ('max_magnification', 'max(imum)?\\s*magnification',    'main\\s*unit\\s*spec',   80, 'Canon lens: Max Magnification under Main Unit Spec'),

    -- === Min Focus Distance under Image Composition ===
    ('min_focus_distance', 'min(imum)?\\s*focus(ing)?\\s*distance', 'image\\s*composition', 82, 'Canon lens: Min Focus Distance under Image Composition'),

    -- === Image Stabilization under Exterior Design / General ===
    ('lens_image_stabilization', 'image\\s*stabilization', 'exterior\\s*design',      78, 'Canon lens: IS under Exterior Design'),
    ('lens_image_stabilization', 'image\\s*stabilization', '^general$',               75, 'Canon lens: IS under General'),

    -- === Filter Thread Diameter under Physical Attributes ===
    ('filter_thread_diameter', 'filter\\s*size(\\s*diameter)?', 'physical\\s*attributes', 82, 'Canon lens: Filter Size under Physical Attributes'),

    -- === Aperture Blades under Physical Attributes ===
    ('aperture_blades', 'aperture\\s*blades?',              'physical\\s*attributes', 80, 'Canon lens: Aperture Blades under Physical Attributes')

  ) AS v(normalized_key, extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = v.normalized_key
  WHERE NOT EXISTS (
    SELECT 1 FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;
