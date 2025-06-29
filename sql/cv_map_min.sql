-- 5a) Minimum MAP per ICU stay

WITH base_icustays AS (
  SELECT
    subject_id,
    hadm_id,
    stay_id,
    intime,
    intime + INTERVAL '24 hours' AS end_24h
  FROM mimiciv_icu.icustays
),

cv_map_min AS (
  SELECT
    b.stay_id,
    MIN(c.valuenum) AS min_map
  FROM mimiciv_icu.chartevents c
  JOIN base_icustays b
    ON c.subject_id = b.subject_id
   AND c.hadm_id    = b.hadm_id
  WHERE c.itemid IN (
    -- ► Replace with “Mean Arterial Pressure” itemids from mimiciv_icu.d_items:
    --    e.g. run:
    --      SELECT itemid, label
    --      FROM mimiciv_icu.d_items
    --      WHERE LOWER(label) LIKE '%mean arterial pressure%';
    224322,  -- example: “Arterial Blood Pressure [Mean]”
    225312  -- (if present in your version)
  )
    AND c.charttime BETWEEN b.intime AND b.end_24h
    AND c.valuenum IS NOT NULL
  GROUP BY b.stay_id
)

SELECT
  cv.stay_id,
  cv.min_map
FROM cv_map_min cv
ORDER BY cv.stay_id
LIMIT 100;

-- need to filter out Null
-- The “worst” (lowest) MAP → MIN(...).
-- In chartevents, MAP is usually recorded in valuenum or sometimes varchar_value. use whichever column contains numeric MAP