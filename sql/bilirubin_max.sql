-- 4) Maximum total bilirubin per ICU stay

WITH base_icustays AS (
  SELECT
    subject_id,
    hadm_id,
    stay_id,
    intime,
    intime + INTERVAL '24 hours' AS end_24h
  FROM mimiciv_icu.icustays
),

bilirubin_max AS (
  SELECT
    b.stay_id,
    MAX(l.value) AS max_bilirubin
  FROM mimiciv_hosp.labevents l
  JOIN base_icustays b
    ON l.subject_id = b.subject_id
    AND l.hadm_id    = b.hadm_id
  WHERE l.itemid IN (
    -- Bilirubin itemids from sofa.sql; e.g., (50872, 50885, …)
    50885, 53089
  )
    AND l.charttime BETWEEN b.intime AND b.end_24h
  GROUP BY b.stay_id
)

SELECT
  bm.stay_id,
  bm.max_bilirubin
FROM bilirubin_max bm
ORDER BY bm.stay_id
LIMIT 100;
-- “Worst” bilirubin → the highest value in 24 h → MAX(l.value)