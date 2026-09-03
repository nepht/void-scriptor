# Sprint 145.18 — Core MVP Vertical Slice Contract

Tanggal audit: 2026-08-27  
Sumber kanonik: `core_mvp_scope_reset_spec.json` (`vertical_slice`) dan `sprint_145.json` langkah 145.18.  
Status: contract/acceptance definition; bukan klaim bahwa seluruh journey telah lulus.

## Release-blocking journey

```text
CREATE_PROJECT
  → CREATE_CHAPTER
  → WRITE
  → AUTOSAVE
  → CLOSE
  → REOPEN
  → SEARCH_OR_LORE_LINK
  → EXPORT
  → BACKUP
  → RESTORE
```

A writer must complete the complete journey on a clean Windows x64 device:

- without login;
- without internet;
- without subscription;
- without Cloud, Network, Payment, or AI provider availability;
- without unrecovered data loss.

## Acceptance contract

| Stage | Required behavior | Evidence boundary | Current status |
|---|---|---|---|
| Create project | Creates a real project package with stable identity and required local structure | filesystem + persistence + UI | Source/local tests exist; clean-device native journey pending |
| Create chapter | Creates a persisted chapter in the selected novel/story with deterministic order | database restart + UI | Source/test evidence exists; full journey pending |
| Write | User can edit manuscript content in the active writing workspace | UI + persistence | Source/widget evidence exists; native interaction unverified |
| Autosave | Content is saved without explicit manual save and reports honest state | service + restart/recovery | Partial; complete crash/power/disk matrix belongs to 145.42 |
| Close | Project closes cleanly and releases database/session resources | lifecycle + process | Local lifecycle coverage exists; clean-device journey pending |
| Reopen | Same project opens with content, hierarchy, selection scope, and metadata intact | database/file restart | Round-trip tests exist; native route unverified |
| Search/lore link | User can find a relevant character/location/faction/lore entry or follow a link; broken links are safe | query/service + UI | Existing search/lore source/tests; full authoring flow evidence remains separate |
| Export | Clean manuscript export preserves text, ordering, encoding, and requested metadata policy | output file + content comparison | Contract exists; complete fidelity matrix pending |
| Backup | Backup is created in configured local storage with integrity metadata | filesystem + hash + diagnostics | Resilience source/tests exist; complete failure matrix pending |
| Restore | Restore preview/operation recovers the intended project without silent discard or empty replacement | disposable package + restart | Partial; 145.42 and compatibility fixtures remain open |

## Success criteria

The vertical slice is successful only when all of the following are true:

1. One real project is created and identified by UUID/stable manifest identity.
2. A chapter/scene is created and reopened in the same order.
3. Written content survives autosave, close, and reopen.
4. Search or lore linking reaches the intended entity without losing project scope.
5. Exported output contains the expected manuscript text and ordering.
6. Backup integrity is checked before restore.
7. Restore returns the expected project and does not silently create an empty replacement.
8. Missing drive, permission failure, interrupted transfer, corrupt input, and other declared failure states are visible and recoverable.
9. Core remains usable when login, internet, Cloud, Network, Payment, and AI are unavailable.
10. Evidence is captured separately for domain, persistence/restart, UI/integration, Windows native runtime, and release/device gates.

## Failure conditions

Any one of these blocks certification:

- unrecovered data loss;
- project cannot reopen;
- export is missing text;
- backup cannot restore;
- login or internet is required;
- missing drive creates an empty replacement project.

Additional safety blockers:

- restore overwrites the wrong project;
- corrupt package is accepted without a clear failure;
- old data is silently discarded during migration;
- autosave reports success when persistence failed;
- Core startup waits on optional provider/network initialization;
- native UI behavior is inferred from a build rather than captured interaction.

## Evidence matrix

| Evidence | Required command/artefact | Current evidence |
|---|---|---|
| Focused Core tests | Relevant `flutter test` suites | Existing focused suites pass in prior verified gate; rerun after source changes |
| Persistence/restart | Disposable project/database round-trip tests | Present across project/story/resilience tests; compatibility/failure coverage incomplete |
| Analyzer | `flutter analyze` | Prior verified output: `No issues found!`; current shared worktree requires fresh gate before final release claim |
| Full regression | `flutter test` | Prior verified output: `All tests passed — 2014 tests`; historical after previous patch set |
| Linux build | `flutter build linux --debug` | Prior verified |
| Windows dependency/codegen | `flutter pub get`, `dart run build_runner build` | Final snapshot prior verified: pub get PASS, 3007 outputs |
| Windows build | `flutter build windows --debug` | Final snapshot prior verified |
| Native journey | Fresh capture and re-capture after every interaction | `UNVERIFIABLE`; driver returned `snapshot_id_required` after login-screen capture |
| Data safety | 145.42 failure matrix | `IN_PROGRESS` under another executor |
| User validation | 145.45–145.47 | Not completed |

Historical command results above are provenance, not a substitute for a fresh final gate after later concurrent edits.

## Ownership and sequencing

- 145.19 enforces dependency direction.
- 145.20–145.23 prove Core isolation from account, internet, providers, and startup coupling.
- 145.24–145.29 prove writing, character, worldbuilding, focus, search, and lore integration.
- 145.30–145.34 prove autosave, storage, portability, backup, and restore safety.
- 145.35–145.39 prove export, optional AI boundary, navigation/settings reduction, and non-Core preservation.
- 145.40–145.42 prove schema compatibility and failure behavior.
- 145.43–145.47 prove UX, internal certification, and user evidence.
- 145.48–145.50 record decisions and close the sprint only after unresolved blockers are handled or explicitly carried forward.

## Guardrails

1. A route, screen, model, or widget test alone does not certify the journey.
2. A successful Windows build does not certify native interaction.
3. Passing local tests does not certify clean-device behavior or hardware/storage failure recovery.
4. Existing user data and concurrent work remain protected.
5. No schema/migration change is authorized by this contract; D-SCHEMA-01 remains OPEN.
6. No login, token, key, payment value, or production data belongs in fixtures or evidence.
7. Failure conditions are acceptance criteria, not optional follow-up polish.

## Decision

`145.18 Vertical Slice Contract` berstatus **VERIFIED sebagai contract definition**. Journey, success criteria, failure conditions, evidence boundaries, sequencing, dan guardrails telah dipetakan dari sumber kanonik. Certification of the complete journey remains `PENDING/UNVERIFIABLE` until the dedicated implementation, failure, native, and user-validation gates pass.

Langkah berikutnya: `145.19 Core Dependency Direction`.

## Evidence paths

- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
- `docs/audits/core-mvp-scope-lock.md`
- `docs/audits/explicit-deferred-scope.md`
- `docs/audits/dependency-coupling-map.md`
- `docs/audits/existing-user-data-compatibility.md`
- `docs/sprints/sprint-145-product-scope-reset-mvp-recovery.md`

N.B. Path `C:/Users/nepht/...` di atas adalah sumber export Windows; source-of-truth aplikasi tetap WSL `/home/nepht/Projects/void_scriptor_multiplatform`.
