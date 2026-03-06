# Quick Reference - All New Code Components

## 🎯 New Endpoints Created

### Customer Service (Port 8081)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/customers/search/mobile/{mobile}` | Search by mobile number |
| GET | `/api/v1/customers/search/email/{email}` | Search by email |
| GET | `/api/v1/customers/search/pan/{pan}` | Search by PAN |
| GET | `/api/v1/health` | Health check |

### Policy Service (Port 8085)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/policies` | Get all policies |
| PATCH | `/api/v1/policies/{id}/status` | Update policy status |
| DELETE | `/api/v1/policies/{id}` | Delete policy |
| GET | `/api/v1/health` | Health check |

### BFF Service (Port 8080)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/bff/health` | Health check |

---

## 📦 New Classes Created

### Customer Service
```
customer/exception/
├── CustomerNotFoundException.java
├── DuplicateCustomerException.java
└── InvalidCredentialsException.java

customer/controller/
└── HealthCheckController.java
```

### Policy Service
```
policy/exception/
├── PolicyNotFoundException.java
├── DuplicatePolicyException.java
└── GlobalExceptionHandler.java

policy/controller/
└── HealthCheckController.java
```

### BFF Service
```
bff/exception/
└── GlobalExceptionHandler.java

bff/controller/
└── HealthCheckController.java
```

### Data Pipeline Service
```
pipeline/common/util/
├── DateParserUtil.java
├── NumericParserUtil.java
└── ValidationUtil.java

pipeline/common/audit/
├── AuditLog.java
├── AuditLogRepository.java
└── AuditService.java

pipeline/processing/service/
└── DataTransformationService.java

pipeline/ingestion/scheduler/
└── FileProcessingScheduler.java

pipeline/config/
└── CacheConfig.java
```

---

## 🔄 Modified Files

### Customer Service
- ✏️ `CustomerController.java` - Added search endpoints
- ✏️ `CustomerService.java` - Added search method signatures
- ✏️ `CustomerServiceImpl.java` - Implemented search logic + custom exceptions
- ✏️ `GlobalExceptionHandler.java` - Enhanced with custom exception handling

### Policy Service
- ✏️ `PolicyController.java` - Added CRUD endpoints + @Valid annotations
- ✏️ `PolicyService.java` - Added new service methods
- ✏️ `PolicyServiceImpl.java` - Implemented methods + custom exceptions
- ✏️ `PolicyRequest.java` - Added validation annotations

### Data Pipeline Service
- ✏️ `DataPipelineApplication.java` - Added @EnableScheduling + audit repo config

---

## 🛠️ Key Utility Methods

### DateParserUtil
```java
LocalDate parseDate(String dateStr)  // Multi-format parsing
LocalDate parseDate(String dateStr, String format)  // Specific format
```

### NumericParserUtil
```java
BigDecimal parseBigDecimal(String value)  // Currency aware
Integer parseInt(String value)
Double parseDouble(String value)
```

### ValidationUtil
```java
boolean isValidEmail(String email)
boolean isValidMobileNumber(String mobile)  // Indian format
boolean isValidPanNumber(String pan)  // Indian format
String normalizeMobileNumber(String mobile)
String normalizePanNumber(String pan)
```

### DataTransformationService
```java
Map<String, Object> transformRecord(Map<String, Object> rawData, List<FieldMapping> mappings)
boolean validateRecord(Map<String, Object> record, List<FieldMapping> mappings)
void enrichRecord(Map<String, Object> record)
```

### AuditService
```java
void logSuccess(String operation, String entityType, String entityId, String performedBy, Long durationMs)
void logFailure(String operation, String entityType, String entityId, String performedBy, String errorMessage, Long durationMs)
void logJobOperation(String jobId, String operation, String performedBy, boolean success, String errorMessage)
```

---

## 🔍 Search Functionality

### Customer Search Examples

**By Mobile:**
```bash
GET http://localhost:8081/api/v1/customers/search/mobile/9876543210
```

**By Email:**
```bash
GET http://localhost:8081/api/v1/customers/search/email/john@example.com
```

**By PAN:**
```bash
GET http://localhost:8081/api/v1/customers/search/pan/ABCDE1234F
```

---

## ⚡ Automatic Processing

### FileProcessingScheduler

**Auto-process uploaded files:**
- Runs every 30 seconds
- Checks for files with status = UPLOADED
- Automatically triggers processing

**Retry failed jobs:**
- Runs every 5 minutes
- Retries jobs that failed > 1 hour ago
- Exponential backoff mechanism

---

## 📊 Audit System

### Tracked Operations
- File upload
- File processing
- Policy creation
- Customer matching
- Status transitions
- All CRUD operations

### Query Examples
```java
// Find all logs for a job
List<AuditLog> logs = auditLogRepository.findByJobId(jobId);

// Find all failures in last 24 hours
LocalDateTime yesterday = LocalDateTime.now().minusDays(1);
List<AuditLog> failures = auditLogRepository.findByStatusAndTimestampAfter("FAILURE", yesterday);

// Find logs by user
List<AuditLog> userLogs = auditLogRepository.findByPerformedBy("user@example.com");
```

---

## 🎨 Transformation Rules

### Supported Rules
- `uppercase` - Convert to uppercase
- `lowercase` - Convert to lowercase
- `trim` - Remove whitespace
- `normalize_mobile` - Normalize Indian mobile number
- `normalize_pan` - Normalize PAN number
- `parse_date` - Multi-format date parsing
- `parse_number` - Parse to BigDecimal
- `parse_integer` - Parse to Integer

### Usage in Field Mappings
```json
{
  "sourceField": "Customer Name",
  "targetField": "fullName",
  "transformRule": "uppercase",
  "required": true
}
```

---

## 🔐 Validation Rules

### Email
Pattern: `^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`

### Indian Mobile Number
- Must be 10 digits
- Must start with 6, 7, 8, or 9
- Example: `9876543210`

### Indian PAN Number
- Format: 5 letters + 4 digits + 1 letter
- Example: `ABCDE1234F`
- Auto-converts to uppercase

---

## 🚀 Deployment Checklist

- [ ] All services compile without errors
- [ ] PostgreSQL database created: `mypolicy_db`
- [ ] MongoDB running on default port
- [ ] Environment variables configured
- [ ] JWT secret key set
- [ ] File storage directory created
- [ ] Health checks responding on all services
- [ ] Scheduled tasks enabled

---

## 📚 Code Organization

```
MyPolicy-Backend/
├── customer-service/          (✅ Complete)
│   ├── Controllers: Auth, CRUD, Search, Health
│   ├── Services: Registration, Login, Search
│   ├── Exceptions: Custom + Global Handler
│   └── Security: JWT, BCrypt
│
├── policy-service/            (✅ Complete)
│   ├── Controllers: CRUD, Status, Health
│   ├── Services: Create, Read, Update, Delete
│   ├── Exceptions: Custom + Global Handler
│   └── Validation: DTOs with constraints
│
├── bff-service/               (✅ Complete)
│   ├── Controllers: Portfolio, Insights, Upload, Health
│   ├── Services: Aggregation, Analysis
│   ├── Clients: Feign to Customer, Policy, Pipeline
│   └── Exceptions: Feign error handling
│
└── data-pipeline-service/     (✅ Complete)
    ├── Ingestion: Upload, Track, Schedule
    ├── Processing: Parse, Transform, Validate
    ├── Matching: Fuzzy match, Identity stitch
    ├── Metadata: Field mappings, Configuration
    ├── Utilities: Parsers, Validators
    ├── Audit: Complete tracking system
    └── Config: Cache, Scheduling
```

---

**Status:** ✅ All code logic implemented
**Last Updated:** February 24, 2026
