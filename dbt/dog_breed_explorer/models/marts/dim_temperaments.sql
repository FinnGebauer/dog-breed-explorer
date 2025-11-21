-- MODEL: dim_temperaments
--
-- Purpose:
--   Dimension table containing individual temperament traits for each breed.
--   Unnests the comma-separated temperament field from dim_breed into one row
--   per breed-temperament combination.
--
-- Use cases:
--   - Filter breeds by specific temperament (e.g., "Friendly")
--   - Count breeds per temperament
--   - Analyze temperament combinations
--
-- Grain: One row per breed_id + temperament combination

WITH breeds AS (
    SELECT 
        breed_id,
        temperament
    FROM {{ ref('stg_dog_api_raw') }}
    WHERE temperament IS NOT NULL
),

unnested AS (
    SELECT 
        breed_id,
        INITCAP(TRIM(temperament_value)) AS temperament  -- "friendly" → "Friendly"
    FROM breeds,
    UNNEST(SPLIT(temperament, ',')) AS temperament_value
)

SELECT
    breed_id,
    temperament
FROM unnested
WHERE temperament != ''