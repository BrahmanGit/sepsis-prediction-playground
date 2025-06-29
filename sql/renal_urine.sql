-- 2b) Total urine output in 24 h (a second renal measure)

WITH base_icustays AS (
  SELECT
    subject_id,
    hadm_id,
    stay_id,
    intime,
    intime + INTERVAL '24 hours' AS end_24h
  FROM mimiciv_icu.icustays
),

renal_urine AS (
  SELECT
    b.stay_id,
    SUM(o.value) AS total_urine_ml_24h
  FROM mimiciv_icu.outputevents o
  JOIN base_icustays b
    ON o.subject_id = b.subject_id
    AND o.hadm_id    = b.hadm_id
  WHERE o.itemid IN (
    -- Insert the itemids for “urine output” from d_items (e.g., itemid = 40055, 43175, etc.)
    226566 , 227489
  )
    AND o.charttime BETWEEN b.intime AND b.end_24h
  GROUP BY b.stay_id
)

SELECT
  ru.stay_id,
  ru.total_urine_ml_24h
FROM renal_urine ru
ORDER BY ru.stay_id
LIMIT 100;

-- 226566 (“Urine and GU Irrigant Out”) 227489 (“GU Irrigant/Urine Volume Out”)
-- later to compare max_creatinine vs. total_urine_ml_24h in final join, to pick whichever gives worse SOFA score
