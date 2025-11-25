-- MODEL: dim_breed
--
-- Purpose:
--   Dimension table containing one row per dog breed. Provides clean, enriched
--   descriptive attributes from the staging layer that can be joined to fact
--   tables. This model:
--     - Ensures a unique record per breed_id (guaranteed by staging)
--     - Keeps descriptive/categorical fields only (no metrics)
--     - Enriches with family-friendly scoring from intermediate layer
--     - Provides business-friendly attributes for filtering and grouping
--
-- Why metrics are excluded:
--   Dimensional modeling best practice separates dimensions (who/what/where)
--   from facts (measures/metrics). Weight, height, and lifespan measurements
--   belong in fact_breed_metrics for proper grain definition and aggregation.

WITH base_breeds AS (
    SELECT * FROM {{ ref('stg_dog_api_raw') }}
),

family_scores AS (
    SELECT * FROM {{ ref('int_calculate_family_friendly_score') }}
),

final AS (
    SELECT
        -- Primary key
        bb.breed_id,
        
        -- Breed identification
        bb.breed_name,
        bb.breed_group,
        bb.bred_for,
        
        -- Geographic attributes
        bb.origin,
        bb.country_code,
        
        -- Descriptive characteristics (text fields, not metrics)
        bb.description,
        bb.history,
        
        -- Family-friendly enrichment
        fs.family_friendly_score,
        fs.is_family_friendly,
        fs.family_friendly_category,

         -- Size classification (derived from staging weight)
        CASE
            WHEN SAFE_DIVIDE(bb.weight_kg_min + bb.weight_kg_max, 2) < 10 THEN "Small (<10kg)"
            WHEN SAFE_DIVIDE(bb.weight_kg_min + bb.weight_kg_max, 2) < 25 THEN "Medium (10-25kg)"
            WHEN SAFE_DIVIDE(bb.weight_kg_min + bb.weight_kg_max, 2) < 45 THEN "Large (25-45kg)"
            ELSE "Giant (>45kg)"
        END AS weight_class,
        
        -- Image reference
        bb.reference_image_id
        
    FROM base_breeds AS bb
    LEFT JOIN family_scores AS fs
        ON bb.breed_id = fs.breed_id
)

SELECT * FROM final
