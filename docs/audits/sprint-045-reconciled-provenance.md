# Sprint 045 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original source records: `83`
- validated source records: `68`
- merged records: `83`
- `COMMON_EQUAL`: `59`
- `COMMON_CHANGED`: `9`
- `ORIGINAL_ONLY`: `15`
- `VALIDATED_ONLY`: `0`
- complete source variants: `0`

The 9 changed records and 15 original-only records remain unresolved. No contract was inferred from missing or conflicting variants.

## Focused evidence

```bash
flutter test test/features/world test/features/character test/features/story test/features/timeline test/features/ai test/features/scene_assets test/features/weapon test/features/project_resilience test/database/project
```

Result: `275 tests passed`.

## Evidence mapping

| Contract family | Evidence | Status |
|---|---|---|
| world identity/digital-twin foundations | world domain, spatial boundary and digital twin tests | `VERIFIED-PARTIAL` |
| character identity/versioning and asset relations | character, weapon and scene asset tests | `VERIFIED-PARTIAL` |
| story/timeline persistence | story, timeline, database and restart tests | `VERIFIED-PARTIAL` |
| AI context/generation boundary | AI provider, context, queue and persistence tests | `VERIFIED-PARTIAL` |
| project resilience/database | resilience, migration and portable project tests | `VERIFIED-PARTIAL` |
| multiverse graph/bridge/crossover runtime | no executable multiverse service/runtime gate | `UNVERIFIABLE` |
| timeline diff/three-way merge/canon conflict | no dedicated cross-universe implementation evidence | `UNVERIFIABLE` |
| cross-universe AI/alternate generator/butterfly analysis | no external or production AI runtime evidence | `UNVERIFIABLE` |
| portability wizard/dependency resolution | local asset models exist, full workflow not proven | `UNVERIFIABLE` |
| changed and original-only records | source conflict/incomplete provenance | `PROVENANCE-UNRESOLVED` |

## Verdict

Sprint 045: `VERIFIED-PARTIAL / HIGH-PROVENANCE-CONFLICT / MULTIVERSE-RUNTIME-UNVERIFIED`.

No production source was changed. Next audit target: Sprint 046.
# Evidence output: 275 tests passed
# Credential values: [REDACTED]
# Secrets: [REDACTED]
