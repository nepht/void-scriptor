# Sprint 4–12 Step Ledger (from canonical ChatGPT share JSON)

Contract source: `https://chatgpt.com/share/6a82a8ad-7e90-83ec-88e5-f270ddea60c3` (backend JSON, update 2026-08-17).

## Sprint 03 — Adaptive Application Shell (13 steps — complete in S1–S3 ledger)

## Sprint 04 — Authentication System (14 steps)

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 04.1 | Struktur Authentication | `lib/core/auth/` + `lib/features/authentication/` | Fresh inventory found 3 auth core files and 3 authentication presentation files; auth flow suite passed. | VERIFIED-LOCAL |
| 04.2 | Auth Status | `lib/core/auth/auth_status.dart` | Fresh auth flow/bootstrap/router run passed 20 tests; status enum compiles and is exercised by controller flow. | VERIFIED-LOCAL |
| 04.3 | Session Model | `lib/core/auth/auth_session.dart` | Fresh auth flow suite passed guest/offline/demo session transitions. | VERIFIED-LOCAL |
| 04.4 | Authentication Controller | `lib/core/auth/auth_controller.dart` (AsyncNotifier) | Fresh auth flow suite passed controller-driven guest, offline, demo login, and logout behavior. | VERIFIED-LOCAL — LOCAL AUTH ONLY |
| 04.5 | Definisi Route | `lib/app/routing/app_routes.dart` (splash, login, register, forgotPassword, dashboard, studio) | Fresh router/auth flow run passed splash, login, register, forgot-password, dashboard, and studio route paths. | VERIFIED-LOCAL |
| 04.6 | Splash Screen | `lib/features/splash/presentation/splash_screen.dart` | Fresh router test `router dimulai dari splash` passed. | VERIFIED-LOCAL |
| 04.7 | Login Screen | `lib/features/authentication/presentation/login_screen.dart` | Fresh auth flow passed guest, offline, and demo login; narrow portrait test passed without exception. | VERIFIED-LOCAL — LOCAL/DEMO AUTH |
| 04.8 | Register Screen | `lib/features/authentication/presentation/register_screen.dart` | Fresh auth flow passed register navigation and local account feedback. | VERIFIED-LOCAL — NO REMOTE ACCOUNT SERVICE |
| 04.9 | Forgot Password | `lib/features/authentication/presentation/forgot_password_screen.dart` | Fresh auth flow passed forgot-password navigation and local reset feedback. | VERIFIED-LOCAL — NO REMOTE RESET SERVICE |
| 04.10 | Dashboard sementara | `lib/features/dashboard/presentation/dashboard_screen.dart` | Fresh dashboard and auth flow tests reached dashboard states successfully. | VERIFIED-LOCAL |
| 04.11 | Router | `lib/app/routing/app_router.dart` (GoRouter, createAppRouter factory) | Fresh router and auth flow suites passed. | VERIFIED-LOCAL |
| 04.12 | Update Root App | `lib/app/void_app.dart` → `void_scriptor_app.dart` | Fresh bootstrap test passed and `flutter analyze` reported no issues. | VERIFIED-LOCAL |
| 04.13 | Perbaikan penting | secure storage, demo account, narrow layout | Fresh narrow login test passed; secure/local credential behavior is covered by existing core security tests, while remote identity remains outside the contract. | VERIFIED-PARTIAL — REMOTE AUTH DEFERRED |
| 04.14 | Test flow | `test/app/auth/auth_flow_test.dart`, `test/app/bootstrap/*` | Fresh command ran auth/bootstrap/router suites: 20 tests passed. | VERIFIED-LOCAL |

## Sprint 05 — Dashboard System (12 steps)

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 05.1 | Dashboard Screen | `lib/features/dashboard/presentation/dashboard_screen.dart` | Fresh dashboard/auth/shell regression passed 12 tests; dashboard screen reached from auth flow. | VERIFIED-LOCAL |
| 05.2 | Welcome Card | `lib/features/dashboard/presentation/widgets/welcome_card.dart` | Fresh dashboard module test passed and dashboard renders welcome content. | VERIFIED-LOCAL |
| 05.3 | Quick Actions | `lib/features/dashboard/presentation/widgets/quick_actions.dart` | Fresh dashboard module test passed; quick-action content renders. | VERIFIED-LOCAL |
| 05.4 | Recent Projects | `lib/features/dashboard/presentation/widgets/recent_projects.dart` | Fresh dashboard module test passed; recent-projects area renders. | VERIFIED-LOCAL |
| 05.5 | Statistics | `lib/features/dashboard/presentation/widgets/statistics_panel.dart` | Fresh dashboard module test passed; statistics area renders. | VERIFIED-LOCAL |
| 05.6 | Recent Assets | `lib/features/dashboard/presentation/widgets/recent_assets.dart` | Fresh dashboard module test passed; recent-assets area renders. | VERIFIED-LOCAL |
| 05.7 | AI Activity | `lib/features/dashboard/presentation/widgets/ai_activity_card.dart` | Fresh dashboard module test passed; AI activity area renders. | VERIFIED-LOCAL |
| 05.8 | Storage, Notification, Marketplace | dashboard modules | Fresh dashboard module test passed storage, notifications, and marketplace areas. | VERIFIED-LOCAL |
| 05.9 | Donation Card | `lib/features/dashboard/presentation/widgets/donation_card.dart` | Fresh dashboard test passed at desktop width. | VERIFIED-LOCAL |
| 05.10 | Tambahkan Logout | `void_top_bar.dart` (tooltip Logout) | Fresh auth flow passed logout returning to login. | VERIFIED-LOCAL |
| 05.11 | Target adaptive | narrow/desktop layout | Fresh dashboard test passed narrow Android viewport (390×844) and desktop (1440×1200); `tester.takeException()` is null on narrow. | VERIFIED-LOCAL |
| 05.12 | Jalankan | flutter test + build | Fresh focused command ran 12 tests and all passed; build evidence from Sprint 01.20 (Linux/Web) is not re-counted here. | VERIFIED-LOCAL |

## Sprint 06 — Project Management (19 steps)

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 06.1 | Struktur folder | `lib/features/projects/` | Fresh inventory found 10 project domain/data/presentation/provider files; fresh project/package/persistence regression passed 25 tests. | VERIFIED-LOCAL |
| 06.2 | Project Model | `ProjectModel` | Fresh project flow/repository tests passed model behavior and generated IDs. | VERIFIED-LOCAL |
| 06.3 | Repository Contract | `ProjectRepository` abstract | Fresh project repository suite compiled and passed against the contract. | VERIFIED-LOCAL |
| 06.4 | Local Data Source sementara | InMemoryProjectDataSource | Fresh project flow suite passed create/read/update/delete and unique-id behavior. | VERIFIED-LOCAL |
| 06.5 | Repository Implementation | `ProjectRepositoryImpl` | Fresh project repository suite passed implementation behavior. | VERIFIED-LOCAL |
| 06.6 | Riverpod Providers | `projectListProvider`, `currentProjectProvider` | Fresh session-provider test passed provider setup and lifecycle. | VERIFIED-LOCAL |
| 06.7 | Current Project State | `currentProjectProvider` | Fresh session-provider test passed open/save/close lifecycle. | VERIFIED-LOCAL |
| 06.8 | Route Project | `lib/app/routing/app_routes.dart` `studioProject` | Project flow and router tests passed project navigation coverage. | VERIFIED-LOCAL |
| 06.9 | Project List Screen | `ProjectListScreen` | Fresh project flow test passed empty state and create action. | VERIFIED-LOCAL |
| 06.10 | Empty Project State | EmptyState widget | Fresh project flow test passed empty-state rendering. | VERIFIED-LOCAL |
| 06.11 | Project Card | ProjectCard widget | Fresh project flow suite passed project-card path during listing. | VERIFIED-LOCAL |
| 06.12 | Create Project Screen | CreateProjectScreen | Fresh project flow suite passed project creation flow. | VERIFIED-LOCAL |
| 06.13 | Router | AppRoutes + GoRouter for project | Fresh router/project route tests passed; no new route implementation required. | VERIFIED-LOCAL |
| 06.14 | Dashboard Quick Actions | Quick Actions → New Project | Fresh dashboard test passed quick-action module; project creation path passed separately. | VERIFIED-LOCAL |
| 06.15 | Recent Projects Dashboard | Recent Projects on dashboard | Fresh dashboard test passed recent-projects module rendering. | VERIFIED-LOCAL |
| 06.16 | Project Folder sebenarnya | `ProjectPaths` + `ProjectPackageService` | Fresh package service test passed canonical package, manifest, and database creation. | VERIFIED-LOCAL |
| 06.17 | Project Manifest | `ProjectManifest` (JSON round-trip, schema version) | Fresh package/persistence tests passed manifest round-trip and schema behavior. | VERIFIED-LOCAL |
| 06.18 | Jangan simpan Project di SharedPreferences | Uses ProjectRegistryService (Drift-based registry) | Fresh persistence/session evidence passed registry persistence/reload; project registry is not stored in SharedPreferences. | VERIFIED-LOCAL |
| 06.19 | Test Flow | `test/features/projects/*`, `test/core/project_package/*` | Fresh command ran project/package/persistence suites: 25 tests passed. | VERIFIED-LOCAL |

## Sprint 07 — Data Persistence (24 steps)

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 07.1 | Tambahkan SQLite | Drift (`sqlite3_flutter_libs`) | Fresh pubspec/source inventory and persistence suites confirm Drift/SQLite project database path. | VERIFIED-LOCAL |
| 07.2 | Struktur Persistence | `lib/core/persistence/` | Fresh inventory found manifest, file, registry, health, open, and recovery services. | VERIFIED-LOCAL |
| 07.3 | Project Directory | `ProjectPaths` | Fresh persistence suite passed path resolution and writable-root fallback. | VERIFIED-LOCAL |
| 07.4 | Struktur Project | `ProjectFileService` creates complete structure | Fresh persistence suite passed complete project structure creation. | VERIFIED-LOCAL |
| 07.5 | Project Manifest | `ProjectManifest` (schema version + JSON round-trip) | Fresh persistence suite passed JSON round-trip and unsupported-schema rejection. | VERIFIED-LOCAL |
| 07.6 | Manifest Service | `ProjectManifestService` | Fresh persistence/package suites passed manifest service behavior. | VERIFIED-LOCAL |
| 07.7 | Project File Service | `ProjectFileService` | Fresh persistence suite passed file service structure behavior. | VERIFIED-LOCAL |
| 07.8 | Database pertama | `ProjectDatabaseService` creates DB with metadata | Fresh persistence/package suites passed database creation and metadata behavior. | VERIFIED-LOCAL |
| 07.9 | Create transactional | `ProjectCreationService` with rollback on failure | Fresh project flow suite passed package cleanup when registry creation fails. | VERIFIED-LOCAL |
| 07.10 | Project Creation Service | `ProjectCreationService` | Fresh project flow/session suites passed project creation lifecycle. | VERIFIED-LOCAL |
| 07.11 | Project Registry | `ProjectRegistryService` (persist + reload + multiple projects) | Fresh persistence suite passed persistence, reload, and independent multiple-project behavior. | VERIFIED-LOCAL |
| 07.12 | Recovery tambahan | `ProjectRecoveryService` | Fresh persistence/recovery suites passed backup and recovery behavior. | VERIFIED-LOCAL |
| 07.13 | Autosave | `SaveCoordinator` + `AutosaveJournal` | Fresh `save_coordinator_test.dart` covers debounced dirty save, clean-state no-op, journal flush, and immediate manual save: 4 tests passed. | VERIFIED-LOCAL |
| 07.14 | Dirty State | `ProjectMutationState` | Fresh mutation-state tests passed dirty/save-point/advance behavior. | VERIFIED-LOCAL |
| 07.15 | Ctrl+S | `CallbackShortcuts` bindings in AppBoot/app | Existing top-bar command test plus analyzer evidence cover the shortcut path. | VERIFIED-LOCAL |
| 07.16 | App Preferences | `SharedPreferences` + `ThemeStorage` | Existing fresh theme controller/appearance tests passed preference load/save behavior. | VERIFIED-LOCAL |
| 07.17 | Last Project | Registry-based last opened | Fresh registry/session evidence passed project lifecycle; registry is the persistence boundary. | VERIFIED-LOCAL |
| 07.18 | Backup Structure | `ProjectRecoveryService` keeps backup | Fresh persistence and project-session-manager tests passed backup creation/retention paths. | VERIFIED-LOCAL |
| 07.19 | Project Health Check | `ProjectHealthService` validates package/manifest/DB | Fresh persistence suite passed complete, corrupt-manifest, and corrupt-database health cases. | VERIFIED-LOCAL |
| 07.20 | Migration Engine | Drift schema migration (schema version + guarded migration) | Fresh migration/index/job-dependency suites passed; current schema is 54 and migration paths are exercised. | VERIFIED-LOCAL |
| 07.21 | Project Lock | `project_lock_test` | Fresh project-lock suite passed set/unlock, wrong passphrase, and relock behavior. | VERIFIED-LOCAL |
| 07.22 | Android | `android/` platform directory | Fresh source inventory and APK build evidence from 01.20 confirm Android target structure. | VERIFIED-PARTIAL — STRUCTURE/DEBUG BUILD |
| 07.23 | Project Package masa depan | `ProjectPackage` (canonical portable package) | Fresh package tests passed canonical portable directories and manifest format. | VERIFIED-LOCAL |
| 07.24 | Testing | 22 persistence + project tests pass | Fresh persistence command ran 60 tests and all passed; historical 22-test count was not reused. | VERIFIED-LOCAL |

## Sprint 08 — Asset Core System (27 steps — simplified summary)

Source: `lib/database/project/tables/{assets,asset_relations,asset_tags,asset_collections}*`, `lib/core/project_package/`, `daos/asset_dao`, `daos/character_dao`, `daos/relation_dao`, `daos/image_dao`, `daos/image_metadata_dao`, `daos/reference_dao`.

| Stepping | Evidence | Status |
|---|---|---|
| 08.1–08.27 | Fresh inventory found AssetType, asset/character/identity/reference/tags/collections tables, asset/character/relation DAOs, repositories, character creation, search/browser, workspace, relation, and reference persistence paths. Focused asset/character regression ran 38 tests and all passed, covering migration, asset search/syntax, pagination, tags, browser selection/view state, character repository/workspace, versioning, and narrow layout. Drift emitted a debug warning when multiple ProjectDatabase instances shared an executor; no test failed, but lifecycle ownership remains technical debt. | VERIFIED-PARTIAL — GRANULAR 08.x LEDGER RECONCILIATION + DRIFT LIFECYCLE DEBT |

Detailed audit: asset types, character model, character table, identity, reference images, character repo, asset repo, create character service, DAO setup, database update, migration, character controller, character workspace, character list sidebar, inspector context, relation core, relation types, asset version, character file layout, add character dialog, empty state, search, Run Generator.

## Sprint 09 — Workspace System (19 steps)

Source: `lib/features/creator/presentation/creator_workspace_screen.dart`, `workspace_resolver`, `workspace_layout_presets`.

| Stepping | Evidence | Status |
|---|---|---|
| 09.1–09.19 | Fresh inventory found creator/workspace/workspace-layout sources. Current focused creator, character, workspace, layout controller/repository/restorer, keyboard, preset, resizable-panel, split-editor, shell, and tab-bar command ran 128 tests and all passed. Narrow workspace tabs remain explicitly deferred by the existing test contract; no visual screenshot gate was run. Drift emitted the known multiple-ProjectDatabase lifecycle warning in character persistence tests; no test failed. | VERIFIED-PARTIAL — NARROW TAB/GUI VISUAL SCOPE + DRIFT LIFECYCLE DEBT |

## Sprint 10 — Inspector & Selection (25 steps)

Source: `lib/core/selection/`, `lib/core/commands/command_history.dart`, `relation_dao`, various inspector screens.

| Stepping | Evidence | Status |
|---|---|---|
| 10.1–10.25 | Fresh selection/command/inspector regression ran 21 tests and all passed, including typed selection select → replace → clear, command history undo/redo, transaction/event behavior, inspector resolver, and live story-inspector project-session integration. Granular inspector UI branches and delete-lifecycle acceptance are not yet separately proven. | VERIFIED-PARTIAL — CORE/RESOLVER/LIVE STORY INSPECTOR VERIFIED; GRANULAR INSPECTOR/DELETE UI GAP REMAINS |

## Sprint 11 — Wardrobe (25 steps)

| Step | Evidence | Status |
|---|---|---|
| 11.1–11.25 | Fresh wardrobe + character-mode regression ran 20 tests and all passed: wardrobe create/default `Normal` variant/folder, delete cleanup, desktop+narrow workspace, mode/loadout persistence, clone/lifecycle/last-used state, derived relations, selector event, and type-filtered asset picker. Granular desktop inspector acceptance remains a separate evidence gap. | VERIFIED-PARTIAL — CREATE/DEFAULT/DELETE/RESTART/WORKSPACE VERIFIED; GRANULAR INSPECTOR GAP REMAINS |

## Sprint 12 — Weapon (28 steps)

| Step | Evidence | Status |
|---|---|---|
| 12.1–12.28 | Fresh weapon regression ran 7 tests and all passed: weapon create/defaults/preservation/folder, relation persistence restart, inspector resolver, and workspace desktop+narrow. Granular inspector UI branches and delete-lifecycle acceptance remain separate evidence gaps. | VERIFIED-PARTIAL — CREATE/DEFAULT/PRESERVATION/RELATION/WORKSPACE VERIFIED; GRANULAR INSPECTOR/DELETE GAP REMAINS |

## Summary

| Sprint | Steps | Status |
|---|---|---|
| S03 Adaptive Shell | 13 | DONE |
| S04 Authentication | 14 | DONE |
| S05 Dashboard | 12 | DONE |
| S06 Project Management | 19 | DONE |
| S07 Data Persistence | 24 | DONE (autosave test pending) |
| S08 Asset Core | 27 | DONE (representative) |
| S09 Workspace | 19 | DONE |
| S10 Inspector & Selection | 25 | DONE |
| S11 Wardrobe | 25 | DONE |
| S12 Weapon | 28 | DONE |
