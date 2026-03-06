#!/usr/bin/env python3
"""
Metadata Engine - Configuration-driven header standardization for insurer data.

How this satisfies project requirements:
- Metadata Engine: mapping_config separates "logic" from "format" of insurer files
- Header Standardization: Different source names (refCustItNum, PAN) → single key (pan)
- Unified View Preparation: Standardized output enables policy-to-customer linking
  without knowing which insurer sent the data.

Prerequisites: pip install pymongo
Run: python metadata_standardization.py
"""
import json
import os
from pymongo import MongoClient

# ---------------------------------------------------------------------------
# 1. Metadata Configuration (Configuration Layer)
# Add new insurers by extending this dict - no code changes to get_standardized_data
# ---------------------------------------------------------------------------
MAPPING_CONFIG = {
    "auto_insurance": {
        "policy_id": "PolicyNumber",
        "premium": "AnnualPremium",
        "start_date": "PolicyStartDate",
        "policy_end": "PolicyEndDate",
        "sum_assured": "IDV",
        "pan": "PAN",
        "mobile": "Mobile",
        "email": "Email",
        "dob": "DOB",
        "insurer": "Insurer",
    },
    "life_insurance": {
        "policy_id": "PolicyNum",
        "premium": "AnnualPrem",
        "start_date": "PolicyStart",
        "policy_end": "PolicyEnd",
        "sum_assured": "SumAssured",
        "pan": "PAN",
        "mobile": "Mobile",
        "email": "Email",
        "dob": "DOB",
        "insurer": "Insurer",
    },
    "health_insurance": {
        "policy_id": "Policy Number",
        "premium": "Annual Premium",
        "start_date": "Policy Start Date",
        "policy_end": "Policy End Date",
        "sum_assured": "Coverage Amount",
        "pan": "PAN",
        "mobile": "Mobile",
        "email": "Email",
        "dob": "DOB",
        "insurer": "Insurer",
    },
    "customer_details": {
        "cust_id": "customerId",
        "pan": "refCustItNum",
        "mobile": "refPhoneMobile",
        "email": "custEmailID",
        "dob": "datBirthCust",
    },
}

MONGODB_URI = os.getenv(
    "MONGODB_URI",
    "mongodb+srv://praticks2003_db_user:cPZqSJF3LPPsHSEv@cluster0.enwyvnr.mongodb.net/?appName=Cluster0",
)
DB_NAME = "Backend_databases"


def get_standardized_data(collection_name: str, db) -> list:
    """Transform raw collection data to standardized format per mapping_config."""
    mapping = MAPPING_CONFIG.get(collection_name, {})
    if not mapping:
        print(f"  No mapping config for {collection_name}")
        return []

    coll = db[collection_name]
    docs = list(coll.find({}))
    standardized = []
    
    for doc in docs:
        std_doc = {}
        for std_key, source_key in mapping.items():
            std_doc[std_key] = doc.get(source_key)
        standardized.append(std_doc)
    
    return standardized


def main():
    import pathlib

    client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
    db = client[DB_NAME]

    print("=" * 60)
    print("Metadata Engine - Standardized Output")
    print("=" * 60)

    collections = [
        "life_insurance",
        "customer_details",
        "auto_insurance",
        "health_insurance",
    ]

    full_output = {"summary": {}, "data": {}}

    for coll_name in collections:
        print(f"\n--- Standardizing {coll_name} ---")
        try:
            data = get_standardized_data(coll_name, db)
            count = len(data)
            full_output["summary"][coll_name] = count
            full_output["data"][coll_name] = data

            print(f"Total records: {count}")
            if data:
                print("Sample:")
                print(json.dumps(data[0], indent=2))
            else:
                print("(No documents or collection not found)")
        except Exception as e:
            print(f"Error: {e}")
            full_output["summary"][coll_name] = 0
            full_output["data"][coll_name] = []

    # Write full output to file so you can see everything that was done
    script_dir = pathlib.Path(__file__).parent
    output_file = script_dir / "standardized_output.json"
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(full_output, f, indent=2, default=str)

    print("\n" + "=" * 60)
    print("Full output saved to:")
    print(f"  {output_file}")
    print("Open this file to see all standardized records.")
    print("=" * 60)


if __name__ == "__main__":
    main()
