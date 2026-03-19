# End-to-End Testing Guide - MyPolicy Insurance Platform

This guide provides step-by-step instructions to validate the complete frontend-backend integration across all user flows.

---

## Pre-requisites

### 1. Prerequisites Checklist

- [ ] JDK 11+ installed
- [ ] Maven 3.6+ installed
- [ ] Flutter SDK with latest stable channel
- [ ] Docker Desktop running (optional - recommended for database services)
- [ ] Postman installed (optional - for API testing)
- [ ] Git bash or PowerShell terminal

### 2. Services Required

The following services must be running:

| Service                | Port  | Status                           |
| ---------------------- | ----- | -------------------------------- |
| BFF Service            | 8090  | **REQUIRED**                     |
| Config Service         | 8888  | Required by BFF                  |
| Customer Service       | 8081  | Called by BFF                    |
| Policy Service         | 8085  | Called by BFF                    |
| Data Pipeline Service  | 8082  | Called by BFF                    |
| Eureka Discovery       | 8761  | Optional (for service discovery) |
| Frontend (Flutter Web) | 8000+ | For manual UI testing            |

---

## Phase 1: Start Backend Services

### Step 1.1: Start Config Service (if using Spring Cloud Config)

```powershell
cd config-service
mvn clean spring-boot:run
# Should see: "Started ConfigApplication in X seconds"
```

### Step 1.2: Start Customer Service

```powershell
cd customer-service
mvn clean spring-boot:run
# Should see: "Started CustomerApplication in X seconds"
# Verify: http://localhost:8081/actuator/health
```

### Step 1.3: Start Policy Service

```powershell
cd policy-service
mvn clean spring-boot:run
# Should see: "Started PolicyApplication in X seconds"
# Verify: http://localhost:8085/actuator/health
```

### Step 1.4: Start Data Pipeline Service

```powershell
cd data-pipeline-service
mvn clean spring-boot:run
# Should see: "Started DataPipelineApplication in X seconds"
# Verify: http://localhost:8082/actuator/health
```

### Step 1.5: Start BFF Service (Last - depends on others)

```powershell
cd bff-service
mvn clean spring-boot:run
# Should see: "Started BffApplication in X seconds"
# Verify: http://localhost:8090/actuator/health
```

**Verification:**

```powershell
# Test BFF is responding
Invoke-RestMethod -Uri "http://localhost:8090/actuator/health"
# Expected response: { "status": "UP" }
```

---

## Phase 2: Start Frontend

### Step 2.1: Get Flutter Dependencies

```powershell
cd frontend
flutter pub get
```

### Step 2.2: Run Flutter Web

```powershell
flutter run -d chrome
# Should open browser at http://localhost:YOUR_PORT
# Default is usually http://localhost:54321
```

---

## Phase 3: Core User Flows Testing

### Flow A: Complete Signup → Login → Dashboard

#### A.1: Signup Flow (Web/Mobile)

1. **Open Frontend Application**
   - Navigate to login screen
   - Click "Sign Up" button

2. **Fill Signup Form**
   - Full Name: `Test User 001`
   - Email: `testuser001@example.com`
   - Mobile: `919876543210`
   - Date of Birth: `1990-05-15`
   - Click **Continue**

3. **Verify API Call**

   ```
   ✅ POST /api/bff/frontend/signup called
   ✅ Response contains customerId
   ✅ Screen navigates to OTP verification
   ```

4. **Enter OTP**
   - Screen shows: "6-digit OTP sent to 919876543210"
   - Enter OTP: `123456` (test OTP)
   - Click **Verify**

5. **Verify OTP API Call**

   ```
   ✅ POST /api/bff/frontend/signup/verify-otp called
   ✅ customerId passed through navigation
   ✅ Screen navigates to Create Password
   ```

6. **Create Password**
   - Password: `TestPassword@123`
   - Confirm Password: `TestPassword@123`
   - Click **Create Account**

7. **Verify Password Creation**
   ```
   ✅ POST /api/bff/frontend/signup/create-password called with customerId
   ✅ Success message shown
   ✅ Screen navigates back to Login
   ✅ Now can login with email/mobile + new password
   ```

#### A.2: Login Flow

1. **On Login Screen**
   - Customer ID / Email / Mobile: `Amit Ramesh Kulkarni` (or registered email)
   - Password: `AKCPK1123L` (test credentials)
   - Click **Login**

2. **Verify Login API Call**

   ```
   ✅ POST /api/bff/auth/login called
   ✅ Response returns JWT token
   ✅ Token stored in app state
   ✅ Token used for all subsequent API calls
   ```

3. **Dashboard Should Load**
   ```
   ✅ GET /api/bff/frontend/dashboard/{customerId} called
   ✅ Portfolio data displayed (policies, totals, etc.)
   ✅ Loading spinner shown during load
   ```

#### A.3: Navigation Through Features

1. **Click Profile**

   ```
   ✅ GET /api/bff/frontend/profile/{customerId} called
   ✅ Customer info displayed (name, email, mobile, DOB)
   ✅ Edit button works (PUT endpoint callable)
   ```

2. **Click Help**

   ```
   ✅ GET /api/bff/frontend/help/faqs called (public, no auth)
   ✅ FAQs displayed
   ✅ GET /api/bff/frontend/help/actions called
   ✅ Help actions displayed
   ```

3. **Click Documents**

   ```
   ✅ GET /api/bff/frontend/documents/{customerId} called
   ✅ Policy documents listed
   ```

4. **Click Analytics**

   ```
   ✅ GET /api/bff/frontend/analytics/{customerId} called
   ✅ Analytics dashboard loaded with insights
   ```

5. **Click Policies → View Policy Detail**
   ```
   ✅ GET /api/bff/frontend/policies/{customerId} called (list)
   ✅ Click individual policy
   ✅ GET /api/bff/frontend/policies/{customerId}/{policyId} called (detail)
   ✅ Policy details displayed with coverage info
   ✅ Loading spinner shown while fetching
   ```

---

### Flow B: Account Recovery

#### B.1: Forgot Password Flow

1. **On Login Screen**
   - Click **"Forgot Password?"** link

2. **Recovery Verification Screen**
   - Enter Customer ID OR Mobile OR Email: `919876543210`
   - Click **Verify**

3. **Verify Recovery API Call**

   ```
   ✅ POST /api/bff/recovery/verify called with customerIdOrEmailOrMobile
   ✅ Screen navigates to OTP verification
   ```

4. **Enter Recovery OTP**
   - Enter OTP: `654321` (test OTP)
   - Click **Verify**

5. **Verify Recovery OTP API Call**
   ```
   ✅ POST /api/bff/recovery/otp/verify called
   ✅ Success message shown
   ✅ Option to reset password or return to login
   ```

#### B.2: Get Customer ID Flow

1. **On Login Screen**
   - Click **"Forgot Customer ID?"** link

2. **Recovery Verification Screen (getCustomerId mode)**
   - Enter Mobile/Email: `testuser001@example.com`
   - Click **Verify**

3. **Verify Recovery API Call**
   ```
   ✅ POST /api/bff/recovery/verify called with getCustomerId mode
   ✅ Customer ID returned and displayed
   ```

---

## Phase 4: Error Scenario Testing

### Test 4.1: Invalid Login Credentials

1. Login Screen
2. Enter invalid credentials
3. **Expected:**
   ```
   ✅ Error message displayed in red container
   ✅ Button remains clickable for retry
   ✅ No navigation occurs
   ```

### Test 4.2: Invalid OTP (Signup Flow)

1. In Signup OTP Screen
2. Enter wrong OTP: `000000`
3. Click Verify
4. **Expected:**
   ```
   ✅ Error message shown
   ✅ Attempts counter decremented (max 3 attempts)
   ✅ After 3 failed attempts: lockdown dialog shown
   ✅ User cannot proceed
   ```

### Test 4.3: Network Error Handling

1. Stop BFF service (`Ctrl+C`)
2. Try any API action from frontend
3. **Expected:**
   ```
   ✅ Loading spinner shown briefly
   ✅ Error message displayed to user
   ✅ User can retry request
   ✅ No app crash
   ```

### Test 4.4: Missing Token Error

1. Manually clear `localStorage` or app state
2. Try accessing dashboard
3. **Expected:**
   ```
   ✅ 401 Unauthorized error caught
   ✅ User redirected to login
   ✅ Clean error message (not raw stack trace)
   ```

---

## Phase 5: API Testing with Postman

### Step 5.1: Import Postman Collection

1. Open Postman
2. Click **Import**
3. Select `MyPolicy-BFF-APIs.postman_collection.json`
4. Collection imported successfully

### Step 5.2: Configure Environment Variables

1. Click **Environments** (gear icon)
2. Create new environment: `MyPolicy Local`
3. Set variables:
   - `baseUrl`: `http://localhost:8090`
   - `token`: _(will be set by Login request)_
   - `customerId`: _(will be set by Login request)_
   - `policyId`: `POL-001` _(sample policy ID)_

### Step 5.3: Run Login Request

1. Navigate to: **Auth & Signup** → **Login**
2. Click **Send**
3. **Expected Response (200 OK):**
   ```json
   {
     "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
     "customer": {
       "customerId": 901120934,
       "fullName": "Amit Ramesh Kulkarni",
       "mobile": "919876543210",
       "email": "amit.kulkarni@gmail.com"
     }
   }
   ```
4. Verify: Environment variables **token** and **customerId** auto-populated

### Step 5.4: Run All Dashboard Endpoints

1. **Get Dashboard** → Send
   - Expected: 200 OK with portfolio data

2. **Get Analytics** → Send
   - Expected: 200 OK with insights and advisory

3. **Get Profile** → Send
   - Expected: 200 OK with customer details

### Step 5.5: Test Policy Endpoints

1. **Get All Policies** → Send
   - Expected: 200 OK with policy list

2. **Get Policy Detail** → Send
   - Expected: 200 OK with single policy details

3. **Get Documents** → Send
   - Expected: 200 OK with document list

### Step 5.6: Test Help Endpoints (No Auth Required)

1. **Get FAQs** → Send
   - Expected: 200 OK with FAQ items

2. **Get Help Actions** → Send
   - Expected: 200 OK with action list

---

## Phase 6: Browser DevTools Inspection

### Step 6.1: Open Chrome DevTools

1. In Flutter Web, press `F12` or right-click → **Inspect**

### Step 6.2: Network Tab - Monitor API Calls

1. Click **Network** tab
2. Perform action: Click Dashboard
3. **Should see:**
   - `POST /api/bff/auth/login` (if not logged in)
   - `GET /api/bff/frontend/dashboard/{customerId}`
   - Status: `200 OK` for both
   - Response payload correctly formatted

### Step 6.3: Check Console for Errors

1. Click **Console** tab
2. Perform navigation actions
3. **Should see:**
   - ✅ No red errors
   - ✅ Appropriate log messages
   - ✅ No CORS errors
   - ✅ No undefined variable access

### Step 6.4: Local Storage - Verify Token Storage

1. Click **Application** tab
2. Navigate to **Local Storage** → `http://localhost:xxxx`
3. **Should see:**
   - `token`: JWT value
   - `customerId`: numeric ID

---

## Phase 7: Performance & Load Testing

### Step 7.1: Response Time Validation

Use Postman or DevTools to verify response times:

| Endpoint      | Expected Time | Acceptable Range |
| ------------- | ------------- | ---------------- |
| Login         | < 500ms       | < 1s             |
| Get Dashboard | < 1s          | < 2s             |
| Get Analytics | < 1.5s        | < 3s             |
| Get Profile   | < 500ms       | < 1s             |
| Get Policies  | < 500ms       | < 1s             |

### Step 7.2: Load Test (Optional)

```powershell
# Using Apache JMeter or similar
# Create thread group with 100 simultaneous users
# Run Login → Dashboard → Profile flow
# Monitor: Response times, error rates, throughput
```

---

## Phase 8: Validation Checklist

### Frontend Integration ✅

- [ ] All 12 screens have API integration
- [ ] All screens show loading spinners during API calls
- [ ] All error responses show user-friendly messages in red
- [ ] Navigation parameters (customerId, policyId) pass correctly through flows
- [ ] Token is automatically captured after login and used in all subsequent requests
- [ ] Signup flow works: Signup → OTP → Password → Login
- [ ] Recovery flow works: Verify → OTP → Success
- [ ] All screens properly handle `mounted` checks before state updates

### API Responses ✅

- [ ] All 27 BFF endpoints accessible at correct paths
- [ ] Login returns JWT token with correct format
- [ ] All protected endpoints check `Authorization: Bearer <token>` header
- [ ] All endpoints return JSON with appropriate status codes
- [ ] Error responses include meaningful error messages
- [ ] No N+1 query problems (each request efficient)
- [ ] Response times within acceptable range

### Error Handling ✅

- [ ] Invalid login credentials show error message
- [ ] Expired passwords handled gracefully
- [ ] Network timeouts trigger retry mechanism
- [ ] Missing token redirects to login
- [ ] Invalid OTP prevents submission after 3 attempts
- [ ] Missing required fields show validation errors

### Security ✅

- [ ] JWT token stored securely in localStorage (for web) or secure storage (mobile)
- [ ] Token included in Authorization header for all protected endpoints
- [ ] No sensitive data (passwords, PAN) logged to console
- [ ] CORS configured correctly if frontend on different origin
- [ ] Rate limiting in place (optional but recommended)

---

## Troubleshooting

### Issue: "Connection refused" on port 8090

**Solution:**

```powershell
# Check if BFF service is running
netstat -ano | findstr :8090

# If not running, start it:
cd bff-service
mvn clean spring-boot:run
```

### Issue: "401 Unauthorized" on protected endpoints

**Solution:**

```
1. Verify token is captured from login response
2. Check Authorization header format: "Bearer <token>"
3. Verify token hasn't expired
4. Re-login to get fresh token
```

### Issue: CORS error in browser console

**Solution:**

```
Add to BFF application.yml:
cors:
  allowed-origins: "http://localhost:*,http://127.0.0.1:*"
  allowed-methods: "GET,POST,PUT,DELETE,OPTIONS"
  allowed-headers: "Authorization,Content-Type"
  allow-credentials: true
```

### Issue: Frontend shows "Loading..." indefinitely

**Solution:**

```
1. Open DevTools → Network tab
2. Check if API request was made
3. Look for response status code
4. If timeout, increase backend service resources
5. Check error logs in backend terminal
```

### Issue: Database connection errors in logs

**Solution:**

```
1. Ensure database is running (if using Docker):
   docker-compose up -d
2. Check database connection strings in application.yml
3. Verify credentials are correct
4. Check port numbers are correct
```

---

## Success Criteria

**E2E Testing is COMPLETE when:**

1. ✅ User can signup with all required fields
2. ✅ User can verify OTP and create password
3. ✅ User can login with credentials
4. ✅ Dashboard loads with real policy data
5. ✅ All navigation links work (Profile, Help, Analytics, Documents)
6. ✅ Policy details screen loads data via API (not hardcoded)
7. ✅ Account recovery flow works end-to-end
8. ✅ All error scenarios show appropriate messages
9. ✅ Token is automatically used for all protected endpoints
10. ✅ No JavaScript errors in browser console
11. ✅ All API response times within acceptable range
12. ✅ No data loss on page refresh (token + state preserved)

---

## Test Execution Report Template

```markdown
# E2E Test Execution Report

Date: [DATE]
Tester: [NAME]
Environment: Local / Docker / Staging

## Summary

- Total Tests: 45
- Passed: \_\_
- Failed: \_\_
- Skipped: \_\_

## Critical Issues Found

1. Issue: [Description]
   Impact: [High/Medium/Low]
   Fix: [Status/Action]

## Recommendations

- [Recommendation 1]
- [Recommendation 2]
```

---

**Last Updated:** March 18, 2026
**Version:** 1.0 - Complete Frontend-Backend Integration E2E Testing
