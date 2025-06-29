import pandas as pd
from sqlalchemy import create_engine, text

db_uri = "postgresql+psycopg2://mimicuser:mimic@localhost:5432/mimiciv"

engine = create_engine(
    db_uri,
    connect_args={"options": "-c search_path=mimiciv_hosp,mimiciv_icu"}
)

# --- SQL Query ---
sql = text ("""
SELECT  p.subject_id AS patient_no,
p.anchor_age AS age,
p.gender AS sex

FROM mimiciv_hosp.patients p
JOIN mimiciv_hosp.admissions ad USING (subject_id) --joins the two tables, with shared key: subject_id
WHERE ad.admittime IS NOT NULL --to ensure patient who have actual hospital admission time
GROUP BY p.subject_id, age, p.gender --now we initiate the output
ORDER BY RANDOM()
LIMIT 100;

-- anchor_age is not real age, the database is de-identified, but useful for comparing with other patients. 

"""
)

with engine.connect() as conn:
    df = pd.read_sql_query(sql, conn)

output_path = "random_patients_age_sex.csv"
df.to_csv(output_path, index=False)

print(f"Done! Saved {len(df)} rows to {output_path}")




