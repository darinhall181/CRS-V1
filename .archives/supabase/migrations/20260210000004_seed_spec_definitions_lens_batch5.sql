-- Batch 5: cover additional section contexts for focal_length, focus_drive_system,
-- aperture_blades, lens_dimensions, and fulltime_manual_focus.

DO $$
BEGIN
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (VALUES

    -- === Focal Length under cinema/broadcast sections ===
    -- Existing rule only covers ^lens$ context
    ('focal_length', 'focal\\s*length(\\s*range)?',     '^general$',            85, 'Canon lens: Focal Length under General'),
    ('focal_length', 'focal\\s*length(\\s*range)?',     'main\\s*unit\\s*spec', 83, 'Canon lens: Focal Length under Main Unit Spec'),
    ('focal_length', 'focal\\s*length(\\s*range)?',     'main\\s*unit\\s*specs', 83, 'Canon lens: Focal Length under Main Unit Specs'),

    -- === Focus Drive System under Lens and AF sections ===
    -- Existing rule only covers focusing context
    ('focus_drive_system', 'focus(ing)?\\s*drive\\s*system', '^lens$',           83, 'Canon lens: Focus Drive System under Lens'),
    ('focus_drive_system', 'focus(ing)?\\s*drive\\s*system', '^af$',             80, 'Canon lens: Focus Drive System under AF'),
    ('focus_drive_system', 'focus(ing)?\\s*drive\\s*system', 'main\\s*unit\\s*spec', 78, 'Canon lens: Focus Drive System under Main Unit Spec'),

    -- === Number of Blades → aperture_blades ===
    -- Canon pages use both "Aperture Blades" and "Number of Blades"
    ('aperture_blades', 'number\\s*of\\s*(aperture\\s*)?blades?', 'main\\s*unit\\s*spec',   82, 'Canon lens: Number of Blades under Main Unit Spec'),
    ('aperture_blades', 'number\\s*of\\s*(aperture\\s*)?blades?', 'image\\s*composition',   80, 'Canon lens: Number of Blades under Image Composition'),
    ('aperture_blades', 'number\\s*of\\s*(aperture\\s*)?blades?', '^lens$',                 82, 'Canon lens: Number of Blades under Lens'),
    ('aperture_blades', 'number\\s*of\\s*(aperture\\s*)?blades?', 'optical\\s*design',      80, 'Canon lens: Number of Blades under Optical Design'),

    -- === Maximum Diameter → lens_dimensions ===
    ('lens_dimensions', 'maximum\\s*diameter',           '^lens$',               78, 'Canon lens: Maximum Diameter under Lens'),
    ('lens_dimensions', 'maximum\\s*diameter',           'main\\s*unit\\s*spec', 76, 'Canon lens: Maximum Diameter under Main Unit Spec'),

    -- === Focus Adjustment → fulltime_manual_focus ===
    -- Values are typically "AF with full-time manual" confirming this is the right key
    ('fulltime_manual_focus', 'focus\\s*adjustment',     'main\\s*unit\\s*spec', 78, 'Canon lens: Focus Adjustment under Main Unit Spec'),
    ('fulltime_manual_focus', 'focus\\s*adjustment',     'focusing',             76, 'Canon lens: Focus Adjustment under Focusing'),

    -- === Close-up Lenses (accessories compatibility) ===
    ('included_lens_cap', 'close.?up\\s*lens(es)?',      'accessories',          65, 'Canon lens: Close-up Lens accessory (closest match)'),

    -- === Lens Coating under Lens section (in addition to Optical Design) ===
    ('lens_coating', 'lens\\s*coating',                  '^lens$',               78, 'Canon lens: Lens Coating under Lens'),
    ('lens_coating', 'lens\\s*coating',                  'main\\s*unit\\s*spec', 75, 'Canon lens: Lens Coating under Main Unit Spec'),

    -- === IS Mode variants ===
    ('lens_image_stabilization', 'is\\s*(mode|system)',  'main\\s*unit\\s*spec', 78, 'Canon lens: IS Mode under Main Unit Spec'),
    ('lens_image_stabilization', 'is\\s*(mode|system)',  '^general$',            75, 'Canon lens: IS Mode under General')

  ) AS v(normalized_key, extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = v.normalized_key
  WHERE NOT EXISTS (
    SELECT 1 FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );
END $$;
