/* =========================================================================
   04_cv_hourly.sql
   Final hourly cardiovascular SOFA (0-4) from MAP + vasopressors (file 2+ file 3)
   ========================================================================= */
SET search_path TO mimiciv_icu;

DROP MATERIALIZED VIEW IF EXISTS sofa_cv_hourly CASCADE;

CREATE MATERIALIZED VIEW sofa_cv_hourly AS
SELECT
    m.stay_id,
    m.hr,
    -- Merge rules: if vaso tier ≥3, keep it; else use MAP tier (0/1)
    GREATEST(v.sofa_cv_vaso, m.sofa_cv_map) AS sofa_cv
FROM map_hourly      m
LEFT JOIN vaso_hourly v USING (stay_id, hr);
