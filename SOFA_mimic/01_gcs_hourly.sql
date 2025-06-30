/* ====================================================================
   01_gcs_hourly.sql
   Creates an hourly table of the worst GCS and mapped SOFA-CNS points
   Dependencies: mimiciv_icu.chartevents, mimiciv_icu.icustays
   ==================================================================== */
SET search_path TO mimiciv_icu;

DROP MATERIALIZED VIEW IF EXISTS gcs_hourly CASCADE;

CREATE MATERIALIZED VIEW gcs_hourly AS
WITH gcs_raw AS (
    SELECT
        ce.stay_id,
        date_trunc('hour', ce.charttime)                         AS hr,
        CASE
            WHEN ce.itemid = 223900 THEN ce.valuenum             -- documented “GCS Total”
            WHEN ce.itemid = 220739 THEN ce.valuenum +  -- motor
                 MAX(valuenum) FILTER (WHERE itemid = 223902) +  -- eye
                 MAX(valuenum) FILTER (WHERE itemid = 223901)    -- verbal
        END                                                      AS gcs_val
    FROM chartevents ce
    WHERE ce.itemid IN (223900, 223902, 223901, 220739)
      AND ce.valunum IS NOT NULL
    GROUP BY ce.stay_id, ce.charttime, ce.itemid, ce.valuenum
), gcs_hour AS (
    SELECT
        stay_id,
        hr,
        MIN(gcs_val) AS worst_gcs   -- lower value = worse neuro status
    FROM gcs_raw
    GROUP BY stay_id, hr
)
SELECT
    stay_id,
    hr,
    worst_gcs,
    /* ------------ map to SOFA-CNS points ------------ */
    CASE
        WHEN worst_gcs IS NULL THEN NULL
        WHEN worst_gcs >= 15            THEN 0
        WHEN worst_gcs BETWEEN 13 AND14 THEN 1
        WHEN worst_gcs BETWEEN 10 AND12 THEN 2
        WHEN worst_gcs BETWEEN  6 AND 9 THEN 3
        ELSE                                4
    END AS sofa_cns
FROM gcs_hour;
