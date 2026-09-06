# Sprint 145.20 — Core Without Account

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json` langkah 145.20 dan `core_mvp_scope_reset_spec.json`.

## Contract

Core startup, create/open/edit/save/search/export/backup/restore must work without account credentials. Guest and Offline are valid local session states, not degraded error states.

## Live implementation evidence

- `lib/core/auth/auth_status.dart` defines `guest` and `offline`.
- `lib/core/auth/auth_session.dart` provides `AuthSession.guest()` and `AuthSession.offline()` with no user ID or email.
- `lib/core/auth/auth_controller.dart` exposes `continueAsGuest()` and `continueOffline()`.
- `lib/app/routing/app_router.dart` treats authenticated, guest, and offline sessions as allowed application sessions.
- `test/app/auth/auth_flow_test.dart` covers Guest → Dashboard, Guest → Studio, Studio → Logout → Login, Offline → Dashboard, and narrow login layout.

## Latest focused evidence

Command:

```text
wsl.exe -d Ubuntu -- bash -lc 'cd /home/nepht/Projects/void_scriptor_multiplatform && export PATH="$HOME/toolchain/flutter/bin:$PATH" && flutter test test/app/auth/auth_flow_test.dart'
```

Result:

```text
All tests passed! — 7 tests
```

## Gaps

- `AuthController.build()` currently returns a demo logged-out state after a fixed delay; it does not yet read a persisted local session.
- The auth flow test proves widget/router behavior, not a clean Windows native click-through.
- The complete Core journey after Guest/Offline—project creation through backup/restore—is not proven by this auth test.
- Native interaction remains `UNVERIFIABLE` because the driver previously returned `snapshot_id_required`.
- No credentials were entered or stored.

## Decision

`145.20 Core Without Account` berstatus **PARTIAL**. Guest and Offline local entry points plus router acceptance are verified in source/widget tests. Persisted session restoration, complete local journey, and native evidence remain open. This is not a reason to add mandatory login or to weaken Core isolation.

Next: `145.21 Core Without Internet or Providers`.

## Evidence paths

- `lib/core/auth/auth_status.dart`
- `lib/core/auth/auth_session.dart`
- `lib/core/auth/auth_controller.dart`
- `lib/app/routing/app_router.dart`
- `test/app/auth/auth_flow_test.dart`
- `docs/audits/core-mvp-vertical-slice-contract.md`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
