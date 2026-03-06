# Eureka Service Discovery - Setup & Verification Guide

## Overview

Your MyPolicy microservices now use **Eureka for service discovery** and **Config Server for centralized configuration**. This eliminates hardcoded URLs and enables dynamic service-to-service communication.

---

## Architecture

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────────┐
│  Config Service │──────▶│ Discovery Service│◀─────│  All Microservices  │
│   (Port 8888)   │      │   (Port 8761)    │      │  register & discover│
└─────────────────┘      └──────────────────┘      └─────────────────────┘
```

**Startup Order:**

1. `config-service` (8888) - Configuration server
2. `discovery-service` (8761) - Eureka server
3. Business services:
   - `customer-service` (8083)
   - `policy-service` (8085)
   - `data-pipeline-service` (8082)
4. `bff-service` (8080) - API Gateway

---

## What Changed

### ✅ Added

- **New `discovery-service`** module with Eureka Server
- Spring Cloud Config + Eureka Client dependencies to all microservices
- Centralized Eureka config in `config-service/src/main/resources/config-repo/`

### ✅ Updated

- **Feign Clients** now use service names instead of hardcoded URLs:
  ```java
  // Before: @FeignClient(name = "customer-service", url = "http://localhost:8081")
  // After:  @FeignClient(name = "customer-service")
  ```
- **Docker Compose** orchestrates startup order with health checks
- All services auto-register with Eureka on startup

### ✅ Removed

- Hardcoded `customer.service.url`, `policy.service.url` from config files
- Manual URL management across environments

---

## Local Development (Without Docker)

### Step 1: Start Infrastructure Services

**Terminal 1 - Config Service:**

```powershell
cd config-service
mvn spring-boot:run
```

Wait for: `Configuration Service Started Successfully! ✓`

**Terminal 2 - Discovery Service:**

```powershell
cd discovery-service
mvn spring-boot:run
```

Wait for Eureka dashboard to be available at `http://localhost:8761`

### Step 2: Start Business Services

**Terminal 3 - Customer Service:**

```powershell
cd customer-service
mvn spring-boot:run
```

**Terminal 4 - Policy Service:**

```powershell
cd policy-service
mvn spring-boot:run
```

**Terminal 5 - Data Pipeline Service:**

```powershell
cd data-pipeline-service
mvn spring-boot:run
```

**Terminal 6 - BFF Service:**

```powershell
cd bff-service
mvn spring-boot:run
```

### Step 3: Verify Registration

Open Eureka Dashboard: **http://localhost:8761**

You should see:

- `CUSTOMER-SERVICE`
- `POLICY-SERVICE`
- `DATA-PIPELINE-SERVICE`
- `BFF-SERVICE`

All with status **UP** (1 instance each).

---

## Docker Deployment

### Build & Start All Services

```powershell
docker compose up --build
```

### Start in Detached Mode

```powershell
docker compose up -d
```

### View Logs

```powershell
# All services
docker compose logs -f

# Specific service
docker compose logs -f discovery-service
docker compose logs -f bff-service
```

### Stop All Services

```powershell
docker compose down
```

### Clean Restart (Remove volumes)

```powershell
docker compose down -v
docker compose up --build
```

---

## Verification Checklist

### 1. Config Server Health

```powershell
curl http://localhost:8888/actuator/health
```

Expected: `{"status":"UP"}`

### 2. Discovery Server Dashboard

Open: **http://localhost:8761**

Verify all services appear under "Instances currently registered with Eureka"

### 3. Service Configuration

Check if a service fetched config correctly:

```powershell
curl http://localhost:8888/customer-service/default
```

Expected: JSON with database config, Eureka settings, etc.

### 4. Service Discovery via BFF

Test that BFF can call customer-service via Eureka:

```powershell
curl http://localhost:8080/api/v1/customers/{customerId}
```

This call uses Eureka discovery (no hardcoded URL).

---

## Configuration Files

All Eureka settings are centralized in Config Server:

```
config-service/src/main/resources/config-repo/
├── bff-service.yaml
├── customer-service.yaml
├── policy-service.yaml
└── data-pipeline-service.yaml
```

Each file contains:

```yaml
eureka:
  client:
    service-url:
      defaultZone: ${EUREKA_DEFAULT_ZONE:http://localhost:8761/eureka}
  instance:
    prefer-ip-address: true
```

**Environment Override (Docker):**

- `EUREKA_DEFAULT_ZONE=http://discovery-service:8761/eureka`

---

## Troubleshooting

### Service Not Appearing in Eureka

1. **Check service logs** for errors:

   ```powershell
   docker compose logs customer-service
   ```

2. **Verify Eureka URL**:
   - Local: `http://localhost:8761/eureka`
   - Docker: `http://discovery-service:8761/eureka`

3. **Check Config Import**:
   Services must fetch config from Config Server before registering with Eureka.
   ```yaml
   spring:
     config:
       import: optional:configserver:http://admin:config123@localhost:8888
   ```

### Feign Client Fails

**Error:** `Load balancer does not have available server for client: customer-service`

**Solution:**

1. Confirm `customer-service` is UP in Eureka dashboard
2. Check `@FeignClient(name = "customer-service")` matches service name in Eureka
3. Ensure calling service has `@EnableFeignClients` annotation

### Config Server Connection Refused

**Error:** `Connection refused: localhost/127.0.0.1:8888`

**Solution:**

1. Start Config Service first (before other services)
2. Check port 8888 is not in use:
   ```powershell
   netstat -ano | findstr :8888
   ```

### Eureka Dashboard Shows Old/Stale Instances

**Solution:**

```powershell
# Restart Discovery Service
docker compose restart discovery-service
```

Or increase heartbeat settings in config:

```yaml
eureka:
  instance:
    lease-renewal-interval-in-seconds: 10
    lease-expiration-duration-in-seconds: 30
```

---

## Best Practices

1. **Always start Config Service first** - Other services depend on it
2. **Wait for health checks** before starting dependent services
3. **Use service names in Feign** - Never hardcode URLs
4. **Monitor Eureka dashboard** - Ensure all services are registered
5. **Set proper timeouts** - Config in `config-repo/*/yaml`:
   ```yaml
   feign:
     client:
       config:
         default:
           connectTimeout: 5000
           readTimeout: 5000
   ```

---

## Ports Summary

| Service               | Port  | Description                    |
| --------------------- | ----- | ------------------------------ |
| Config Service        | 8888  | Configuration server           |
| Discovery Service     | 8761  | Eureka server                  |
| BFF Service           | 8080  | API Gateway                    |
| Customer Service      | 8083  | Customer management            |
| Data Pipeline Service | 8082  | Ingestion & processing         |
| Policy Service        | 8085  | Policy management              |
| PostgreSQL            | 5432  | Database                       |
| MongoDB               | 27017 | NoSQL storage (ingestion logs) |

---

## Next Steps

1. **Test discovery-based calls:**

   ```bash
   # BFF calls customer-service via Eureka
   curl http://localhost:8080/api/v1/customers/123
   ```

2. **Scale services dynamically:**

   ```powershell
   docker compose up --scale customer-service=3
   ```

   Load will be balanced across 3 instances automatically.

3. **Add resilience patterns:**
   - Circuit breakers (Resilience4j)
   - Retry policies
   - Fallback handlers

4. **Secure Eureka dashboard** in production:
   - Add Spring Security to `discovery-service`
   - Use HTTPS for service-to-service communication

---

## Support

For issues or questions:

1. Check service logs: `docker compose logs [service-name]`
2. Verify Eureka dashboard: `http://localhost:8761`
3. Test Config Server: `http://localhost:8888/actuator/health`

**Happy service discovery! 🚀**
