# Sprint 145.23 — Startup Path Simplification

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json` langkah 145.23 dan `core_mvp_scope_reset_spec.json`.

## Required contract

Dashboard dan local recent projects harus tersedia secepat mungkin. Account, Cloud, provider, dan optional feature initialization tidak boleh menahan Core startup. UI harus menunjukkan status local-only secara jujur.

## Live implementation

- `lib/main.dart` memanggil `prepareBootstrap()` sebelum `runApp()`.
- `prepareBootstrap()` memiliki file-backed desktop path dan in-memory web path.
- `BootstrapGate` mengganti app dengan `RecoveryShell` pada recovery mode.
- `RecoveryShell` tidak memakai repository, database, atau platform channel.
- `appRouterProvider` menunggu `authControllerProvider` dan mengarahkan unauthenticated state ke Login; Guest/Offline diterima sebagai application session.
- Dashboard tersedia pada `AppRoutes.dashboard` dan dibungkus `VoidAppShell`.
- Router file mengimpor banyak optional feature screens dan route builders pada composition layer.

## Evidence

Existing tests cover:

- `test/app/bootstrap/app_diagnostics_test.dart`
- `test/app/bootstrap/bootstrap_gate_test.dart`
- `test/app/bootstrap/startup_recovery_policy_test.dart`
- `test/app/bootstrap/web_bootstrap_test.dart`
- `test/app/auth/auth_flow_test.dart`
- `test/core/performance/startup_metrics_test.dart`

These prove bootstrap policy, recovery rendering, in-memory web composition, auth flow, and startup metric primitives. They do not prove first-frame Dashboard availability before auth/provider initialization, nor do they prove that all optional route construction is deferred.

## Current boundary

`prepareBootstrap()` is intentionally awaited before `runApp()`, so diagnostic startup work precedes the first frame. Auth has a deliberate 700 ms demo delay. The router composition eagerly references optional feature screens, although most provider/network work is not proven to run during startup.

The evidence therefore distinguishes:

- recovery path: **VERIFIED dependency-free**;
- local Guest/Offline entry: **VERIFIED in widget tests**;
- immediate Core Dashboard/recent-project availability: **PENDING**;
- optional initialization deferral from all startup paths: **PARTIAL**;
- native startup timing and route interaction: **UNVERIFIABLE** due `snapshot_id_required` driver blocker.

## Safe next slice

1. Add a RED test for a first-frame local-only startup seam using injected bootstrap/auth dependencies.
2. Measure whether optional provider/network initialization occurs before Dashboard.
3. Split route registration or lazy construction only where the test identifies a real startup dependency.
4. Preserve `createAppRouter` compatibility and existing route labels.
5. Re-run auth/bootstrap focused tests, then full analyzer/test/build gates.

Do not remove optional routes solely because they are deferred; preserve them behind honest feature state.

## Decision

`145.23 Startup Path Simplification` berstatus **PARTIAL**. Recovery and local auth paths are present and tested, but immediate Dashboard/recent-project availability and complete optional-initialization deferral are not proven. No startup refactor was applied because the required injection/lazy-route contract is not yet defined and router files contain concurrent changes.

Next: `145.24 Novel Workspace Core`.

## Evidence paths

- `lib/main.dart`
- `lib/app/bootstrap/app_diagnostics.dart`
- `lib/app/bootstrap/bootstrap_gate.dart`
- `lib/app/routing/app_router.dart`
- `lib/core/auth/auth_controller.dart`
- `test/app/bootstrap/app_diagnostics_test.dart`
- `test/app/bootstrap/bootstrap_gate_test.dart`
- `test/app/bootstrap/startup_recovery_policy_test.dart`
- `test/app/bootstrap/web_bootstrap_test.dart`
- `test/app/auth/auth_flow_test.dart`
- `test/core/performance/startup_metrics_test.dart`
- `docs/audits/core-without-account.md`
- `docs/audits/module-boundary-feature-flags.md`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`
