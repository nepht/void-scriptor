# Sprint 044 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original source records: `84`
- validated source records: `75`
- merged records: `84`
- `COMMON_EQUAL`: `67`
- `COMMON_CHANGED`: `8`
- `ORIGINAL_ONLY`: `9`
- `VALIDATED_ONLY`: `0`
- complete source variants: `0`

The 8 changed records and 9 original-only records remain unresolved. No contract was inferred from missing or conflicting variants.

## Focused evidence

```bash
flutter test test/features/marketplace test/core/plugin test/core/agent test/features/ai test/features/project_resilience test/core/security test/database/project
```

Result: `255 tests passed`.

## Evidence mapping

| Contract family | Evidence | Status |
|---|---|---|
| marketplace domain/workspace/library/seller UI | marketplace domain, presentation and controller tests | `VERIFIED-PARTIAL` |
| agent package/capability/permission/sandbox | agent, marketplace permission and plugin sandbox tests | `VERIFIED-PARTIAL` |
| plugin persistence/SDK/host | plugin repository, restart, SDK, host and UI tests | `VERIFIED-PARTIAL` |
| AI provider/queue/review | AI provider contracts, queue, review and persistence tests | `VERIFIED-PARTIAL` |
| project resilience/security/database | resilience, lock, key derivation and migration tests | `VERIFIED-PARTIAL` |
| payment/payout/entitlement/subscription | no payment or hosted commerce runtime gate | `UNVERIFIABLE` |
| semantic discovery/recommendations/search index | no production semantic/index service evidence | `UNVERIFIABLE` |
| package signing/integrity/kill switch/moderation | local models only; no production security service gate | `UNVERIFIABLE` |
| marketplace/entitlement APIs and hosted distribution | no network/backend runtime evidence | `UNVERIFIABLE` |
| changed and original-only records | source conflict/incomplete provenance | `PROVENANCE-UNRESOLVED` |

## Verdict

Sprint 044: `VERIFIED-PARTIAL / HIGH-PROVENANCE-CONFLICT / MARKETPLACE-BACKEND-UNVERIFIED`.

No production source was changed. Next audit target: Sprint 045.
# Evidence output: 255 tests passed
# Credential values: [REDACTED]
# Secrets: [REDACTED]
