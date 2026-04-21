-- UI-friendly views (JSON payloads + matrix grids)

-- Still image "File Size" matrix (grid-shaped for UI)
-- Dimensions:
-- - format_group (e.g., JPEG*2, HEIF*3, RAW, RAW+JPEG*2)
-- - quality (e.g., L, M, S1, RAW, C-RAW, etc.)
CREATE OR REPLACE VIEW v_still_image_file_size_grid AS
WITH base AS (
    SELECT
        p.id AS product_id,
        p.slug AS product_slug,
        (m.dims->>'format_group') AS format_group,
        (m.dims->>'quality') AS quality,
        jsonb_strip_nulls(
            jsonb_build_object(
                'mb', m.numeric_value,
                'unit', m.unit_used,
                'extra',
                CASE
                    WHEN m.value_text IS NULL THEN NULL::jsonb
                    WHEN left(btrim(m.value_text), 1) IN ('{', '[') THEN m.value_text::jsonb
                    ELSE jsonb_build_object('text', m.value_text)
                END
            )
        ) AS cell
    FROM product_spec_matrix m
    JOIN product p ON p.id = m.product_id
    JOIN spec_definition sd ON sd.id = m.spec_definition_id
    WHERE sd.normalized_key = 'still_image_file_size_table'
)
SELECT
    product_id,
    product_slug,
    format_group,
    jsonb_object_agg(quality, cell) AS cells
FROM base
GROUP BY product_id, product_slug, format_group;


-- Grouped specs JSON payload (for accordion/detail pages)
-- Shape:
-- {
--   "sections": {
--     "<Section Name>": {
--       "<normalized_key>": { label, value, numeric, unit, bool }
--     }
--   }
-- }
CREATE OR REPLACE VIEW v_product_specs_grouped_json AS
WITH base AS (
    SELECT
        p.id AS product_id,
        p.slug AS product_slug,
        COALESCE(ss.section_name, 'Other') AS section_name,
        sd.normalized_key AS normalized_key,
        sd.display_name AS display_name,
        ps.spec_value AS spec_value,
        ps.numeric_value AS numeric_value,
        ps.unit_used AS unit_used,
        ps.boolean_value AS boolean_value
    FROM product_spec ps
    JOIN product p ON p.id = ps.product_id
    JOIN spec_definition sd ON sd.id = ps.spec_definition_id
    LEFT JOIN spec_section ss ON ss.id = sd.section_id
),
per_section AS (
    SELECT
        product_id,
        product_slug,
        section_name,
        jsonb_object_agg(
            normalized_key,
            jsonb_strip_nulls(
                jsonb_build_object(
                    'label', display_name,
                    'value', spec_value,
                    'numeric', numeric_value,
                    'unit', unit_used,
                    'bool', boolean_value
                )
            )
        ) AS specs
    FROM base
    GROUP BY product_id, product_slug, section_name
)
SELECT
    product_id,
    product_slug,
    jsonb_object_agg(section_name, specs) AS sections
FROM per_section
GROUP BY product_id, product_slug;

