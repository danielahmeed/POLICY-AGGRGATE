# MyPolicy (POLICY-AGGRGATE)

Unified insurance portfolio platform: **Spring Boot microservices backend** + **Flutter dashboard frontend**, wired together via a **BFF** (Backend-for-Frontend).

- **Backend**: Config Server + Eureka + Customer + Policy + Data Pipeline + BFF
- **Frontend**: Flutter (HDFC-style UI) that logs in via BFF and renders portfolio data from the real dataset (via data-pipeline-service)
- **Run options**: local dev (Maven + Flutter) or full stack in Docker Compose

---

## Repository layout

```
POLICY-AGGRGATE/
├─ MyPolicy-Backend/                 # Spring Boot microservices + Docker Compose
│  ├─ docker-compose.yml             # Brings up backend + nginx-served frontend
│  ├─ config-service/
│  ├─ discovery-service/
│  ├─ customer-service/
│  ├─ policy-service/
│  ├─ data-pipeline-service/
│  └─ bff-service/
└─ frontend/                         # Flutter app (web build served by nginx in Docker)
```

- **Backend docs**: `MyPolicy-Backend/README.md`
- **Frontend docs**: `frontend/README.md`

---

## Architecture (high level)

```
Browser ──► Frontend (nginx) ──► BFF (8090) ──► Customer (8081)
                               │            ├──► Policy (8085)
                               │            └──► Data-pipeline (8082) ──► MongoDB Atlas
                               │
                               ├──► Config (8888)
                               └──► Eureka (8761)
```

### Services & ports (Docker host)

| Service | Host Port | Notes |
|---|---:|---|
| frontend (nginx) | **8080** | Serves Flutter Web build |
| bff-service | **8090** | Login + portfolio aggregation APIs |
| discovery-service | **8761** | Eureka dashboard |
| config-service | **8889** | Mapped from container `8888` to avoid conflicts |
| customer-service | **8081** | Customer APIs + auth |
| data-pipeline-service | **8082** | Dataset ingestion + portfolio API |
| policy-service | **8085** | Policy APIs |

---

## Quick start (recommended): Docker Compose

Prerequisites:
- Docker Desktop + Docker Compose

Run the full stack:

```bash
cd MyPolicy-Backend
docker compose up --build -d
```

Open:
- **Frontend (web app):** `http://localhost:8080`
- **BFF (APIs + legacy static UI):** `http://localhost:8090`
- **Eureka:** `http://localhost:8761`
- **Config (host-mapped):** `http://localhost:8889`

Logs / stop:

```bash
cd MyPolicy-Backend
docker compose logs -f
docker compose down
```

---

## Local development (Maven + Flutter)

This mode is useful when iterating quickly on code.

### Backend (run in order)

From `MyPolicy-Backend/`, start in separate terminals:

1. `config-service` (8888)
2. `discovery-service` (8761)
3. `customer-service` (8081)
4. `policy-service` (8085)
5. `data-pipeline-service` (8082)
6. `bff-service` (8090)

Full instructions and verification steps are in `MyPolicy-Backend/README.md`.

### Frontend

From `frontend/`:

```bash
flutter pub get
flutter run -d chrome
```

The Flutter app is configured to call the BFF (`/api/bff/...`) through the API client layer. In Docker, the web build is baked with `API_BASE_URL=http://bff-service:8090`.

---

## Key BFF endpoints used by the frontend

Base URL (local): `http://localhost:8090`

- `POST /api/bff/auth/login`
- `GET /api/bff/portfolio/{customerId}`

Detailed contracts (with request/response examples) live in:
- `MyPolicy-Backend/API_CONTRACTS.md`

---

## Notes & troubleshooting

- **Config port in Docker**: `config-service` runs on container port `8888` but is mapped to **host `8889`**.
- **If Docker can’t connect**: ensure Docker Desktop is running and configured for Linux containers.
- **Flutter web not reflecting changes**: do a full restart (`q` then re-run) if hot reload doesn’t update UI.

---

## License

This repository currently does not define a license file. Add `LICENSE` if you intend to open-source or share publicly with clear terms.

