# MyPolicy Insurance Platform — Jira Project Documentation

**Project Key**: `MPOL`  
**Project Type**: Scrum  
**Created**: March 10, 2026  
**Team**: MyPolicy Engineering

---

## Project Overview

MyPolicy is a unified insurance portfolio management platform that aggregates policies from multiple insurers (Auto, Health, Life) into a single customer dashboard. The system uses identity stitching to link policies to customers and provides coverage advisory recommendations.

**Tech Stack**: Spring Boot (Java 17), Flutter (Dart), MongoDB Atlas, Spring Cloud (Eureka + Config), Docker

---

# EPICS

---

## EPIC 1: Infrastructure & Service Discovery

**Key**: `MPOL-E1`  
**Summary**: Infrastructure & Service Discovery Setup  
**Description**: Set up the foundational infrastructure for the MyPolicy microservices platform, including service discovery (Eureka), centralized configuration (Spring Cloud Config), and Docker containerization.  
**Priority**: Highest  
**Labels**: `infrastructure`, `devops`

---

### Story 1.1: Eureka Discovery Service

**Key**: `MPOL-1`  
**Type**: Story  
**Summary**: Implement Eureka Service Discovery  
**Description**: Set up Spring Cloud Netflix Eureka Server so all microservices can register and discover each other dynamically without hardcoded URLs.  
**Story Points**: 3  
**Priority**: Highest  
**Acceptance Criteria**:
- Eureka Server starts on port 8761
- Dashboard accessible at http://localhost:8761
- All microservices auto-register on startup
- Health check endpoint at /actuator/health

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 1.1.1 | MPOL-1a | Create discovery-service Spring Boot project with Eureka Server dependency | Done |
| 1.1.2 | MPOL-1b | Configure application.yaml (port 8761, self-registration disabled) | Done |
| 1.1.3 | MPOL-1c | Add @EnableEurekaServer annotation to main class | Done |
| 1.1.4 | MPOL-1d | Create Dockerfile for discovery-service | Done |
| 1.1.5 | MPOL-1e | Verify all services appear in Eureka dashboard | Done |

---

### Story 1.2: Spring Cloud Config Service

**Key**: `MPOL-2`  
**Type**: Story  
**Summary**: Implement Centralized Configuration Service  
**Description**: Set up Spring Cloud Config Server to serve externalized configuration to all microservices from a central location, secured with basic authentication.  
**Story Points**: 3  
**Priority**: Highest  
**Acceptance Criteria**:
- Config Server starts on port 8888
- Serves YAML configs for all 4 business services (bff, customer, policy, data-pipeline)
- Secured with basic auth (admin/config123)
- All services pull config on startup via `spring.config.import`

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 1.2.1 | MPOL-2a | Create config-service Spring Boot project with Config Server dependency | Done |
| 1.2.2 | MPOL-2b | Configure file-system backend with config-repo directory | Done |
| 1.2.3 | MPOL-2c | Add Spring Security with basic auth for config endpoints | Done |
| 1.2.4 | MPOL-2d | Create environment-specific configs for each service (bff, customer, pipeline, policy) | Done |
| 1.2.5 | MPOL-2e | Create Dockerfile for config-service | Done |

---

### Story 1.3: Docker Compose Orchestration

**Key**: `MPOL-3`  
**Type**: Story  
**Summary**: Dockerize All Microservices with Docker Compose  
**Description**: Containerize all 6 services with Docker and create a docker-compose.yml that orchestrates startup with proper dependency ordering, health checks, and networking.  
**Story Points**: 5  
**Priority**: High  
**Acceptance Criteria**:
- Each service has a Dockerfile (Alpine-based JDK 17)
- docker-compose.yml starts all 6 services in correct order
- Health checks on every container
- Dependency chain: Config → Discovery → Business Services → BFF
- Single `mypolicy-net` Docker network

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 1.3.1 | MPOL-3a | Create Dockerfile for each service (multi-stage build, Alpine JDK 17) | Done |
| 1.3.2 | MPOL-3b | Write docker-compose.yml with service dependency chain | Done |
| 1.3.3 | MPOL-3c | Configure health checks for all containers (curl actuator) | Done |
| 1.3.4 | MPOL-3d | Create docker-deploy.ps1 PowerShell deployment script | Done |
| 1.3.5 | MPOL-3e | Configure environment variables for Docker networking (Eureka zone, Config import) | Done |
| 1.3.6 | MPOL-3f | Test full stack startup with `docker-compose up --build` | Done |

---

## EPIC 2: Customer Service

**Key**: `MPOL-E2`  
**Summary**: Customer Management Microservice  
**Description**: Build the Customer Service microservice responsible for user registration, authentication (Full Name + PAN login with JWT), customer data management, and search capabilities. Uses MongoDB Atlas for persistence.  
**Priority**: Highest  
**Labels**: `backend`, `authentication`, `customer`

---

### Story 2.1: Customer Registration

**Key**: `MPOL-4`  
**Type**: Story  
**Summary**: Implement Customer Registration API  
**Description**: As a new user, I want to register with my personal details so that I can access MyPolicy. The system should create a customer record in MongoDB with a UUID, BCrypt-hashed password, and validation.  
**Story Points**: 5  
**Priority**: Highest  
**Acceptance Criteria**:
- `POST /api/v1/customers/register` creates a new customer
- Request: firstName, lastName, email, mobile, password, panNumber, dob
- UUID auto-generated as customerId
- Password stored as BCrypt hash
- Duplicate email/mobile check returns 409 Conflict
- Returns 201 Created with customer details (no password in response)

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 2.1.1 | MPOL-4a | Create Customer document model with @Document annotation (MongoDB) | Done |
| 2.1.2 | MPOL-4b | Create CustomerRepository extending MongoRepository | Done |
| 2.1.3 | MPOL-4c | Implement CustomerServiceImpl.register() with validation | Done |
| 2.1.4 | MPOL-4d | Add BCrypt password encoding | Done |
| 2.1.5 | MPOL-4e | Create CustomerController with POST /register endpoint | Done |
| 2.1.6 | MPOL-4f | Add duplicate email/mobile validation | Done |

---

### Story 2.2: Customer Login (Full Name + PAN)

**Key**: `MPOL-5`  
**Type**: Story  
**Summary**: Implement Login with Full Name + PAN Authentication  
**Description**: As a customer, I want to log in using my full name and PAN number so that I can securely access my insurance portfolio. The system queries the `customer_details` collection (master customer data imported from insurers) and returns a JWT token.  
**Story Points**: 8  
**Priority**: Highest  
**Acceptance Criteria**:
- `POST /api/v1/customers/login` accepts `{ "customerIdOrUserId": "Full Name", "password": "PAN" }`
- Queries `customer_details` collection by fullName (case-insensitive) + PAN
- Returns JWT token (HS256, 24hr expiry) + customer details
- Returns 401 Unauthorized on invalid credentials

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 2.2.1 | MPOL-5a | Create CustomerDetails document model mapping to customer_details collection | Done |
| 2.2.2 | MPOL-5b | Create CustomerDetailsRepository with findFirstByCustomerFullNameIgnoreCaseAndRefCustItNum | Done |
| 2.2.3 | MPOL-5c | Implement JwtService (HS256 signing, 24hr expiry, token generation + validation) | Done |
| 2.2.4 | MPOL-5d | Implement CustomerServiceImpl.login() with Name+PAN matching | Done |
| 2.2.5 | MPOL-5e | Create LoginRequest and AuthResponse DTOs | Done |
| 2.2.6 | MPOL-5f | Create POST /login endpoint in CustomerController | Done |

---

### Story 2.3: Customer Search APIs

**Key**: `MPOL-6`  
**Type**: Story  
**Summary**: Implement Customer Search by PAN, Email, and Mobile  
**Description**: As a system service, I need to search customers by PAN, email, or mobile number for identity stitching and account recovery.  
**Story Points**: 3  
**Priority**: High  
**Acceptance Criteria**:
- `GET /api/v1/customers/search/pan/{pan}` — search by PAN number
- `GET /api/v1/customers/search/email/{email}` — search by email
- `GET /api/v1/customers/search/mobile/{mobile}` — search by mobile
- Returns 200 OK with customer or 404 Not Found

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 2.3.1 | MPOL-6a | Add findByPanNumber, findByEmail, findByMobileNumber to CustomerRepository | Done |
| 2.3.2 | MPOL-6b | Implement search methods in CustomerServiceImpl | Done |
| 2.3.3 | MPOL-6c | Create GET search endpoints in CustomerController | Done |

---

### Story 2.4: Get Customer Profile

**Key**: `MPOL-7`  
**Type**: Story  
**Summary**: Implement Get Customer by ID and Get Customer Details  
**Description**: As a service consumer, I need to fetch customer profile by UUID (customers collection) or by integer ID (customer_details collection).  
**Story Points**: 3  
**Priority**: High  
**Acceptance Criteria**:
- `GET /api/v1/customers/{customerId}` — fetch from customers collection (UUID)
- `GET /api/v1/customers/details/{customerId}` — fetch from customer_details collection (integer ID)
- `PUT /api/v1/customers/{customerId}` — update customer profile

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 2.4.1 | MPOL-7a | Implement getCustomerById (UUID) from customers collection | Done |
| 2.4.2 | MPOL-7b | Implement getCustomerDetails (integer ID) from customer_details collection | Done |
| 2.4.3 | MPOL-7c | Implement updateCustomer with partial field updates | Done |
| 2.4.4 | MPOL-7d | Create REST endpoints (GET, PUT) in CustomerController | Done |

---

## EPIC 3: Policy Service

**Key**: `MPOL-E3`  
**Summary**: Policy Management Microservice  
**Description**: Build the Policy Service microservice for CRUD operations on insurance policies. Stores policies in MongoDB (database: mypolicy) and supports filtering by customer ID, status updates, and duplicate detection.  
**Priority**: High  
**Labels**: `backend`, `policy`

---

### Story 3.1: Create Policy

**Key**: `MPOL-8`  
**Type**: Story  
**Summary**: Implement Create Policy API  
**Description**: As an admin or pipeline service, I want to create insurance policy records so that they can be tracked in the system.  
**Story Points**: 5  
**Priority**: High  
**Acceptance Criteria**:
- `POST /api/v1/policies` creates a new policy
- Request: customerId, insurerId, policyNumber, policyType, planName, premiumAmount, sumAssured, startDate, endDate, status
- Duplicate check on policyNumber + insurerId
- Auto-generates UUID, sets createdAt/updatedAt timestamps
- Returns 201 Created

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 3.1.1 | MPOL-8a | Create Policy document model with @Document annotation | Done |
| 3.1.2 | MPOL-8b | Create PolicyRepository with findByPolicyNumberAndInsurerId | Done |
| 3.1.3 | MPOL-8c | Implement PolicyServiceImpl.createPolicy() with duplicate check | Done |
| 3.1.4 | MPOL-8d | Create PolicyController with POST endpoint | Done |

---

### Story 3.2: Query Policies

**Key**: `MPOL-9`  
**Type**: Story  
**Summary**: Implement Policy Query APIs  
**Description**: As a customer or BFF service, I need to fetch policies by customer ID, by policy ID, or list all policies.  
**Story Points**: 3  
**Priority**: High  
**Acceptance Criteria**:
- `GET /api/v1/policies/customer/{customerId}` — all policies for a customer
- `GET /api/v1/policies/{id}` — single policy by ID
- `GET /api/v1/policies` — list all policies

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 3.2.1 | MPOL-9a | Add findByCustomerId to PolicyRepository | Done |
| 3.2.2 | MPOL-9b | Implement query methods in PolicyServiceImpl | Done |
| 3.2.3 | MPOL-9c | Create GET endpoints in PolicyController | Done |

---

### Story 3.3: Update & Delete Policies

**Key**: `MPOL-10`  
**Type**: Story  
**Summary**: Implement Policy Status Update and Deletion  
**Description**: As an admin, I want to update a policy's status (ACTIVE/EXPIRED/CANCELLED) or delete policies.  
**Story Points**: 2  
**Priority**: Medium  
**Acceptance Criteria**:
- `PATCH /api/v1/policies/{id}/status?status=EXPIRED` — update status
- `DELETE /api/v1/policies/{id}` — soft/hard delete
- updatedAt timestamp auto-set on change

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 3.3.1 | MPOL-10a | Implement updatePolicyStatus in PolicyServiceImpl | Done |
| 3.3.2 | MPOL-10b | Implement deletePolicy in PolicyServiceImpl | Done |
| 3.3.3 | MPOL-10c | Create PATCH and DELETE endpoints in PolicyController | Done |

---

## EPIC 4: Data Pipeline Service

**Key**: `MPOL-E4`  
**Summary**: Data Pipeline & Identity Stitching Service  
**Description**: Build the consolidated Data Pipeline Service that handles CSV ingestion from insurers, field standardization using mapping configuration, 3-tier identity stitching (PAN → Mobile+DOB → Email+DOB), PII encryption, unified portfolio generation, and coverage advisory recommendations.  
**Priority**: Highest  
**Labels**: `backend`, `data-pipeline`, `identity-stitching`, `advisory`

---

### Story 4.1: CSV File Upload & Parsing

**Key**: `MPOL-11`  
**Type**: Story  
**Summary**: Implement CSV Upload and Parsing Module  
**Description**: As an insurer admin, I want to upload insurance CSV files (auto, health, life) so that they can be ingested into the system. Uses OpenCSV library.  
**Story Points**: 5  
**Priority**: Highest  
**Acceptance Criteria**:
- `POST /api/pipeline/upload` accepts multipart CSV + collectionName
- FileProcessingService parses CSV headers from row 1
- Maps each row to Map<header, value>
- Coerces numeric fields (DOB, Premium, IDV)
- Returns parsed record count

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 4.1.1 | MPOL-11a | Create PipelineController with POST /api/pipeline/upload endpoint | Done |
| 4.1.2 | MPOL-11b | Implement FileProcessingService.parseCsv() using OpenCSV | Done |
| 4.1.3 | MPOL-11c | Add multipart file size configuration (max 50MB) | Done |
| 4.1.4 | MPOL-11d | Handle CSV validation (header check, empty rows, encoding) | Done |

---

### Story 4.2: Raw Data Ingestion into MongoDB

**Key**: `MPOL-12`  
**Type**: Story  
**Summary**: Ingest Parsed CSV Records into Raw MongoDB Collections  
**Description**: After parsing, insert raw records into the appropriate MongoDB collection (auto_insurance, health_insurance, or life_insurance) in batch.  
**Story Points**: 3  
**Priority**: Highest  
**Acceptance Criteria**:
- MetadataIngestionService.ingestRecords(collectionName, records) inserts batch
- Records stored in collection matching the source (auto_insurance, health_insurance, life_insurance)
- Audit log entry created

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 4.2.1 | MPOL-12a | Implement MetadataIngestionService.ingestRecords() with MongoTemplate batch insert | Done |
| 4.2.2 | MPOL-12b | Add audit logging for ingestion operations | Done |

---

### Story 4.3: Field Standardization via Mapping Config

**Key**: `MPOL-13`  
**Type**: Story  
**Summary**: Standardize Fields Across Insurers Using mapping_config.json  
**Description**: As a pipeline process, I need to standardize field names from different insurers into a common format so that identity stitching can work uniformly. Different CSV files use different headers (e.g., "PolicyNumber" vs "Policy Number" vs "PolicyNum").  
**Story Points**: 5  
**Priority**: Highest  
**Acceptance Criteria**:
- mapping_config.json defines field mappings for each collection (auto, health, life)
- MetadataIngestionService.standardizeAllPolicies() reads all 3 collections and standardizes
- Normalizes currency, dates, mobile numbers
- Returns Map<collection, List<StandardizedRecord>>

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 4.3.1 | MPOL-13a | Create mapping_config.json with field mappings for auto, health, life collections | Done |
| 4.3.2 | MPOL-13b | Implement StandardizedRecord model with common fields (policyId, premium, sumAssured, pan, mobile, email, dob) | Done |
| 4.3.3 | MPOL-13c | Implement MetadataIngestionService.standardizeAllPolicies() with config-driven mapping | Done |
| 4.3.4 | MPOL-13d | Add field normalization (currency formatting, date parsing, mobile cleanup) | Done |

---

### Story 4.4: Identity Stitching (3-Tier Matching)

**Key**: `MPOL-14`  
**Type**: Story  
**Summary**: Implement 3-Tier Identity Stitching to Link Policies to Customers  
**Description**: As a pipeline process, I need to link each standardized insurance policy to a customer record using a priority-based matching strategy: PAN match first, then Mobile+DOB, then Email+DOB. Matched records have PII encrypted and are saved to unified_portfolio.  
**Story Points**: 13  
**Priority**: Highest  
**Acceptance Criteria**:
- Priority 1: Match by PAN number → label `PAN_MATCH`
- Priority 2: Match by Mobile + DOB → label `MOBILE_DOB_MATCH`
- Priority 3: Match by Email + DOB → label `EMAIL_DOB_MATCH`
- Unmatched policies tracked but not stored
- PII fields (PAN, Mobile, Email) encrypted with AES-256 before saving
- unified_portfolio collection cleared before re-stitching
- Returns StitchingResult { total, matched, unmatched }

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 4.4.1 | MPOL-14a | Create StitchingService with 3-tier priority matching logic | Done |
| 4.4.2 | MPOL-14b | Query customer_details by PAN (findFirstByRefCustItNum) | Done |
| 4.4.3 | MPOL-14c | Query customer_details by Mobile+DOB (findByRefPhoneMobileAndDatBirthCust) | Done |
| 4.4.4 | MPOL-14d | Query customer_details by Email+DOB (findByCustEmailIDAndDatBirthCust) | Done |
| 4.4.5 | MPOL-14e | Implement AES-256 PII encryption for matched records | Done |
| 4.4.6 | MPOL-14f | Create UnifiedPortfolioRecord model and repository | Done |
| 4.4.7 | MPOL-14g | Save matched records to unified_portfolio collection with matchMethod label | Done |
| 4.4.8 | MPOL-14h | Return StitchingResult with total/matched/unmatched counts | Done |

---

### Story 4.5: Pipeline Orchestration (End-to-End)

**Key**: `MPOL-15`  
**Type**: Story  
**Summary**: Orchestrate Full Pipeline: Upload → Parse → Ingest → Standardize → Stitch  
**Description**: Create PipelineOrchestratorService that coordinates the full pipeline workflow in sequence. Also support running pipeline on existing MongoDB data (without new upload).  
**Story Points**: 5  
**Priority**: Highest  
**Acceptance Criteria**:
- `POST /api/pipeline/upload` runs full pipeline (upload + parse + ingest + standardize + stitch)
- `POST /api/pipeline/run` runs pipeline on existing data (standardize + stitch only)
- Returns: { message, total, matched, unmatched }

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 4.5.1 | MPOL-15a | Implement PipelineOrchestratorService orchestrating all modules | Done |
| 4.5.2 | MPOL-15b | Create POST /api/pipeline/upload endpoint (full pipeline) | Done |
| 4.5.3 | MPOL-15c | Create POST /api/pipeline/run endpoint (re-stitch existing data) | Done |

---

### Story 4.6: Unified Portfolio Retrieval

**Key**: `MPOL-16`  
**Type**: Story  
**Summary**: Implement Unified Portfolio API for Customer  
**Description**: As a customer, I want to view all my stitched insurance policies (auto, health, life) from the unified_portfolio collection.  
**Story Points**: 3  
**Priority**: High  
**Acceptance Criteria**:
- `GET /api/portfolio/{customerId}` returns all stitched policies for a customer
- Response includes: policyId, insurer, sourceCollection, premium, sumAssured, dates, matchMethod
- Returns totalPolicies count

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 4.6.1 | MPOL-16a | Create PortfolioService with findByCustomerId query | Done |
| 4.6.2 | MPOL-16b | Create GET /api/portfolio/{customerId} endpoint | Done |
| 4.6.3 | MPOL-16c | Map UnifiedPortfolioRecord to PolicySummary DTO | Done |

---

### Story 4.7: Coverage Advisory Engine

**Key**: `MPOL-17`  
**Type**: Story  
**Summary**: Implement Rule-Based Coverage Advisory Recommendations  
**Description**: As a customer, I want to receive personalized insurance advisory recommendations that analyze my portfolio for gaps, inadequate coverage, and expiring policies.  
**Story Points**: 8  
**Priority**: High  
**Acceptance Criteria**:
- `GET /api/advisory/{customerId}` returns advisory analysis
- Rule 1: Product Gap Detection — missing categories (life/health/auto) → PROTECTION_GAP (HIGH)
- Rule 2: Sum Assured Adequacy — Life < 10x premium, Health < ₹3L, Auto < ₹1L → MEDIUM/LOW
- Rule 3: Temporal Gap Detection — expired → HIGH, expiring within 90 days → MEDIUM
- Response: { customerId, advisory[], summary{total, categories, gaps}, unifiedView[] }

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 4.7.1 | MPOL-17a | Create AdvisoryRuleService with configurable thresholds (from application.yaml) | Done |
| 4.7.2 | MPOL-17b | Implement Rule 1: Product Gap Detection | Done |
| 4.7.3 | MPOL-17c | Implement Rule 2: Sum Assured Adequacy check | Done |
| 4.7.4 | MPOL-17d | Implement Rule 3: Temporal Gap / Policy Expiry detection | Done |
| 4.7.5 | MPOL-17e | Create AdvisoryResponse, AdvisoryNote, AdvisorySummary DTOs | Done |
| 4.7.6 | MPOL-17f | Create GET /api/advisory/{customerId} endpoint | Done |

---

## EPIC 5: BFF Service (Backend for Frontend)

**Key**: `MPOL-E5`  
**Summary**: BFF API Gateway Service  
**Description**: Build the BFF (Backend-for-Frontend) service that acts as the single API gateway for the Flutter frontend. Routes requests to downstream microservices via Feign clients, aggregates responses, and provides a unified API surface on port 8090.  
**Priority**: Highest  
**Labels**: `backend`, `bff`, `gateway`

---

### Story 5.1: Authentication Gateway

**Key**: `MPOL-18`  
**Type**: Story  
**Summary**: Implement Auth Endpoints in BFF (Login, Register, Update)  
**Description**: As a Flutter app, I need a single gateway endpoint for authentication that forwards to Customer Service.  
**Story Points**: 3  
**Priority**: Highest  
**Acceptance Criteria**:
- `POST /api/bff/auth/login` → forwards to Customer Service login
- `POST /api/bff/auth/register` → forwards to Customer Service register
- `PUT /api/bff/auth/customer/{id}` → forwards to Customer Service update
- Uses Feign client (CustomerClient) for inter-service calls

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 5.1.1 | MPOL-18a | Create CustomerClient Feign interface with login, register, update methods | Done |
| 5.1.2 | MPOL-18b | Create LoginRequest and AuthResponse DTOs for BFF layer | Done |
| 5.1.3 | MPOL-18c | Create AuthController with /api/bff/auth/* endpoints | Done |

---

### Story 5.2: Portfolio Aggregation Gateway

**Key**: `MPOL-19`  
**Type**: Story  
**Summary**: Implement Portfolio Aggregation in BFF  
**Description**: As a Flutter app, I need a single endpoint that returns the complete customer portfolio by aggregating data from Customer Service (customer info) and Data Pipeline (stitched policies).  
**Story Points**: 5  
**Priority**: Highest  
**Acceptance Criteria**:
- `GET /api/bff/portfolio/{customerId}` returns aggregated portfolio
- Parallel calls: Customer Service (get details) + Data Pipeline (get unified portfolio)
- Calculates totalPolicies, totalPremium, totalCoverage
- Returns: { customer, policies[], totalPolicies, totalPremium, totalCoverage }

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 5.2.1 | MPOL-19a | Create DataPipelineClient Feign interface for portfolio endpoint | Done |
| 5.2.2 | MPOL-19b | Create PortfolioService to aggregate customer info + policies | Done |
| 5.2.3 | MPOL-19c | Create PortfolioResponse, PolicyDTO, DataPipelinePortfolioResponse DTOs | Done |
| 5.2.4 | MPOL-19d | Create PortfolioController with GET /api/bff/portfolio/{customerId} | Done |

---

### Story 5.3: Advisory Gateway

**Key**: `MPOL-20`  
**Type**: Story  
**Summary**: Implement Advisory Endpoint in BFF  
**Description**: As a Flutter app, I need a gateway endpoint for coverage advisory that forwards to Data Pipeline.  
**Story Points**: 2  
**Priority**: High  
**Acceptance Criteria**:
- `GET /api/bff/advisory/{customerId}` forwards to Data Pipeline advisory
- Returns: DataPipelineAdvisoryResponse with advisory notes + summary

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 5.3.1 | MPOL-20a | Create AdvisoryService that calls DataPipelineClient.getAdvisory() | Done |
| 5.3.2 | MPOL-20b | Create DataPipelineAdvisoryResponse DTO (with AdvisoryNote, AdvisorySummary) | Done |
| 5.3.3 | MPOL-20c | Create AdvisoryController with GET /api/bff/advisory/{customerId} | Done |

---

### Story 5.4: Coverage Insights Gateway

**Key**: `MPOL-21`  
**Type**: Story  
**Summary**: Implement Coverage Insights Endpoint in BFF  
**Description**: As a Flutter app, I need a gateway endpoint for coverage insights that aggregates customer + policy data and calculates coverage scores.  
**Story Points**: 5  
**Priority**: High  
**Acceptance Criteria**:
- `GET /api/bff/insights/{customerId}` returns coverage analysis
- Fetches customer from Customer Service + policies from Policy Service
- Calculates actual vs recommended coverage by type (TERM_LIFE: ₹1Cr, HEALTH: ₹10L, MOTOR: ₹5L)
- Identifies coverage gaps with severity (HIGH/MEDIUM/LOW)
- Returns: { coverageByType, gaps[], recommendations[], overallScore }

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 5.4.1 | MPOL-21a | Create PolicyClient Feign interface for policy queries | Done |
| 5.4.2 | MPOL-21b | Create InsightsService with coverage analysis logic | Done |
| 5.4.3 | MPOL-21c | Create CoverageInsights DTO (CoverageByType, CoverageGap, Recommendation, CoverageScore) | Done |
| 5.4.4 | MPOL-21d | Create InsightsController with GET /api/bff/insights/{customerId} | Done |

---

### Story 5.5: File Upload Gateway

**Key**: `MPOL-22`  
**Type**: Story  
**Summary**: Implement File Upload Proxy in BFF  
**Description**: As an admin user, I need a BFF endpoint to upload CSV files that forwards to Data Pipeline.  
**Story Points**: 2  
**Priority**: High  
**Acceptance Criteria**:
- `POST /api/bff/upload` accepts multipart file + uploadedBy + insurerId
- `GET /api/bff/upload/status/{jobId}` checks ingestion status
- Forwards to Data Pipeline via IngestionClient Feign

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 5.5.1 | MPOL-22a | Create IngestionClient Feign interface | Done |
| 5.5.2 | MPOL-22b | Create FileUploadController with POST /api/bff/upload | Done |
| 5.5.3 | MPOL-22c | Add GET /api/bff/upload/status/{jobId} for status checking | Done |

---

### Story 5.6: Health Check & CORS

**Key**: `MPOL-23`  
**Type**: Story  
**Summary**: Implement Health Check and CORS Configuration  
**Description**: BFF needs health check endpoints for monitoring and CORS configuration for Flutter web app communication.  
**Story Points**: 2  
**Priority**: High  
**Acceptance Criteria**:
- `GET /api/bff/health` returns service status + timestamp
- `GET /api/bff/ping` returns "pong" (liveness probe)
- CORS enabled for localhost origins (Flutter web dev)

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 5.6.1 | MPOL-23a | Create HealthCheckController with /health and /ping | Done |
| 5.6.2 | MPOL-23b | Configure CORS in WebMvcConfigurer (allow localhost origins) | Done |

---

## EPIC 6: Flutter Frontend (HDFC-UI)

**Key**: `MPOL-E6`  
**Summary**: HDFC Insurance Flutter Dashboard  
**Description**: Build the Flutter web/mobile frontend application (HDFC-UI) that provides the user interface for login, portfolio dashboard, policy details, analytics, and account recovery. Integrates with the BFF Service on port 8090.  
**Priority**: High  
**Labels**: `frontend`, `flutter`, `ui`

---

### Story 6.1: Login Screen

**Key**: `MPOL-24`  
**Type**: Story  
**Summary**: Implement Login Screen with Full Name + PAN Authentication  
**Description**: As a customer, I want a login screen where I enter my full name and PAN number to access my portfolio. The screen should have HDFC branding, image slideshow, error handling, and responsive layout.  
**Story Points**: 5  
**Priority**: Highest  
**Acceptance Criteria**:
- Two input fields: "Full Name" and "PAN Number"
- Calls `POST /api/bff/auth/login` with { customerIdOrUserId, password }
- Stores JWT token on success for subsequent API calls
- Navigates to Dashboard on success
- Shows error message on failure
- Responsive: side-by-side on desktop, stacked on mobile
- HDFC logo + illustration slideshow (3 SVGs, 5s interval)
- "Get Customer ID" and "Forgot Password?" links

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 6.1.1 | MPOL-24a | Create login_screen.dart with responsive layout (Row on desktop, Column on mobile) | Done |
| 6.1.2 | MPOL-24b | Implement illustration panel with HDFC logo + animated SVG slideshow | Done |
| 6.1.3 | MPOL-24c | Build login form card (Full Name field, PAN field, password toggle, Continue button) | Done |
| 6.1.4 | MPOL-24d | Integrate ApiService.login() with JWT token storage | Done |
| 6.1.5 | MPOL-24e | Add error message display and loading state | Done |
| 6.1.6 | MPOL-24f | Add navigation to recovery screens (Get Customer ID, Forgot Password) | Done |

---

### Story 6.2: Dashboard Screen (Portfolio View)

**Key**: `MPOL-25`  
**Type**: Story  
**Summary**: Implement Insurance Portfolio Dashboard  
**Description**: As a customer, I want to see all my insurance policies on a dashboard with summary cards, category filters, and individual policy cards.  
**Story Points**: 8  
**Priority**: Highest  
**Acceptance Criteria**:
- Calls `GET /api/bff/portfolio/{customerId}` on load
- Summary cards: Total Policies count, Total Annual Premium, Total Coverage
- Category filter tabs: All, Life, Health, Auto, Expired, Others
- Policy cards show: name, policyId, status badge (Active/Due/Expired), premium, sum insured
- Sorting: Due → Active → Expired
- Responsive grid layout
- Error state with retry button
- Loading spinner

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 6.2.1 | MPOL-25a | Create dashboard_screen.dart with portfolio fetch on initState | Done |
| 6.2.2 | MPOL-25b | Create summary_card.dart widget for totals display | Done |
| 6.2.3 | MPOL-25c | Create category_filter.dart widget for tab-based category filtering | Done |
| 6.2.4 | MPOL-25d | Create policy_card.dart widget with status badge and policy info | Done |
| 6.2.5 | MPOL-25e | Implement sorting logic (Due → Active → Expired) | Done |
| 6.2.6 | MPOL-25f | Create custom_appbar.dart with customer name display | Done |
| 6.2.7 | MPOL-25g | Add error state, loading state, retry mechanism | Done |

---

### Story 6.3: Policy Detail Screen

**Key**: `MPOL-26`  
**Type**: Story  
**Summary**: Implement Policy Detail View  
**Description**: As a customer, I want to tap on a policy card and see full details about that policy.  
**Story Points**: 3  
**Priority**: High  
**Acceptance Criteria**:
- Displays full policy details: name, policyId, description, status, premium, sum insured, category
- Action buttons: Download Policy, File Claim, Manage Policy (UI placeholders)
- Navigated from Dashboard via policy card tap

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 6.3.1 | MPOL-26a | Create policy_detail_screen.dart with policy data display | Done |
| 6.3.2 | MPOL-26b | Add action button row (Download, File Claim, Manage) as UI placeholders | Done |
| 6.3.3 | MPOL-26c | Wire navigation from policy_card.dart tap to detail screen | Done |

---

### Story 6.4: Analytical Dashboard

**Key**: `MPOL-27`  
**Type**: Story  
**Summary**: Implement Analytics Dashboard with Charts  
**Description**: As a customer, I want to see visual analytics of my insurance portfolio including donut charts for category distribution and coverage breakdown.  
**Story Points**: 5  
**Priority**: Medium  
**Acceptance Criteria**:
- Donut chart showing policy distribution by category (Life, Health, Auto, Others)
- Summary statistics: total policies, total premium, total coverage
- Category percentage breakdown
- Uses sample data (hardcoded) — future: integrate with portfolio API

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 6.4.1 | MPOL-27a | Create analytical_dashboard.dart screen | Done |
| 6.4.2 | MPOL-27b | Create donut_chart.dart custom painter widget | Done |
| 6.4.3 | MPOL-27c | Create info_card.dart for statistics display | Done |
| 6.4.4 | MPOL-27d | Calculate category percentages and totals from policy data | Done |

---

### Story 6.5: Account Recovery Flow

**Key**: `MPOL-28`  
**Type**: Story  
**Summary**: Implement Account Recovery (OTP + Verification) Screens  
**Description**: As a customer, I want to recover my account via OTP verification if I forget my Customer ID or password. Currently uses mock data for demonstration.  
**Story Points**: 5  
**Priority**: Low  
**Acceptance Criteria**:
- Recovery Verification Screen: enter Customer ID, Email, or Phone for verification
- Two modes: "forgotPassword" and "getCustomerId"
- OTP Screen: 6-digit OTP input with 5-minute expiry timer
- 3 attempt limit for OTP
- Currently mock: hardcoded OTP `123456` and test credentials

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 6.5.1 | MPOL-28a | Create recovery_verification_screen.dart with dual mode (forgot password / get ID) | Done |
| 6.5.2 | MPOL-28b | Create recovery_otp_screen.dart with 6-digit OTP input | Done |
| 6.5.3 | MPOL-28c | Implement 5-minute countdown timer | Done |
| 6.5.4 | MPOL-28d | Add 3-attempt limit with lockout | Done |
| 6.5.5 | MPOL-28e | Mock verification logic (hardcoded credentials for demo) | Done |

---

### Story 6.6: API Service Layer & Models

**Key**: `MPOL-29`  
**Type**: Story  
**Summary**: Implement Flutter API Service Layer and Data Models  
**Description**: Build the service/model layer in Flutter that handles all HTTP communication with the BFF backend, JWT token management, and data serialization.  
**Story Points**: 5  
**Priority**: Highest  
**Acceptance Criteria**:
- ApiConfig: base URL (localhost:8090), all endpoint paths
- ApiService: login(), register(), getPortfolio(), getInsights(), getAdvisory(), checkHealth()
- JWT token stored in static variable, auto-attached to Authorization header
- Customer model: fromJson() mapping matching backend CustomerDTO
- Policy model: fromJson() with status parsing (ACTIVE/DUE/EXPIRED) and category detection (life/health/auto/others)
- ApiException class for error handling

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 6.6.1 | MPOL-29a | Create api_config.dart with base URL and all endpoint path constants | Done |
| 6.6.2 | MPOL-29b | Create api_service.dart with static HTTP methods and JWT token management | Done |
| 6.6.3 | MPOL-29c | Create customer_model.dart (Customer, AuthResponse) with fromJson() | Done |
| 6.6.4 | MPOL-29d | Create policy_model.dart (Policy, PolicyStatus, PolicyCategory) with fromJson() | Done |
| 6.6.5 | MPOL-29e | Add getAdvisory() method for coverage advisory integration | Done |

---

### Story 6.7: HDFC Theme & Branding

**Key**: `MPOL-30`  
**Type**: Story  
**Summary**: Implement HDFC Branding Theme  
**Description**: Apply HDFC Insurance branding (blue/red color scheme, typography, spacing) across the entire Flutter app.  
**Story Points**: 3  
**Priority**: Medium  
**Acceptance Criteria**:
- Primary blue: #2E5AAC, Primary red for CTAs
- Consistent spacing scale (4, 8, 12, 16, 24, 32, 48)
- Border radius presets (small, medium, large)
- Card shadows, background grey, text colors
- Responsive breakpoints (mobile < 650px, tablet, desktop)

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 6.7.1 | MPOL-30a | Create app_theme.dart with HDFC color constants and spacing | Done |
| 6.7.2 | MPOL-30b | Define lightTheme with typography and component themes | Done |
| 6.7.3 | MPOL-30c | Add SVG assets (HDFC logo, insurance illustrations) | Done |

---

### Story 6.8: Flutter Docker Deployment

**Key**: `MPOL-31`  
**Type**: Story  
**Summary**: Dockerize Flutter Web App  
**Description**: Create a Dockerfile for the Flutter HDFC-UI to build and serve the web app.  
**Story Points**: 2  
**Priority**: Medium  
**Acceptance Criteria**:
- Dockerfile builds Flutter web app
- Serves static files via nginx or similar
- Web deployment config in web/ directory

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 6.8.1 | MPOL-31a | Create Dockerfile for Flutter web build | Done |
| 6.8.2 | MPOL-31b | Configure web/index.html and manifest.json | Done |

---

## EPIC 7: Documentation & Quality

**Key**: `MPOL-E7`  
**Summary**: Project Documentation & Code Quality  
**Description**: Create comprehensive documentation including HLD, LLD, API sequence diagrams, beginner guide, deployment guide, and establish testing infrastructure.  
**Priority**: Medium  
**Labels**: `documentation`, `quality`

---

### Story 7.1: High-Level Design Document

**Key**: `MPOL-32`  
**Type**: Story  
**Summary**: Create HLD with Mermaid Architecture Diagrams  
**Description**: Document the system architecture with Mermaid diagrams showing all services, data flows, and MongoDB collections.  
**Story Points**: 3  
**Priority**: High  
**Acceptance Criteria**:
- System architecture diagram (Client → BFF → Services → MongoDB)
- Service communication matrix (BFF → Customer/Policy/Pipeline endpoints)
- Data flow overview (CSV ingestion → Portfolio view)

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 7.1.1 | MPOL-32a | Create HLD.md with system architecture Mermaid diagram | Done |
| 7.1.2 | MPOL-32b | Add service communication matrix diagram | Done |
| 7.1.3 | MPOL-32c | Add data flow overview diagram | Done |

---

### Story 7.2: API Sequence Diagrams

**Key**: `MPOL-33`  
**Type**: Story  
**Summary**: Create Detailed API Sequence Diagrams for All Flows  
**Description**: Document all API flows with Mermaid sequence diagrams showing request/response flow through all service layers.  
**Story Points**: 5  
**Priority**: High  
**Acceptance Criteria**:
- 9 sequence diagrams covering all major flows
- Includes: Registration, Login, CSV Upload & Pipeline, Portfolio View, Advisory, Insights, Customer Search, Policy CRUD, End-to-End

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 7.2.1 | MPOL-33a | Diagram 1: User Registration Flow | Done |
| 7.2.2 | MPOL-33b | Diagram 2: User Login Flow (Full Name + PAN) | Done |
| 7.2.3 | MPOL-33c | Diagram 3: CSV Upload & Pipeline Processing Flow | Done |
| 7.2.4 | MPOL-33d | Diagram 4: Portfolio View Flow | Done |
| 7.2.5 | MPOL-33e | Diagram 5: Coverage Advisory Flow | Done |
| 7.2.6 | MPOL-33f | Diagram 6: Coverage Insights Flow | Done |
| 7.2.7 | MPOL-33g | Diagram 7: Customer Search Flow | Done |
| 7.2.8 | MPOL-33h | Diagram 8: Policy CRUD Flow | Done |
| 7.2.9 | MPOL-33i | Diagram 9: Complete End-to-End Flow | Done |

---

### Story 7.3: LLD (Low-Level Design)

**Key**: `MPOL-34`  
**Type**: Story  
**Summary**: Create Low-Level Design Document  
**Description**: Document the detailed class-level design for each microservice.  
**Story Points**: 5  
**Priority**: Medium  

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 7.3.1 | MPOL-34a | Document BFF service class design (controllers, services, Feign clients, DTOs) | Done |
| 7.3.2 | MPOL-34b | Document Customer service class design (entity, repository, service, JWT) | Done |
| 7.3.3 | MPOL-34c | Document Data Pipeline class design (all modules, models, repositories) | Done |
| 7.3.4 | MPOL-34d | Document Policy service class design | Done |

---

### Story 7.4: Beginner's Guide

**Key**: `MPOL-35`  
**Type**: Story  
**Summary**: Create Spring Boot Beginner's Guide  
**Description**: Write a comprehensive guide for developers new to Spring Boot, explaining the architecture, layers, code flow, and key concepts using MyPolicy as the example.  
**Story Points**: 3  
**Priority**: Medium  

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 7.4.1 | MPOL-35a | Write sections: What is Spring Boot, Architecture Overview, Understanding Layers | Done |
| 7.4.2 | MPOL-35b | Write sections: Complete Code Flow, Key Concepts, Database Integration | Done |
| 7.4.3 | MPOL-35c | Write sections: Consolidated Service, Real World Walkthrough, FAQ, Glossary | Done |

---

## EPIC 8: Future Enhancements (Backlog)

**Key**: `MPOL-E8`  
**Summary**: Future Enhancements & Technical Debt  
**Description**: Planned improvements and technical debt items for future sprints.  
**Priority**: Low  
**Labels**: `backlog`, `enhancement`, `tech-debt`

---

### Story 8.1: API Documentation (Swagger/SpringDoc)

**Key**: `MPOL-36`  
**Type**: Story  
**Summary**: Add Swagger/OpenAPI Documentation  
**Description**: Integrate SpringDoc OpenAPI to auto-generate interactive API documentation for all microservices.  
**Story Points**: 3  
**Priority**: Medium  
**Status**: To Do  

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 8.1.1 | MPOL-36a | Add springdoc-openapi dependency to each service | To Do |
| 8.1.2 | MPOL-36b | Add @Operation annotations to all controller methods | To Do |
| 8.1.3 | MPOL-36c | Configure Swagger UI path and API info | To Do |

---

### Story 8.2: Comprehensive Test Suite

**Key**: `MPOL-37`  
**Type**: Story  
**Summary**: Implement Unit and Integration Tests  
**Description**: Currently no tests exist. Build a comprehensive test suite covering all services.  
**Story Points**: 13  
**Priority**: High  
**Status**: To Do  

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 8.2.1 | MPOL-37a | Unit tests for CustomerServiceImpl (register, login, search) | To Do |
| 8.2.2 | MPOL-37b | Unit tests for PolicyServiceImpl (CRUD operations) | To Do |
| 8.2.3 | MPOL-37c | Unit tests for StitchingService (3-tier matching logic) | To Do |
| 8.2.4 | MPOL-37d | Unit tests for AdvisoryRuleService (all 3 rules) | To Do |
| 8.2.5 | MPOL-37e | Unit tests for FileProcessingService (CSV parsing) | To Do |
| 8.2.6 | MPOL-37f | Integration tests for BFF → downstream service calls | To Do |
| 8.2.7 | MPOL-37g | Flutter widget tests for login, dashboard screens | To Do |

---

### Story 8.3: Security Hardening

**Key**: `MPOL-38`  
**Type**: Story  
**Summary**: Harden Security (JWT Validation, Secrets Management, Audit Logging)  
**Description**: Strengthen security posture: validate JWT on all protected BFF endpoints, move secrets to a vault, add audit logging.  
**Story Points**: 8  
**Priority**: High  
**Status**: To Do  

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 8.3.1 | MPOL-38a | Add JWT validation filter on all /api/bff/* endpoints (except auth) | To Do |
| 8.3.2 | MPOL-38b | Move MongoDB connection string, JWT secret, AES key to environment variables / vault | To Do |
| 8.3.3 | MPOL-38c | Add @PreAuthorize checks on sensitive endpoints | To Do |
| 8.3.4 | MPOL-38d | Implement audit logging for login, upload, stitching operations | To Do |
| 8.3.5 | MPOL-38e | Rate-limit login endpoint to prevent brute force | To Do |

---

### Story 8.4: Account Recovery (Real Implementation)

**Key**: `MPOL-39`  
**Type**: Story  
**Summary**: Implement Real OTP-Based Account Recovery  
**Description**: Replace mock account recovery with actual OTP delivery via SMS/email and server-side verification.  
**Story Points**: 8  
**Priority**: Medium  
**Status**: To Do  

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 8.4.1 | MPOL-39a | Create OTP generation and storage service (backend) | To Do |
| 8.4.2 | MPOL-39b | Integrate SMS gateway (Twilio/AWS SNS) for OTP delivery | To Do |
| 8.4.3 | MPOL-39c | Integrate email service (SendGrid/SES) for OTP delivery | To Do |
| 8.4.4 | MPOL-39d | Create BFF endpoints for OTP send/verify | To Do |
| 8.4.5 | MPOL-39e | Update Flutter recovery screens to call real backend | To Do |

---

### Story 8.5: Analytics Dashboard (Live Data)

**Key**: `MPOL-40`  
**Type**: Story  
**Summary**: Connect Analytics Dashboard to Live Portfolio Data  
**Description**: The analytical dashboard currently uses hardcoded sample data. Connect it to the real portfolio API.  
**Story Points**: 3  
**Priority**: Medium  
**Status**: To Do  

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 8.5.1 | MPOL-40a | Replace PolicyData.getSamplePolicies() with ApiService.getPortfolio() call | To Do |
| 8.5.2 | MPOL-40b | Add loading/error states to analytics screen | To Do |
| 8.5.3 | MPOL-40c | Integrate advisory data into analytics charts | To Do |

---

### Story 8.6: Distributed Tracing & Monitoring

**Key**: `MPOL-41`  
**Type**: Story  
**Summary**: Add Distributed Tracing and Centralized Monitoring  
**Description**: Add Spring Cloud Sleuth + Zipkin for distributed tracing, and Prometheus + Grafana for metrics monitoring.  
**Story Points**: 5  
**Priority**: Low  
**Status**: To Do  

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 8.6.1 | MPOL-41a | Add Micrometer Tracing + Zipkin dependencies to all services | To Do |
| 8.6.2 | MPOL-41b | Deploy Zipkin container in docker-compose.yml | To Do |
| 8.6.3 | MPOL-41c | Add Prometheus metrics endpoint to all services | To Do |
| 8.6.4 | MPOL-41d | Deploy Grafana dashboard with service health panels | To Do |

---

### Story 8.7: Global Error Handling

**Key**: `MPOL-42`  
**Type**: Story  
**Summary**: Implement Global Exception Handlers in All Services  
**Description**: Add @ControllerAdvice global error handlers for consistent error responses across all services.  
**Story Points**: 3  
**Priority**: Medium  
**Status**: To Do  

| Sub-task | Key | Summary | Status |
|----------|-----|---------|--------|
| 8.7.1 | MPOL-42a | Create GlobalExceptionHandler with @ControllerAdvice in each service | To Do |
| 8.7.2 | MPOL-42b | Standardize error response format: { timestamp, status, error, message, path } | To Do |
| 8.7.3 | MPOL-42c | Handle: ResourceNotFoundException, DuplicateException, ValidationException, FeignException | To Do |

---

# SUMMARY

## Epic Overview

| # | Epic | Stories | Sub-tasks | Status |
|---|------|---------|-----------|--------|
| E1 | Infrastructure & Service Discovery | 3 | 16 | **Done** |
| E2 | Customer Service | 4 | 16 | **Done** |
| E3 | Policy Service | 3 | 9 | **Done** |
| E4 | Data Pipeline & Identity Stitching | 7 | 27 | **Done** |
| E5 | BFF Service (API Gateway) | 6 | 17 | **Done** |
| E6 | Flutter Frontend (HDFC-UI) | 8 | 32 | **Done** |
| E7 | Documentation & Quality | 4 | 15 | **Done** |
| E8 | Future Enhancements (Backlog) | 7 | 25 | **To Do** |
| **Total** | **8 Epics** | **42 Stories** | **157 Sub-tasks** | — |

## Story Points Distribution

| Epic | Story Points | % of Total |
|------|-------------|------------|
| Infrastructure | 11 | 8% |
| Customer Service | 19 | 14% |
| Policy Service | 10 | 7% |
| Data Pipeline | 42 | 31% |
| BFF Service | 19 | 14% |
| Flutter Frontend | 36 | 26% |
| **Total (Done)** | **137 SP** | **100%** |
| **Backlog** | **43 SP** | — |

## Sprint Mapping (Suggested Retrospective)

| Sprint | Focus | Stories | SP |
|--------|-------|---------|-----|
| Sprint 1 | Infrastructure + DB setup | MPOL-1 to MPOL-3 | 11 |
| Sprint 2 | Customer Service + Auth | MPOL-4 to MPOL-7 | 19 |
| Sprint 3 | Policy Service + Pipeline Core | MPOL-8 to MPOL-13 | 23 |
| Sprint 4 | Identity Stitching + Advisory | MPOL-14 to MPOL-17 | 29 |
| Sprint 5 | BFF Gateway | MPOL-18 to MPOL-23 | 19 |
| Sprint 6 | Flutter UI (Core) | MPOL-24 to MPOL-27 | 21 |
| Sprint 7 | Flutter UI (Extras) + Docs | MPOL-28 to MPOL-35 | 26 |
| Sprint 8+ | Backlog / Tech Debt | MPOL-36 to MPOL-42 | 43 |
