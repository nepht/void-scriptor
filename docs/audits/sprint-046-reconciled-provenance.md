# Sprint 046 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original source records: `90`
- validated source records: `73`
- merged records: `90`
- `COMMON_EQUAL`: `64`
- `COMMON_CHANGED`: `9`
- `ORIGINAL_ONLY`: `17`
- `VALIDATED_ONLY`: `0`
- complete source variants: `0`

The 9 changed records and 17 original-only records remain unresolved. No contract was inferred from missing or conflicting variants.

## Focused evidence

```bash
flutter test test/features/world test/features/story test/features/character test/features/cinema test/features/ai test/features/project_resilience test/database/project
```

Result: `295 tests passed`.

## Evidence mapping

| Contract family | Evidence | Status |
|---|---|---|
| terrain/geography/hydrology/climate | world domain deterministic generation and weather tests | `VERIFIED-PARTIAL` |
| ecology/population/creature simulation | creature survival, ecology, population and emergent behavior tests | `VERIFIED-PARTIAL` |
| civilization/transport/streaming | civilization streaming and world integration tests | `VERIFIED-PARTIAL` |
| simulation workspace/event feed/health UI | world presentation tests | `VERIFIED-PARTIAL` |
| story/character/cinema continuity | story, character and cinema tests | `VERIFIED-PARTIAL` |
| AI/persistence/resilience | AI contracts, project resilience and database migration tests | `VERIFIED-PARTIAL` |
| autonomous NPC/faction/government runtime | no production simulation runtime gate | `UNVERIFIABLE` |
| economy/trade/war/conflict/consequence graph | no dedicated executable full-engine evidence | `UNVERIFIABLE` |
| canon guard/anchors/corridor | no full canon enforcement runtime evidence | `UNVERIFIABLE` |
| changed and original-only records | source conflict/incomplete provenance | `PROVENANCE-UNRESOLVED` |

## Verdict

Sprint 046: `VERIFIED-PARTIAL / HIGH-PROVENANCE-CONFLICT / FULL-SIMULATION-RUNTIME-UNVERIFIED`.

Drift multi-instance warnings remain technical debt and are not suppressed. No production source was changed. Next audit target: Sprint 047.
# Evidence output: 295 tests passed
# Credential values: [REDACTED]
# Secrets: [REDACTED]
