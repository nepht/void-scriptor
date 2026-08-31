# ADR-0001 — Core Shared-Type Ownership and Dependency Direction

- Status: Accepted
- Date: 2026-08-31
- Step: Sprint 145.19 Core Dependency Direction
- Driver: Choirudin (product/architecture authority), implemented by nephthys cron

## Context

The canonical step requires the layer direction
`Network depends on Cloud/Core; Cloud depends on Core; Core depends on neither`.
In this repository Core lives in `lib/core`, Cloud/Network feature families live
in `lib/features`. A live scan on 2026-08-31 (HEAD 48b7e751) found exactly three
direct `lib/core -> lib/features` imports:

| Core file | Imported feature type |
|---|---|
| `lib/core/persistence/project_registry_service.dart` | `features/projects/domain/project_model.dart` (`ProjectModel`) |
| `lib/core/selection/selection_model.dart` | `features/assets/domain/asset_type.dart` (`AssetType`) |
| `lib/core/commands/command_type_registry.dart` | `features/project_resilience/application/command_history_repository.dart` (`CommandHistoryRecord`, `CommandHistoryStatus`) |

These types are shared value objects consumed by Core services and multiple
feature families. The earlier audit (2026-08-27) blocked enforcement because
the destination contracts were not chosen. This ADR chooses them.

## Decision

1. **Stable, feature-neutral value types used by Core are owned by Core.**
   They live under `lib/core/domain/`:
   - `ProjectModel` -> `lib/core/domain/project_model.dart`
   - `AssetType` -> `lib/core/domain/asset_type.dart`
   - `CommandHistoryRecord`, `CommandHistoryStatus` -> `lib/core/domain/command_history.dart`

2. **The former feature files remain as compatibility exports** so existing
   public import paths keep compiling: each moved type's old path re-exports
   the Core-owned file. No call site outside the three core files changes.

3. **Feature-owned logic stays in features.** The Drift-backed
   `CommandHistoryRepository` (with `CommandHistoryRecordInput` and all
   database methods) remains in
   `lib/features/project_resilience/application/command_history_repository.dart`
   and imports the Core-owned record types. Core never imports Drift or the
   repository.

4. **Enforcement**: `test/core/architecture/core_dependency_direction_test.dart`
   scans production `lib/core` imports/exports and fails on any
   `lib/core -> lib/features` edge. No allowlist; the migration must reach
   zero.

5. **No behavior change.** Type identity, JSON serialization, and equality are
   preserved verbatim; this is a file relocation plus compatibility exports.

## Consequences

- `lib/core` has zero dependency edges into `lib/features` after migration.
- Feature files that re-export Core types create no Core->feature edge.
- Future shared value types placed in `lib/core/domain/` must not import
  `lib/features`; the architecture test enforces direction for the whole tree.
- The enforcement test is the acceptance evidence for step 145.19.
