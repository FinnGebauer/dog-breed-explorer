-- MODEL: stg_dog_api_raw
--
-- Purpose:
--   This staging model cleans and standardises the raw Dog API data loaded into
--   the raw layer by dlt. It:
--   - Renames fields into a consistent naming convention
--   - Parses weight, height, and lifespan ranges into numeric min/max columns
--   - Ensures stable primary keys (breed_id)
--   - **De-duplicates records, keeping the most recent load**
--   - **Converts empty strings to NULL across all columns**
--   - Preserves raw descriptive fields for reference
--   - Exposes dlt lineage metadata (_dlt_id, _dlt_load_id)
--
-- Why this model exists:
--   The raw table stores the API response exactly as delivered by dlt.
--   This model transforms it into a clean, analytics-friendly schema and serves
--   as the single source of truth for downstream marts.


WITH source AS (

    SELECT * FROM {{ source('raw', 'dog_api_raw') }}

),

renamed AS (

    SELECT
        -- primary key
        id AS breed_id,

        -- breed information
        NULLIF(TRIM(name), '') AS breed_name,
        NULLIF(TRIM(breed_group), '') AS breed_group,
        NULLIF(TRIM(bred_for), '') AS bred_for,
        NULLIF(TRIM(origin), '') AS origin,
        NULLIF(TRIM(country_code), '') AS country_code,

        -- characteristics
        NULLIF(TRIM(temperament), '') AS temperament,
        NULLIF(TRIM(description), '') AS description,
        NULLIF(TRIM(history), '') AS history,

        -- measurements - weight
        NULLIF(TRIM(weight__metric), '') AS weight_metric_raw,
        NULLIF(TRIM(weight__imperial), '') AS weight_imperial_raw,
        SAFE_CAST(
            REGEXP_EXTRACT(
                NULLIF(TRIM(weight__metric), ''),
                r'^(\d+)'
            ) AS INT64
        ) AS weight_kg_min,
        SAFE_CAST(
            REGEXP_EXTRACT(
                NULLIF(TRIM(weight__metric), ''),
                r'(\d+)$'
            ) AS INT64
        ) AS weight_kg_max,

        -- measurements - height
        NULLIF(TRIM(height__metric), '') AS height_metric_raw,
        NULLIF(TRIM(height__imperial), '') AS height_imperial_raw,
        SAFE_CAST(
            REGEXP_EXTRACT(
                NULLIF(TRIM(height__metric), ''),
                r'^(\d+)'
            ) AS INT64
        ) AS height_cm_min,
        SAFE_CAST(
            REGEXP_EXTRACT(
                NULLIF(TRIM(height__metric), ''),
                r'(\d+)$'
            ) AS INT64
        ) AS height_cm_max,

        -- life span
        NULLIF(TRIM(life_span), '') AS life_span_raw,
        SAFE_CAST(
            REGEXP_EXTRACT(
                NULLIF(TRIM(life_span), ''),
                r'^(\d+)'
            ) AS INT64
        ) AS life_span_years_min,
        SAFE_CAST(
            REGEXP_EXTRACT(
                NULLIF(TRIM(life_span), ''),
                r'(\d+)\s*(?:years?|Years)'
            ) AS INT64
        ) AS life_span_years_max,

        -- metadata
        NULLIF(TRIM(reference_image_id), '') AS reference_image_id,

        -- dlt metadata
        _dlt_load_id,
        _dlt_id,

        -- Row number to identify duplicates (keep most recent load)
        ROW_NUMBER() OVER (
            PARTITION BY id 
            ORDER BY _dlt_load_id DESC, _dlt_id DESC
        ) AS row_num

    FROM source

),

deduplicated AS (
    SELECT * 
    FROM renamed
    WHERE row_num = 1
)

SELECT 
    * EXCEPT(row_num)
FROM deduplicated