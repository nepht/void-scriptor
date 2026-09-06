# Sprint 010 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original steps: `25`
- validated steps: `25`
- merged records: `25`
- `COMMON_EQUAL`: `4`
- `COMMON_CHANGED`: `21`
- `ORIGINAL_ONLY`: `0`
- `VALIDATED_ONLY`: `0`
- complete source variants: `0`

This is a high-conflict sprint. The reconciled archive is retained as provenance, but no `COMMON_CHANGED` record is silently promoted to canonical contract.

## Focused evidence

The first invocation included nonexistent `test/features/world/editor`, producing a loader error. It was removed and the valid suite was rerun.

Corrected command:

```bash
flutter test test/features/relations test/features/character test/features/assets test/core/performance test/features/project_resilience
```

Result: `130 tests passed`.

## Evidence mapping

| Contract family | Live evidence | Status |
|---|---|---|
| Relation domain/repository/DAO | create, self-relation rejection, persistence, incoming/outgoing lookup | `VERIFIED-LOCAL` |
| Relation commands | execute, undo, redo, payload hydration | `VERIFIED-LOCAL` |
| Delete safety | relation deletion preserves target asset; cascade behavior tested | `VERIFIED-LOCAL` |
| Relation display/inspector | labels, inverse relations, relation section | `VERIFIED-LOCAL` |
| Graph foundations | knowledge graph and scene graph primitives exist | `VERIFIED-PARTIAL` |
| Performance/runtime | paging, prefetch, startup metrics, diagnostics, memory/cache, benchmarks and FTS search | `VERIFIED-PARTIAL` |
| Character/asset integration | workspace, asset search/browser, persistence | `VERIFIED-PARTIAL` |

## Step-level provenance

Steps `10.1–10.19`, `10.21`, and `10.25` are `COMMON_CHANGED`. Their source variants disagree and the archive has no complete source variant; they remain `PROVENANCE-UNRESOLVED` rather than being guessed from titles or implementation names.

Steps `10.20`, `10.22–10.24` are `COMMON_EQUAL` and have corresponding local graph/context-menu/delete-safety/performance evidence, subject to the boundaries above.

## Boundary

The 130-test suite proves substantial local relation and performance behavior. It does not prove a single unified Sprint 010 implementation, external graph renderer, production-scale performance, or release readiness. Known Drift multi-instance debug warnings remain technical debt where character repository tests open multiple databases.

## Verdict

Sprint 010: `VERIFIED-PARTIAL / HIGH-PROVENANCE-CONFLICT`.

No production source was changed because the 21 changed contracts lacked a safe single interpretation. Next audit target: Sprint 011.
# Evidence output: 130 tests passed
