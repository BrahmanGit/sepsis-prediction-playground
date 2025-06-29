import pandas as pd
from sqlalchemy import create_engine, text

# ── 1) Database connection ─────────────────────────────────────────────────────
db_uri = "postgresql+psycopg2://mimicuser:mimic@localhost:5432/mimiciv"
engine = create_engine(
    db_uri,
    connect_args={"options": "-csearch_path=mimiciv_hosp,mimiciv_icu,mimiciv_derived"}
)

# ── 2) Query all tables and columns in the three schemas ────────────────────────
sql = text("""
SELECT
  table_schema,
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema IN ('mimiciv_hosp', 'mimiciv_icu', 'mimiciv_derived')
ORDER BY table_schema, table_name, ordinal_position;
""")

# ── 3) Execute and load into pandas DataFrame ───────────────────────────────────
with engine.connect() as conn:
    df_columns = pd.read_sql_query(sql, conn)

# ── 4) Save to CSV for sharing, or inspect directly ─────────────────────────────
output_file = "mimiciv_all_tables_columns.csv"
df_columns.to_csv(output_file, index=False)

print(f"Saved table/column catalog to '{output_file}'.")
print(df_columns.head(20))
