/* =========================================================================
   02_map_hourly.sql
   Hourly minimum Mean Arterial Pressure (MAP) + SOFA‐CV (MAP-only version)
   ========================================================================= */
SET search_path TO mimiciv_icu;

DROP MATERIALIZED VIEW IF EXISTS map_hourly CASCADE;

CREATE MATERIALIZED VIEW map_hourly AS
WITH map_raw AS (
    SELECT
        stay_id,
        date_trunc('hour', charttime) AS hr,
        valuenum                       AS map_val
    FROM chartevents
    WHERE itemid IN (220045, 225312)      -- arterial & NIBP MAP
      AND valuenum IS NOT NULL
),
map_hour AS (
    SELECT
        stay_id,
        hr,
        MIN(map_val) AS map_min
    FROM map_raw
    GROUP BY stay_id, hr
)
SELECT
    stay_id,
    hr,
    map_min,
    CASE
        WHEN map_min IS NULL THEN NULL
        WHEN map_min < 70    THEN 1       -- SOFA cardiovascular = 1 if <70
        ELSE 0
    END AS sofa_cv_map
FROM map_hour;
