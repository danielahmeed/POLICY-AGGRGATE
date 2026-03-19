# Customer Service — Full Slide Content

---

## SLIDE 1: Service Overview

| Property             | Value                                 |
| -------------------- | ------------------------------------- |
| **Service Name**     | customer-service                      |
| **Port**             | 8081                                  |
| **Java Version**     | 17                                    |
| **Spring Boot**      | 3.1.5                                 |
| **Spring Cloud**     | 2022.0.4                              |
| **Database**         | MongoDB Atlas (`Backend_databases`)   |
| **Authentication**   | JWT (Bearer Token, HS256, 24h expiry) |
| **Password Hashing** | BCrypt                                |
| **Build Tool**       | Maven                                 |

**Tech Stack**: Spring Boot + Spring Security + Spring Data MongoDB + Spring Cloud (Eureka + Config Server) + JWT + Docker + Lombok + OpenCSV

---

## SLIDE 2: Architecture & Communication

**Microservice Communication:**

```
[Frontend/Mobile App]
        ↓
[BFF Service (8080)] ──Feign Client──→ [Customer Service (8081)]
        ↓                                       ↓
[Eureka Discovery (8761)]               [MongoDB Atlas]
        ↓
[Config Server (8888)]
```

- **Service Discovery**: Eureka auto-registration as `customer-service`
- **Config Management**: Pulls from Config Server at startup
- **BFF Integration**: Feign HTTP client via service discovery
- **Stateless**: JWT-based, no server-side sessions — horizontally scalable

---

## SLIDE 3: Two Authentication Flows

### Flow 1 — Standard Registration + Login

1. `POST /api/v1/customers/register` → stores in `customers` collection (BCrypt password)
2. `POST /api/v1/customers/login` → validates credentials → returns JWT token
3. All subsequent requests include `Authorization: Bearer <token>`

### Flow 2 — Portfolio Login (Full Name + PAN)

1. `POST /api/bff/auth/login` → BFF proxies to customer-service
2. Looks up `customer_details` collection (full name + PAN match)
3. Generates JWT → used for portfolio viewing via `/api/bff/portfolio/{customerId}`

---

## SLIDE 4: REST API Endpoints

**Base**: `http://localhost:8081/api/v1/customers`

| Method | Endpoint                  | Purpose                          | Auth   |
| ------ | ------------------------- | -------------------------------- | ------ |
| POST   | `/register`               | Register new customer            | Public |
| POST   | `/login`                  | Login (full name + PAN)          | Public |
| GET    | `/{customerId}`           | Get customer by UUID             | JWT    |
| GET    | `/details/{customerId}`   | Get by Integer ID (BFF internal) | Public |
| PUT    | `/{customerId}`           | Update customer profile          | JWT    |
| GET    | `/search/mobile/{mobile}` | Search by mobile                 | JWT    |
| GET    | `/search/email/{email}`   | Search by email                  | JWT    |
| GET    | `/search/pan/{pan}`       | Search by PAN                    | JWT    |

**Health Endpoints:**

| Endpoint                       | Response                                            |
| ------------------------------ | --------------------------------------------------- |
| `GET /api/v1/health`           | `{ "status": "UP", "service": "customer-service" }` |
| `GET /api/v1/ping`             | `"pong"`                                            |
| `GET /health` or `/api/health` | Detailed health with version, port, DB info         |

---

## SLIDE 5: Data Models

### Customer Entity (MongoDB: `customers` collection)

| Field                                         | Type          | Constraints                          |
| --------------------------------------------- | ------------- | ------------------------------------ |
| `customerId`                                  | String (UUID) | Primary Key                          |
| `firstName`, `lastName`                       | String        | Required                             |
| `email`                                       | String        | Unique Index, Required               |
| `mobileNumber`                                | String        | Unique Index, Required               |
| `panNumber`                                   | String        | Unique Index                         |
| `dateOfBirth`                                 | LocalDate     |                                      |
| `passwordHash`                                | String        | BCrypt encoded                       |
| `permanentAddressLine1/2/3`                   | String        | Address fields                       |
| `permanentAddressCity`, `permanentAddressZip` | String        |                                      |
| `status`                                      | Enum          | ACTIVE, INACTIVE, SUSPENDED, DELETED |
| `createdAt`, `updatedAt`                      | LocalDateTime | Timestamps                           |

### CustomerDetails Entity (MongoDB: `customer_details` collection)

| Field              | Type    | Purpose              |
| ------------------ | ------- | -------------------- |
| `customerId`       | Integer | Legacy system ID     |
| `customerFullName` | String  | Login username       |
| `refCustItNum`     | String  | PAN (login password) |
| `refPhoneMobile`   | Object  | Mobile number        |
| `datBirthCust`     | Integer | DOB (YYYYMMDD)       |
| `custEmailID`      | String  | Email                |

---

## SLIDE 6: DTOs & Validation

### Registration Request

| Field                                      | Validation             |
| ------------------------------------------ | ---------------------- |
| `firstName`                                | `@NotBlank`            |
| `lastName`                                 | `@NotBlank`            |
| `email`                                    | `@NotBlank` + `@Email` |
| `mobileNumber`                             | `@NotBlank`            |
| `password`                                 | `@NotBlank`            |
| `panNumber`, `dateOfBirth`, address fields | Optional               |

### Update Request

| Field          | Validation                                            |
| -------------- | ----------------------------------------------------- |
| `email`        | `@Email` format                                       |
| `mobileNumber` | `@Pattern(^[0-9]{10}$)` — 10 digits                   |
| `panNumber`    | `@Pattern(^[A-Z]{5}[0-9]{4}[A-Z]{1}$)` — standard PAN |
| All fields     | Optional (partial update support)                     |

### Auth Response

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "customer": { "customerId": "...", "firstName": "...", ... }
}
```

---

## SLIDE 7: Security Architecture

### Security Configuration

- **Public**: `/register`, `/login`, `/details/**`, health endpoints, actuator
- **Protected**: All other endpoints require valid JWT

### JWT Token Details

| Property   | Value                                         |
| ---------- | --------------------------------------------- |
| Algorithm  | HS256 (HMAC-SHA256)                           |
| Expiration | 24 hours                                      |
| Claims     | Subject (username), issued-at, expiration     |
| Validation | Signature + expiration check on every request |

### Filter Chain

```
Request → JwtAuthenticationFilter → SecurityFilterChain → Controller
                ↓
    Extract Bearer token → Validate signature → Set SecurityContext
```

### Password Security

- BCrypt encoding for stored passwords
- Never returns password in response DTOs

---

## SLIDE 8: Business Logic Layer

### CustomerServiceImpl — Key Operations

1. **registerCustomer()** — Validates uniqueness (email/mobile) → generates UUID → BCrypt password → saves to MongoDB
2. **login()** — Matches full name + PAN in `customer_details` → generates JWT
3. **getCustomerById()** — Retrieves from `customers` by UUID
4. **updateCustomer()** — Partial update (only non-null fields) → validates uniqueness
5. **searchByMobile/Email/Pan()** — Returns `Optional<CustomerResponse>`
6. **getCustomerDetailsByIntegerId()** — Retrieves from `customer_details` by Integer ID (portfolio)

### CsvImportService — Bulk Import

- Parses CSV via OpenCSV
- Converts rows to registration requests
- Skips duplicates (checks email existence)
- Returns `ImportResult` with success/fail counts & details
- Default password: `DefaultPassword@123`

---

## SLIDE 9: Exception Handling

### Global Exception Handler

| Exception                         | HTTP Status      | When                       |
| --------------------------------- | ---------------- | -------------------------- |
| `CustomerNotFoundException`       | 404 NOT FOUND    | Lookup fails               |
| `DuplicateCustomerException`      | 409 CONFLICT     | Duplicate email/mobile/PAN |
| `InvalidCredentialsException`     | 401 UNAUTHORIZED | Login failure              |
| `MethodArgumentNotValidException` | 400 BAD REQUEST  | Validation errors          |
| `RuntimeException`                | 400 BAD REQUEST  | Generic errors             |

### Error Response Format

```json
{
  "timestamp": "2026-03-11T10:30:00",
  "message": "Customer not found with id: xxx",
  "status": 404,
  "errors": { "email": "Invalid email format" }
}
```

---

## SLIDE 10: BFF Integration

### Feign Client in BFF Service

```java
@FeignClient(name = "customer-service")
public interface CustomerClient {
  @PostMapping("/api/v1/customers/register")
  CustomerDTO register(@RequestBody Object request);

  @PostMapping("/api/v1/customers/login")
  AuthResponse login(@RequestBody LoginRequest request);

  @GetMapping("/api/v1/customers/{customerId}")
  CustomerDTO getCustomerById(@PathVariable String customerId);

  @GetMapping("/api/v1/customers/details/{customerId}")
  CustomerDTO getCustomerDetails(@PathVariable Integer customerId);
}
```

### Portfolio Flow (BFF)

```
BFF receives GET /api/bff/portfolio/{customerId}
  → Calls customer-service: GET /api/v1/customers/details/{customerId}
  → Calls data-pipeline-service: GET /portfolio/{customerId}
  → Combines both into unified portfolio response
```

---

## SLIDE 11: Docker & Deployment

### Multi-Stage Dockerfile

```
Stage 1 (Build): maven:3.9-eclipse-temurin-17-alpine
  → mvn dependency:go-offline → mvn package -DskipTests

Stage 2 (Run): eclipse-temurin:17-jre-alpine
  → COPY app.jar → EXPOSE 8081
  → HEALTHCHECK every 15s (60s startup grace)
```

### Environment Variables

| Variable                  | Default                                 | Purpose   |
| ------------------------- | --------------------------------------- | --------- |
| `SPRING_DATA_MONGODB_URI` | MongoDB Atlas connection                | Database  |
| `CONFIG_SERVER_URI`       | `http://admin:config123@localhost:8888` | Config    |
| `EUREKA_DEFAULT_ZONE`     | `http://localhost:8761/eureka`          | Discovery |

### Database Migration

- **supabase-migrate.ps1**: PowerShell script for PostgreSQL → Supabase migration
- Uses `pg_dump` + `psql` with secure password input

---

## SLIDE 12: Data Repository Layer

### CustomerRepository (MongoDB)

```java
public interface CustomerRepository extends MongoRepository<Customer, String> {
  Optional<Customer> findByEmail(String email);
  Optional<Customer> findByMobileNumber(String mobileNumber);
  Optional<Customer> findByPanNumber(String panNumber);
  boolean existsByEmail(String email);
  boolean existsByMobileNumber(String mobileNumber);
}
```

### CustomerDetailsRepository (MongoDB)

```java
public interface CustomerDetailsRepository extends MongoRepository<CustomerDetails, String> {
  Optional<CustomerDetails> findFirstByCustomerFullNameIgnoreCaseAndRefCustItNum(
    String customerFullName, String refCustItNum);
  Optional<CustomerDetails> findFirstByCustomerId(Integer customerId);
}
```

---

## SLIDE 13: Sample Data

### Customer_data.csv — 20 records from 8 cities

| Sample Fields | Example Values                                                   |
| ------------- | ---------------------------------------------------------------- |
| Customer ID   | 901120934 – 901120953                                            |
| Full Name     | Amit Ramesh Kulkarni, Sneha Prakash Patil                        |
| Mobile        | 919876543210 (with country code)                                 |
| DOB           | 19920314 (YYYYMMDD)                                              |
| PAN           | AKCPK1123L                                                       |
| Cities        | Delhi, Pune, Noida, Bangalore, Hyderabad, Mumbai, Patiala, Patna |

---

## SLIDE 14: Key Technical Highlights

- **Lombok** — `@Data`, `@Builder`, `@RequiredArgsConstructor`, `@Slf4j` reduce boilerplate
- **Spring Data MongoDB** — `@Document`, `@Indexed(unique=true)`, derived query methods
- **Spring Security** — Stateless `SecurityFilterChain` + JWT filter pipeline
- **Validation** — Jakarta Bean Validation (`@NotBlank`, `@Email`, `@Pattern`)
- **REST Best Practices** — Proper HTTP status codes, consistent JSON, DTOs separate from entities
- **Horizontal Scalability** — Stateless JWT, shared MongoDB, Eureka load-balancing

---

## SLIDE 15: Source Code Structure

```
customer-service/
├── src/main/java/com/mypolicy/customer/
│   ├── CustomerServiceApplication.java          ← Entry point
│   ├── controller/
│   │   ├── CustomerController.java              ← REST endpoints
│   │   ├── HealthCheckController.java           ← /health, /ping
│   │   └── HealthController.java                ← Detailed health
│   ├── service/
│   │   ├── CustomerService.java                 ← Interface (7 methods)
│   │   ├── impl/CustomerServiceImpl.java        ← Business logic
│   │   └── CsvImportService.java                ← Bulk CSV import
│   ├── repository/
│   │   ├── CustomerRepository.java              ← MongoDB (customers)
│   │   └── CustomerDetailsRepository.java       ← MongoDB (customer_details)
│   ├── model/
│   │   ├── Customer.java                        ← Entity (customers)
│   │   ├── CustomerDetails.java                 ← Entity (customer_details)
│   │   └── CustomerStatus.java                  ← Enum
│   ├── dto/
│   │   ├── CustomerRegistrationRequest.java     ← Registration input
│   │   ├── LoginRequest.java                    ← Login input
│   │   ├── CustomerResponse.java                ← API response
│   │   ├── CustomerUpdateRequest.java           ← Update input
│   │   ├── AuthResponse.java                    ← Token + customer
│   │   └── CustomerCsvImportRequest.java        ← CSV row mapping
│   ├── exception/
│   │   ├── GlobalExceptionHandler.java          ← @ControllerAdvice
│   │   ├── CustomerNotFoundException.java       ← 404
│   │   ├── DuplicateCustomerException.java      ← 409
│   │   └── InvalidCredentialsException.java     ← 401
│   ├── security/
│   │   ├── JwtService.java                      ← Token generation/validation
│   │   ├── JwtAuthenticationFilter.java         ← Request filter
│   │   └── CustomUserDetailsService.java        ← User lookup
│   └── config/
│       └── SecurityConfig.java                  ← Spring Security setup
├── src/main/resources/
│   └── application.yaml                         ← Configuration
├── mypolicy_db.sql                              ← PostgreSQL schema dump
├── Customer_data.csv                            ← 20 sample records
├── scripts/supabase-migrate.ps1                 ← Migration script
├── Dockerfile                                   ← Multi-stage Docker build
└── pom.xml                                      ← Maven dependencies
```

---

## SLIDE 16: Database Schema (PostgreSQL — mypolicy_db.sql)

### Customers Table

```sql
CREATE TABLE public.customers (
  customer_id   VARCHAR(255) NOT NULL PRIMARY KEY,
  first_name    VARCHAR(255) NOT NULL,
  last_name     VARCHAR(255) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  mobile_number VARCHAR(255) NOT NULL UNIQUE,
  pan_number    VARCHAR(255) UNIQUE,
  date_of_birth DATE,
  password_hash VARCHAR(255) NOT NULL,
  address       TEXT,
  status        VARCHAR(255) NOT NULL
                CHECK (status IN ('ACTIVE','INACTIVE','SUSPENDED','DELETED')),
  created_at    TIMESTAMP(6),
  updated_at    TIMESTAMP(6)
);
```

### Policies Table

```sql
CREATE TABLE public.policies (
  id             VARCHAR(255) NOT NULL PRIMARY KEY,
  customer_id    VARCHAR(255) NOT NULL,
  policy_number  VARCHAR(255) NOT NULL,
  policy_type    VARCHAR(255) NOT NULL,
  insurer_id     VARCHAR(255) NOT NULL,
  plan_name      VARCHAR(255),
  premium_amount NUMERIC(38,2) NOT NULL,
  sum_assured    NUMERIC(38,2) NOT NULL,
  start_date     DATE,
  end_date       DATE,
  status         VARCHAR(255)
                 CHECK (status IN ('ACTIVE','EXPIRED','LAPSED','PENDING','CANCELLED')),
  created_at     TIMESTAMP(6),
  updated_at     TIMESTAMP(6),
  UNIQUE (policy_number, insurer_id)
);
```

### Insurer Configurations Table

```sql
CREATE TABLE public.insurer_configurations (
  config_id      VARCHAR(255) NOT NULL PRIMARY KEY,
  insurer_id     VARCHAR(255) NOT NULL,
  insurer_name   VARCHAR(255) NOT NULL,
  field_mappings JSONB,
  active         BOOLEAN NOT NULL,
  updated_at     TIMESTAMP(6)
);
```

---

## SLIDE 17: Dependencies (pom.xml)

| Dependency                                   | Version  | Purpose                      |
| -------------------------------------------- | -------- | ---------------------------- |
| `spring-boot-starter-parent`                 | 3.1.5    | Spring Boot framework        |
| `spring-cloud-starter-config`                | 2022.0.4 | Config server integration    |
| `spring-cloud-starter-netflix-eureka-client` | 2022.0.4 | Service discovery            |
| `spring-boot-starter-web`                    | 3.1.5    | REST API support             |
| `spring-boot-starter-data-mongodb`           | 3.1.5    | MongoDB ODM                  |
| `spring-boot-starter-validation`             | 3.1.5    | Bean validation (Jakarta)    |
| `spring-boot-starter-security`               | 3.1.5    | Authentication/authorization |
| `jjwt-api`                                   | 0.11.5   | JWT token generation         |
| `jjwt-impl`                                  | 0.11.5   | JWT implementation (runtime) |
| `jjwt-jackson`                               | 0.11.5   | JWT Jackson serialization    |
| `opencsv`                                    | 5.9      | CSV parsing                  |
| `lombok`                                     | 1.18.40  | Code generation              |

### Build Plugins

| Plugin                     | Version | Purpose              |
| -------------------------- | ------- | -------------------- |
| `maven-compiler-plugin`    | 3.14.1  | Java 17 compilation  |
| `spring-boot-maven-plugin` | 3.1.5   | Build executable JAR |
