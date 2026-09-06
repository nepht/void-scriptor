# Sprint 089 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original source records: `127`
- validated source records: `124`
- merged records: `127`
- `COMMON_EQUAL`: `123`
- `COMMON_CHANGED`: `1`
- `ORIGINAL_ONLY`: `3`
- `VALIDATED_ONLY`: `0`
- complete source variants: `0`

Changed and original-only records remain unresolved; no missing contract was inferred.

## Focused evidence

```bash
flutter test test/features/release test/core/publishing test/core/jobs test/features/project_resilience
flutter analyze
git diff --check
```

Results:

- `115 tests passed`
- `flutter analyze`: `No issues found!`
- `git diff --check`: passed; chained command exited `0`

## Evidence mapping

| Contract family | Evidence | Status |
|---|---|---|
| publishing pipeline ordering and failure propagation | pipeline tests | `VERIFIED-PARTIAL` |
| manifest fields, validation and JSON roundtrip | manifest tests | `VERIFIED-PARTIAL` |
| semantic versioning and channel isolation | publish model/distribution tests | `VERIFIED-PARTIAL` |
| release review, moderation, provenance, schedule and analytics models | release domain tests | `VERIFIED-PARTIAL` |
| publishing, discovery, revenue and public project UI | release presentation tests | `VERIFIED-PARTIAL` |
| resilience and background job regressions | scoped regression suite | `VERIFIED-PARTIAL` |
| signed artifacts, real build/package outputs, CDN/upload, store submission, update client, monetization telemetry and production delivery | no executable production gate | `UNVERIFIABLE` |
| changed and original-only records | source conflict/incomplete provenance | `PROVENANCE-UNRESOLVED` |

## Verdict

Sprint 089: `VERIFIED-PARTIAL / PROVENANCE-CONFLICT / PUBLISHING-PRODUCTION-UNVERIFIED`.

No speculative signing, CDN, store, updater, or monetization integration claim was added.

# Credential values: [REDACTED]
# Secrets: [REDACTED]

Drift multi-instance warnings remain technical debt and are not suppressed.

# Evidence output: 115 tests passed
# Analyzer output: No issues found!
# Diff check: passed
# End of ledger

Next audit target: Sprint 090.
