# Insurer CSV Upload & Processing API

## Overview

Insurers can upload CSV/Excel policy files via the Data Pipeline Service. Files are validated, mapped to a canonical schema, massaged (dates, currency, mobile), and matched to customers using mobile, email, PAN, and DOB.

## Prerequisites

- **data-pipeline-service** running on port 8082
- **customer-service** on 8081 (for customer matching)
- **policy-service** on 8085 (for policy creation)
- PostgreSQL (mypolicy_db) and MongoDB (ingestion_db)

## API Endpoints

### 1. Upload CSV/Excel

```http
POST /api/public/v1/ingestion/upload
Content-Type: multipart/form-data
```

| Parameter   | Type  | Required | Description |
|------------|-------|----------|-------------|
| file       | File  | Yes      | CSV or Excel (.csv, .xls, .xlsx) |
| insurerId  | String| Yes      | Schema identifier (see below) |
| uploadedBy | String| Yes      | User/system identifier |
| fileType   | String| No       | "normal" (default) or "correction" |

**insurerId values** (must match `metadata/insurer-field-mappings.yaml`):

| insurerId     | Use for                    | Sample file |
|---------------|----------------------------|-------------|
| `HEALTH_INSURER` | Health insurance CSVs   | `Datasets/Health_Insurance.csv` |
| `AUTO_INSURER`   | Auto/Motor insurance CSVs | `Datasets/Auto_Insurance.csv` |
| `LIFE_INSURER`   | Life insurance CSVs     | `Datasets/Life_Insurance.csv` |

**Example (PowerShell):**
```powershell
curl.exe -X POST -F "file=@Datasets/Health_Insurance.csv" -F "insurerId=HEALTH_INSURER" -F "uploadedBy=insurer-admin" http://localhost:8082/api/public/v1/ingestion/upload
```

**Response:**
```json
{
  "jobId": "uuid-here",
  "status": "UPLOADED"
}
```

### 2. Trigger Processing

```http
POST /api/public/v1/ingestion/process/{jobId}
```

| Query Param  | Required | Description |
|--------------|----------|-------------|
| policyType   | No       | HEALTH, MOTOR, TERM_LIFE. Resolved from config if omitted. |

**Example:**
```powershell
curl.exe -X POST "http://localhost:8082/api/public/v1/ingestion/process/{jobId}?policyType=HEALTH"
```

### 3. Get Job Status

```http
GET /api/public/v1/ingestion/status/{jobId}
```

**Response:**
```json
{
  "jobId": "...",
  "status": "COMPLETED",
  "processedRecords": 100,
  "totalRecords": 100,
  "filePath": "...",
  "insurerId": "HEALTH_INSURER",
  "fileType": "normal",
  "createdAt": "...",
  "updatedAt": "..."
}
```

## End-to-End Flow

1. **Upload:** `POST /upload` with file + `insurerId` + `uploadedBy` → get `jobId`
2. **Process:** `POST /process/{jobId}` (optional `policyType`) → processing runs
3. **Status:** `GET /status/{jobId}` → check status, processedRecords, totalRecords

## Customer Matching

Policies are matched to the Customer Master using (in order):

- Mobile number  
- PAN number  
- Email  
- Verification with name (fuzzy) and DOB when available  

Unmatched policies are logged for manual review.

## Metadata & Data Massaging

- **Field mapping:** `metadata/insurer-field-mappings.yaml` maps source columns to canonical fields
- **Date:** Normalized to ISO `yyyy-MM-dd` (accepts YYYYMMDD, dd/MM/yyyy)
- **Currency:** Stripped of symbols, normalized to number
- **Mobile:** Digits only, 91 prefix for 10-digit Indian numbers
- **Status:** Mapped to ACTIVE, LAPSED, CANCELLED, PENDING
