# Customer Service — Complete Line-by-Line Code Explanation

> This document explains **every file** in the Customer Service microservice line by line, so you can confidently present and explain the code in any review, viva, or interview.

---

## Table of Contents

1. [Project Structure Overview](#1-project-structure-overview)
2. [pom.xml (Dependencies)](#2-pomxml-dependencies)
3. [application.yaml (Configuration)](#3-applicationyaml-configuration)
4. [CustomerServiceApplication.java (Main Class)](#4-customerserviceapplicationjava-main-class)
5. [Model Layer](#5-model-layer)
   - 5.1 Customer.java
   - 5.2 CustomerDetails.java
   - 5.3 CustomerStatus.java
6. [Repository Layer](#6-repository-layer)
   - 6.1 CustomerRepository.java
   - 6.2 CustomerDetailsRepository.java
7. [DTO Layer (Data Transfer Objects)](#7-dto-layer)
   - 7.1 LoginRequest.java
   - 7.2 AuthResponse.java
   - 7.3 CustomerRegistrationRequest.java
   - 7.4 CustomerResponse.java
   - 7.5 CustomerUpdateRequest.java
   - 7.6 CustomerCsvImportRequest.java
8. [Service Layer](#8-service-layer)
   - 8.1 CustomerService.java (Interface)
   - 8.2 CustomerServiceImpl.java (Implementation)
   - 8.3 CsvImportService.java
9. [Security Layer](#9-security-layer)
   - 9.1 JwtService.java
   - 9.2 JwtAuthenticationFilter.java
   - 9.3 CustomUserDetailsService.java
10. [Controller Layer](#10-controller-layer)
    - 10.1 CustomerController.java
    - 10.2 HealthController.java
    - 10.3 HealthCheckController.java
11. [Exception Handling](#11-exception-handling)
    - 11.1 CustomerNotFoundException.java
    - 11.2 DuplicateCustomerException.java
    - 11.3 InvalidCredentialsException.java
    - 11.4 GlobalExceptionHandler.java
12. [How the Complete Flow Works](#12-how-the-complete-flow-works)

---

## 1. Project Structure Overview

```
customer-service/
├── pom.xml                          ← Maven build + dependency configuration
├── src/main/resources/
│   └── application.yaml             ← Server port, MongoDB connection, Eureka config
└── src/main/java/com/mypolicy/customer/
    ├── CustomerServiceApplication.java    ← Spring Boot main class (entry point)
    ├── model/
    │   ├── Customer.java                  ← MongoDB document for "customers" collection
    │   ├── CustomerDetails.java           ← MongoDB document for "customer_details" collection
    │   └── CustomerStatus.java            ← Enum: ACTIVE, INACTIVE, SUSPENDED, DELETED
    ├── repository/
    │   ├── CustomerRepository.java        ← MongoDB CRUD for "customers"
    │   └── CustomerDetailsRepository.java ← MongoDB queries for "customer_details"
    ├── dto/
    │   ├── LoginRequest.java              ← Login input (fullName + PAN)
    │   ├── AuthResponse.java              ← Login output (JWT token + customer)
    │   ├── CustomerRegistrationRequest.java ← Registration input
    │   ├── CustomerResponse.java          ← Customer output (no password)
    │   ├── CustomerUpdateRequest.java     ← Profile update input
    │   └── CustomerCsvImportRequest.java  ← CSV row mapping
    ├── service/
    │   ├── CustomerService.java           ← Service interface (contract)
    │   ├── impl/
    │   │   └── CustomerServiceImpl.java   ← Business logic (register, login, search, update)
    │   └── CsvImportService.java          ← Bulk CSV import logic
    ├── security/
    │   ├── JwtService.java                ← JWT token generation + validation
    │   ├── JwtAuthenticationFilter.java   ← Filter that checks JWT on every request
    │   └── CustomUserDetailsService.java  ← Loads user profile for Spring Security
    ├── controller/
    │   ├── CustomerController.java        ← REST endpoints (register, login, search, update)
    │   ├── HealthController.java          ← Health check (/, /health, /api/health)
    │   └── HealthCheckController.java     ← Health check (/api/v1/health, /api/v1/ping)
    └── exception/
        ├── CustomerNotFoundException.java   ← 404 error
        ├── DuplicateCustomerException.java  ← 409 error
        ├── InvalidCredentialsException.java ← 401 error
        └── GlobalExceptionHandler.java      ← Catches all exceptions → JSON error response
```

**Layered Architecture**:
```
Client Request → Controller → Service → Repository → MongoDB
                     ↑              ↑
              Exception Handler   Security (JWT Filter)
```

---

## 2. pom.xml (Dependencies)

This file tells Maven what libraries to download and how to build the project.

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.1.5</version>
</parent>
```
**Line-by-line**:
- `<parent>` — Inherits default settings from Spring Boot 3.1.5 (plugin versions, dependency management, Java defaults).
- `version 3.1.5` — This means we use Spring Boot 3.x, which requires **Java 17+** and uses **Jakarta EE** (not javax).

```xml
<groupId>com.mypolicy</groupId>
<artifactId>customer-service</artifactId>
<version>0.0.1-SNAPSHOT</version>
```
- `groupId` — Our company/project namespace (like a package name).
- `artifactId` — The name of this specific module: `customer-service`.
- `SNAPSHOT` — Indicates this is a development version, not a release.

### Dependencies Explained

| Dependency | What It Does |
|-----------|-------------|
| `spring-cloud-starter-config` | Pulls configuration from Config Server (port 8888) on startup |
| `spring-cloud-starter-netflix-eureka-client` | Registers this service with Eureka (port 8761) so other services can discover it |
| `spring-boot-starter-web` | Provides REST API capabilities (embedded Tomcat, @RestController, @GetMapping, etc.) |
| `spring-boot-starter-data-mongodb` | MongoDB integration — provides MongoRepository, @Document, MongoTemplate |
| `spring-boot-starter-validation` | Bean validation — @NotBlank, @Email, @Pattern annotations on DTOs |
| `lombok` | Reduces boilerplate — auto-generates getters, setters, constructors, builders at compile time |
| `spring-boot-starter-security` | Spring Security framework — password encoding, authentication filters, security context |
| `jjwt-api` + `jjwt-impl` + `jjwt-jackson` | JJWT library (v0.11.5) — creates and validates JSON Web Tokens (HS256 algorithm) |
| `opencsv` | CSV file parsing library — reads CSV files and maps rows to Java objects |
| `spring-boot-starter-test` | Testing (JUnit 5, Mockito) — `scope: test` means only available during testing |

### Build Plugins

```xml
<plugin>
    <artifactId>maven-compiler-plugin</artifactId>
    <configuration>
        <source>17</source>
        <target>17</target>
        <annotationProcessorPaths>
            <path>
                <groupId>org.projectlombok</groupId>
                <artifactId>lombok</artifactId>
```
- Compiles code with **Java 17** source and target.
- `annotationProcessorPaths` → tells the compiler to process Lombok annotations at compile time (generates getters/setters bytecode).

```xml
<plugin>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <configuration>
        <excludes>
            <exclude>
                <groupId>org.projectlombok</groupId>
```
- Builds an executable fat JAR (includes all dependencies inside one JAR).
- Excludes Lombok from the final JAR because it's only needed at compile time.

---

## 3. application.yaml (Configuration)

```yaml
server:
  port: 8081
```
- **Line 1-2**: The service runs on **port 8081**. When you hit `http://localhost:8081`, it reaches this service.

```yaml
spring:
  config:
    import: optional:configserver:http://admin:config123@localhost:8888
```
- **Line 4-6**: On startup, the service tries to pull configuration from **Config Server** at port 8888.
- `optional:` — If Config Server is not running, the service still starts (doesn't crash).
- `admin:config123` — Basic auth credentials to access Config Server.

```yaml
  application:
    name: customer-service
```
- **Line 7-8**: Names this service `customer-service`. This name is used for:
  1. **Eureka registration** — other services discover it by this name.
  2. **Config Server** — looks for a file named `customer-service.yaml` in its config repo.

```yaml
  data:
    mongodb:
      uri: ${SPRING_DATA_MONGODB_URI:mongodb+srv://...@cluster0.enwyvnr.mongodb.net/...}
      database: Backend_databases
```
- **Line 10-13**: MongoDB connection.
- `${SPRING_DATA_MONGODB_URI:...}` — Uses the environment variable `SPRING_DATA_MONGODB_URI` if set; otherwise falls back to the hardcoded MongoDB Atlas connection string.
- `database: Backend_databases` — All collections (customers, customer_details) live in this database.

```yaml
eureka:
  client:
    service-url:
      defaultZone: ${EUREKA_DEFAULT_ZONE:http://localhost:8761/eureka}
  instance:
    prefer-ip-address: true
```
- **Line 15-20**: Eureka service discovery configuration.
- `defaultZone` — URL of the Eureka server. Uses env var or defaults to localhost:8761.
- `prefer-ip-address: true` — Registers with its IP address instead of hostname (important for Docker networking).

---

## 4. CustomerServiceApplication.java (Main Class)

```java
package com.mypolicy.customer;                                    // 1
                                                                   // 2
import org.springframework.boot.SpringApplication;                 // 3
import org.springframework.boot.autoconfigure.SpringBootApplication; // 4
                                                                   // 5
@SpringBootApplication                                             // 6
public class CustomerServiceApplication {                          // 7
                                                                   // 8
    public static void main(String[] args) {                       // 9
        SpringApplication.run(CustomerServiceApplication.class, args); // 10
    }                                                              // 11
}                                                                  // 12
```

| Line | Explanation |
|------|------------|
| 1 | **Package declaration** — this class belongs to `com.mypolicy.customer` package |
| 3 | Imports `SpringApplication` — the class that boots up the Spring context |
| 4 | Imports `@SpringBootApplication` — a meta-annotation that combines 3 annotations |
| 6 | **`@SpringBootApplication`** — This single annotation does 3 things: |
|   | 1. `@Configuration` — Marks this class as a source of bean definitions |
|   | 2. `@EnableAutoConfiguration` — Spring Boot auto-configures beans based on dependencies (e.g., sees `spring-boot-starter-data-mongodb` → auto-creates MongoTemplate, MongoRepository beans) |
|   | 3. `@ComponentScan` — Scans `com.mypolicy.customer` and all sub-packages for `@Component`, `@Service`, `@Repository`, `@Controller`, `@RestController` classes and registers them as Spring beans |
| 7 | Class declaration — the entry point of the application |
| 9 | `main()` — Java's entry point. JVM calls this first |
| 10 | **`SpringApplication.run(...)`** — Boots up the entire Spring context: |
|   | 1. Starts embedded Tomcat server on port 8081 |
|   | 2. Scans and registers all beans (@Service, @Repository, @Controller, etc.) |
|   | 3. Connects to MongoDB Atlas |
|   | 4. Registers with Eureka discovery server |
|   | 5. Pulls config from Config Server (if available) |

---

## 5. Model Layer

Models represent the **data structure** stored in MongoDB. Each model maps to a **MongoDB collection** (like a table in SQL).

### 5.1 Customer.java

```java
package com.mypolicy.customer.model;                              // 1

import lombok.Data;                                                // 2
import lombok.NoArgsConstructor;                                   // 3
import lombok.AllArgsConstructor;                                  // 4
import lombok.Builder;                                             // 5
import org.springframework.data.annotation.Id;                     // 6
import org.springframework.data.mongodb.core.index.Indexed;        // 7
import org.springframework.data.mongodb.core.mapping.Document;     // 8
                                                                   // 9
import java.time.LocalDate;                                        // 10
import java.time.LocalDateTime;                                    // 11
                                                                   // 12
@Data                                                              // 13
@Builder                                                           // 14
@NoArgsConstructor                                                 // 15
@AllArgsConstructor                                                // 16
@Document(collection = "customers")                                // 17
public class Customer {                                            // 18
                                                                   // 19
  @Id                                                              // 20
  private String customerId;                                       // 21
                                                                   // 22
  private String firstName;                                        // 23
  private String lastName;                                         // 24
                                                                   // 25
  @Indexed(unique = true)                                          // 26
  private String email;                                            // 27
                                                                   // 28
  @Indexed(unique = true)                                          // 29
  private String mobileNumber;                                     // 30
                                                                   // 31
  @Indexed(unique = true)                                          // 32
  private String panNumber;                                        // 33
                                                                   // 34
  private LocalDate dateOfBirth;                                   // 35
  private String passwordHash;                                     // 36
                                                                   // 37
  private String permanentAddressLine1;                            // 38
  private String permanentAddressLine2;                            // 39
  private String permanentAddressLine3;                            // 40
  private String permanentAddressCity;                              // 41
  private String permanentAddressZip;                               // 42
  private String customerAddressZip;                                // 43
  private String address;                                          // 44
                                                                   // 45
  @Builder.Default                                                 // 46
  private CustomerStatus status = CustomerStatus.ACTIVE;           // 47
                                                                   // 48
  private LocalDateTime createdAt;                                 // 49
  private LocalDateTime updatedAt;                                 // 50
}                                                                  // 51
```

| Line(s) | Explanation |
|---------|------------|
| 2-5 | **Lombok imports** — These are compile-time annotations that auto-generate code |
| 6 | `@Id` import — Marks a field as the MongoDB document `_id` |
| 7 | `@Indexed` import — Creates a MongoDB index on a field |
| 8 | `@Document` import — Maps this class to a MongoDB collection |
| 13 | **`@Data`** — Lombok: auto-generates `getters`, `setters`, `toString()`, `equals()`, `hashCode()` for ALL fields. Without this, you'd need to write ~50 lines of boilerplate |
| 14 | **`@Builder`** — Lombok: lets you create objects using fluent builder pattern: `Customer.builder().firstName("Rahul").build()` |
| 15 | **`@NoArgsConstructor`** — Lombok: generates empty constructor `Customer()`. Required by MongoDB for deserialization |
| 16 | **`@AllArgsConstructor`** — Lombok: generates constructor with ALL fields as parameters |
| 17 | **`@Document(collection = "customers")`** — This class maps to the MongoDB collection named **"customers"**. Each instance of `Customer` = one document in that collection |
| 20-21 | **`@Id`** on `customerId` — This field maps to MongoDB's `_id` field. It's the primary key. We store UUIDs here (e.g., `"a7b3c1d4-..."`) |
| 26-27 | **`@Indexed(unique = true)`** on `email` — Creates a unique index in MongoDB. If you try to insert two customers with the same email, MongoDB throws a duplicate key error |
| 29-30 | Same unique index on `mobileNumber` |
| 32-33 | Same unique index on `panNumber` |
| 35 | `LocalDate` — Stores date-only (e.g., `1995-06-15`), no time component |
| 36 | `passwordHash` — Stores the **BCrypt-hashed** password, never the plain text |
| 38-44 | Address fields — Multiple address lines + city + zip (maps to CSV columns from Customer_data.csv) |
| 46-47 | **`@Builder.Default`** — When using builder pattern, if you don't set `status`, it defaults to `ACTIVE`. Without this, builder would set it to `null` |
| 49-50 | Audit timestamps — `createdAt` = when record was created, `updatedAt` = last modification time |

**In MongoDB, a Customer document looks like**:
```json
{
  "_id": "a7b3c1d4-e5f6-7890-abcd-ef1234567890",
  "firstName": "Rahul",
  "lastName": "Sharma",
  "email": "rahul@example.com",
  "mobileNumber": "9876543210",
  "panNumber": "ABCDE1234F",
  "dateOfBirth": "1995-06-15",
  "passwordHash": "$2a$10$xJHr...",
  "status": "ACTIVE"
}
```

---

### 5.2 CustomerDetails.java

This maps to the **`customer_details`** collection — master customer data imported from insurers. This is the collection used for **login authentication**.

```java
package com.mypolicy.customer.model;                              // 1

import org.springframework.data.annotation.Id;                     // 2
import org.springframework.data.mongodb.core.mapping.Document;     // 3

@Document(collection = "customer_details")                         // 4
public class CustomerDetails {                                     // 5

    @Id                                                            // 6
    private String id;                                             // 7
    private Integer customerId;                                    // 8
    private String refCustItNum;      // PAN number                // 9
    private Object refPhoneMobile;                                 // 10
    private Integer datBirthCust;                                  // 11
    private String custEmailID;                                    // 12
    private String customerFullName;                               // 13

    // Manual getters and setters (lines 15-37)                    // 14
    public String getId() { return id; }                           // 15
    public void setId(String id) { this.id = id; }                // 16
    // ... (similar for all fields)
}
```

| Line(s) | Explanation |
|---------|------------|
| 4 | **`@Document(collection = "customer_details")`** — Maps to `customer_details` collection in MongoDB. This data comes from the insurer's master CSV (Customer_data.csv) |
| 6-7 | `@Id` on `id` — MongoDB's auto-generated `_id` field (ObjectId) |
| 8 | `customerId` — Integer ID from the insurer's system (e.g., `1001`) — NOT the UUID we generate |
| 9 | **`refCustItNum`** — PAN card number. This is matched against the "password" field during login |
| 10 | `refPhoneMobile` — Declared as `Object` (not String) because the CSV data sometimes stores phone as a number, sometimes as a string |
| 11 | `datBirthCust` — Date of birth stored as integer (YYYYMMDD format, e.g., `19950615`) |
| 12 | `custEmailID` — Customer's email address |
| 13 | **`customerFullName`** — Full name matched against the "Customer ID/User ID" field during login |
| 15-37 | Manual getters/setters — This class doesn't use Lombok `@Data`, so getters and setters are written manually |

**Why two collections?** 
- `customers` = self-registered users (via registration form)
- `customer_details` = insurer-provided master data (bulk imported from CSV). Login uses this collection to match Full Name + PAN.

---

### 5.3 CustomerStatus.java

```java
package com.mypolicy.customer.model;                              // 1

public enum CustomerStatus {                                       // 2
  ACTIVE, INACTIVE, SUSPENDED, DELETED                             // 3
}                                                                  // 4
```

| Line | Explanation |
|------|------------|
| 2 | **`enum`** — A fixed set of constants. A customer can only be in one of these 4 states |
| 3 | `ACTIVE` = normal user, `INACTIVE` = deactivated, `SUSPENDED` = temporarily blocked, `DELETED` = soft-deleted |

---

## 6. Repository Layer

Repositories are **interfaces** that Spring Data MongoDB automatically implements at runtime. You declare the method signature, and Spring generates the MongoDB query.

### 6.1 CustomerRepository.java

```java
package com.mypolicy.customer.repository;                         // 1

import com.mypolicy.customer.model.Customer;                      // 2
import org.springframework.data.mongodb.repository.MongoRepository; // 3

import java.util.Optional;                                         // 4

public interface CustomerRepository extends MongoRepository<Customer, String> { // 5
  Optional<Customer> findByEmail(String email);                    // 6
  Optional<Customer> findByMobileNumber(String mobileNumber);      // 7
  Optional<Customer> findByPanNumber(String panNumber);            // 8
  boolean existsByEmail(String email);                             // 9
  boolean existsByMobileNumber(String mobileNumber);               // 10
}
```

| Line | Explanation |
|------|------------|
| 5 | **`extends MongoRepository<Customer, String>`** — This gives us FREE built-in methods: |
|   | `save(customer)` — Insert or update a document |
|   | `findById(id)` — Find by `_id` field (customerId) |
|   | `findAll()` — Get all documents |
|   | `deleteById(id)` — Delete by ID |
|   | `count()` — Count all documents |
|   | `<Customer, String>` — First generic = entity type, Second = type of **@Id** field (String UUID) |
| 6 | **`findByEmail(String email)`** — Spring Data auto-generates: `db.customers.find({email: "..."})`  Returns `Optional<Customer>` — either the customer or empty (avoids null pointer) |
| 7 | `findByMobileNumber` — Same pattern: auto-generates `{mobileNumber: "..."}` query |
| 8 | `findByPanNumber` — Auto-generates `{panNumber: "..."}` query |
| 9 | **`existsByEmail`** — Returns `true`/`false`. Used during registration to check if email already taken. More efficient than `findByEmail` because it doesn't load the full document |
| 10 | `existsByMobileNumber` — Same, for mobile number duplicate check |

**How Spring Data naming works (Query Derivation)**:
```
findBy + FieldName → becomes → db.collection.find({fieldName: value})
existsBy + FieldName → becomes → db.collection.countDocuments({fieldName: value}) > 0
```

---

### 6.2 CustomerDetailsRepository.java

```java
package com.mypolicy.customer.repository;                         // 1

import com.mypolicy.customer.model.CustomerDetails;               // 2
import org.springframework.data.mongodb.repository.MongoRepository; // 3

import java.util.Optional;                                         // 4

public interface CustomerDetailsRepository extends MongoRepository<CustomerDetails, String> { // 5

    Optional<CustomerDetails> findFirstByCustomerFullNameIgnoreCaseAndRefCustItNum(  // 6
            String customerFullName, String refCustItNum);         // 7

    Optional<CustomerDetails> findFirstByCustomerId(Integer customerId); // 8
}
```

| Line | Explanation |
|------|------------|
| 5 | Extends `MongoRepository<CustomerDetails, String>` for the `customer_details` collection |
| 6-7 | **THE LOGIN QUERY** — This is the most important method. Let's break down the name: |
|   | `findFirst` — Return only the first matching document |
|   | `By` — Start of the query condition |
|   | `CustomerFullName` — Match the `customerFullName` field |
|   | `IgnoreCase` — Case-insensitive match (so "rahul sharma" matches "Rahul Sharma") |
|   | `And` — Logical AND |
|   | `RefCustItNum` — Also match the `refCustItNum` field (PAN number) |
|   | **Generated MongoDB query**: `db.customer_details.findOne({customerFullName: /^rahul sharma$/i, refCustItNum: "ABCDE1234F"})` |
| 8 | `findFirstByCustomerId(Integer)` — Used by BFF to get customer profile after login. Queries by the integer `customerId` field (not the string `_id`) |

---

## 7. DTO Layer

DTOs (Data Transfer Objects) are plain Java classes used to **shape the data** flowing in and out of the API. They separate the API contract from the database model.

### 7.1 LoginRequest.java

```java
package com.mypolicy.customer.dto;                                // 1

import jakarta.validation.constraints.NotBlank;                    // 2
import lombok.Data;                                                // 3

@Data                                                              // 4
public class LoginRequest {                                        // 5
  @NotBlank(message = "Customer ID / User ID (full name) is required") // 6
  private String customerIdOrUserId;                               // 7

  @NotBlank(message = "Password (PAN) is required")                // 8
  private String password;                                         // 9
}                                                                  // 10
```

| Line | Explanation |
|------|------------|
| 2 | `jakarta.validation.constraints.NotBlank` — Jakarta Bean Validation constraint (Note: `jakarta` not `javax` because we're on Spring Boot 3.x) |
| 4 | `@Data` — Lombok generates getters/setters for `customerIdOrUserId` and `password` |
| 6-7 | **`@NotBlank`** on `customerIdOrUserId` — If this field is null or empty string, the request is rejected with 400 Bad Request + the message. This field holds the customer's **full name** (e.g., "Rahul Sharma") |
| 8-9 | `@NotBlank` on `password` — This field holds the customer's **PAN number** (e.g., "ABCDE1234F"). It's called "password" because the frontend sends it as the password field |

**Example JSON request**:
```json
{
  "customerIdOrUserId": "Rahul Sharma",
  "password": "ABCDE1234F"
}
```

---

### 7.2 AuthResponse.java

```java
package com.mypolicy.customer.dto;                                // 1

import lombok.AllArgsConstructor;                                  // 2
import lombok.Builder;                                             // 3
import lombok.Data;                                                // 4
import lombok.NoArgsConstructor;                                   // 5

@Data                                                              // 6
@Builder                                                           // 7
@AllArgsConstructor                                                // 8
@NoArgsConstructor                                                 // 9
public class AuthResponse {                                        // 10
  private String token;                                            // 11
  private CustomerResponse customer;                               // 12
}                                                                  // 13
```

| Line | Explanation |
|------|------------|
| 6-9 | Lombok annotations — generates getters, setters, builder, and constructors |
| 11 | `token` — The JWT string returned to the client after successful login (e.g., `"eyJhbGciOiJIUzI1NiJ9..."`) |
| 12 | `customer` — The customer's profile data (nested object) |

**Example JSON response**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "customer": {
    "customerId": "1001",
    "firstName": "Rahul Sharma",
    "email": "rahul@example.com",
    "status": "ACTIVE"
  }
}
```

---

### 7.3 CustomerRegistrationRequest.java

```java
@Data                                                              // 1
public class CustomerRegistrationRequest {                         // 2
  @NotBlank(message = "First name is required")                    // 3
  private String firstName;                                        // 4

  @NotBlank(message = "Last name is required")                     // 5
  private String lastName;                                         // 6

  @NotBlank(message = "Email is required")                         // 7
  @Email(message = "Invalid email format")                         // 8
  private String email;                                            // 9

  @NotBlank(message = "Mobile number is required")                 // 10
  private String mobileNumber;                                     // 11

  @NotBlank(message = "Password is required")                      // 12
  private String password;                                         // 13

  private String panNumber;                                        // 14
  private LocalDate dateOfBirth;                                   // 15

  private String permanentAddressLine1;                            // 16
  private String permanentAddressLine2;                            // 17
  private String permanentAddressLine3;                            // 18
  private String permanentAddressCity;                              // 19
  private String permanentAddressZip;                               // 20
  private String customerAddressZip;                                // 21
  private String address;                                          // 22
}                                                                  // 23
```

| Line | Explanation |
|------|------------|
| 3-4 | First name is **required** — `@NotBlank` rejects null, empty, and whitespace-only strings |
| 7-9 | Email must be present AND valid format — `@Email` validates format like `x@y.z` |
| 12-13 | Password is required — will be BCrypt-hashed before storage |
| 14-15 | `panNumber` and `dateOfBirth` are **optional** (no `@NotBlank`) |
| 16-22 | Address fields — all optional, used when importing from CSV |

---

### 7.4 CustomerResponse.java

```java
@Data                                                              // 1
@Builder                                                           // 2
public class CustomerResponse {                                    // 3
  private String customerId;                                       // 4
  private String firstName;                                        // 5
  private String lastName;                                         // 6
  private String email;                                            // 7
  private String mobileNumber;                                     // 8
  private String panNumber;                                        // 9
  private LocalDate dateOfBirth;                                   // 10
  private String permanentAddressLine1;                            // 11
  // ... more address fields ...
  private String address;                                          // 12
  private CustomerStatus status;                                   // 13
}                                                                  // 14
```

| Line | Explanation |
|------|------------|
| 2 | `@Builder` — so we can create responses like `CustomerResponse.builder().customerId("...").firstName("...").build()` |
| 3-13 | Contains **only the fields safe to return** to the client. Notice: **NO `passwordHash` field** — the password is never sent back to the client |
| 13 | `status` — Returns the customer's account status (ACTIVE/INACTIVE/SUSPENDED/DELETED) |

---

### 7.5 CustomerUpdateRequest.java

```java
@Data                                                              // 1
@NoArgsConstructor                                                 // 2
@AllArgsConstructor                                                // 3
public class CustomerUpdateRequest {                               // 4
  private String firstName;                                        // 5
  private String lastName;                                         // 6

  @Email(message = "Invalid email format")                         // 7
  private String email;                                            // 8

  @Pattern(regexp = "^[0-9]{10}$", message = "Mobile number must be 10 digits") // 9
  private String mobileNumber;                                     // 10

  @Pattern(regexp = "^[A-Z]{5}[0-9]{4}[A-Z]{1}$", message = "Invalid PAN format") // 11
  private String panNumber;                                        // 12

  private String dateOfBirth;                                      // 13
  // ... address fields ...
  private String address;                                          // 14
}                                                                  // 15
```

| Line | Explanation |
|------|------------|
| 5-6 | All fields are **optional** (no `@NotBlank`) — this supports **partial updates** (only update the fields you send) |
| 7-8 | `@Email` — If email is provided, it must be valid format |
| 9-10 | **`@Pattern`** — If mobile is provided, it must be exactly 10 digits. `^[0-9]{10}$` means: start (`^`) + exactly 10 digits (`[0-9]{10}`) + end (`$`) |
| 11-12 | **`@Pattern`** for PAN — Must be 5 uppercase letters + 4 digits + 1 uppercase letter (e.g., `ABCDE1234F`) |
| 13 | `dateOfBirth` is String here (not LocalDate) — will be parsed in the service layer using `LocalDate.parse()` |

---

### 7.6 CustomerCsvImportRequest.java

```java
@Data                                                              // 1
@NoArgsConstructor                                                 // 2
public class CustomerCsvImportRequest {                            // 3

  @CsvBindByName(column = "customerId")                            // 4
  private String customerId;                                       // 5

  @CsvBindByName(column = "customerFullName")                      // 6
  private String customerFullName;                                 // 7

  @CsvBindByName(column = "refPhoneMobile")                        // 8
  private String refPhoneMobile;                                   // 9

  @CsvBindByName(column = "datBirthCust")                          // 10
  private String datBirthCust;                                     // 11

  @CsvBindByName(column = "custEmailID")                           // 12
  private String custEmailID;                                      // 13

  @CsvBindByName(column = "refCustItNum")                          // 14
  private String refCustItNum;                                     // 15

  @CsvBindByName(column = "txtPermadrAdd1")                        // 16
  private String txtPermadrAdd1;                                   // 17
  // ... more CSV columns ...

  public CustomerRegistrationRequest toCustomerRegistrationRequest() { // 18
    CustomerRegistrationRequest request = new CustomerRegistrationRequest(); // 19

    String[] nameParts = customerFullName.split(" ", 2);           // 20
    request.setFirstName(nameParts[0]);                            // 21
    request.setLastName(nameParts.length > 1 ? nameParts[1] : ""); // 22

    request.setEmail(custEmailID);                                 // 23
    request.setMobileNumber(refPhoneMobile);                       // 24
    request.setPanNumber(refCustItNum);                             // 25

    try {                                                          // 26
      if (datBirthCust != null && !datBirthCust.isEmpty()) {       // 27
        LocalDate dob = LocalDate.parse(dateStr,                   // 28
            DateTimeFormatter.ofPattern("yyyyMMdd"));              // 29
        request.setDateOfBirth(dob);                               // 30
      }                                                            // 31
    } catch (Exception e) { /* skip invalid dates */ }             // 32

    request.setPassword("DefaultPassword@123");                    // 33
    return request;                                                // 34
  }                                                                // 35
}
```

| Line | Explanation |
|------|------------|
| 4-5 | **`@CsvBindByName(column = "customerId")`** — OpenCSV annotation. Maps the CSV column header `"customerId"` to this field. When OpenCSV reads the CSV, it finds the column by name and puts the value here |
| 14-15 | `refCustItNum` — Maps to the PAN card column in the CSV |
| 18 | **`toCustomerRegistrationRequest()`** — Converts a CSV row into a registration request object |
| 20-22 | **Name splitting** — `"Rahul Sharma".split(" ", 2)` → `["Rahul", "Sharma"]`. The `2` limits to max 2 parts so middle names stay with last name |
| 28-29 | **Date parsing** — CSV stores DOB as `"19950615"` (YYYYMMDD). `DateTimeFormatter.ofPattern("yyyyMMdd")` parses it to `LocalDate 1995-06-15` |
| 33 | Default password — CSV-imported customers get a default password. They should change it on first login |

---

## 8. Service Layer

The service layer contains the **business logic**. Controllers delegate all work to service methods.

### 8.1 CustomerService.java (Interface)

```java
public interface CustomerService {                                 // 1
  CustomerResponse registerCustomer(CustomerRegistrationRequest request); // 2
  AuthResponse login(LoginRequest request);                        // 3
  CustomerResponse getCustomerById(String customerId);             // 4
  CustomerResponse updateCustomer(String customerId, CustomerUpdateRequest request); // 5
  Optional<CustomerResponse> searchByMobile(String mobile);        // 6
  Optional<CustomerResponse> searchByEmail(String email);          // 7
  Optional<CustomerResponse> searchByPan(String pan);              // 8
  Optional<CustomerResponse> getCustomerDetailsByIntegerId(Integer customerId); // 9
}
```

| Line | Explanation |
|------|------------|
| 1 | **Interface** — Defines the **contract** (what methods exist) without implementation. This follows the **Dependency Inversion Principle** — the controller depends on the interface, not the implementation |
| 2 | `registerCustomer` — Takes registration data, returns customer response |
| 3 | `login` — Takes name+PAN, returns JWT token + customer details |
| 6-8 | `searchBy*` returns `Optional` — could be empty if not found (no exception thrown) |
| 9 | `getCustomerDetailsByIntegerId` — Gets customer from the `customer_details` collection by integer ID |

**Why use an interface?** — If we ever need a different implementation (mock for testing, different database), we can swap it without changing the controller code.

---

### 8.2 CustomerServiceImpl.java (Implementation) — THE CORE

```java
package com.mypolicy.customer.service.impl;                       // 1

import com.mypolicy.customer.dto.*;                                // 2
import com.mypolicy.customer.exception.*;                          // 3
import com.mypolicy.customer.model.*;                              // 4
import com.mypolicy.customer.repository.CustomerRepository;        // 5
import com.mypolicy.customer.service.CustomerService;              // 6
import lombok.RequiredArgsConstructor;                             // 7
import org.springframework.stereotype.Service;                     // 8
import org.springframework.transaction.annotation.Transactional;   // 9

import java.time.LocalDate;                                        // 10
import java.util.Optional;                                         // 11

@Service                                                           // 12
@RequiredArgsConstructor                                           // 13
public class CustomerServiceImpl implements CustomerService {      // 14

  private final CustomerRepository customerRepository;             // 15
  private final com.mypolicy.customer.repository.CustomerDetailsRepository customerDetailsRepository; // 16
  private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder; // 17
  private final com.mypolicy.customer.security.JwtService jwtService; // 18
```

| Line | Explanation |
|------|------------|
| 12 | **`@Service`** — Tells Spring: "This class is a service bean. Register it in the application context." Spring will create ONE instance (singleton) and inject it wherever needed |
| 13 | **`@RequiredArgsConstructor`** — Lombok: generates a constructor with all `final` fields as parameters. Spring uses this constructor for **dependency injection** |
| 14 | `implements CustomerService` — This class provides the actual implementation for the interface |
| 15 | **`private final CustomerRepository`** — `final` + `@RequiredArgsConstructor` = Spring injects the repository bean via constructor injection |
| 16 | **`customerDetailsRepository`** — For querying the `customer_details` collection (login) |
| 17 | **`passwordEncoder`** — BCryptPasswordEncoder bean provided by Spring Security auto-config. Used to hash passwords |
| 18 | **`jwtService`** — Our custom JWT utility for generating tokens |

#### registerCustomer() Method

```java
  @Override                                                        // 19
  @Transactional                                                   // 20
  public CustomerResponse registerCustomer(CustomerRegistrationRequest request) { // 21
    if (customerRepository.existsByEmail(request.getEmail())) {    // 22
      throw new DuplicateCustomerException("Email", request.getEmail()); // 23
    }                                                              // 24
    if (customerRepository.existsByMobileNumber(request.getMobileNumber())) { // 25
      throw new DuplicateCustomerException("Mobile number", request.getMobileNumber()); // 26
    }                                                              // 27

    Customer customer = new Customer();                            // 28
    customer.setCustomerId(java.util.UUID.randomUUID().toString()); // 29
    customer.setFirstName(request.getFirstName());                 // 30
    customer.setLastName(request.getLastName());                   // 31
    customer.setEmail(request.getEmail());                         // 32
    customer.setMobileNumber(request.getMobileNumber());           // 33
    customer.setPasswordHash(passwordEncoder.encode(request.getPassword())); // 34
    customer.setPanNumber(request.getPanNumber());                 // 35
    customer.setDateOfBirth(request.getDateOfBirth());             // 36
    customer.setAddress(request.getAddress());                     // 37
    customer.setStatus(CustomerStatus.ACTIVE);                     // 38

    Customer saved = customerRepository.save(customer);            // 39
    return mapToResponse(saved);                                   // 40
  }
```

| Line | Explanation |
|------|------------|
| 19 | `@Override` — Compiler check: ensures this method signature matches the interface |
| 20 | **`@Transactional`** — If any exception occurs during this method, all database changes are **rolled back**. Ensures data consistency |
| 22-24 | **Duplicate email check** — `existsByEmail()` runs count query. If true, throws `DuplicateCustomerException` which returns HTTP 409 Conflict |
| 25-27 | **Duplicate mobile check** — Same pattern for mobile number |
| 29 | **UUID generation** — `UUID.randomUUID().toString()` creates a unique ID like `"a7b3c1d4-e5f6-..."`. This becomes the `_id` in MongoDB |
| 34 | **`passwordEncoder.encode()`** — BCrypt hashes the password. `"MyPass123"` → `"$2a$10$xJHr..."`. One-way hashing — cannot be reversed. Same input produces different hash each time (uses random salt) | 
| 39 | **`customerRepository.save(customer)`** — Inserts the document into MongoDB `customers` collection. Returns the saved document (with server-generated fields set) |
| 40 | **`mapToResponse(saved)`** — Converts the `Customer` entity to `CustomerResponse` DTO (strips out `passwordHash` so it's not sent to the client) |m        

#### login() Method

```java
  @Override                                                        // 41
  public com.mypolicy.customer.dto.AuthResponse login(LoginRequest request) { // 42
    String fullName = request.getCustomerIdOrUserId() != null      // 43
        ? request.getCustomerIdOrUserId().trim() : "";             // 44
    String pan = request.getPassword() != null                     // 45
        ? request.getPassword().trim() : "";                       // 46

    com.mypolicy.customer.model.CustomerDetails customerDetails =  // 47
        customerDetailsRepository                                  // 48
            .findFirstByCustomerFullNameIgnoreCaseAndRefCustItNum(fullName, pan) // 49
            .orElseThrow(() -> new InvalidCredentialsException()); // 50

    String token = jwtService.generateToken(                       // 51
        customerDetails.getCustomerFullName());                    // 52
    CustomerResponse response = mapCustomerDetailsToResponse(customerDetails); // 53
    return new com.mypolicy.customer.dto.AuthResponse(token, response); // 54
  }
```

| Line | Explanation |
|------|------------|
| 43-44 | **Extract & trim full name** — Gets the `customerIdOrUserId` field (which is the customer's full name like "Rahul Sharma"). `.trim()` removes leading/trailing whitespace |
| 45-46 | **Extract & trim PAN** — Gets the `password` field (which is actually the PAN number like "ABCDE1234F") |
| 47-50 | **THE AUTHENTICATION QUERY** — Searches `customer_details` collection for a document where `customerFullName` matches (case-insensitive) AND `refCustItNum` (PAN) matches exactly. If no match → throws `InvalidCredentialsException` → returns HTTP 401 |
| 51-52 | **Generate JWT** — Creates a JWT token with the customer's full name as the `subject`. The token is signed with HS256 and valid for 24 hours |
| 53 | **Map to response** — Converts the `CustomerDetails` entity to `CustomerResponse` DTO |
| 54 | **Return** — Wraps the JWT token + customer data in `AuthResponse` and sends it back |

#### updateCustomer() Method

```java
  @Override                                                        // 55
  @Transactional                                                   // 56
  public CustomerResponse updateCustomer(String customerId, CustomerUpdateRequest request) { // 57
    Customer customer = customerRepository.findById(customerId)    // 58
        .orElseThrow(() -> new CustomerNotFoundException(customerId, "id")); // 59

    if (request.getFirstName() != null && !request.getFirstName().isEmpty()) { // 60
      customer.setFirstName(request.getFirstName());               // 61
    }                                                              // 62

    if (request.getEmail() != null && !request.getEmail().isEmpty()) { // 63
      customerRepository.findByEmail(request.getEmail()).ifPresent(existing -> { // 64
        if (!existing.getCustomerId().equals(customerId)) {        // 65
          throw new DuplicateCustomerException("Email", request.getEmail()); // 66
        }                                                          // 67
      });                                                          // 68
      customer.setEmail(request.getEmail());                       // 69
    }                                                              // 70
    // ... similar blocks for lastName, mobileNumber, panNumber, dateOfBirth, address

    Customer updated = customerRepository.save(customer);          // 71
    return mapToResponse(updated);                                 // 72
  }
```

| Line | Explanation |
|------|------------|
| 58-59 | **Find existing customer** — Looks up by ID. If not found → 404 error |
| 60-62 | **Partial update pattern** — Only updates `firstName` if it's non-null and non-empty. Fields not sent in the request body remain unchanged |
| 63-70 | **Email update with duplicate check** — If email is being changed, first check if the new email is already used by a DIFFERENT customer (line 65: `!existing.getCustomerId().equals(customerId)` allows the customer to "update" to their own current email) |
| 71 | **`save(customer)`** — MongoDB upsert: since `customerId` (the `_id`) already exists, this **updates** the document instead of inserting a new one |

#### Search Methods

```java
  @Override
  public Optional<CustomerResponse> searchByMobile(String mobile) { // 73
    return customerRepository.findByMobileNumber(mobile)           // 74
        .map(this::mapToResponse);                                 // 75
  }

  @Override
  public Optional<CustomerResponse> searchByEmail(String email) {  // 76
    return customerRepository.findByEmail(email)                   // 77
        .map(this::mapToResponse);                                 // 78
  }

  @Override
  public Optional<CustomerResponse> searchByPan(String pan) {      // 79
    return customerRepository.findByPanNumber(pan)                 // 80
        .map(this::mapToResponse);                                 // 81
  }

  @Override
  public Optional<CustomerResponse> getCustomerDetailsByIntegerId(Integer customerId) { // 82
    return customerDetailsRepository.findFirstByCustomerId(customerId) // 83
        .map(this::mapCustomerDetailsToResponse);                  // 84
  }
```

| Line | Explanation |
|------|------------|
| 74-75 | Queries MongoDB for mobile number. `.map(this::mapToResponse)` — if found, converts entity to DTO. If not found, returns `Optional.empty()` |
| 76-81 | Same pattern for email and PAN searches |
| 82-84 | Searches `customer_details` collection by integer customerId. Used by BFF to get profile for logged-in users |

#### Mapper Methods

```java
  private CustomerResponse mapToResponse(Customer c) {             // 85
    return CustomerResponse.builder()                              // 86
        .customerId(c.getCustomerId())                             // 87
        .firstName(c.getFirstName())                               // 88
        .lastName(c.getLastName())                                 // 89
        .email(c.getEmail())                                       // 90
        .mobileNumber(c.getMobileNumber())                         // 91
        .status(c.getStatus())                                     // 92
        .panNumber(c.getPanNumber())                               // 93
        .dateOfBirth(c.getDateOfBirth())                           // 94
        .address(c.getAddress())                                   // 95
        .build();                                                  // 96
  }

  private CustomerResponse mapCustomerDetailsToResponse(CustomerDetails cd) { // 97
    String customerIdStr = cd.getCustomerId() != null              // 98
        ? String.valueOf(cd.getCustomerId()) : "";                 // 99
    String mobile = cd.getRefPhoneMobile() != null                 // 100
        ? cd.getRefPhoneMobile().toString() : null;                // 101
    return CustomerResponse.builder()                              // 102
        .customerId(customerIdStr)                                 // 103
        .firstName(cd.getCustomerFullName())                       // 104
        .lastName("")                                              // 105
        .email(cd.getCustEmailID())                                // 106
        .mobileNumber(mobile)                                      // 107
        .status(CustomerStatus.ACTIVE)                             // 108
        .panNumber(null)   // Do not expose PAN in response        // 109
        .dateOfBirth(null)                                         // 110
        .address(null)                                             // 111
        .build();                                                  // 112
  }
```

| Line | Explanation |
|------|------------|
| 85-96 | **`mapToResponse`** — Converts `Customer` entity to `CustomerResponse` DTO. Uses builder pattern for clean object creation. Notice `passwordHash` is **never** copied to the response |
| 97-112 | **`mapCustomerDetailsToResponse`** — Maps `CustomerDetails` (insurer data) to the same DTO. The `customerFullName` goes into `firstName`, `lastName` is empty string, and **PAN is set to null** for security (lines 109-110) |
| 98-99 | Converts Integer customerId to String (since `CustomerResponse.customerId` is String type) |
| 100-101 | Safely converts `Object refPhoneMobile` to String. Uses `Object` because the CSV data is inconsistent |

---

### 8.3 CsvImportService.java

Handles **bulk import** of customers from a CSV file.

```java
@Service                                                           // 1
@RequiredArgsConstructor                                           // 2
@Slf4j                                                             // 3
public class CsvImportService {                                    // 4

  private final CustomerRepository customerRepository;             // 5
  private final PasswordEncoder passwordEncoder;                   // 6

  @Transactional                                                   // 7
  public ImportResult importCustomersFromCsv(MultipartFile file) { // 8
    ImportResult result = new ImportResult();                       // 9

    if (file.isEmpty()) {                                          // 10
      result.setSuccess(false);                                    // 11
      result.setErrorMessage("File is empty");                     // 12
      return result;                                               // 13
    }

    try {                                                          // 14
      InputStreamReader reader = new InputStreamReader(file.getInputStream()); // 15

      List<CustomerCsvImportRequest> csvRecords =                  // 16
          new CsvToBeanBuilder<CustomerCsvImportRequest>(reader)   // 17
              .withType(CustomerCsvImportRequest.class)            // 18
              .withIgnoreLeadingWhiteSpace(true)                   // 19
              .build()                                             // 20
              .parse();                                            // 21

      log.info("Parsed {} records from CSV", csvRecords.size());   // 22

      int successCount = 0;                                        // 23
      int failCount = 0;                                           // 24

      for (int i = 0; i < csvRecords.size(); i++) {                // 25
        try {                                                      // 26
          CustomerCsvImportRequest csvRecord = csvRecords.get(i);  // 27

          if (customerRepository.findByEmail(csvRecord.getCustEmailID()).isPresent()) { // 28
            log.warn("Customer with email {} already exists, skipping row {}", // 29
                csvRecord.getCustEmailID(), i + 2);                // 30
            failCount++;                                           // 31
            result.getSkippedEmails().add(csvRecord.getCustEmailID()); // 32
            continue;                                              // 33
          }

          CustomerRegistrationRequest registrationRequest =        // 34
              csvRecord.toCustomerRegistrationRequest();            // 35

          Customer customer = Customer.builder()                   // 36
              .customerId(java.util.UUID.randomUUID().toString())  // 37
              .firstName(registrationRequest.getFirstName())       // 38
              .lastName(registrationRequest.getLastName())         // 39
              .email(registrationRequest.getEmail())               // 40
              .mobileNumber(registrationRequest.getMobileNumber()) // 41
              .panNumber(registrationRequest.getPanNumber())       // 42
              .dateOfBirth(registrationRequest.getDateOfBirth())   // 43
              .passwordHash(passwordEncoder.encode(registrationRequest.getPassword())) // 44
              .permanentAddressLine1(registrationRequest.getPermanentAddressLine1()) // 45
              // ... more address fields ...
              .status(CustomerStatus.ACTIVE)                       // 46
              .build();                                            // 47

          customerRepository.save(customer);                       // 48
          successCount++;                                          // 49
          result.getImportedEmails().add(customer.getEmail());     // 50

        } catch (Exception e) {                                    // 51
          failCount++;                                             // 52
          result.getFailedRows().add("Row " + (i + 2) + ": " + e.getMessage()); // 53
        }
      }

      result.setSuccess(true);                                     // 54
      result.setTotalRecords(csvRecords.size());                   // 55
      result.setSuccessCount(successCount);                        // 56
      result.setFailCount(failCount);                              // 57
    } catch (Exception e) {                                        // 58
      result.setSuccess(false);                                    // 59
      result.setErrorMessage("Error processing CSV file: " + e.getMessage()); // 60
    }

    return result;                                                 // 61
  }
```

| Line | Explanation |
|------|------------|
| 3 | **`@Slf4j`** — Lombok: auto-creates a `log` variable. You can use `log.info(...)`, `log.warn(...)`, `log.error(...)` without declaring a Logger |
| 15 | **`file.getInputStream()`** — `MultipartFile` is Spring's wrapper for uploaded files. `getInputStream()` gives us direct access to the file bytes |
| 17-21 | **OpenCSV parsing** — `CsvToBeanBuilder` reads the CSV stream and maps each row to a `CustomerCsvImportRequest` object. Line 18: `.withType(...)` tells it which class to map to. Line 19: trims leading whitespace. Line 21: `.parse()` reads ALL rows and returns a List |
| 22 | Logs how many rows were parsed (e.g., "Parsed 150 records from CSV") |
| 25-53 | **Row-by-row processing loop** — Each row is processed individually so one bad row doesn't kill the whole import |
| 28-33 | **Duplicate check** — Skips rows where the email already exists. `continue` skips to the next row |
| 30 | `i + 2` — CSV row 1 is headers, row 2 is first data row, but `i` is 0-indexed, so we add 2 for human-readable row numbers |
| 34-35 | Converts the CSV row object to a standard registration request |
| 36-47 | Uses **Builder pattern** to create a `Customer` entity from the registration request |
| 44 | **BCrypt hashing** — `passwordEncoder.encode("DefaultPassword@123")` creates a unique hash each time |
| 51-53 | Error in a single row is caught silently — the loop continues with the next row |

---

## 9. Security Layer

### 9.1 JwtService.java

Handles **creating** and **validating** JSON Web Tokens.

```java
@Service                                                           // 1
public class JwtService {                                          // 2

  @Value("${jwt.secret:404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970}") // 3
  private String secretKey;                                        // 4

  @Value("${jwt.expiration:86400000}")                             // 5
  private long jwtExpiration;                                       // 6
```

| Line | Explanation |
|------|------------|
| 3-4 | **`@Value`** — Injects property from `application.yaml`. The `:` after `jwt.secret` provides a **default value** if the property is not set. The long hex string is a 256-bit (32-byte) secret key for HS256 signing |
| 5-6 | `86400000` milliseconds = **24 hours**. This is how long the JWT token is valid |

```java
  public String extractUsername(String token) {                    // 7
    return extractClaim(token, Claims::getSubject);                // 8
  }

  public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) { // 9
    final Claims claims = extractAllClaims(token);                 // 10
    return claimsResolver.apply(claims);                           // 11
  }
```

| Line | Explanation |
|------|------------|
| 7-8 | **`extractUsername`** — Gets the "subject" from the JWT. The subject is the customer's full name (set during `generateToken`) |
| 9-11 | **Generic claim extractor** — Takes any function that extracts data from Claims. `Claims::getSubject` extracts the subject. `Claims::getExpiration` would extract the expiration date. The `<T>` generic means it can return any type |

```java
  public String generateToken(String username) {                   // 12
    return generateToken(new HashMap<>(), username);               // 13
  }

  public String generateToken(Map<String, Object> extraClaims, String username) { // 14
    return Jwts.builder()                                          // 15
        .setClaims(extraClaims)                                    // 16
        .setSubject(username)                                      // 17
        .setIssuedAt(new Date(System.currentTimeMillis()))         // 18
        .setExpiration(new Date(System.currentTimeMillis() + jwtExpiration)) // 19
        .signWith(getSignInKey(), SignatureAlgorithm.HS256)        // 20
        .compact();                                                // 21
  }
```

| Line | Explanation |
|------|------------|
| 12-13 | **Overloaded method** — Simple version takes just username. Calls the detailed version with no extra claims |
| 15 | `Jwts.builder()` — Creates a JWT builder (from JJWT library) |
| 16 | `setClaims(extraClaims)` — Adds custom key-value pairs to the JWT (currently empty HashMap) |
| 17 | **`setSubject(username)`** — Sets the "sub" claim = customer's full name. This is the main identity stored in the token |
| 18 | `setIssuedAt(...)` — Sets "iat" claim = current timestamp. Shows when the token was created |
| 19 | **`setExpiration(...)`** — Sets "exp" claim = current time + 86400000ms (24 hours). After this time, the token is rejected |
| 20 | **`signWith(key, HS256)`** — Signs the token with our secret key using HMAC-SHA256 algorithm. This signature prevents tampering — if anyone changes the token content, the signature won't match |
| 21 | `.compact()` — Serializes to the final string: `"eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJSYWh1bCBTaGFybWE..."` |

**A JWT has 3 parts** (separated by dots):
```
Header.Payload.Signature
eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJSYWh1bCBTaGFybWEiLCJpYXQiOjE3...}.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

```java
  public boolean isTokenValid(String token, String username) {     // 22
    final String extractedUsername = extractUsername(token);        // 23
    return (extractedUsername.equals(username)) && !isTokenExpired(token); // 24
  }

  private boolean isTokenExpired(String token) {                   // 25
    return extractExpiration(token).before(new Date());            // 26
  }
```

| Line | Explanation |
|------|------------|
| 22-24 | **Token validation** — Two checks: (1) username in token matches expected username, (2) token hasn't expired |
| 25-26 | **Expiration check** — Extracts the `exp` date from claims and checks if it's before now |

```java
  private Claims extractAllClaims(String token) {                  // 27
    return Jwts.parserBuilder()                                    // 28
        .setSigningKey(getSignInKey())                             // 29
        .build()                                                   // 30
        .parseClaimsJws(token)                                     // 31
        .getBody();                                                // 32
  }

  private Key getSignInKey() {                                     // 33
    return Keys.hmacShaKeyFor(                                     // 34
        io.jsonwebtoken.io.Decoders.BASE64.decode(secretKey));     // 35
  }
```

| Line | Explanation |
|------|------------|
| 28-32 | **Parse JWT** — Creates a parser with our signing key, parses the token string, verifies the signature, and returns the payload (claims). If the token is tampered with, `parseClaimsJws` throws an exception |
| 33-35 | **Convert secret to Key** — Decodes the Base64 secret string into bytes, then creates an HMAC-SHA key object that Java's crypto library can use |

---

### 9.2 JwtAuthenticationFilter.java

This is a **servlet filter** that intercepts EVERY HTTP request and validates the JWT token.

```java
@Component                                                         // 1
@RequiredArgsConstructor                                           // 2
public class JwtAuthenticationFilter extends OncePerRequestFilter { // 3

  private final JwtService jwtService;                             // 4
  private final UserDetailsService userDetailsService;             // 5

  @Override
  protected boolean shouldNotFilter(HttpServletRequest request) {  // 6
    String path = request.getRequestURI();                         // 7
    return path != null && path.startsWith("/api/v1/customers/details/"); // 8
  }
```

| Line | Explanation |
|------|------------|
| 1 | `@Component` — Registers as a Spring bean, auto-detected by Spring Security |
| 3 | **`extends OncePerRequestFilter`** — Spring guarantees this filter runs exactly ONCE per request (even with request forwarding) |
| 6-8 | **`shouldNotFilter`** — Requests to `/api/v1/customers/details/*` **skip** JWT validation. This is because the BFF calls this endpoint internally (service-to-service) and may not have a user JWT |

```java
  @Override
  protected void doFilterInternal(HttpServletRequest request,      // 9
      HttpServletResponse response, FilterChain filterChain)       // 10
      throws ServletException, IOException {                       // 11

    final String authHeader = request.getHeader("Authorization");  // 12
    final String jwt;                                              // 13
    final String username;                                         // 14

    if (authHeader == null || !authHeader.startsWith("Bearer ")) { // 15
      filterChain.doFilter(request, response);                     // 16
      return;                                                      // 17
    }

    jwt = authHeader.substring(7);                                 // 18
```

| Line | Explanation |
|------|------------|
| 9-11 | **`doFilterInternal`** — The main method. Called for every incoming request |
| 12 | Gets the `Authorization` header value (e.g., `"Bearer eyJhbGci..."`) |
| 15-17 | **No token?** — If header is missing or doesn't start with "Bearer ", skip authentication and continue to the next filter. The request continues as **unauthenticated** (public endpoints like /login and /register still work) |
| 18 | **Extract token** — `"Bearer eyJhbGci...".substring(7)` → `"eyJhbGci..."`. Removes the "Bearer " prefix (7 characters) |

```java
    try {                                                          // 19
      username = jwtService.extractUsername(jwt);                   // 20

      if (username != null &&                                      // 21
          SecurityContextHolder.getContext().getAuthentication() == null) { // 22

        UserDetails userDetails = this.userDetailsService          // 23
            .loadUserByUsername(username);                          // 24

        if (jwtService.isTokenValid(jwt, userDetails.getUsername())) { // 25

          UsernamePasswordAuthenticationToken authToken =           // 26
              new UsernamePasswordAuthenticationToken(              // 27
                  userDetails, null, userDetails.getAuthorities()); // 28

          authToken.setDetails(                                    // 29
              new WebAuthenticationDetailsSource()                  // 30
                  .buildDetails(request));                          // 31

          SecurityContextHolder.getContext()                        // 32
              .setAuthentication(authToken);                        // 33
        }
      }
    } catch (Exception e) {                                        // 34
      logger.warn("JWT validation failed: " + e.getMessage());     // 35
    }

    filterChain.doFilter(request, response);                       // 36
  }
```

| Line | Explanation |
|------|------------|
| 20 | **Extract username from JWT** — Parses the token and gets the "sub" claim (customer's full name) |
| 21-22 | **Guard clause** — Only authenticate if: (1) username exists in token, (2) no authentication is already set in the current request's security context |
| 23-24 | **Load user from database** — Calls `CustomUserDetailsService.loadUserByUsername()` to verify the user exists in the database |
| 25 | **Validate token** — Checks: is the username correct? Is the token not expired? |
| 26-28 | **Create authentication object** — `UsernamePasswordAuthenticationToken` is Spring Security's representation of an authenticated user. Parameters: (principal=userDetails, credentials=null, authorities=roles) |
| 29-31 | **Attach request details** — Adds IP address and session info to the authentication object (used for audit logging) |
| 32-33 | **SET SECURITY CONTEXT** — This is the critical line. After this, Spring Security considers this request as **authenticated**. All `@PreAuthorize` checks and controller access will pass for this request |
| 34-35 | If JWT parsing fails (expired, invalid signature, malformed), catch the exception, log a warning, and continue WITHOUT setting authentication (request is treated as unauthenticated) |
| 36 | **Continue the filter chain** — Pass the request to the next filter and eventually to the controller |

---

### 9.3 CustomUserDetailsService.java

Required by Spring Security to load user data from the database.

```java
@Service                                                           // 1
@RequiredArgsConstructor                                           // 2
public class CustomUserDetailsService implements UserDetailsService { // 3

  private final CustomerRepository customerRepository;             // 4

  @Override
  public UserDetails loadUserByUsername(String email)              // 5
      throws UsernameNotFoundException {                           // 6
    Customer customer = customerRepository.findByEmail(email)      // 7
        .orElseThrow(() -> new UsernameNotFoundException(          // 8
            "Customer not found with email: " + email));           // 9

    return User.builder()                                          // 10
        .username(customer.getEmail())                             // 11
        .password(customer.getPasswordHash())                      // 12
        .authorities(new ArrayList<>())                            // 13
        .accountExpired(false)                                     // 14
        .accountLocked(false)                                      // 15
        .credentialsExpired(false)                                 // 16
        .disabled(false)                                           // 17
        .build();                                                  // 18
  }
}
```

| Line | Explanation |
|------|------------|
| 3 | **`implements UserDetailsService`** — This is a Spring Security interface. Spring uses this to load user details during authentication |
| 5 | `loadUserByUsername` — Spring Security calls this method whenever it needs to look up a user. Despite the name "username", we pass an email |
| 7-9 | Queries MongoDB `customers` collection by email. Throws `UsernameNotFoundException` if not found |
| 10-18 | **Creates a Spring Security `User` object** — This is what Spring Security uses internally. It wraps: username (email), password hash (for password matching), authorities (empty list = no roles defined yet), and account status flags |

---

## 10. Controller Layer

Controllers **receive HTTP requests**, **validate input**, **call service methods**, and **return HTTP responses**.

### 10.1 CustomerController.java

```java
@RestController                                                    // 1
@RequestMapping("/api/v1/customers")                               // 2
@RequiredArgsConstructor                                           // 3
public class CustomerController {                                  // 4

  private final CustomerService customerService;                   // 5
```

| Line | Explanation |
|------|------------|
| 1 | **`@RestController`** — Combines `@Controller` + `@ResponseBody`. Every method return value is automatically serialized to JSON and written to the HTTP response body |
| 2 | **`@RequestMapping("/api/v1/customers")`** — Base path for ALL endpoints in this controller. Every endpoint URL starts with `/api/v1/customers` |
| 3 | Lombok injects `customerService` via constructor |
| 5 | **`CustomerService`** (interface, not impl!) — This is dependency injection. Spring injects `CustomerServiceImpl` at runtime because it's the only class that implements `CustomerService` |

#### Register Endpoint

```java
  @PostMapping("/register")                                        // 6
  public ResponseEntity<CustomerResponse> register(                // 7
      @Valid @RequestBody CustomerRegistrationRequest request) {   // 8
    return ResponseEntity.status(HttpStatus.CREATED)               // 9
        .body(customerService.registerCustomer(request));          // 10
  }
```

| Line | Explanation |  
|------|------------|
| 6 | **`@PostMapping("/register")`** — Maps `POST /api/v1/customers/register` to this method |
| 7 | `ResponseEntity<CustomerResponse>` — Wraps the response body with HTTP status code and headers |
| 8 | **`@Valid`** — Triggers bean validation on the request body. Checks `@NotBlank`, `@Email` annotations. If validation fails → 400 Bad Request (handled by `GlobalExceptionHandler`) |
| 8 | **`@RequestBody`** — Takes the raw JSON from the HTTP request body and deserializes it into a `CustomerRegistrationRequest` object (using Jackson) |
| 9 | **`HttpStatus.CREATED`** — Returns HTTP **201 Created** (not 200 OK) because we're creating a new resource |
| 10 | Calls the service method and puts the result in the response body |

**Full HTTP flow**: `POST /api/v1/customers/register` + JSON body → Spring deserializes to `CustomerRegistrationRequest` → `@Valid` validates fields → `registerCustomer()` → MongoDB insert → returns JSON + 201

#### Login Endpoint

```java
  @PostMapping("/login")                                           // 11
  public ResponseEntity<AuthResponse> login(                       // 12
      @Valid @RequestBody LoginRequest request) {                  // 13
    return ResponseEntity.ok(customerService.login(request));      // 14
  }
```

| Line | Explanation |
|------|------------|
| 11 | Maps `POST /api/v1/customers/login` |
| 13 | `@Valid` validates `@NotBlank` on customerIdOrUserId and password |
| 14 | `ResponseEntity.ok(...)` → HTTP **200 OK** + JSON body with `{ token, customer }` |

#### Get Customer Endpoint

```java
  @GetMapping("/{customerId}")                                     // 15
  public ResponseEntity<CustomerResponse> getCustomer(             // 16
      @PathVariable String customerId) {                           // 17
    return ResponseEntity.ok(customerService.getCustomerById(customerId)); // 18
  }
```

| Line | Explanation |
|------|------------|
| 15 | **`@GetMapping("/{customerId}")`** — Maps `GET /api/v1/customers/abc-123-uuid`. The `{customerId}` is a **path variable** |
| 17 | **`@PathVariable`** — Extracts the `customerId` from the URL path. `GET /api/v1/customers/abc-123` → `customerId = "abc-123"` |

#### Get Customer Details Endpoint

```java
  @GetMapping("/details/{customerId}")                             // 19
  public ResponseEntity<CustomerResponse> getCustomerDetails(      // 20
      @PathVariable Integer customerId) {                          // 21
    return customerService.getCustomerDetailsByIntegerId(customerId) // 22
        .map(ResponseEntity::ok)                                   // 23
        .orElse(ResponseEntity.notFound().build());                // 24
  }
```

| Line | Explanation |
|------|------------|
| 19 | Maps `GET /api/v1/customers/details/1001` — note this uses **Integer** ID, not UUID |
| 22-24 | **Optional handling** — If found: wraps in 200 OK. If not found: returns **404 Not Found** with empty body. No exception thrown. This is a **graceful failure pattern** |
| 23 | `ResponseEntity::ok` — Method reference. Equivalent to `response -> ResponseEntity.ok(response)` |

#### Search Endpoints

```java
  @GetMapping("/search/mobile/{mobile}")                           // 25
  public ResponseEntity<CustomerResponse> searchByMobile(          // 26
      @PathVariable String mobile) {                               // 27
    return customerService.searchByMobile(mobile)                  // 28
        .map(ResponseEntity::ok)                                   // 29
        .orElse(ResponseEntity.notFound().build());                // 30
  }

  @GetMapping("/search/email/{email}")                             // 31
  // ... same pattern ...

  @GetMapping("/search/pan/{pan}")                                 // 32
  // ... same pattern ...
```

| Line | Explanation |
|------|------------|
| 25-30 | **Search by mobile** — `GET /api/v1/customers/search/mobile/9876543210`. Returns 200 + customer if found, or 404 if not |
| 31-32 | Same pattern for email and PAN search endpoints |

---

### 10.2 HealthController.java

```java
@RestController                                                    // 1
public class HealthController {                                    // 2

  @Value("${server.port}")                                         // 3
  private String serverPort;                                       // 4

  @Value("${spring.data.mongodb.uri:}")                            // 5
  private String databaseUri;                                      // 6

  @GetMapping({ "/", "/health", "/api/health" })                   // 7
  public ResponseEntity<Map<String, Object>> health() {            // 8
    Map<String, Object> response = new HashMap<>();                // 9
    response.put("status", "UP");                                  // 10
    response.put("service", "Customer Service");                   // 11
    response.put("version", "0.0.1-SNAPSHOT");                     // 12
    response.put("timestamp", LocalDateTime.now());                // 13
    response.put("port", serverPort);                              // 14
    response.put("database", extractDatabaseType(databaseUri));    // 15

    Map<String, String> endpoints = new HashMap<>();               // 16
    endpoints.put("register", "POST /api/v1/customers/register");  // 17
    endpoints.put("login", "POST /api/v1/customers/login");        // 18
    response.put("availableEndpoints", endpoints);                 // 19

    return ResponseEntity.ok(response);                            // 20
  }
```

| Line | Explanation |
|------|------------|
| 3-4 | Injects the server port (8081) from config |
| 7 | **Maps 3 URLs to the same method** — The array syntax `{ "/", "/health", "/api/health" }` means hitting any of these 3 paths calls this method. Docker health checks typically hit `/health` |
| 9-19 | Builds a status map: service name, version, current time, port, database type, and available endpoints. This is useful for monitoring tools and debugging |

---

### 10.3 HealthCheckController.java

```java
@RestController                                                    // 1
@RequestMapping("/api/v1")                                         // 2
public class HealthCheckController {                               // 3

  @GetMapping("/health")                                           // 4
  public ResponseEntity<Map<String, Object>> health() {            // 5
    Map<String, Object> health = new HashMap<>();                  // 6
    health.put("status", "UP");                                    // 7
    health.put("service", "customer-service");                     // 8
    health.put("timestamp", LocalDateTime.now());                  // 9
    return ResponseEntity.ok(health);                              // 10
  }

  @GetMapping("/ping")                                             // 11
  public ResponseEntity<String> ping() {                           // 12
    return ResponseEntity.ok("pong");                              // 13
  }
}
```

| Line | Explanation |
|------|------------|
| 2 | Base path: `/api/v1` |
| 4-10 | **Health endpoint** — `GET /api/v1/health` returns minimal status JSON. Used by Docker Compose health checks: `curl -f http://localhost:8081/api/v1/health` |
| 11-13 | **Ping endpoint** — `GET /api/v1/ping` returns just the string `"pong"`. Simplest possible liveness check |

---

## 11. Exception Handling

### 11.1 CustomerNotFoundException.java

```java
public class CustomerNotFoundException extends RuntimeException {  // 1
  public CustomerNotFoundException(String message) {               // 2
    super(message);                                                // 3
  }
  public CustomerNotFoundException(String customerId, String field) { // 4
    super(String.format("Customer not found with %s: %s", field, customerId)); // 5
  }
}
```

| Line | Explanation |
|------|------------|
| 1 | **`extends RuntimeException`** — Unchecked exception. Doesn't require `throws` declaration. When thrown, it bubbles up to `GlobalExceptionHandler` |
| 4-5 | Convenience constructor — `new CustomerNotFoundException("abc-123", "id")` → message: `"Customer not found with id: abc-123"` |

### 11.2 DuplicateCustomerException.java

```java
public class DuplicateCustomerException extends RuntimeException { // 1
  public DuplicateCustomerException(String field, String value) {  // 2
    super(String.format("%s already exists: %s", field, value));   // 3
  }
}
```

- `new DuplicateCustomerException("Email", "rahul@example.com")` → `"Email already exists: rahul@example.com"`

### 11.3 InvalidCredentialsException.java

```java
public class InvalidCredentialsException extends RuntimeException { // 1
  public InvalidCredentialsException() {                           // 2
    super("Invalid email or password");                            // 3
  }
}
```

- Thrown when login fails (full name + PAN doesn't match any record)

### 11.4 GlobalExceptionHandler.java

```java
@ControllerAdvice                                                  // 1
public class GlobalExceptionHandler {                              // 2

  @ExceptionHandler(CustomerNotFoundException.class)               // 3
  public ResponseEntity<Map<String, Object>>                       // 4
      handleCustomerNotFoundException(CustomerNotFoundException ex) { // 5
    Map<String, Object> error = new HashMap<>();                   // 6
    error.put("timestamp", LocalDateTime.now());                   // 7
    error.put("message", ex.getMessage());                         // 8
    error.put("status", HttpStatus.NOT_FOUND.value());             // 9
    return new ResponseEntity<>(error, HttpStatus.NOT_FOUND);      // 10
  }

  @ExceptionHandler(DuplicateCustomerException.class)              // 11
  // ... returns 409 CONFLICT ...

  @ExceptionHandler(InvalidCredentialsException.class)             // 12
  // ... returns 401 UNAUTHORIZED ...

  @ExceptionHandler(RuntimeException.class)                        // 13
  // ... returns 400 BAD_REQUEST (catch-all) ...

  @ExceptionHandler(MethodArgumentNotValidException.class)         // 14
  public ResponseEntity<Map<String, Object>>                       // 15
      handleValidationExceptions(MethodArgumentNotValidException ex) { // 16
    Map<String, Object> errors = new HashMap<>();                  // 17
    errors.put("timestamp", LocalDateTime.now());                  // 18
    errors.put("status", HttpStatus.BAD_REQUEST.value());          // 19

    Map<String, String> fieldErrors = new HashMap<>();             // 20
    ex.getBindingResult().getFieldErrors()                         // 21
        .forEach(error -> fieldErrors.put(                         // 22
            error.getField(), error.getDefaultMessage()));         // 23
    errors.put("errors", fieldErrors);                             // 24

    return new ResponseEntity<>(errors, HttpStatus.BAD_REQUEST);   // 25
  }
}
```

| Line | Explanation |
|------|------------|
| 1 | **`@ControllerAdvice`** — This class intercepts exceptions thrown by ANY controller in the application. Acts as a **centralized exception handler** |
| 3-10 | **`@ExceptionHandler(CustomerNotFoundException.class)`** — When any controller method throws `CustomerNotFoundException`, this method catches it and returns a structured JSON error with HTTP **404 Not Found** |
| 11 | `DuplicateCustomerException` → HTTP **409 Conflict** |
| 12 | `InvalidCredentialsException` → HTTP **401 Unauthorized** |
| 13 | `RuntimeException` → HTTP **400 Bad Request** (generic catch-all for any unexpected runtime exception) |
| 14-25 | **`MethodArgumentNotValidException`** — Thrown automatically by Spring when `@Valid` validation fails. Lines 20-23: extracts field-level errors (e.g., `{"email": "Invalid email format", "firstName": "First name is required"}`) and returns them in a structured format |

**Error Response Format**:
```json
{
  "timestamp": "2026-03-10T14:30:00",
  "status": 404,
  "message": "Customer not found with id: abc-123"
}
```

---

## 12. How the Complete Flow Works

### Login Flow (Step by Step)

```
1. Flutter sends: POST /api/v1/customers/login
   Body: { "customerIdOrUserId": "Rahul Sharma", "password": "ABCDE1234F" }

2. Spring deserializes JSON → LoginRequest object
   @Valid checks @NotBlank → both fields present ✓

3. CustomerController.login() is called
   → Delegates to customerService.login(request)

4. CustomerServiceImpl.login():
   a. Extracts fullName = "Rahul Sharma" (trimmed)
   b. Extracts pan = "ABCDE1234F" (trimmed)
   c. Calls: customerDetailsRepository
        .findFirstByCustomerFullNameIgnoreCaseAndRefCustItNum("Rahul Sharma", "ABCDE1234F")
   d. MongoDB query: db.customer_details.findOne({
        customerFullName: /^Rahul Sharma$/i,
        refCustItNum: "ABCDE1234F"
      })
   e. If NOT found → throws InvalidCredentialsException → 401
   f. If found → continues

5. jwtService.generateToken("Rahul Sharma"):
   a. Creates JWT payload: { sub: "Rahul Sharma", iat: 1710000000, exp: 1710086400 }
   b. Signs with HS256 + secret key
   c. Returns: "eyJhbGciOiJIUzI1NiJ9..."

6. mapCustomerDetailsToResponse(customerDetails):
   a. Maps customerId (Integer 1001) → String "1001"
   b. Maps customerFullName → firstName
   c. Sets panNumber = null (security: don't expose PAN)

7. Returns: AuthResponse { token: "eyJ...", customer: { customerId: "1001", ... } }
   → Spring serializes to JSON → HTTP 200 OK
```

### Registration Flow (Step by Step)

```
1. POST /api/v1/customers/register
   Body: { firstName, lastName, email, mobile, password, panNumber, dob }

2. @Valid validation runs → checks @NotBlank, @Email

3. CustomerServiceImpl.registerCustomer():
   a. existsByEmail(email) → if true → 409 Conflict
   b. existsByMobileNumber(mobile) → if true → 409 Conflict
   c. UUID.randomUUID() → generates unique ID
   d. passwordEncoder.encode(password) → BCrypt hash
   e. customerRepository.save(customer) → MongoDB insert
   f. mapToResponse(saved) → strips password, returns DTO

4. Returns: CustomerResponse + HTTP 201 Created
```

### Request with JWT (After Login)

```
1. Flutter sends: GET /api/bff/portfolio/1001
   Header: Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...

2. JwtAuthenticationFilter.doFilterInternal():
   a. Extracts "Bearer eyJ..." → jwt = "eyJ..."
   b. jwtService.extractUsername(jwt) → "Rahul Sharma"
   c. userDetailsService.loadUserByUsername("Rahul Sharma")
   d. jwtService.isTokenValid(jwt, "Rahul Sharma") → true
   e. Sets SecurityContextHolder authentication ✓

3. Request proceeds to controller as authenticated
```

---

## Quick Reference: All Endpoints

| Method | Endpoint | Description | Response |
|--------|----------|-------------|----------|
| POST | `/api/v1/customers/register` | Register new customer | 201 + CustomerResponse |
| POST | `/api/v1/customers/login` | Login (Name + PAN → JWT) | 200 + AuthResponse |
| GET | `/api/v1/customers/{customerId}` | Get customer by UUID | 200 + CustomerResponse |
| GET | `/api/v1/customers/details/{customerId}` | Get customer by integer ID | 200 / 404 |
| PUT | `/api/v1/customers/{customerId}` | Update customer profile | 200 + CustomerResponse |
| GET | `/api/v1/customers/search/mobile/{mobile}` | Search by mobile | 200 / 404 |
| GET | `/api/v1/customers/search/email/{email}` | Search by email | 200 / 404 |
| GET | `/api/v1/customers/search/pan/{pan}` | Search by PAN | 200 / 404 |
| GET | `/`, `/health`, `/api/health` | Health check (detailed) | 200 + status |
| GET | `/api/v1/health` | Health check (minimal) | 200 + status |
| GET | `/api/v1/ping` | Liveness probe | 200 + "pong" |

---

## Key Annotations Cheat Sheet

| Annotation | What It Does |
|-----------|-------------|
| `@SpringBootApplication` | Entry point — enables auto-config + component scanning |
| `@RestController` | Class handles HTTP requests, returns JSON |
| `@RequestMapping("/path")` | Base URL path for all methods in the class |
| `@GetMapping` / `@PostMapping` / `@PutMapping` | Maps HTTP GET/POST/PUT to this method |
| `@PathVariable` | Extracts value from URL path (`/users/{id}` → id) |
| `@RequestBody` | Deserializes JSON request body to Java object |
| `@Valid` | Triggers bean validation (@NotBlank, @Email, etc.) |
| `@Service` | Marks class as a business service bean |
| `@Repository` | Marks interface as a data access bean |
| `@Component` | Generic Spring bean (auto-registered) |
| `@Document(collection)` | Maps class to MongoDB collection |
| `@Id` | Marks the primary key field (maps to MongoDB `_id`) |
| `@Indexed(unique=true)` | Creates unique MongoDB index |
| `@Data` | Lombok: generates getters, setters, toString, equals, hashCode |
| `@Builder` | Lombok: generates builder pattern |
| `@RequiredArgsConstructor` | Lombok: generates constructor for `final` fields |
| `@Slf4j` | Lombok: creates `log` variable for logging |
| `@Value("${key}")` | Injects config property from application.yaml |
| `@Transactional` | Wraps method in a transaction (rollback on error) |
| `@ControllerAdvice` | Global exception handler for all controllers |
| `@ExceptionHandler` | Catches specific exception type |
| `@NotBlank` | Validation: field must not be null or empty |
| `@Email` | Validation: must be valid email format |
| `@Pattern(regexp)` | Validation: must match regex pattern |
| `@CsvBindByName` | OpenCSV: maps CSV column header to this field |
