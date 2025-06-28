import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql://postgres:Mimic25@localhost:5432/icu_projects"
)

df = pd.read_excel("SOAP_Gesamt.xls", sheet_name="Stamm")
df.to_sql("soap_stamm", engine, if_exists="replace", index=False)

print("Loaded", len(df), "rows into icu_projects.soap_stamm"