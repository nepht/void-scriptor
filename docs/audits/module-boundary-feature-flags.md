# Sprint 145.22 — Module Boundary and Feature Flags

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json` langkah 145.22 dan `core_mvp_scope_reset_spec.json`.

## Required contract

Non-Core services must sit behind explicit interfaces, safe flags, timeout/circuit behavior, and dependency injection or an equivalent composition seam. Disabled capabilities must have no side effects and must not block Core startup, open, save, export, backup, or restore.

## Existing foundations

### Feature flags

- `lib/core/feature_flags/feature_flag_registry.dart` defines 13 v1.2 flags.
- All 13 flags default to `OFF`.
- Unknown flags are rejected with `ArgumentError`.
- Registry instances are independent; no global state leakage.
- `resetToDefaults()` returns every known flag to `OFF`.
- The registry intentionally leaves persistence of overrides to the settings/application layer.

Tests:

- `test/core/feature_flags/feature_flag_registry_test.dart`

### Audited workflow flag

- `lib/workflow/workflow_feature_flag.dart` defines a separate workflow-intelligence flag.
- Stable default is `OFF`.
- Runtime override requires a reason and emits an audit event.
- A failing audit sink does not block the override.
- The workflow module documents its dependency boundary and does not import Flutter UI libraries.

Tests:

- `test/workflow/workflow_feature_flag_test.dart`

### Failure and timeout policies

- `lib/workflow/workflow_policies.dart` provides bounded retry, per-step timeout, idempotency gating, and explicit failure policies.
- `lib/workflow/workflow_runner.dart` applies the per-step timeout.
- AI provider fallback/timeout behavior is separately covered under 145.21.

Tests:

- `test/workflow/workflow_policies_test.dart`
- `test/workflow/workflow_runner_test.dart`
- `test/features/ai/application/provider_router_test.dart`
- `test/features/ai/application/provider_timeout_test.dart`

## Missing integration contract

The current repository does not yet prove one consistent boundary for every Cloud/Network/AI capability:

1. The v1.2 registry names a finite wave-1 set, while Cloud/Network capabilities use other feature surfaces and specifications.
2. No architecture test currently rejects new `lib/core → lib/features` imports; that violation is recorded under 145.19.
3. No shared interface contract maps each deferred capability to a flag, injected service, unavailable state, timeout, circuit behavior, and no-side-effect guarantee.
4. No single test proves that every disabled optional capability avoids network, credential, filesystem, database, or payment side effects.
5. Persistence of flag overrides is intentionally out of scope for the registry and needs an owner before being added.
6. Startup composition still imports many optional screens directly, so source presence is not proof of deferred initialization.

## Safe implementation sequence

1. Approve the shared-type ownership ADR for 145.19.
2. Define a capability descriptor/interface with flag identity, layer, dependency, availability, and failure policy.
3. Keep `FeatureFlagRegistry` as the existing flag primitive unless a contract proves it insufficient.
4. Add RED tests for one optional capability: default OFF, no side effects when OFF, explicit enable, bounded failure, and Core fallback.
5. Implement the smallest composition-root wiring for that capability.
6. Repeat per capability; do not migrate all optional modules horizontally.
7. Add architecture/import boundary tests after canonical shared-type locations are decided.

## Evidence classification

| Boundary | Status |
|---|---|
| Flag primitive default OFF and validation | VERIFIED by focused tests |
| Workflow override audit and failure policy | VERIFIED by focused tests |
| AI timeout/fallback seams | VERIFIED in isolated tests |
| All Cloud/Network capabilities behind one explicit boundary | PENDING |
| No side effects for every disabled optional capability | PENDING |
| Core startup independent of all optional modules | PARTIAL; direct router imports remain |
| Dependency direction | BLOCKED under 145.19 |
| Production/release readiness | DEFERRED |

## Decision

`145.22 Module Boundary and Feature Flags` berstatus **PARTIAL**. Safe-off flag and bounded-failure primitives exist and are tested, but a complete cross-module contract and no-side-effect enforcement are not yet proven. No new registry, schema, route, credential, network integration, or broad refactor is authorized by this audit.

Next: `145.23 Startup Path Simplification`.

## Evidence paths

- `lib/core/feature_flags/feature_flag_registry.dart`
- `test/core/feature_flags/feature_flag_registry_test.dart`
- `lib/workflow/workflow_feature_flag.dart`
- `lib/workflow/workflow_policies.dart`
- `lib/workflow/workflow_runner.dart`
- `test/workflow/workflow_feature_flag_test.dart`
- `test/workflow/workflow_policies_test.dart`
- `test/workflow/workflow_runner_test.dart`
- `docs/audits/core-dependency-direction.md`
- `docs/audits/core-without-internet-providers.md`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
