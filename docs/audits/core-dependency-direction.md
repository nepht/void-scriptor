# Sprint 145.19 — Core Dependency Direction

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json` langkah 145.19 dan `core_mvp_scope_reset_spec.json`.

## Required direction

```text
NETWORK → CLOUD → CORE
CORE → neither Cloud nor Network
```

More precisely:

- Network may depend on Cloud and Core.
- Cloud may depend on Core.
- Core must not depend on Cloud or Network.
- Core domain/application code must not depend on feature presentation or feature-owned domain types when the feature is an optional layer.

## Live evidence

The following direct imports currently cross from `lib/core` into `lib/features`:

| Core file | Imported feature type | Consequence |
|---|---|---|
| `lib/core/persistence/project_registry_service.dart` | `features/projects/domain/project_model.dart` | Registry persistence is coupled to the Projects feature model |
| `lib/core/selection/selection_model.dart` | `features/assets/domain/asset_type.dart` | Shared selection state is coupled to an asset feature enum |
| `lib/core/commands/command_type_registry.dart` | `features/project_resilience/application/command_history_repository.dart` | Core command registry is coupled to resilience application data |

These are source observations from the live worktree, not inferred from historical summaries.

## Current test/evidence status

- No existing dependency-boundary test was found that would prevent these imports.
- Existing source/test/build gates do not prove architectural direction.
- The repository contains many concurrent modifications; the three imports touch public types and are not safe to rewrite as a quick cleanup.
- No schema, route, persistence, or user data was changed for this audit.

## Why this is blocked

The canonical step says to enforce boundaries but does not choose the destination contracts for these shared types. Several safe designs are possible:

1. move stable value objects/enums to `lib/core/domain/`;
2. introduce a dedicated `lib/core/contracts/` package;
3. invert dependencies through interfaces/registries at the composition root;
4. retain a compatibility export while migrating call sites.

Choosing one without an ADR and ownership review could break imports, generated code, provider wiring, or concurrent agent work. A dependency test written immediately would correctly go RED, but production remediation requires a contract first.

## Remediation gate

Before implementation:

1. write an ADR naming canonical owners for `ProjectModel`, `AssetType`, and `CommandHistoryRecord`;
2. define compatibility exports for existing public imports;
3. map all importers and generated files;
4. add a failing architecture test that scans only production `lib/core/**` imports;
5. move one type at a time and run focused tests after each move;
6. run full analyzer, test, supported builds, and diff checks;
7. preserve concurrent ownership and do not use broad restore/format commands.

The architecture test must reject new `lib/core → lib/features` imports but may need an allowlist during the migration. The final allowlist should be empty or explicitly justified in an ADR.

## Decision

`145.19 Core Dependency Direction` berstatus **BLOCKED**. The direction is defined and violations are verified, but enforcement cannot safely proceed without a shared-type ownership contract and migration ADR. This is an architectural blocker, not a test failure and not a reason to weaken current tests.

Next independent step: `145.20 Core Without Account`.

## Evidence paths

- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`
- `docs/audits/dependency-coupling-map.md`
- `docs/audits/core-mvp-scope-lock.md`
- `docs/sprints/sprint-145-product-scope-reset-mvp-recovery.md`
