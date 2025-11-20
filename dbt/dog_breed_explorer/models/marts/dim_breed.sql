-- MODEL: dim_breed
--
-- Purpose:
--   Dimension table containing one row per dog breed. Provides clean, enriched
--   descriptive attributes from the staging layer that can be joined to fact
--   tables. This model:
--     - Ensures a unique record per breed_id
--     - Keeps descriptive/categorical fields
--     - Leaves metrics to fact tables
--
-- Notes:
--   If the API introduces duplicates or multiple entries per breed in the future,
--   the ROW_NUMBER logic below keeps only the latest one.

WITH base AS (

    SELECT *
    FROM {{ ref('stg_dog_api_raw') }}

),

deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY breed_id 
            ORDER BY _dlt_load_id DESC
        ) AS rn
    FROM base
)

SELECT
    -- Primary key
    breed_id,
    
    -- Basic identification
    breed_name,
    breed_group,
    
    -- Origin information
    bred_for,
    origin,
    country_code,
    
    -- Characteristics
    temperament,
    
    -- Detailed information
    description,
    history,
    
    -- References
    reference_image_id
FROM deduped
WHERE rn = 1
