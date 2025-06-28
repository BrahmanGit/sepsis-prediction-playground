-- 7b) Maximum FiO₂ per ICU stay
WITH base_icustays AS (
  SELECT
    stay_id,
    intime,
    intime + INTERVAL '24 hours' AS end_24h
  FROM mimiciv_icu.icustays
),

-- 1) Pull all hourly P/F ratios from the derived “bg” table for each stay
pafi AS (
  SELECT
    b.stay_id,
    bg.charttime,
    -- Choose the ventilated ratio if available, else non‐ventilated
    COALESCE(bg.pao2fio2ratio_vent, bg.pao2fio2ratio_novent) AS pf_ratio
  FROM mimiciv_derived.bg bg
  JOIN base_icustays b
    ON bg.stay_id = b.stay_id
   AND bg.charttime BETWEEN b.intime AND b.end_24h
),

-- 2) Take the minimum P/F ratio over that 24 h window
resp_pf_min AS (
  SELECT
    stay_id,
    MIN(pf_ratio) AS min_pf_ratio
  FROM pafi
  GROUP BY stay_id
)

SELECT
  rf.stay_id,
  rf.min_pf_ratio
FROM resp_pf_min rf
ORDER BY rf.stay_id
LIMIT 100;

-- Once we have max_pao2 and max_fio2, the “worst” PF ratio is:
-- min_PF_ratio = max_pao2 / max_fio2