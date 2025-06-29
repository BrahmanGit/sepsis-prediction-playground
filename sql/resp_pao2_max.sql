-- 7a) Maximum PaO₂ per ICU stay (for best oxygenation)

WITH base_icustays AS (
  SELECT
    subject_id,
    hadm_id,
    stay_id,
    intime,
    intime + INTERVAL '24 hours' AS end_24h
  FROM mimiciv_icu.icustays
),

resp_pao2_max AS (
  SELECT
    b.stay_id,
    MAX(l.value) AS max_pao2
  FROM mimiciv_hosp.labevents l
  JOIN base_icustays b
    ON l.subject_id = b.subject_id
   AND l.hadm_id    = b.hadm_id
  WHERE l.itemid IN (
    -- ► Replace with actual “PaO2” itemids from mimiciv_hosp.d_labitems:
    --    e.g. run:
    --      SELECT itemid, label
    --      FROM mimiciv_hosp.d_labitems
    --      WHERE LOWER(label) LIKE '%pao2%';
    50821,  -- common examples: “pO2” in ABG panels
    52042       -- (any additional “pO2” codes you find)
  )
    AND l.charttime BETWEEN b.intime AND b.end_24h
  GROUP BY b.stay_id
)

SELECT
  rp.stay_id,
  rp.max_pao2
FROM resp_pao2_max rp
ORDER BY rp.stay_id
LIMIT 100;

-- We need both PaO₂ (arterial) from labevents and FiO₂ (FIO₂) from chartevents, then compute the ratio.
-- In SOFA we want the lowest PF ratio, so we ultimately take highest PaO₂ (thus max pao2) to pair with the highest FiO₂ (worst ratio).
