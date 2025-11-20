-- MODEL: fact_breed_metrics
--
-- Purpose:
--   Fact table providing numeric metrics for each dog breed, such as:
--     - min/max/avg weight (kg)
--     - min/max/avg height (cm)
--     - min/max/avg life expectancy (years)
--
--   This table supports analytical use cases like:
--     - Ranking breeds by size or longevity
--     - Filtering breeds by ranges
--     - Visualizing distributions (Looker Studio dashboard)
--
-- Notes:
--   Each metric is computed from the cleaned staging fields using simple averages.
--   Descriptive attributes are intentionally not included — they belong in dim_breed.

WITH base AS (

    SELECT *
    FROM {{ ref('stg_dog_api_raw') }}

),

metrics AS (

    SELECT
        breed_id,

        -- Life span metrics
        life_span_years_min,
        life_span_years_max,
        SAFE_DIVIDE(life_span_years_min + life_span_years_max, 2) AS life_span_years_avg,

        -- Weight metrics (kg)
        weight_kg_min,
        weight_kg_max,
        SAFE_DIVIDE(weight_kg_min + weight_kg_max, 2) AS weight_kg_avg,

        -- Height metrics (cm)
        height_cm_min,
        height_cm_max,
        SAFE_DIVIDE(height_cm_min + height_cm_max, 2) AS height_cm_avg,

        -- Lineage metadata for debugging / freshness checks
        _dlt_load_id,
        _dlt_id

    FROM base
)

SELECT *
FROM metrics
