# Sprint 012 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original steps: `18`
- validated steps: `28`
- merged records: `28`
- `COMMON_EQUAL`: `1`
- `COMMON_CHANGED`: `17`
- `ORIGINAL_ONLY`: `0`
- `VALIDATED_ONLY`: `10`
- complete source variants: `0`

This is a high-conflict sprint. Changed and validated-only records remain unresolved; no inferred title or implementation is promoted to canonical contract.

## Focused evidence

```bash
flutter test test/features/weapon test/features/relations test/features/character test/database/project test/features/inspector
```

Result: `40 tests passed`.

## Evidence mapping

| Contract family | Live evidence | Status |
|---|---|---|
| Weapon domain/table/create | model, technical fields, defaults, filesystem package and creation transaction | `VERIFIED-LOCAL` |
| Weapon relation/persistence | `uses` relation survives database restart and relation display/delete safety | `VERIFIED-LOCAL` |
| Weapon workspace/inspector | desktop technical detail sheet, narrow vertical layout and typed inspector | `VERIFIED-LOCAL` |
| Character/asset/database boundary | character persistence, schema/index/migration and inspector tests | `VERIFIED-PARTIAL` |

## Provenance boundary

Only step `12.9` is `COMMON_EQUAL`. Steps `12.1–12.8` and `12.10–12.18` are `COMMON_CHANGED`; steps `12.19–12.28` are `VALIDATED_ONLY`. Their source contents remain unresolved in the archive and cannot be safely reconstructed from labels alone.

## Local warning

Known Drift multiple-`ProjectDatabase` debug warning appeared during character repository isolation tests. The suite remained green; warning is active technical debt.

## Verdict

Sprint 012: `VERIFIED-PARTIAL / HIGH-PROVENANCE-CONFLICT`.

No production source was changed because no single executable contract could be established for the changed records.

Next audit target: Sprint 013.
# Evidence output: 40 tests passed
