import pandas as pd
from sqlalchemy import create_engine, text

# ── 1) Connect to PostgreSQL ─────────────────────────────────────────────────
engine = create_engine(
    "postgresql+psycopg2://mimicuser:<your_password>@localhost:5432/mimiciv",
    connect_args={"options": "-csearch_path=mimiciv_icu,mimiciv_hosp"}
)

# ── 2) Step 1: Randomly select 5 eligible ICU stays with platelet labs ───────
get_stays_sql = text("""
WITH eligible_stays AS (
  SELECT DISTINCT
    icu.subject_id,
    icu.hadm_id,
    icu.stay_id,
    icu.intime,
    icu.outtime
  FROM mimiciv_icu.icustays icu
  JOIN mimiciv_hosp.labevents le
    ON icu.subject_id = le.subject_id
   AND icu.hadm_id    = le.hadm_id
   AND le.charttime BETWEEN icu.intime AND icu.outtime
  WHERE le.itemid = 51265
    AND le.valuenum IS NOT NULL
)
SELECT *
FROM eligible_stays
ORDER BY RANDOM()
LIMIT 5;
""")

with engine.connect() as conn:
    stays = pd.read_sql_query(get_stays_sql, conn)

if stays.empty:
    raise RuntimeError("❌ No ICU stays with platelet data found.")

# ── 3) Pull platelet measurements for each stay ──────────────────────────────
all_rows = []
for _, r in stays.iterrows():
    sql = text("""
        SELECT subject_id, charttime, valuenum
        FROM mimiciv_hosp.labevents
        WHERE subject_id = :sid
          AND hadm_id = :hadm
          AND itemid = 51265
          AND charttime BETWEEN :intime AND :outtime
          AND valuenum IS NOT NULL;
    """)
    labs = pd.read_sql_query(sql, engine, params={
        "sid": r.subject_id,
        "hadm": r.hadm_id,
        "intime": r.intime,
        "outtime": r.outtime
    })
    if not labs.empty:
        labs["stay_id"] = r.stay_id
        labs["icu_day"] = (
            pd.to_datetime(labs["charttime"]).dt.normalize() -
            pd.to_datetime(r.intime).normalize()
        ).dt.days
        labs["platelet_val"] = labs["valuenum"]
        all_rows.append(labs[["subject_id", "stay_id", "icu_day", "platelet_val"]])

if not all_rows:
    raise RuntimeError("❌ No platelet values found for the selected stays.")

df_all = pd.concat(all_rows)

# ── 4) Compute daily minimum and save ────────────────────────────────────────
df_grouped = (
    df_all.groupby(["subject_id", "stay_id", "icu_day"], as_index=False)
          .agg(platelet_min=("platelet_val", "min"))
          .sort_values(["subject_id", "icu_day"])
)

df_grouped.to_csv("platelet_min_long.csv", index=False)

df_wide = df_grouped.pivot(index="subject_id", columns="icu_day", values="platelet_min")
df_wide.to_csv("platelet_min_wide.csv", index=True)

print("✅ Done! Files saved:")
print(" • platelet_min_long.csv")
print(" • platelet_min_wide.csv")
