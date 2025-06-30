/* =========================================================================
   05_resp_hourly.sql
   Hourly PaO2 / FiO2 ratio + mech-vent flag → SOFA-Resp
   ========================================================================= */
SET search_path TO mimiciv_icu;

DROP MATERIALIZED VIEW IF EXISTS sofa_resp_hourly CASCADE;

WITH fio2 AS (
    SELECT
        stay_id,
        date_trunc('hour', charttime) AS hr,
        AVG(valuenum)                AS fio2_avg
    FROM chartevents
    WHERE itemid = 223835            -- FiO2 (%)
      AND valuenum IS NOT NULL
    GROUP BY stay_id, hr
),
pao2 AS (
    SELECT
        stay_id,
        date_trunc('hour', charttime) AS hr,
        AVG(valuenum)                 AS pao2_avg
    FROM mimiciv_hosp.labevents
    WHERE itemid IN (50821,50822)    -- PaO2 arterial
      AND valuenum IS NOT NULL
    GROUP BY stay_id, hr
),
pf AS (
    SELECT
        p.stay_id,
        p.hr,
        pao2_avg / NULLIF(f.fio2_avg,0) AS pf_ratio
    FROM pao2 p
    LEFT JOIN fio2 f USING (stay_id, hr)
)
SELECT
    stay_id,
    hr,
    pf_ratio,
    CASE
        WHEN pf_ratio IS NULL        THEN NULL
        WHEN pf_ratio < 100          THEN 4
        WHEN pf_ratio < 200          THEN 3
        WHEN pf_ratio < 300          THEN 2
        WHEN pf_ratio < 400          THEN 1
        ELSE 0
    END AS sofa_resp
INTO MATERIALIZED VIEW sofa_resp_hourly;
