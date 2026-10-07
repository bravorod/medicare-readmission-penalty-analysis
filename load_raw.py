import io
import os
import re
import zipfile

import pandas as pd
import requests
from google.cloud import bigquery

SOURCES = {
    "hrrp_penalties": "https://www.cms.gov/files/zip/fy2026-hospital-readmissions-reduction-program-supplemental-data-file.zip",
    "hrrp_readmissions": "https://data.cms.gov/provider-data/sites/default/files/resources/a171bc36c488d3e0dc33ec63abb469a6_1770163617/FY_2026_Hospital_Readmissions_Reduction_Program_Hospital.csv",
    "inpatient_payments": "https://data.cms.gov/sites/default/files/2026-04/d9525c59-002b-45b3-af22-c81061a62dcd/mup_inp_ry26_p04_v10_dy24_prv.csv",
    "hospitals": "https://data.cms.gov/provider-data/sites/default/files/resources/893c372430d9d71a1c52737d01239d47_1785189955/Hospital_General_Information.csv",
    "patient_survey": "https://data.cms.gov/provider-data/sites/default/files/resources/78a50346fbe828ea0ce2837847af6a7c_1785189950/HCAHPS-Hospital.csv",
    "death_rates": "https://data.cms.gov/provider-data/sites/default/files/resources/6af7c44d77436e5a1caac3ce39a83fe9_1785189947/Complications_and_Deaths-Hospital.csv",
}


def read(url):
    content = requests.get(url, timeout=300).content
    if url.endswith(".zip"):
        with zipfile.ZipFile(io.BytesIO(content)) as z:
            df = pd.read_csv(z.open("FR FY 2026.txt"), sep="\t", skiprows=1, dtype=str)
    else:
        df = pd.read_csv(io.BytesIO(content), dtype=str)
    df.columns = [re.sub(r"[^0-9a-z]+", "_", c.strip().lower()).strip("_") for c in df.columns]
    return df.loc[:, ~df.columns.str.startswith("unnamed")]


def main():
    client = bigquery.Client(project=os.environ["GCP_PROJECT"])
    client.create_dataset("raw", exists_ok=True)
    job_config = bigquery.LoadJobConfig(write_disposition="WRITE_TRUNCATE")
    for name, url in SOURCES.items():
        df = read(url)
        client.load_table_from_dataframe(df, f"{client.project}.raw.{name}", job_config=job_config).result()
        print(f"{name}: {len(df):,} rows")


if __name__ == "__main__":
    main()
