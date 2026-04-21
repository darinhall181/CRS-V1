-- Seed migration (idempotent): Canon camera mapping batch 6
-- Focus: remaining high-frequency Speedlite/HDR/Video/Interface/Customization labels.

DO $$
DECLARE
  cat_id UUID;
  s_connect UUID;
  s_video UUID;
  s_other UUID;
  s_photo UUID;
BEGIN
  SELECT id INTO cat_id FROM product_category WHERE slug = 'mirrorless-cameras';
  IF cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=% not found. Run category seeds first.', 'mirrorless-cameras';
  END IF;

  SELECT id INTO s_connect FROM spec_section WHERE section_name='Connectivity'         AND category_id=cat_id;
  SELECT id INTO s_video   FROM spec_section WHERE section_name='Videography Features' AND category_id=cat_id;
  SELECT id INTO s_photo   FROM spec_section WHERE section_name='Photography Features' AND category_id=cat_id;
  SELECT id INTO s_other   FROM spec_section WHERE section_name='Other Features'       AND category_id=cat_id;

  -- Add missing definitions (safe to re-run)
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance) VALUES
    (s_photo,  'E‑TTL II Flash Meterings',               'e_ttl_ii_flash_meterings',      'text', NULL, cat_id, 1),
    (s_photo,  'Flash Function Menu',                    'flash_function_menu',           'text', NULL, cat_id, 1),

    -- HDR / Video features
    (s_other,  'HDR PQ Shooting',                        'hdr_pq_shooting',               'text', NULL, cat_id, 1),
    (s_video,  'Canon Log',                              'canon_log',                     'text', NULL, cat_id, 1),

    -- Interface label variants (map into existing text terminals too, but keep canonical key for UI)
    (s_connect,'Microphone Input Terminal',              'microphone_input_terminal',     'text', NULL, cat_id, 1),
    (s_connect,'Wireless Remote Control',                'wireless_remote_control',       'text', NULL, cat_id, 1),
    (s_connect,'Multi-function Shoe',                    'multi_function_shoe',           'text', NULL, cat_id, 1),

    -- Customization
    (s_other,  'Customize Buttons',                      'customize_buttons',             'text', NULL, cat_id, 1),
    (s_other,  'Custom Controls',                        'custom_controls',               'text', NULL, cat_id, 1),

    -- Minor content buckets (often low value, but frequent enough)
    (s_other,  'Movies (Folder Name / Dual shooting)',   'movies_bucket',                 'text', NULL, cat_id, 0)
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
      -- External Speedlite
      ('e_ttl_ii_flash_meterings',   '^e-?ttl\\s*ii\\s*flash\\s*meterings?$',  '^external\\s*speedlite$', 75, 'Canon: E‑TTL II flash meterings'),
      ('flash_function_menu',        '^flash\\s*function\\s*menu$',            '^external\\s*speedlite$', 75, 'Canon: flash function menu'),

      -- HDR PQ Shooting appears under sections like "HDR Shooting - Still" and "HDR Shooting and Movie Recording"
      ('hdr_pq_shooting',            '^hdr\\s*pq\\s*shooting$',                'hdr\\s*shooting',          75, 'Canon: HDR PQ shooting'),

      -- Canon Log (Video Shooting)
      ('canon_log',                  '^canon\\s*log$',                         '^video\\s*shooting$',      75, 'Canon: Canon Log'),

      -- Interface variants
      ('microphone_terminal',        '^microphone\\s*input\\s*terminal$',      '^interface$',              80, 'Canon: mic input terminal -> microphone_terminal'),
      ('microphone_input_terminal',  '^microphone\\s*input\\s*terminal$',      '^interface$',              70, 'Canon: mic input terminal (dedicated key)'),
      ('wireless_remote_control',    '^wireless\\s*remote\\s*control$',        '^interface$',              75, 'Canon: wireless remote control'),
      ('multi_function_shoe',        '^multi-?function\\s*shoe$',              '^interface$',              75, 'Canon: multi-function shoe'),

      -- Customization
      ('customize_buttons',          '^customize\\s*buttons$',                  '^customization$',          75, 'Canon: customize buttons'),
      ('custom_controls',            '^custom\\s*controls$',                    '^customization$',          75, 'Canon: custom controls'),

      -- Bucket-ish grouping
      ('movies_bucket',              '^movies$',                                '(folder\\s*name|dual\\s*shooting)', 60, 'Canon: Movies bucket')

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


