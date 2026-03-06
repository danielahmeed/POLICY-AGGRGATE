#!/usr/bin/env python3
"""Load sample CSVs into MongoDB Atlas. Run before metadata_standardization."""
import csv
import os
import pathlib
from pymongo import MongoClient

MONGODB_URI = os.getenv(
    "MONGODB_URI",
    "mongodb+srv://praticks2003_db_user:cPZqSJF3LPPsHSEv@cluster0.enwyvnr.mongodb.net/?appName=Cluster0",
)
DB_NAME = "Backend_databases"
DATASETS = pathlib.Path(__file__).parent.parent / "Datasets"

CONFIGS = [
    ("Customer_data.csv", "customer_details", {"customerId": int, "refPhoneMobile": lambda x: int(x) if x and x.isdigit() else x, "datBirthCust": int}),
    ("Auto_Insurance.csv", "auto_insurance", {"DOB": int, "Mobile": int, "PolicyStartDate": int, "PolicyEndDate": int, "IDV": int, "AnnualPremium": int}),
    ("Life_Insurance.csv", "life_insurance", {"DOB": int, "Mobile": int, "PolicyStart": int, "PolicyEnd": int, "SumAssured": int, "AnnualPrem": int, "PolicyTerm": int}),
    ("Health_Insurance.csv", "health_insurance", {"DOB": int, "Mobile": int, "Coverage Amount": int, "Annual Premium": int, "Policy Start Date": int, "Policy End Date": int}),
]


def coerce_row(row, types):
    for k, v in row.items():
        if k in types and v:
            try:
                row[k] = types[k](v)
            except (ValueError, TypeError):
                pass
    return row


def main():
    client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=10000)
    db = client[DB_NAME]

    for filename, coll_name, types in CONFIGS:
        path = DATASETS / filename
        if not path.exists():
            print(f"Skip (not found): {filename}")
            continue
        with open(path, "r", encoding="utf-8") as f:
            rows = list(csv.DictReader(f))
        for r in rows:
            coerce_row(r, types)
        db[coll_name].delete_many({})
        db[coll_name].insert_many(rows)
        print(f"Loaded {len(rows)} docs into {coll_name}")
    print("Done. Run metadata_standardization.py then policy_stitching.py")


if __name__ == "__main__":
    main()
