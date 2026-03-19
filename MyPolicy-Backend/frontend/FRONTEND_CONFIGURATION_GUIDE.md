# Frontend Configuration Guide

This guide lists what is configured in the current Flutter frontend and what is required whenever you add a new page or reusable component.

## 1. Current Frontend Components

### Routing and app shell

- `MaterialApp` and route generation are configured in `lib/main.dart`.
- Route constants are centralized in `lib/utils/app_routes.dart`.

### Screens (pages)

- Auth flow: Login, Signup, Signup OTP, Create Password, Recovery Verification, Recovery OTP
- Customer flow: Dashboard, Analytics, Policy Detail, Profile
- Support flow: Help, FAQ, Documents

### Shared building blocks

- Widgets under `lib/widgets/` such as `CustomAppBar`, `PolicyCard`, `DonutChart`, `SummaryCard`, `HelpCard`, `FaqSection`, etc.
- Theme tokens and `ThemeData` in `lib/theme/app_theme.dart`.
- Data model in `lib/models/policy_model.dart`.
- Static/dashboard constants in `lib/utils/dashboard_constants.dart`.

### Assets and package config

- Image assets are configured in `pubspec.yaml` under `flutter.assets`.
- Third-party packages are declared in `pubspec.yaml`.

## 2. Required Steps for Every New Page

1. Create the page file in `lib/screens/`.
2. Define constructor arguments explicitly (for example `customerId`, `customerName`) and keep them required where possible.
3. Register a route constant in `lib/utils/app_routes.dart`.
4. Add route handling in `lib/main.dart` (`onGenerateRoute`).
5. Add at least one navigation entry point using `Navigator.pushNamed` or `pushReplacementNamed`.
6. Use `AppTheme` tokens (colors, spacing, radius, shadows) instead of hard-coded style values when possible.
7. Ensure responsive behavior with `LayoutBuilder`, constraints, and scroll safety.
8. Add loading/error/empty UI states if the page depends on async data.
9. Add/update widget tests in `test/` for route creation and key interactions.
10. Verify Docker web build success (`docker compose up -d --build --no-deps frontend`).

## 3. Required Steps for Every New Reusable Component

1. Create the component under `lib/widgets/`.
2. Keep it stateless unless local UI state is required.
3. Make props typed and explicit (`required` for mandatory fields).
4. Keep business logic out of UI widgets; pass data/callbacks from parent screens.
5. Add semantic labels/tooltips for interactive controls where applicable.
6. Ensure keyboard/mouse support for web and desktop usage.
7. Reuse `AppTheme` tokens and avoid duplicating style constants.
8. Add a focused widget test for render + tap/callback behavior.

## 4. Data/API Integration Checklist for New Pages

1. Add model classes in `lib/models/` for new response structures.
2. Add/update a service/client layer (if API calls are introduced).
3. Map and validate response fields before rendering.
4. Handle API failure states with retry and user feedback.
5. Keep auth/session data handling consistent with existing flows.

## 5. Final Validation Checklist

- `flutter pub get`
- `flutter test`
- `docker compose up -d --build --no-deps frontend`
- Open `http://localhost:8080` and manually verify:
  - primary auth flow
  - dashboard navigation
  - support pages
  - profile interactions

## 6. Notes for This Project

- Prefer named routes for all new pages for consistent navigation and easier deep-link handling.
- Keep customer context (`customerId`, `customerName`) flowing through route arguments.
- Keep shared styles centralized in `AppTheme` to prevent UI drift.
