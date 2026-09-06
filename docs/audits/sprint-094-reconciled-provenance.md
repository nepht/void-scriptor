# Sprint 094 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original source records: `114`
- validated source records: `121`
- merged records: `121`
- `COMMON_EQUAL`: `28`
- `COMMON_CHANGED`: `86`
- `ORIGINAL_ONLY`: `0`
- `VALIDATED_ONLY`: `7`
- complete source variants: `0`

This is a high-conflict sprint: 93 of 121 records are unresolved variants. Per contract, changed and validated-only records are NOT treated as evidence; no missing contract was inferred.

## Focused evidence

```bash
flutter test test/features/world/domain/privacy_zones_test.dart test/features/intent/domain/sensor_privacy_test.dart test/features/intent/domain/privacy_policy_test.dart test/core/security
flutter analyze
git diff --check
```

Results:

- `38 tests passed`
- `flutter analyze`: `No issues found!`
- `git diff --check`: passed; chained command exited `0`

## Evidence mapping

| Contract family | Evidence | Status |
|---|---|---|
| privacy zones deny capture in sensitive bounds, deny-by-default on overlap | `privacy_zones_test.dart` | `VERIFIED-PARTIAL` |
| sensor permission deny-by-default, recording indicator, explicit local processing/retention, payload not stored, revocation stops recording | `sensor_privacy_test.dart` | `VERIFIED-PARTIAL` |
| voice input consent gate and immediate revocation | `privacy_policy_test.dart` | `VERIFIED-PARTIAL` |
| project lock, AES-GCM cipher, PBKDF2 key derivation, secret masking UI | `core/security` tests | `VERIFIED-PARTIAL` |
| data export/delete requests, retention policy registry, telemetry consent management, legal request workflow, production data governance | no executable production gate | `UNVERIFIABLE` |
| 86 changed + 7 validated-only records | source conflict/incomplete provenance | `PROVENANCE-BLOCKED` |

## Verdict

Sprint 094: `VERIFIED-PARTIAL / PROVENANCE-BLOCKED / DATA-GOVERNANCE-PRODUCTION-UNVERIFIED`.

The 93 unresolved records are not implemented, claimed, or inferred. No speculative governance claim was added.

# Credential values: [REDACTED]
# Secrets: [REDACTED]

Drift multi-instance warnings remain technical debt and are not suppressed.

# Evidence output: 38 tests passed
# Analyzer output: No issues found!
# Diff check: passed
# End of ledger

Next audit target: Sprint 095.

