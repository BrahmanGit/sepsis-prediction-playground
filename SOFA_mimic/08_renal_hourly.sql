/* =========================================================================
   08_renal_hourly.sql
   Hourly worst creatinine → SOFA-Renal (0-4)
   ========================================================================= */
SET search_path TO mimiciv_icu;

DROP MATERIALIZED VIEW IF EXISTS sofa_renal_hourly CASCADE;

CREATE MATERIALIZED VIEW sofa_renal_hourly AS
WITH cr AS (
    SELECT
        stay_id,
        date_trunc('hour', charttime) AS hr,
        MAX(valuenum)                 AS creat
    FROM mimiciv_hosp.labevents
    WHERE itemid = 50912             -- Creatinine
      AND valuenum IS NOT NULL
    GROUP BY stay_id, hr
)
SELECT
    stay_id,
    hr,
    creat,
    CASE
        WHEN creat IS NULL    THEN NULL
        WHEN creat >= 5.0     THEN 4
        WHEN creat >= 3.5     THEN 3
        WHEN creat >= 2.0     THEN 2
        WHEN creat >= 1.2     THEN 1
        ELSE 0
    END AS sofa_renal
FROM cr;
