import os

from google.cloud import bigquery

TABLES = [
    "hospital_readmission_penalty",
    "hospital_penalty_conditions",
    "readmission_penalty_by_condition",
    "readmission_penalty_by_state",
    "penalty_vs_quality",
]


def main():
    client = bigquery.Client(project=os.environ["GCP_PROJECT"])
    for table in TABLES:
        df = client.query(f"select * from `{client.project}.medicare.{table}`").to_dataframe()
        df.to_csv(f"tableau/extracts/{table}.csv", index=False)
        print(f"{table}: {len(df):,} rows")


if __name__ == "__main__":
    main()
