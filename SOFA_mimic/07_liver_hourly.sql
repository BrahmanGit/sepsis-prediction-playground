/* =========================================================================
   07_liver_hourly.sql
   Hourly worst total bilirubin → SOFA-Liver (0-4)
   ========================================================================= */
SET search_path TO mimiciv_icu;

DROP MATERIALIZED VIEW IF EXISTS sofa_liver_hourly CASCADE;

CREATE MATERIALIZED VIEW sofa_liver_hourly AS
WITH bil AS (
    SELECT
        stay_id,
        date_trunc('hour', charttime) AS hr,
        MAX(valuenum)                 AS bilirubin
    FROM mimiciv_hosp.labevents
    WHERE itemid = 50885             -- Bilirubin total
      AND valuenum IS NOT NULL
    GROUP BY stay_id, hr
)
SELECT
    stay_id,
    hr,
    bilirubin,
    CASE
        WHEN bilirubin IS NULL THEN NULL
        WHEN bilirubin >= 12   THEN 4
        WHEN bilirubin >= 6    THEN 3
        WHEN bilirubin >= 2    THEN 2
        WHEN bilirubin >= 1.2  THEN 1
        ELSE 0
    END AS sofa_liver
FROM bil;
