-- 6) Minimum GCS total score per ICU stay
WITH base_icustays AS (
  SELECT
    subject_id,
    hadm_id,
    stay_id,
    intime,
    intime + INTERVAL '24 hours' AS end_24h
  FROM mimiciv_icu.icustays
),

-- 1) Pull each GCS component at each timestamp (Eye, Motor, Verbal)
gcs_components AS (
  SELECT
    c.subject_id,
    c.hadm_id,
    c.stay_id,
    c.charttime,
    COALESCE(
      MAX(CASE WHEN c.itemid = 220739 THEN c.valuenum END)
      OVER (PARTITION BY c.subject_id, c.hadm_id, c.stay_id, c.charttime),
      0
    )
    +
    COALESCE(
      MAX(CASE WHEN c.itemid = 223901 THEN c.valuenum END)
      OVER (PARTITION BY c.subject_id, c.hadm_id, c.stay_id, c.charttime),
      0
    )
    +
    COALESCE(
      MAX(CASE WHEN c.itemid = 223900 THEN c.valuenum END)
      OVER (PARTITION BY c.subject_id, c.hadm_id, c.stay_id, c.charttime),
      0
    ) AS gcs_total
  FROM mimiciv_icu.chartevents c
  WHERE c.itemid IN (220739, 223901, 223900)
),

-- 2) Restrict to 0–24 h window and take the minimum total per stay
cns_gcs_min AS (
  SELECT
    b.stay_id,
    MIN(gc.gcs_total) AS min_gcs_total
  FROM gcs_components gc
  JOIN base_icustays b
    ON gc.subject_id = b.subject_id
   AND gc.hadm_id    = b.hadm_id
   AND gc.charttime BETWEEN b.intime AND b.end_24h
  GROUP BY b.stay_id
)

SELECT
  cm.stay_id,
  cm.min_gcs_total
FROM cns_gcs_min cm
ORDER BY cm.stay_id
LIMIT 100;

-- sofa.sql already does the “unpivot” of GCS components into one total score, so we will copy that logic.
-- The minimum total GCS in 24 h is what matters for SOFA.