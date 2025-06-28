-- 3) Minimum platelet count (coagulation) per ICU stay
-- Purpose: For each ICU stay, pull the MIN platelet count in the first 24 h.

WITH base_icustays AS (
  SELECT
    subject_id,
    hadm_id,
    stay_id,
    intime,
    intime + INTERVAL '24 hours' AS end_24h
  FROM mimiciv_icu.icustays
),

platelet_min AS (
  SELECT
    b.stay_id,
    MIN(l.value) AS min_platelet
  FROM mimiciv_hosp.labevents l
  JOIN base_icustays b
    ON l.subject_id = b.subject_id
   AND l.hadm_id    = b.hadm_id
  WHERE l.itemid IN (
    -- ► Replace these with the actual “Platelet” itemids from mimiciv_hosp.d_labitems:
    --    e.g. run:
    --      SELECT itemid, label
    --      FROM mimiciv_hosp.d_labitems
    --      WHERE LOWER(label) LIKE '%platelet%';
    51265,  -- example: “Platelets”
    53189
  )
    AND l.charttime BETWEEN b.intime AND b.end_24h
  GROUP BY b.stay_id
)

SELECT
  pm.stay_id,
  pm.min_platelet
FROM platelet_min pm
ORDER BY pm.stay_id
LIMIT 100;
