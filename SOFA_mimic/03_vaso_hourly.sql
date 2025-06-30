/* =========================================================================
   03_vaso_hourly.sql
   Hourly max vaso-inotrope dose and SOFA‐CV (vasopressor tier)
   ========================================================================= */
SET search_path TO mimiciv_icu;

DROP MATERIALIZED VIEW IF EXISTS vaso_hourly CASCADE;

CREATE MATERIALIZED VIEW vaso_hourly AS
WITH doses AS (
    SELECT
        ie.stay_id,
        date_trunc('hour', ie.starttime) AS hr,
        CASE
            WHEN ie.itemid = 221906 THEN ie.rate          -- norepinephrine
            WHEN ie.itemid = 222315 THEN ie.rate          -- epinephrine
            WHEN ie.itemid = 221289 THEN ie.rate          -- dopamine
            WHEN ie.itemid = 222168 THEN ie.rate          -- dobutamine
            ELSE NULL
        END AS dose
    FROM inputevents ie
    WHERE ie.itemid IN (221906,222315,221289,222168)
      AND ie.rate IS NOT NULL
), vaso_hour AS (
    SELECT
        stay_id,
        hr,
        MAX(dose) AS max_dose
    FROM doses
    GROUP BY stay_id, hr
)
SELECT
    stay_id,
    hr,
    max_dose,
    CASE
        WHEN max_dose IS NULL            THEN 0
        WHEN max_dose >= 0.10            THEN 4
        WHEN max_dose BETWEEN 0.01 AND .099 THEN 3
        ELSE 0
    END AS sofa_cv_vaso
FROM vaso_hour;
