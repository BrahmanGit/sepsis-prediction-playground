/* =========================================================================
   06_coag_hourly.sql
   Hourly worst platelet count → SOFA-Coag (0-4)
   ========================================================================= */
SET search_path TO mimiciv_icu;

DROP MATERIALIZED VIEW IF EXISTS sofa_coag_hourly CASCADE;

CREATE MATERIALIZED VIEW sofa_coag_hourly AS
WITH plts AS (
    SELECT
        stay_id,
        date_trunc('hour', charttime) AS hr,
        MIN(valuenum)                 AS plt_min
    FROM mimiciv_hosp.labevents
    WHERE itemid = 51265             -- Platelet
      AND valuenum IS NOT NULL
    GROUP BY stay_id, hr
)
SELECT
    stay_id,
    hr,
    plt_min,
    CASE
        WHEN plt_min IS NULL  THEN NULL
        WHEN plt_min < 20     THEN 4
        WHEN plt_min < 50     THEN 3
        WHEN plt_min < 100    THEN 2
        WHEN plt_min < 150    THEN 1
        ELSE 0
    END AS sofa_coag
FROM plts;
