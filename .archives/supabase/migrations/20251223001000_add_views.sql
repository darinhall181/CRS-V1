-- Views (added after init)
-- Still image recording pixels matrix (grid-shaped for UI)
CREATE OR REPLACE VIEW v_still_image_recording_pixels_grid AS
WITH base AS (
    SELECT
        p.id AS product_id,
        p.slug AS product_slug,
        (m.dims->>'media_type') AS media_type,
        (m.dims->>'image_size') AS image_size,
        (m.dims->>'aspect_ratio') AS aspect_ratio,
        jsonb_strip_nulls(
            jsonb_build_object(
                'mp', m.numeric_value,
                'unit', m.unit_used,
                'width_px', m.width_px,
                'height_px', m.height_px,
                'is_available', m.is_available,
                'is_inexact', m.is_inexact_proportion,
                'notes', m.notes
            )
        ) AS cell
    FROM product_spec_matrix m
    JOIN product p ON p.id = m.product_id
    JOIN spec_definition sd ON sd.id = m.spec_definition_id
    WHERE sd.normalized_key = 'still_image_recording_pixels'
)
SELECT
    product_id,
    product_slug,
    media_type,
    image_size,
    jsonb_object_agg(aspect_ratio, cell) AS cells
FROM base
GROUP BY product_id, product_slug, media_type, image_size;

