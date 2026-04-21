-- Demo seed migration (idempotent): EOS R6 Mark III + still image recording pixels matrix
-- Purpose: verify Supabase CLI cloud migration workflow, including product_spec_matrix.
--
-- This migration:
-- - ensures Brand: Canon exists
-- - ensures Category: mirrorless-cameras exists (created in 20251224003000_seed_product_categories.sql)
-- - ensures a "Recording" spec section exists for mirrorless-cameras
-- - ensures spec_definition: still_image_recording_pixels exists
-- - upserts product: eos-r6-mark-iii
-- - inserts parent product_spec + matrix cells into product_spec_matrix

DO $$
DECLARE
  v_brand_id UUID;
  v_cat_id UUID;
  v_product_id UUID;
  v_recording_section UUID;
  v_spec_def_id UUID;
BEGIN
  -- Brand prerequisite
  INSERT INTO brand (name, slug, website_url, scraping_enabled)
  VALUES ('Canon', 'canon', 'https://www.usa.canon.com', TRUE)
  ON CONFLICT (slug) DO NOTHING;
  SELECT id INTO v_brand_id FROM brand WHERE slug = 'canon';

  -- Category prerequisite
  SELECT id INTO v_cat_id FROM product_category WHERE slug = 'mirrorless-cameras';
  IF v_cat_id IS NULL THEN
    RAISE EXCEPTION 'Seed failed: product_category with slug=% not found. Run category seed migrations first.', 'mirrorless-cameras';
  END IF;

  -- Spec section for matrix spec
  INSERT INTO spec_section (section_name, category_id, display_order)
  VALUES ('Recording', v_cat_id, 75)
  ON CONFLICT (section_name, category_id) DO NOTHING;
  SELECT id INTO v_recording_section
  FROM spec_section
  WHERE section_name = 'Recording' AND category_id = v_cat_id;

  -- Spec definition for matrix
  INSERT INTO spec_definition (section_id, display_name, normalized_key, data_type, unit, category_id, importance)
  VALUES (
    v_recording_section,
    'Still Image Recording Pixels (Matrix)',
    'still_image_recording_pixels',
    'matrix',
    NULL,
    v_cat_id,
    6
  )
  ON CONFLICT (normalized_key) DO NOTHING;
  SELECT id INTO v_spec_def_id FROM spec_definition WHERE normalized_key = 'still_image_recording_pixels';

  -- Product upsert
  INSERT INTO product (
    brand_id,
    category_id,
    model,
    full_name,
    slug,
    manufacturer_url,
    source_url,
    scraping_status,
    is_active
  ) VALUES (
    v_brand_id,
    v_cat_id,
    'EOS R6 Mark III',
    'Canon EOS R6 Mark III',
    'eos-r6-mark-iii',
    'https://www.usa.canon.com/shop/p/eos-r6-mark-iii',
    'https://www.usa.canon.com/shop/p/eos-r6-mark-iii',
    'seeded',
    TRUE
  )
  ON CONFLICT (slug) DO UPDATE SET
    brand_id = EXCLUDED.brand_id,
    category_id = EXCLUDED.category_id,
    full_name = EXCLUDED.full_name,
    manufacturer_url = EXCLUDED.manufacturer_url,
    source_url = EXCLUDED.source_url,
    scraping_status = EXCLUDED.scraping_status,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

  SELECT id INTO v_product_id FROM product WHERE slug = 'eos-r6-mark-iii';

  -- Parent product_spec row for discoverability + provenance
  INSERT INTO product_spec (product_id, spec_definition_id, spec_value, raw_value, raw_value_jsonb, extraction_confidence)
  VALUES (
    v_product_id,
    v_spec_def_id,
    'See product_spec_matrix (still image recording pixels)',
    'PDF table: Recording pixels — cropping & aspect ratios (values approximate; shaded=inexact proportion)',
    '{
      "source": "canon_pdf",
      "table": "Recording pixels — cropping & aspect ratios",
      "scope": "Still image recording",
      "notes": [
        "Values for recorded pixels rounded off to nearest 100,000th",
        "Shaded cells indicate inexact proportion",
        "RAW and C-RAW images generated in 3:2 aspect ratio; set aspect ratio/cropping is appended and applied in RAW processing",
        "JPEG/HEIF images generated in the set aspect ratio",
        "These aspect ratios and pixel counts also apply to resizing"
      ],
      "dims": ["media_type", "image_size", "aspect_ratio"],
      "value_fields": ["numeric_value_mp", "width_px", "height_px", "is_available", "is_inexact_proportion"]
    }'::jsonb,
    1.0
  )
  ON CONFLICT (product_id, spec_definition_id) DO NOTHING;

  -- Matrix cells
  INSERT INTO product_spec_matrix (
    product_id,
    spec_definition_id,
    dims,
    numeric_value,
    unit_used,
    width_px,
    height_px,
    is_available,
    is_inexact_proportion,
    notes,
    extraction_confidence
  )
  SELECT
    v_product_id,
    v_spec_def_id,
    v.dims::jsonb,
    v.mp,
    'MP',
    v.w,
    v.h,
    v.is_available,
    v.is_inexact,
    v.notes,
    1.0
  FROM (
    VALUES
      -- JPEG/HEIF - L
      ('{"media_type":"JPEG/HEIF","image_size":"L","aspect_ratio":"3:2"}',      32.3::numeric, 6960::int, 4640::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"L","aspect_ratio":"1.6x_crop"}',12.4::numeric, 4320::int, 2880::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"L","aspect_ratio":"1:1"}',      21.5::numeric, 4640::int, 4640::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"L","aspect_ratio":"4:3"}',      28.6::numeric, 6160::int, 4640::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"L","aspect_ratio":"16:9"}',     27.2::numeric, 6960::int, 3904::int, true,  false, NULL),

      -- JPEG/HEIF - M
      ('{"media_type":"JPEG/HEIF","image_size":"M","aspect_ratio":"3:2"}',      15.4::numeric, 4800::int, 3200::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"M","aspect_ratio":"1.6x_crop"}',NULL::numeric, NULL::int, NULL::int, false, false, 'Not available'),
      ('{"media_type":"JPEG/HEIF","image_size":"M","aspect_ratio":"1:1"}',      10.2::numeric, 3200::int, 3200::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"M","aspect_ratio":"4:3"}',      13.6::numeric, 4256::int, 3200::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"M","aspect_ratio":"16:9"}',     12.9::numeric, 4880::int, 2688::int, true,  false, NULL),

      -- JPEG/HEIF - S1 (3:2 cell shaded in PDF = inexact proportion)
      ('{"media_type":"JPEG/HEIF","image_size":"S1","aspect_ratio":"3:2"}',      8.1::numeric, 3472::int, 2320::int, true,  true,  NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"S1","aspect_ratio":"1.6x_crop"}',NULL::numeric, NULL::int, NULL::int, false, false, 'Not available'),
      ('{"media_type":"JPEG/HEIF","image_size":"S1","aspect_ratio":"1:1"}',      5.4::numeric, 2320::int, 2320::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"S1","aspect_ratio":"4:3"}',      7.1::numeric, 3072::int, 2320::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"S1","aspect_ratio":"16:9"}',     6.8::numeric, 3472::int, 1952::int, true,  false, NULL),

      -- JPEG/HEIF - S2 (some cells shaded in PDF = inexact proportion)
      ('{"media_type":"JPEG/HEIF","image_size":"S2","aspect_ratio":"3:2"}',      3.8::numeric, 2400::int, 1600::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"S2","aspect_ratio":"1.6x_crop"}',3.8::numeric, 2400::int, 1600::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"S2","aspect_ratio":"1:1"}',      2.6::numeric, 1600::int, 1600::int, true,  false, NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"S2","aspect_ratio":"4:3"}',      3.4::numeric, 2112::int, 1600::int, true,  true,  NULL),
      ('{"media_type":"JPEG/HEIF","image_size":"S2","aspect_ratio":"16:9"}',     3.2::numeric, 2400::int, 1344::int, true,  true,  NULL),

      -- RAW / C-RAW
      ('{"media_type":"RAW/C-RAW","image_size":"RAW/C-RAW","aspect_ratio":"3:2"}',      32.3::numeric, 6960::int, 4640::int, true,  false, NULL),
      ('{"media_type":"RAW/C-RAW","image_size":"RAW/C-RAW","aspect_ratio":"1.6x_crop"}',12.4::numeric, 4320::int, 2880::int, true,  false, NULL),
      ('{"media_type":"RAW/C-RAW","image_size":"RAW/C-RAW","aspect_ratio":"4:3"}',      32.3::numeric, 6960::int, 4640::int, true,  false, NULL)
  ) AS v(dims, mp, w, h, is_available, is_inexact, notes)
  ON CONFLICT (product_id, spec_definition_id, dims) DO NOTHING;

END $$;

