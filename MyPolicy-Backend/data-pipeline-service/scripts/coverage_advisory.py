#!/usr/bin/env python3
"""
Coverage Insights & Protection Gap Analysis - Advisory-Led UX

Transitions the system from a data repository to an "Advisory-Led UX" by:
- Product Presence Gap: Identifies missing insurance categories (Life, Health, Auto)
- Sum Insured Adequacy: Compares coverage vs industry benchmarks (e.g. 10x premium for Life)
- Temporal Gaps: Flags policies nearing expiry or already lapsed

Delivers: Unified Portfolio View, Coverage Insights, Human-Readable Advisory

Prerequisites: pip install pymongo
Run: python coverage_advisory.py [customer_id]   # e.g. 901120934
     python coverage_advisory.py --all           # all customers
     python coverage_advisory.py --demo          # insert demo policies and show full advisory
"""
import json
import os
import sys
from datetime import datetime
from pymongo import MongoClient

MONGODB_URI = os.getenv(
    "MONGODB_URI",
    "mongodb+srv://praticks2003_db_user:cPZqSJF3LPPsHSEv@cluster0.enwyvnr.mongodb.net/?appName=Cluster0",
)
DB_NAME = "Backend_databases"

# Advisory thresholds
REQUIRED_CATEGORIES = ["life_insurance", "health_insurance", "auto_insurance"]
LIFE_SUM_ASSURED_MULTIPLIER = 10  # Sum Assured should be >= premium * 10
HEALTH_COVERAGE_MIN = 300000  # Minimum recommended health coverage (INR)
AUTO_IDV_MIN = 100000  # Minimum recommended IDV for auto (INR)
DAYS_NEARING_EXPIRY = 90  # Flag if policy expires within 90 days


def parse_yyyymmdd(value):
    """Parse YYYYMMDD int to date, or return None."""
    if value is None:
        return None
    s = str(value)
    if len(s) != 8 or not s.isdigit():
        return None
    try:
        year = int(s[0:4])
        month = int(s[4:6])
        day = int(s[6:8])
        return datetime(year, month, day).date()
    except ValueError:
        return None


def generate_coverage_advisory(db, customer_id: int) -> dict:
    """Generate advisory for a single customer."""
    advisories = []
    categories = {}
    
    # Check each insurance category
    for category in REQUIRED_CATEGORIES:
        col = db[category]
        policies = list(col.find({"customerId": customer_id}))
        categories[category] = len(policies)
        
        if not policies:
            advisories.append({
                "type": "PRODUCT_GAP",
                "severity": "HIGH",
                "message": f"No {category.replace('_', ' ')} policy found. Consider buying coverage.",
                "action": "Review available plans"
            })
        else:
            for policy in policies:
                # Check sum assured adequacy (for life insurance)
                if category == "life_insurance":
                    sum_assured = policy.get("SumAssured") or 0
                    premium = policy.get("AnnualPrem") or 0
                    if sum_assured < premium * LIFE_SUM_ASSURED_MULTIPLIER:
                        advisories.append({
                            "type": "PROTECTION_GAP",
                            "severity": "MEDIUM",
                            "message": f"Life coverage of {sum_assured} is below recommended {premium * LIFE_SUM_ASSURED_MULTIPLIER}. Consider increasing sum assured.",
                            "action": "Top-up protection"
                        })
                
                # Check health coverage
                elif category == "health_insurance":
                    coverage = policy.get("Coverage Amount") or 0
                    if coverage < HEALTH_COVERAGE_MIN:
                        advisories.append({
                            "type": "PROTECTION_GAP",
                            "severity": "MEDIUM",
                            "message": f"Health coverage of {coverage} is below recommended {HEALTH_COVERAGE_MIN}. Consider increasing coverage.",
                            "action": "Increase health coverage"
                        })
                
                # Check auto IDV
                elif category == "auto_insurance":
                    idv = policy.get("IDV") or 0
                    if idv < AUTO_IDV_MIN:
                        advisories.append({
                            "type": "PROTECTION_GAP",
                            "severity": "LOW",
                            "message": f"Auto IDV of {idv} is below recommended {AUTO_IDV_MIN}.",
                            "action": "Consider increasing IDV"
                        })
                
                # Check expiry date
                policy_end = policy.get("PolicyEnd") or policy.get("Policy End Date") or policy.get("PolicyEndDate")
                if policy_end:
                    expiry_date = parse_yyyymmdd(policy_end)
                    if expiry_date:
                        today = datetime.now().date()
                        days_left = (expiry_date - today).days
                        
                        if days_left < 0:
                            advisories.append({
                                "type": "TEMPORAL_GAP",
                                "severity": "HIGH",
                                "message": f"{category.replace('_', ' ')} policy expired on {expiry_date}. Renew immediately.",
                                "action": "Renew policy"
                            })
                        elif days_left < DAYS_NEARING_EXPIRY:
                            advisories.append({
                                "type": "TEMPORAL_GAP",
                                "severity": "MEDIUM",
                                "message": f"{category.replace('_', ' ')} policy expires in {days_left} days. Renew soon.",
                                "action": "Schedule renewal"
                            })
    
    summary = {
        "total_policies": sum(categories.values()),
        "categories_present": [c for c, count in categories.items() if count > 0],
        "gaps_identified": len(advisories)
    }
    
    return {
        "customerId": customer_id,
        "summary": summary,
        "advisory": advisories,
        "generated_at": datetime.now().isoformat()
    }


def insert_demo_records(db, customer_id: int):
    """Insert demo policies for testing."""
    db["unified_portfolio"].insert_one({
        "customerId": customer_id,
        "policy_id": "DEMO_LIFE_001",
        "insurer": "MaxLife",
        "premium": 50000,
        "sum_assured": 250000,
        "start_date": 20230101,
        "policy_end": 20330101,
        "source_collection": "life_insurance"
    })
    
    db["unified_portfolio"].insert_one({
        "customerId": customer_id,
        "policy_id": "DEMO_AUTO_001",
        "insurer": "HDFC ERGO",
        "premium": 15000,
        "sum_assured": 100000,
        "start_date": 20230601,
        "policy_end": 20240531,
        "source_collection": "auto_insurance"
    })


def main():
    client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
    db = client[DB_NAME]

    if len(sys.argv) > 1 and sys.argv[1] == "--demo":
        # Insert demo records and run advisory for Amit Kulkarni
        customer_id = 901120934
        db["unified_portfolio"].delete_many({"customerId": customer_id})
        insert_demo_records(db, customer_id)
        result = generate_coverage_advisory(db, customer_id)
        print("=" * 60)
        print(f"Coverage Advisory (DEMO) - Customer {customer_id}")
        print("=" * 60)
        print(json.dumps(result, indent=2, default=str))
        return

    if len(sys.argv) > 1 and sys.argv[1] == "--all":
        # Generate advisory for all customers in customer_details
        customers = list(db["customer_details"].find({}, {"customerId": 1}))
        customer_ids = [c["customerId"] for c in customers if c.get("customerId") is not None]
        print("=" * 60)
        print("Coverage Advisory - All Customers")
        print("=" * 60)
        results = []
        for cid in customer_ids:
            result = generate_coverage_advisory(db, cid)
            results.append(result)
            print(f"\n--- Customer {cid} ---")
            print(f"Policies: {result['summary']['total_policies']} | Gaps: {result['summary']['gaps_identified']}")
            for note in result["advisory"][:3]:  # First 3 advisories
                msg = note["message"]
                print(f"  [{note['type']}] {msg[:80]}{'...' if len(msg) > 80 else ''}")
        # Save to file
        out_path = os.path.join(os.path.dirname(__file__), "advisory_output.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2, default=str)
        print(f"\nFull output saved to: {out_path}")
    else:
        # Single customer (default: Amit Kulkarni 901120934)
        customer_id = int(sys.argv[1]) if len(sys.argv) > 1 else 901120934
        result = generate_coverage_advisory(db, customer_id)
        print("=" * 60)
        print(f"Coverage Advisory - Customer {customer_id}")
        print("=" * 60)
        print(json.dumps(result, indent=2, default=str))


if __name__ == "__main__":
    main()
