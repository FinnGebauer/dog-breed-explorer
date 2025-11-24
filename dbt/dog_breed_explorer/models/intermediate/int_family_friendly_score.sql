-- MODEL: int_family_friendly_score
--
-- Purpose:
--   This intermediate model calculates a family-friendliness score for each dog breed
--   based on their temperament traits. It:
--   - Parses temperament strings to identify positive and negative family-friendly traits
--   - Assigns weighted scores to positive traits (e.g., gentle=3, playful=2, intelligent=1)
--   - Applies penalties for cautionary traits (e.g., aggressive=-5, dominant=-3)
--   - Calculates a net family_friendly_score (positive_score + negative_score)
--   - Categorizes breeds into family-friendliness levels
--   - Provides a boolean flag for simple filtering (score >= 3)
--
-- Why this model exists:
--   Enables data consumers to filter and rank breeds by family-friendliness without
--   manually parsing temperament strings. The scoring system is transparent and adjustable
--   via trait weights. Used downstream in dim_breed to enrich breed dimensions.
--
-- Scoring logic:
--   - Positive traits: gentle, patient, loving, friendly (weight 2-3)
--   - Negative traits: aggressive, dominant, territorial (penalty -1 to -5)
--   - Categories: highly_family_friendly (6+), family_friendly (3-5),
--     moderately_suitable (0-2), less_suitable (<0)


WITH source AS (
    SELECT * FROM {{ ref('stg_dog_api_raw') }}
),

-- Define family-friendly temperament keywords with weights
-- Higher weight = stronger indicator of family-friendliness
family_friendly_traits AS (
    SELECT trait, weight 
    FROM UNNEST([
        STRUCT('gentle' AS trait, 3 AS weight),
        STRUCT('patient', 3),
        STRUCT('tolerant', 3),
        STRUCT('loving', 3),
        STRUCT('affectionate', 3),
        STRUCT('friendly', 3),
        STRUCT('sweet-tempered', 3),
        STRUCT('playful', 2),
        STRUCT('loyal', 2),
        STRUCT('devoted', 2),
        STRUCT('trustworthy', 2),
        STRUCT('calm', 2),
        STRUCT('easygoing', 2),
        STRUCT('adaptable', 2),
        STRUCT('sociable', 2),
        STRUCT('good-natured', 2),
        STRUCT('even tempered', 2),
        STRUCT('good-tempered', 2),
        STRUCT('cheerful', 2),
        STRUCT('merry', 2),
        STRUCT('happy', 2),
        STRUCT('joyful', 2),
        STRUCT('people-oriented', 2),
        STRUCT('familial', 3),
        STRUCT('intelligent', 1),
        STRUCT('trainable', 1),
        STRUCT('obedient', 1),
        STRUCT('responsive', 1),
        STRUCT('reliable', 1),
        STRUCT('stable', 1),
        STRUCT('companionable', 2)
    ])
),

-- Define traits that are less family-friendly (subtract from score)
cautionary_traits AS (
    SELECT trait, penalty 
    FROM UNNEST([
        STRUCT('aggressive' AS trait, -5 AS penalty),
        STRUCT('dominant', -3),
        STRUCT('fierce', -3),
        STRUCT('territorial', -2),
        STRUCT('suspicious', -2),
        STRUCT('aloof', -2),
        STRUCT('independent', -1),
        STRUCT('stubborn', -1),
        STRUCT('willful', -1),
        STRUCT('strong willed', -1)
    ])
),

breed_scores AS (
    SELECT
        breed_id,
        breed_name,
        temperament,
        
        -- Calculate positive score
        COALESCE(
            SUM(
                CASE
                    WHEN LOWER(temperament) LIKE CONCAT('%', LOWER(fft.trait), '%')
                    THEN fft.weight
                    ELSE 0
                END
            ),
            0
        ) AS positive_score,
        
        -- Calculate negative score
        COALESCE(
            SUM(
                CASE
                    WHEN LOWER(temperament) LIKE CONCAT('%', LOWER(ct.trait), '%')
                    THEN ct.penalty
                    ELSE 0
                END
            ),
            0
        ) AS negative_score
        
    FROM source
    CROSS JOIN family_friendly_traits AS fft
    CROSS JOIN cautionary_traits AS ct
    WHERE temperament IS NOT NULL AND temperament != ''
    GROUP BY breed_id, breed_name, temperament
),

final AS (
    SELECT
        breed_id,
        breed_name,
        temperament,
        positive_score,
        negative_score,
        positive_score + negative_score AS family_friendly_score,
        
        -- Create flag based on threshold (score >= 3)
        CASE
            WHEN positive_score + negative_score >= 3 THEN TRUE
            ELSE FALSE
        END AS is_family_friendly,
        
        -- Categorize by score ranges
        CASE
            WHEN positive_score + negative_score >= 6 THEN 'highly_family_friendly'
            WHEN positive_score + negative_score >= 3 THEN 'family_friendly'
            WHEN positive_score + negative_score >= 0 THEN 'moderately_suitable'
            ELSE 'less_suitable'
        END AS family_friendly_category
        
    FROM breed_scores
)

SELECT * FROM final