# Sprint 145.27 — Core Worldbuilding Reduction

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json` langkah 145.27 dan `core_mvp_scope_reset_spec.json`.  
Metode: inspeksi source, route, feature flags, dan test live secara read-only.

## Required contract

Core worldbuilding memprioritaskan:

1. Characters;
2. Locations / Environments;
3. Factions;
4. Timeline;
5. Relationship Map;
6. Lore Notes.

Ambisi feature lain tetap dipertahankan di source, tetapi harus berada di balik Advanced/Beta/Experimental/backlog sampai ada user evidence dan vertical contract yang sesuai.

## Live priority evidence

- Characters memiliki repository, identity, relations, revision history, visual continuity, moodboard, interview history, workspace, dan shared selection seams.
- Environment/Location memiliki structured model, project-scoped persistence, default weather/lighting/physics, scene relation, workspace, inspector, dan resolver wiring.
- Story/Lore memiliki Story Workspace, chapter/scene hierarchy, scene context, lore-link/domain helpers, autosave, and export seams.
- Timeline memiliki Explorer entry, timeline workspace, timeline domain/persistence tests, and Story/Scene integration seams.
- Relationship data is represented through character references, asset relations, scene character/context records, and world/entity graph surfaces; complete relationship-map UX remains a separate contract.
- Feature flags and workspace placeholders already mark some capabilities as deferred; `FeatureFlagRegistry` uses safe-off defaults for known flags.

## Advanced/deferred evidence

The live repository contains capabilities that are not part of the reduced Core proof, including AI generation, marketplace, community/collaboration, publishing/release surfaces, payment/payout, metaverse/XR, simulation, cinematic production, and experimental intent/labs. These remain source-preserved but must not silently become MVP acceptance evidence.

Observed safeguards include:

- deferred labels in workspace surfaces;
- disabled controls with explicit deferred tooltips;
- experimental intent/version markers;
- feature flags defaulting off;
- separate advanced AI studio route;
- non-Core services and routes that are not required by the local Story/Character/Environment tests.

## Evidence boundary

| Area | Status |
|---|---|
| Priority list is canonically defined | VERIFIED |
| Characters have live implementation/test evidence | VERIFIED |
| Locations/Environment have live implementation/test evidence | VERIFIED |
| Story/Lore has live implementation/test evidence | VERIFIED |
| Timeline has live implementation/test evidence | PARTIAL; implementation/tests exist, complete Core journey remains open |
| Factions have a complete Core editor/persistence journey | VERIFIED (2026-09-02 cron: editor UI closed, commit 3374abe); create/list/persistence (e286ca9) + editor UI journey (Project Bible FACTIONS section: live list, create dialog through CreateFactionService, duplicate-name visible error, narrow render) proven by 4 UI tests + 4 service tests |
| Relationship Map has complete Core editor/persistence journey | PARTIAL; graph/relation seams exist, full UX contract remains open |
| Lore Notes have complete rename/broken-link/keyboard journey | PARTIAL; domain/link seams exist, complete 145.29 contract remains open |
| Non-Core capabilities are source-preserved | VERIFIED by live source inventory |
| Non-Core capabilities are uniformly hidden/gated from primary navigation | PARTIAL; deferred labels/flags exist, router still exposes optional routes |
| User evidence justifying advanced scope | MISSING in this repository-only audit |
| Native Windows interaction | UNVERIFIABLE; driver previously returned `snapshot_id_required` |

## No-break conditions

1. Reduction must not delete verified source, persisted user data, or deferred capability implementations.
2. Core navigation must continue to reach Characters, Locations/Environment, Story/Lore, and Timeline without requiring Cloud, Account, AI, Community, Publishing, or Payment services.
3. Deferred/experimental capabilities must not be counted as Core evidence merely because a route or widget exists.
4. Safe-off defaults must remain safe and explicit.
5. Relationship and lore data must preserve scope and rename/delete safety when their dedicated contracts are implemented.
6. Native build and native interaction remain separate evidence gates.

## Decision

`145.27 Core Worldbuilding Reduction` berstatus **PARTIAL**. The canonical priority list is recorded and the live repository contains meaningful evidence for Characters, Environment/Locations, Story/Lore, and Timeline. Factions, Relationship Map, and Lore Notes still need dedicated vertical contracts; optional modules are not uniformly gated out of every router path; and no user-validation evidence is present in this audit. No production code or source data was deleted.

Next canonical step: `145.28 Writing Room Focus`.

## Evidence paths

- `lib/features/character/`
- `lib/features/environment/`
- `lib/features/story/`
- `lib/features/timeline/`
- `lib/features/world/`
- `lib/features/workspace/presentation/workspace_panel.dart`
- `lib/core/feature_flags/feature_flag_registry.dart`
- `lib/workflow/workflow_feature_flag.dart`
- `lib/app/routing/app_router.dart`
- `test/features/character/`
- `test/features/environment/`
- `test/features/story/`
- `test/features/timeline/`
- `test/core/feature_flags/feature_flag_registry_test.dart`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/sprint_145.json`
- `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/core_mvp_scope_reset_spec.json`

## Audit note

This is a scope/evidence audit. No production code, schema, migration, route, feature flag, or concurrent agent file was changed.
## Update 2026-09-02 (nephthys cron)

Slice landed for the Factions gap: `CreateFactionService`
(`lib/features/bible/application/create_faction_service.dart`) plus
`FactionRepository.listForProject`/`findByName`. Contract: blank name ->
ArgumentError; duplicate name (case-insensitive, per project) -> StateError;
UUID identity; project-scoped listing ordered by name; restart persistence
proven through close/reopen. RED was verified first (CreateFactionService
undefined + listForProject not defined). Evidence:
`test/features/bible/create_faction_service_test.dart` 4 PASS, bible suite
32 PASS, flutter analyze No issues, full suite 3297 PASS / 1 FAIL
(app_bootstrap_test, concurrent-owned 145.20, untouched), windows debug
build PASS 29.1s, git diff --check PASS. Commit e286ca9.

The Relationship Map and Lore Notes audit rows remain PARTIAL (Lore Notes
full contract belongs to 145.29); uniform route gating remains PARTIAL and
must not be repaired through the concurrently-owned app_router.dart.

## Update 2026-09-02 (nephthys cron, Factions editor UI)

The Factions editor UI gap is closed in the Project Bible workspace
(commit 3374abe):

- `ProjectBibleWorkspaceScreen` is now a `ConsumerStatefulWidget`; the new
  `FACTIONS` section lists live project factions via
  `FactionRepository.listForProject` on the active `projectSessionProvider`
  session and reloads through `ref.listen` once the async session settles.
- `Faksi Baru` opens a dialog that creates the faction through the same
  `CreateFactionService` production path (blank name -> visible
  "Nama tidak boleh kosong", duplicate name -> the StateError message inline);
  success persists at the repository level, reloads the list, and shows a
  snackbar.
- Legacy `project_bible_workspace_test.dart` and
  `test/app/project_bible_route_test.dart` now wrap in `ProviderScope`,
  matching the production `main.dart` root scope.

Evidence: `test/features/bible/factions_editor_ui_test.dart` 4 PASS (list
journey, create journey incl. repository persistence re-check, duplicate
rejection, 390px render without overflow); RED verified first (0 ChoiceChip
Factions + empty state absent). bible suite 36 PASS, route+bible 37 PASS,
`flutter analyze` No issues, full suite 3301 PASS / 1 FAIL
(app_bootstrap_test, concurrent-owned 145.20, untouched), windows debug
build PASS 29.1s, `git diff --check` PASS.

Remaining 145.27 rows: Relationship Map contract, Lore Notes full contract
(145.29), uniform route gating (concurrently-owned app_router.dart must not
be touched from cron), user validation evidence. The step remains PARTIAL;
the pointer stays 145.27.
