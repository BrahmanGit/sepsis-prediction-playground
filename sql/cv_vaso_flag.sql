-- 5b) Flag if any vasopressor administered (norepinephrine, epinephrine, etc.)
WITH base_icustays AS (
  SELECT
    subject_id,
    hadm_id,
    stay_id,
    intime,
    intime + INTERVAL '24 hours' AS end_24h
  FROM mimiciv_icu.icustays
),

-- 1) Find any vasopressor infusions in CareVue inputevents
vaso_cv AS (
  SELECT
    ie.subject_id,
    ie.hadm_id,
    ie.stay_id,
    ie.rate AS amount,      -- infusion rate
    ie.charttime,
    di.label AS drug_name
  FROM mimiciv_icu.inputevents_cv ie
  JOIN mimiciv_icu.d_items di
    ON ie.itemid = di.itemid
  WHERE LOWER(di.label) LIKE '%norepinephrine%'
     OR LOWER(di.label) LIKE '%epinephrine%'
     OR LOWER(di.label) LIKE '%dobutamine%'
     OR LOWER(di.label) LIKE '%dopamine%'
),

-- 2) Find any vasopressor infusions in MetaVision inputevents
vaso_mv AS (
  SELECT
    ie.subject_id,
    ie.hadm_id,
    ie.stay_id,
    ie.rate AS amount,
    ie.charttime,
    di.label AS drug_name
  FROM mimiciv_icu.inputevents_mv ie
  JOIN mimiciv_icu.d_items di
    ON ie.itemid = di.itemid
  WHERE LOWER(di.label) LIKE '%norepinephrine%'
     OR LOWER(di.label) LIKE '%epinephrine%'
     OR LOWER(di.label) LIKE '%dobutamine%'
     OR LOWER(di.label) LIKE '%dopamine%'
),

-- 3) Find any vasopressor prescriptions (hospital side)
vaso_rx AS (
  SELECT
    p.subject_id,
    p.hadm_id,
    p.stay_id,
    p.dose AS amount,       -- prescription dose (could be mg or mcg; interpret carefully)
    p.starttime AS charttime,
    p.drug AS drug_name
  FROM mimiciv_hosp.prescriptions p
  WHERE LOWER(p.drug) LIKE '%norepinephrine%'
     OR LOWER(p.drug) LIKE '%epinephrine%'
     OR LOWER(p.drug) LIKE '%dobutamine%'
     OR LOWER(p.drug) LIKE '%dopamine%'
),

-- 4) Combine all vasopressor events into one set “i”
all_vaso AS (
  SELECT * FROM vaso_cv
  UNION ALL
  SELECT * FROM vaso_mv
  UNION ALL
  SELECT * FROM vaso_rx
),

-- 5) Filter to first 24 h per stay, then take the MAX rate/dose
cv_vaso_flag AS (
  SELECT
    b.stay_id,
    MAX(i.amount) AS max_vaso_rate
  FROM all_vaso i
  JOIN base_icustays b
    ON i.subject_id = b.subject_id
   AND i.hadm_id    = b.hadm_id
  WHERE i.charttime BETWEEN b.intime AND b.end_24h
  GROUP BY b.stay_id
)

SELECT
  vf.stay_id,
  vf.max_vaso_rate
FROM cv_vaso_flag vf
ORDER BY vf.stay_id
LIMIT 100;

-- UNION ICU input events + hospital prescriptions to catch any vasopressor given
-- ?? We take the maximum dose/rate administered in 24 h → MAX(...). If > 0, we know pressors were used. ??
-- in final SOFA calculation: if max_vaso_rate > 0, we score that instead of MAP
