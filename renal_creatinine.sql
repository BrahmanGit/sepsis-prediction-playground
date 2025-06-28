-- 2a) Max creatinine per ICU stay (0–24 h)
WITH base_icustays AS (
  SELECT
    subject_id,
    hadm_id,
    stay_id,
    intime,
    intime + INTERVAL '24 hours' AS end_24h
  FROM mimiciv_icu.icustays
),

 renal_creatinine AS (
  SELECT
    b.stay_id,
    MAX(l.value) AS max_creatinine
  FROM mimiciv_hosp.labevents l
  JOIN base_icustays b
    ON l.subject_id = b.subject_id
    AND l.hadm_id     = b.hadm_id
  WHERE l.itemid IN (
    -- Copy the exact itemids from sofa.sql for creatinine, e.g. (50912, 50913, ...)
    -- (Example; replace with the full list in `sofa.sql`)
    50912, 51081
  )
    AND l.charttime BETWEEN b.intime AND b.end_24h
  GROUP BY b.stay_id
)

SELECT
  rc.stay_id,
  rc.max_creatinine
FROM renal_creatinine rc
ORDER BY rc.stay_id
LIMIT 100;


-- SOFA cares about serum (or plasma) creatinine only. thus those two specific numbers.