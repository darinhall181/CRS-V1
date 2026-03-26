-- Seed migration (idempotent): Canon lens spec sections, definitions, and mapping rules.
-- Covers the highest-frequency unmapped labels from lens extractions.

DO $$
DECLARE
  cat_id UUID;

  s_lens        UUID;
  s_optical     UUID;
  s_focusing    UUID;
  s_exterior    UUID;
  s_physical    UUID;
  s_accessories UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'lenses';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=lenses not found. Run 20251228014500 first.';
  END IF;

  -- ----------------------------------------------------------------
  -- Spec Sections
  -- ----------------------------------------------------------------
  INSERT INTO spec_section (section_name, category_id, display_order) VALUES
    ('Lens',            cat_id, 10),
    ('Optical Design',  cat_id, 20),
    ('Focusing',        cat_id, 30),
    ('Exterior Design', cat_id, 40),
    ('Physical',        cat_id, 50),
    ('Accessories',     cat_id, 60)
  ON CONFLICT (section_name, category_id) DO NOTHING;

  SELECT id INTO s_lens        FROM spec_section WHERE section_name = 'Lens'            AND category_id = cat_id;
  SELECT id INTO s_optical     FROM spec_section WHERE section_name = 'Optical Design'  AND category_id = cat_id;
  SELECT id INTO s_focusing    FROM spec_section WHERE section_name = 'Focusing'        AND category_id = cat_id;
  SELECT id INTO s_exterior    FROM spec_section WHERE section_name = 'Exterior Design' AND category_id = cat_id;
  SELECT id INTO s_physical    FROM spec_section WHERE section_name = 'Physical'        AND category_id = cat_id;
  SELECT id INTO s_accessories FROM spec_section WHERE section_name = 'Accessories'     AND category_id = cat_id;

  -- ----------------------------------------------------------------
  -- Spec Definitions
  -- ----------------------------------------------------------------
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    -- Core lens identity (importance 8-10: used by compatibility checker)
    (s_lens,        'Focal Length',                      'focal_length',               'text',    'mm',  cat_id, 10),
    (s_lens,        'Aperture Range',                    'lens_aperture_range',        'text',    NULL,  cat_id, 10),
    (s_lens,        'Lens Mount Type',                   'lens_mount_type',            'text',    NULL,  cat_id, 10),
    (s_lens,        'Compatible Cameras',                'lens_compatible_cameras',    'text',    NULL,  cat_id,  8),
    (s_lens,        'Minimum Focusing Distance',         'min_focus_distance',         'text',    NULL,  cat_id,  7),
    (s_lens,        'Maximum Magnification',             'max_magnification',          'text',    NULL,  cat_id,  6),
    (s_lens,        'Angle of View',                     'angle_of_view',              'text',    NULL,  cat_id,  7),
    (s_lens,        'Field of View at Min Focus Dist.',  'field_of_view_at_mfd',       'text',    NULL,  cat_id,  5),
    (s_lens,        'Zoom Ratio',                        'zoom_ratio',                 'text',    NULL,  cat_id,  6),
    (s_lens,        'Image Stabilization',               'lens_image_stabilization',   'text',    NULL,  cat_id,  8),
    (s_lens,        'Dust / Weather Resistance',         'lens_weather_sealing',       'text',    NULL,  cat_id,  7),

    -- Optical design
    (s_optical,     'Lens Construction',                 'lens_construction',          'text',    NULL,  cat_id,  6),
    (s_optical,     'Special Elements',                  'lens_special_elements',      'text',    NULL,  cat_id,  5),
    (s_optical,     'Lens Coating',                      'lens_coating',               'text',    NULL,  cat_id,  4),
    (s_optical,     'Filter Thread Diameter',            'filter_thread_diameter',     'number',  'mm',  cat_id, 10),
    (s_optical,     'Aperture Blades',                   'aperture_blades',            'number',  NULL,  cat_id,  5),

    -- Focusing
    (s_focusing,    'Focus Drive System',                'focus_drive_system',         'text',    NULL,  cat_id,  6),
    (s_focusing,    'Full-time Manual Focus',            'fulltime_manual_focus',      'text',    NULL,  cat_id,  5),
    (s_focusing,    'Focus Distance Range Selection',    'focus_distance_range_sel',   'text',    NULL,  cat_id,  4),

    -- Exterior design
    (s_exterior,    'Control Ring',                      'lens_control_ring',          'text',    NULL,  cat_id,  5),
    (s_exterior,    'AF/MF Switch',                      'lens_af_mf_switch',          'text',    NULL,  cat_id,  5),
    (s_exterior,    'Manual Focus Ring',                 'lens_manual_focus_ring',     'text',    NULL,  cat_id,  4),
    (s_exterior,    'Distance Limiter Switch',           'distance_limiter_switch',    'text',    NULL,  cat_id,  4),
    (s_exterior,    'Distance Scale',                    'distance_scale',             'text',    NULL,  cat_id,  3),
    (s_exterior,    'Lens Function Button',              'lens_function_button',       'text',    NULL,  cat_id,  3),
    (s_exterior,    'Tripod Collar',                     'lens_tripod_collar',         'text',    NULL,  cat_id,  3),

    -- Physical
    (s_physical,    'Lens Weight',                       'lens_weight',                'text',    NULL,  cat_id,  8),
    (s_physical,    'Lens Dimensions',                   'lens_dimensions',            'text',    NULL,  cat_id,  7),

    -- Accessories
    (s_accessories, 'Lens Hood',                         'included_lens_hood',         'text',    NULL,  cat_id,  4),
    (s_accessories, 'Lens Cap',                          'included_lens_cap',          'text',    NULL,  cat_id,  3),
    (s_accessories, 'Lens Case',                         'included_lens_case',         'text',    NULL,  cat_id,  3),
    (s_accessories, 'Extender Compatibility',            'extender_compatibility',     'text',    NULL,  cat_id,  6),
    (s_accessories, 'Extension Tube Compatibility',      'extension_tube_compat',      'text',    NULL,  cat_id,  5)
  ON CONFLICT (normalized_key) DO NOTHING;

  -- ----------------------------------------------------------------
  -- Spec Mapping Rules
  -- ----------------------------------------------------------------
  INSERT INTO spec_mapping (spec_definition_id, extraction_pattern, context_pattern, priority, notes)
  SELECT sd.id, v.extraction_pattern, v.context_pattern, v.priority, v.notes
  FROM (VALUES

    -- === Lens section ===
    ('focal_length',             'focal\\s*length',                                  '^lens$',              90, 'Canon lens: Focal Length'),
    ('lens_aperture_range',      'maximum\\s*and\\s*min(imum)?\\s*aperture',         '^lens$',              90, 'Canon lens: Max/Min Aperture'),
    ('lens_mount_type',          'lens\\s*mount(\\s*type)?',                         '^lens$',              90, 'Canon lens: Lens Mount Type'),
    ('lens_compatible_cameras',  'compatible\\s*cameras?',                           '^lens$',              85, 'Canon lens: Compatible Cameras'),
    ('min_focus_distance',       'min(imum)?\\s*focus(ing)?\\s*distance',            '^lens$',              85, 'Canon lens: Min Focusing Distance'),
    ('max_magnification',        'max(imum)?\\s*magnification',                      '^lens$',              80, 'Canon lens: Max Magnification'),
    ('angle_of_view',            'angle\\s*of\\s*view',                              '^lens$',              80, 'Canon lens: Angle of View'),
    ('field_of_view_at_mfd',     'field\\s*of\\s*view',                              '^lens$',              75, 'Canon lens: Field of View'),
    ('zoom_ratio',               'zoom\\s*ratio',                                    '^lens$',              75, 'Canon lens: Zoom Ratio'),
    ('lens_image_stabilization', 'image\\s*stabilization|^is\\s*(mode|\\()',         '^lens$',              80, 'Canon lens: IS under Lens'),
    ('lens_weather_sealing',     'dust.{0,5}(water|weather)',                        '^lens$',              80, 'Canon lens: Dust/Water Resistance'),

    -- === Optical Design section ===
    ('lens_construction',        'lens\\s*construction',                             'optical\\s*design',   85, 'Canon lens: Lens Construction'),
    ('lens_special_elements',    'special\\s*(lens\\s*)?elements?',                  'optical\\s*design',   80, 'Canon lens: Special Elements'),
    ('lens_coating',             'lens\\s*coating',                                  'optical\\s*design',   75, 'Canon lens: Lens Coating'),
    ('filter_thread_diameter',   'filter\\s*size(\\s*diameter)?',                    'optical\\s*design',   90, 'Canon lens: Filter Size Diameter'),
    ('aperture_blades',          'aperture\\s*blades?',                              'optical\\s*design',   80, 'Canon lens: Aperture Blades'),
    ('lens_image_stabilization', 'image\\s*stabilization(\\s*\\(yaw)?',              'optical\\s*design',   75, 'Canon lens: IS under Optical Design'),

    -- === Focusing section ===
    ('focus_drive_system',       'focus(ing)?\\s*drive\\s*system',                   'focusing',            85, 'Canon lens: Focus Drive System'),
    ('fulltime_manual_focus',    'full.?time\\s*manual\\s*focus(ing)?',              'focusing',            80, 'Canon lens: Full-time Manual Focus'),
    ('focus_distance_range_sel', 'focus\\s*distance\\s*range\\s*selection',          'focusing',            70, 'Canon lens: Focus Distance Range Selection'),

    -- === Exterior Design section ===
    ('lens_control_ring',        'control\\s*ring',                                  'exterior\\s*design',  80, 'Canon lens: Control Ring'),
    ('lens_af_mf_switch',        'af\\s*.\\s*mf\\s*switch',                          'exterior\\s*design',  80, 'Canon lens: AF/MF Switch'),
    ('lens_manual_focus_ring',   'manual\\s*focus\\s*ring',                          'exterior\\s*design',  75, 'Canon lens: Manual Focus Ring'),
    ('distance_limiter_switch',  'distance\\s*limiter\\s*switch',                    'exterior\\s*design',  75, 'Canon lens: Distance Limiter Switch'),
    ('distance_scale',           '^distance\\s*scale$',                              'exterior\\s*design',  70, 'Canon lens: Distance Scale'),
    ('lens_function_button',     'lens\\s*function\\s*buttons?',                     'exterior\\s*design',  65, 'Canon lens: Lens Function Button'),
    ('lens_tripod_collar',       'tripod\\s*collar',                                 'exterior\\s*design',  65, 'Canon lens: Tripod Collar'),

    -- === Dimensions, Weight section ===
    ('lens_weight',              '^weight$',                                          'dimensions.{0,10}weight', 90, 'Canon lens: Weight'),
    ('lens_dimensions',          '^(maximum\\s*outer|dimensions|length)\\b',         'dimensions.{0,10}weight', 85, 'Canon lens: Dimensions/Length'),

    -- === Accessories section ===
    ('included_lens_hood',       'lens\\s*hood',                                     'accessories',         75, 'Canon lens: Lens Hood'),
    ('included_lens_cap',        'lens\\s*cap',                                      'accessories',         70, 'Canon lens: Lens Cap'),
    ('included_lens_case',       'lens\\s*case',                                     'accessories',         70, 'Canon lens: Lens Case'),
    ('extender_compatibility',   '(rf|ef)\\s*extenders?',                            'accessories',         75, 'Canon lens: Extender Compatibility'),
    ('extension_tube_compat',    'extension\\s*tubes?',                              'accessories',         70, 'Canon lens: Extension Tube Compatibility'),

    -- === Cross-section: Filter Size in Main Unit Spec (cinema/broadcast lenses) ===
    ('filter_thread_diameter',   '^filter\\s*size$',                                 'main\\s*unit\\s*spec', 80, 'Canon lens: Filter Size under Main Unit Spec')

  ) AS v(normalized_key, extraction_pattern, context_pattern, priority, notes)
  JOIN spec_definition sd ON sd.normalized_key = v.normalized_key
  WHERE NOT EXISTS (
    SELECT 1 FROM spec_mapping sm
    WHERE sm.spec_definition_id = sd.id
      AND sm.extraction_pattern = v.extraction_pattern
      AND sm.context_pattern IS NOT DISTINCT FROM v.context_pattern
  );

END $$;