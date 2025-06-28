-- 1) Define each ICU stay with its 24 h window
WITH base_icustays AS (
  SELECT
    subject_id,
    hadm_id,
    stay_id,
    intime,
    -- Create an “end_24h” column exactly 24 h after ICU intime
    intime + INTERVAL '24 hours' AS end_24h
  FROM mimiciv_icu.icustays
)
