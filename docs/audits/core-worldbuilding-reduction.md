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
| Timeline has live implementation/test evidence | VERIFIED (2026-09-02 cron: scene-to-timeline journey closed; production Material fix + drag-to-command-to-DB journey + move persistence restart) |
| Factions have a complete Core editor/persistence journey | VERIFIED (2026-09-02 cron: editor UI closed, commit 3374abe); create/list/persistence (e286ca9) + editor UI journey (Project Bible FACTIONS section: live list, create dialog through CreateFactionService, duplicate-name visible error, narrow render) proven by 4 UI tests + 4 service tests |
| Relationship Map has complete Core editor/persistence journey | VERIFIED (2026-09-02 cron: contract 93470b3 + evidence closure 2026-09-02b; map service resolved-name rows, live-session Bible RELATIONSHIP MAP section, restart persistence via close/reopen, empty state, narrow 390px render, non-character endpoints keep raw ids; relation core/delete/display/journey suites) |
| Lore Notes have complete rename/broken-link/keyboard journey | VERIFIED (2026-09-02 cron d: cross-workspace search UI journey CLOSED, commits terpisah feat+docs. `GlobalSearchLauncher` (`lib/features/workspace/application/global_search_launcher.dart`) menyatukan 4 domain Core dalam satu query — baris universal `Assets` (character/environment/story via `AssetDao.getAllAssets()`) + tabel `Factions` (via `FactionRepository.listForProject`); ranking deterministik exact>prefix>substring lalu abjad, scope per proyek, filter tipe, query kosong menghasilkan kosong. UI: `showGlobalSearchSheet` (`lib/features/workspace/presentation/global_search_sheet.dart`) dipanggil dari tombol 'Cari di Proyek' di `ProjectOverview` (workspace tanpa seleksi), hasil dipilih menulis SelectionModel ter-typed ke shared `selectionProvider` (jalur produksi yang sama dengan Explorer) dan resolver membuka Character Workspace; hit faksi memicu callback navigasi khusus. Journey test live-session `test/features/workspace/global_search_journey_test.dart` 2 PASS (RED wiring terverifikasi via stash round-trip: tanpa wiring, 'Cari di Proyek' 0 widgets); launcher test `global_search_launcher_test.dart` 1 PASS RED-terverifikasi (Method not found); workspace+assets 30 PASS; story+bible+character 249 PASS; analyze workspace No issues; diff --check PASS; native interaction tetap UNVERIFIABLE dari cron |
| Non-Core capabilities are source-preserved | VERIFIED by live source inventory |
| Non-Core capabilities are uniformly hidden/gated from primary navigation | VERIFIED (rekonsiliasi 2026-09-09: commit 117f157 menggate 11 demo route + publishing/plugins via RouteCapabilityGuard.canonicalRules (13 rules, fallback /dashboard); kedua site router membungkus redirect guard; tidak ada surface navigasi shell/dashboard yang push/go ke route gated; gate fresh HEAD b7ad693 test/core/capabilities 30/30 PASS; route gated hanya terjangkau deep-link manual) |
| User evidence justifying advanced scope | MISSING in this repository-only audit |
| Native Windows interaction | VERIFIED terbatas (run146 2026-09-09: journey native penuh create project -> story A/B -> draft -> switch -> characters -> kembali dieksekusi via computer-use pada build Debug HEAD 7ce1641 dgn isolasi storage; journey lain di luar cakupan run itu tetap UNVERIFIABLE dari cron tanpa sesi desktop) |

## No-break conditions

1. Reduction must not delete verified source, persisted user data, or deferred capability implementations.
2. Core navigation must continue to reach Characters, Locations/Environment, Story/Lore, and Timeline without requiring Cloud, Account, AI, Community, Publishing, or Payment services.
3. Deferred/experimental capabilities must not be counted as Core evidence merely because a route or widget exists.
4. Safe-off defaults must remain safe and explicit.
5. Relationship and lore data must preserve scope and rename/delete safety when their dedicated contracts are implemented.
6. Native build and native interaction remain separate evidence gates.

## Decision

`145.27 Core Worldbuilding Reduction` berstatus **PARTIAL**. The evidence table above records landed verification for Characters, Environment/Locations, Timeline, Factions, Relationship Map, and the Lore Notes journey. Those completed slices must not be selected again solely from the older narrative updates below. Remaining boundaries are user-validation evidence and native Windows interaction proof (uniform route gating ditutup: lihat baris gating pada tabel evidence, commit 117f157 + test/core/capabilities 30/30 PASS di HEAD 2026-09-09). A passing analyzer, test suite, or build does not by itself close those boundaries. No production code or source data was deleted.

Current unresolved canonical step: `145.27`, consistent with `.hermes/ROADMAP_STATE.json` and the roadmap guard. Do not advance the pointer from this audit alone. The dated updates below preserve historical evidence and may describe gaps subsequently closed in the evidence table.

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

## Update 2026-09-04 — workspace domain separation

The workspace chrome now follows the selected Core domain instead of showing
the same static Character tabs for every asset:

- Novel Workspace: Outline, Manuscript, Lore Links, Versions, Export;
- Character Workspace: Profile, Identity, Relationships, Visuals, Notes;
- Worldbuilding Workspace: Overview, Locations, Factions, Timeline, Lore Notes;
- supporting media/tools remain in a neutral Asset Workspace rather than being
  presented as Novel, Character, or Worldbuilding data.

The labels are descriptive structure, not dead controls. The live editor below
continues to resolve through the existing typed selection path. Narrow-width
widget coverage switches Novel → Character → Worldbuilding at 390×844 without
overflow. The workspace suite also closes a test-harness database overlap that
previously emitted Drift multiple-database warnings during project-scope search
verification. This slice improves domain separation but does not close 145.27:
uniform non-Core route gating, user validation, and native Windows interaction
proof remain open.
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


## Update 2026-09-02 (nephthys cron, Relationship Map contract)

Step 145.27 Core Worldbuilding Reduction - the Relationship Map contract row
is closed with an executable vertical slice (commit 93470b3):

- Service layer: `CharacterRelationMapService.mapForProject` resolves every
  project relation whose endpoints include characters into
  `CharacterRelationMapEntry` rows with real names; non-character endpoints
  keep their asset id so the map stays honest. Backed by an additive
  `RelationDao.getProjectRelations` query (no schema change, no codegen).
- UI layer: Project Bible workspace gains a RELATIONSHIP MAP section
  (ConsumerStatefulWidget over `projectSessionProvider`, ref.listen session
  settle reload, empty hint, narrow-safe card layout) placed after the
  FACTIONS section.
- RED verified first: `CharacterRelationMapService` undefined (service test
  load failure), then "RELATIONSHIP MAP" 0 widgets in the UI test, before
  each GREEN.

Evidence: focused relations+bible 49 PASS, character_relation_map_service_test
2 PASS, relationship_map_ui_test 2 PASS, `flutter analyze` No issues (after
removing one unused import), full suite 3305 PASS / 1 FAIL
(app_bootstrap_test, concurrent-owned 145.20, untouched), windows debug build
PASS 34.2s, `git diff --check` PASS, roadmap guard PASS pre+post.

Remaining 145.27 rows: Lore Notes full contract (145.29), uniform route
gating (concurrently-owned app_router.dart must not be touched from cron),
user validation evidence. The step remains PARTIAL; the pointer stays 145.27.

## Update 2026-09-02 (nephthys cron, Timeline Core journey)

Step 14527 Core Worldbuilding Reduction - the Timeline journey row is closed
with an executable vertical slice:

- Production bug found and fixed: opening Timeline from a real scene
  (SceneWorkspaceScreen._openTimeline -> MaterialPageRoute) rendered
  TimelineWorkspaceScreen without a Material ancestor, and TimelineClip's
  InkWell crashed with No Material widget found. Fix wraps the pushed route
  in a Scaffold (lib/features/story/presentation/scene_workspace_screen.dart).
  The journey test reproduced this crash before the fix (RED for real).
- test/features/timeline/timeline_scene_journey_test.dart proves the full
  production path: live project session -> SceneWorkspaceScreen Open
  Timeline -> ensureTimelineForScene -> TimelineWorkspaceScreen with the
  live clip -> drag 160px -> MoveTimelineClipCommand through the mutation
  bus -> clip startSeconds 2 persisted in the live SQLite database.
- test/features/timeline/timeline_move_persistence_test.dart proves a
  moved clip timing survives close/reopen of the project database (schema
  59).

Evidence: timeline suite 13 PASS, story+workspaces 197 PASS, flutter
analyze No issues, git diff --check PASS, windows debug build PASS 26.9s.

Remaining 14527 rows: Lore Notes full contract (14529), uniform route
gating (concurrently-owned app_router.dart must not be touched from cron),
user validation evidence. The step remains PARTIAL; the pointer stays
14527.


## Update 2026-09-02b (nephthys cron, Relationship Map evidence closure)

Step 14527 Core Worldbuilding Reduction - the Relationship Map row is closed
as VERIFIED by completing the missing execution boundaries of the landed
contract (commit 93470b3) without new production code:

- Restart persistence: character_relation_map_service_test now proves a
  character-to-character relation created through CreateRelationService is
  re-resolved by CharacterRelationMapService.mapForProject after the project
  database is closed and reopened (schema 59, real SQLite on disk).
- Narrow layout: relationship_map_ui_test now renders the RELATIONSHIP MAP
  section with resolved names at 390x844 and asserts
  tester.takeException() is null (no RenderFlex overflow).
- Existing boundaries re-confirmed live this run: live-session UI with
  resolved names, empty-state hint, focused relations+bible suites.

Evidence: focused relationship_map tests 6 PASS (3 UI + 3 service, RED
attempt not applicable - PASS-first evidence on landed contract, same pattern
as 145.25g), bible+relations suites 51 PASS, flutter analyze No issues
(9.7s), git diff --check PASS, full flutter test and windows debug build
executed in this run (see ledger entry for final counts).

Remaining 14527 rows: Lore Notes full contract (14529), uniform route
gating (concurrently-owned app_router.dart must not be touched from cron),
user validation evidence. The step remains PARTIAL; the pointer stays
14527.

## Update 2026-09-02 (nephthys cron, universal rename wiring)

The remaining actionable 145.27 row was Lore Notes rename wiring. Slice
landed in `RenameCharacterCommand`
(`lib/features/character/application/rename_character_command.dart`): an
optional `loreRetarget` parameter now defaults to `const
LoreBacklinkService()`, so every production construction site
(`CharacterController.rename`, `CommandTypeRegistry` replay in
`project_session_manager.dart`) gains rename-safe lore links without
touching concurrently-owned files. `_rename` retargets link segments from
the other name toward the applied name: execute/redo move `[[oldName]]` to
`[[newName]]`, undo moves them back; plain text and escaped `\[[name]]`
literals are untouched (verified by assertion). RED was verified twice:
`No named parameter with the name 'loreRetarget'` (test 1) and unchanged
content without the default wiring, staged via stash round-trip (test 2).
Evidence: `test/features/character/rename_character_command_lore_retarget_test.dart`
2 PASS; rename/backlinks focused suites 18 PASS; character +
project_resilience + commands regression 120 PASS; flutter analyze No
issues; windows debug build PASS 27.7s (final HEAD); git diff --check
PASS. Commit 14e1ae8. Full suite: 3314 PASS / 1 FAIL
(app_bootstrap_test, concurrent-owned 145.20, untouched).

The step remains PARTIAL: cross-workspace search UI journey (145.29),
uniform route gating (concurrently-owned app_router.dart), native
interaction, and user validation evidence stay open. The pointer stays
145.27.
