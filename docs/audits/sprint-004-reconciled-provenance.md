# Sprint 004 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original steps: `9`
- validated steps: `14`
- merged records: `14`
- `COMMON_EQUAL`: `8`
- `COMMON_CHANGED`: `1`
- `ORIGINAL_ONLY`: `0`
- `VALIDATED_ONLY`: `5`

## Focused evidence

The first invocation contained nonexistent directory arguments (`test/features/authentication` and `test/features/splash`) and exited with loader errors. This was corrected without treating it as a product failure.

Corrected command:

```bash
flutter test test/app/auth/auth_flow_test.dart test/app/routing/app_router_test.dart test/app/routing/back_navigation_test.dart test/features/project_resilience/project_session_lifecycle_test.dart test/features/project_resilience/project_session_manager_test.dart
```

Result: `26 tests passed`.

## Step mapping

| Step | Reconciled class | Live evidence | Status |
|---|---|---|---|
| 4.1 | `COMMON_EQUAL` | authentication structure and core auth modules | `VERIFIED-LOCAL` |
| 4.2 | `COMMON_EQUAL` | auth status model | `VERIFIED-LOCAL` |
| 4.3 | `COMMON_EQUAL` | auth session model | `VERIFIED-LOCAL` |
| 4.4 | `COMMON_EQUAL` | auth controller and flow tests | `VERIFIED-LOCAL` |
| 4.5 | `COMMON_EQUAL` | app routes/router tests | `VERIFIED-LOCAL` |
| 4.6 | `COMMON_EQUAL` | splash/login navigation path | `VERIFIED-PARTIAL` |
| 4.7 | `COMMON_EQUAL` | login/guest/offline/demo auth tests | `VERIFIED-LOCAL` |
| 4.8 | `COMMON_EQUAL` | register screen and local feedback tests | `VERIFIED-LOCAL` |
| 4.9 | `COMMON_CHANGED` | source variants differ; local auth behavior is verified but provenance remains unresolved | `VERIFIED-PARTIAL` |
| 4.10 | `VALIDATED_ONLY` | forgot-password screen and local reset feedback | `VERIFIED-LOCAL` |
| 4.11 | `VALIDATED_ONLY` | guest/offline session behavior | `VERIFIED-LOCAL` |
| 4.12 | `VALIDATED_ONLY` | route/back navigation integration | `VERIFIED-LOCAL` |
| 4.13 | `VALIDATED_ONLY` | project session lifecycle, lock and migration backup | `VERIFIED-LOCAL` |
| 4.14 | `VALIDATED_ONLY` | read-only session safety | `VERIFIED-LOCAL` |

## Boundary

The 26-test suite proves local auth/session/routing behavior. It does not prove remote identity backend, real email delivery, OAuth, device session revocation, store builds or production authentication infrastructure.

## Verdict

Sprint 004: `VERIFIED-PARTIAL / PROVENANCE-UNRESOLVED`.

Next audit target: Sprint 005.
# Evidence output: 26 tests passed
## Gate

No production source was changed for this provenance audit. User-owned and concurrent files remain untouched.
