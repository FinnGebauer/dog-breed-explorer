-- MODEL: dim_breed
--
-- Purpose:
--   Dimension table containing one row per dog breed. Provides clean, enriched
--   descriptive attributes from the staging layer that can be joined to fact
--   tables. This model:
--     - Ensures a unique record per breed_id (guaranteed by staging)
--     - Keeps descriptive/categorical fields
--     - Enriches with family-friendly scoring
--     - Leaves metrics to fact tables

WITH base_breeds AS (
    SELECT * FROM {{ ref('stg_dog_api_raw') }}
),

family_scores AS (
    SELECT * FROM {{ ref('int_family_friendly_score') }}
),

final AS (
    SELECT
        bb.breed_id,
        bb.breed_name,
        bb.breed_group,
        bb.temperament,
        bb.life_span_raw AS life_span,
        bb.weight_imperial_raw AS weight_imperial,
        bb.height_imperial_raw AS height_imperial,
        bb.origin,
        bb.bred_for,
        
        -- Add family-friendly metrics
        COALESCE(fs.family_friendly_score, 0) AS family_friendly_score,
        COALESCE(fs.is_family_friendly, FALSE) AS is_family_friendly,
        COALESCE(fs.family_friendly_category, 'unknown') AS family_friendly_category,
        
        bb._dlt_load_id AS loaded_at
        
    FROM base_breeds AS bb
    LEFT JOIN family_scores AS fs
        ON bb.breed_id = fs.breed_id
)

SELECT * FROM final
