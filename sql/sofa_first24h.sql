-- 8) Combine all organ-specific pulls into one “sofa_first24h” table
, sofa_first24h AS (
  SELECT
    b.stay_id,

    -- Renal: choose whichever worst: higher creatinine vs. low urine
    rcreat.max_creatinine,
    ruri.total_urine_ml_24h,

    -- Coagulation
    plate.min_platelet,

    -- Liver
    bil.max_bilirubin,

    -- Cardio: based on MAP vs. pressors
    cvmap.min_map,
    cvv.max_vaso_rate,

    -- CNS
    gcs.min_gcs_total,

    -- Respiratory
    resp_pao2.max_pao2,
    resp_fio2.max_fio2
  FROM base_icustays b

  LEFT JOIN renal_creatinine rcreat
    ON b.stay_id = rcreat.stay_id
  LEFT JOIN renal_urine ruri
    ON b.stay_id = ruri.stay_id

  LEFT JOIN platelet_min plate
    ON b.stay_id = plate.stay_id

  LEFT JOIN bilirubin_max bil
    ON b.stay_id = bil.stay_id

  LEFT JOIN cv_map_min cvmap
    ON b.stay_id = cvmap.stay_id
  LEFT JOIN cv_vaso_flag cvv
    ON b.stay_id = cvv.stay_id

  LEFT JOIN cns_gcs_min gcs
    ON b.stay_id = gcs.stay_id

  LEFT JOIN resp_pao2_max resp_pao2
    ON b.stay_id = resp_pao2.stay_id
  LEFT JOIN resp_fio2_max resp_fio2
    ON b.stay_id = resp_fio2.stay_id
)

--LEFT JOIN all staging tables on stay_id so that if a stay is missing a particular lab
-- (e.g., no bilirubin drawn), the columns become NULL.
-- in this case, i need to handle Null e.g. treating missing as zero, or exclude from scoring per
-- clinical trial.
