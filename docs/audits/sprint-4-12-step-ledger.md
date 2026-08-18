# Sprint 4–12 Step Ledger (from canonical ChatGPT share JSON)

Contract source: `https://chatgpt.com/share/6a82a8ad-7e90-83ec-88e5-f270ddea60c3` (backend JSON, update 2026-08-17).

## Sprint 03 — Adaptive Application Shell (13 steps — complete in S1–S3 ledger)

## Sprint 04 — Authentication System (14 steps)

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 04.1 | Struktur Authentication | `lib/core/auth/` + `lib/features/authentication/` | present | DONE |
| 04.2 | Auth Status | `lib/core/auth/auth_status.dart` (enum checking/authenticated/unauthenticated/guest/offline) | auth tests + compile | DONE |
| 04.3 | Session Model | `lib/core/auth/auth_session.dart` | auth tests | DONE |
| 04.4 | Authentication Controller | `lib/core/auth/auth_controller.dart` (AsyncNotifier) | auth flow tests | DONE |
| 04.5 | Definisi Route | `lib/app/routing/app_routes.dart` (splash, login, register, forgotPassword, dashboard, studio) | router tests | DONE |
| 04.6 | Splash Screen | `lib/features/splash/presentation/splash_screen.dart` | router test: "router dimulai dari splash" | DONE |
| 04.7 | Login Screen | `lib/features/authentication/presentation/login_screen.dart` | auth flow test: guest/offline/demo login | DONE |
| 04.8 | Register Screen | `lib/features/authentication/presentation/register_screen.dart` | auth flow test: register submit gives local account feedback | DONE |
| 04.9 | Forgot Password | `lib/features/authentication/presentation/forgot_password_screen.dart` | auth flow test: forgot password submit gives local reset feedback | DONE |
| 04.10 | Dashboard sementara | `lib/features/dashboard/presentation/dashboard_screen.dart` | dashboard tests pass | DONE |
| 04.11 | Router | `lib/app/routing/app_router.dart` (GoRouter, createAppRouter factory) | app_router test + auth_flow test | DONE |
| 04.12 | Update Root App | `lib/app/void_app.dart` → `void_scriptor_app.dart` | bootstrap test | DONE |
| 04.13 | Perbaikan penting | secure storage, demo account, narrow layout | login narrow viewport test pass | DONE |
| 04.14 | Test flow | `test/app/auth/auth_flow_test.dart`, `test/app/bootstrap/*` | 43 auth+app tests pass | DONE |

## Sprint 05 — Dashboard System (12 steps)

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 05.1 | Dashboard Screen | `lib/features/dashboard/presentation/dashboard_screen.dart` | dashboard test | DONE |
| 05.2 | Welcome Card | Widgets in dashboard | dashboard renders | DONE |
| 05.3 | Quick Actions | Quick action modules | dashboard renders | DONE |
| 05.4 | Recent Projects | Recent projects area | dashboard renders | DONE |
| 05.5 | Statistics | Statistics area | dashboard renders | DONE |
| 05.6 | Recent Assets | Recent assets area | dashboard renders | DONE |
| 05.7 | AI Activity | AI activity area | dashboard renders | DONE |
| 05.8 | Storage, Notification, Marketplace | dashboard modules | dashboard renders | DONE |
| 05.9 | Donation Card | donation module | donation_test passes | DONE |
| 05.10 | Tambahkan Logout | `void_top_bar.dart` (tooltip Logout) | auth flow test: logout returns to login | DONE |
| 05.11 | Target adaptive | narrow/desktop layout | narrow viewport test pass | DONE |
| 05.12 | Jalankan | flutter test + build | 2 tests + varified | DONE |

## Sprint 06 — Project Management (19 steps)

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 06.1 | Struktur folder | `lib/features/projects/` | present | DONE |
| 06.2 | Project Model | `ProjectModel` | project_repository_test | DONE |
| 06.3 | Repository Contract | `ProjectRepository` abstract | project_repository_test | DONE |
| 06.4 | Local Data Source sementara | InMemoryProjectDataSource | project_repository_test | DONE |
| 06.5 | Repository Implementation | `ProjectRepositoryImpl` | project_repository_test | DONE |
| 06.6 | Riverpod Providers | `projectListProvider`, `currentProjectProvider` | project_session_provider_test | DONE |
| 06.7 | Current Project State | `currentProjectProvider` | project_session_provider_test | DONE |
| 06.8 | Route Project | `lib/app/routing/app_routes.dart` `studioProject` | router test | DONE |
| 06.9 | Project List Screen | `ProjectListScreen` | project_flow_test: shows empty state | DONE |
| 06.10 | Empty Project State | EmptyState widget | project_flow_test | DONE |
| 06.11 | Project Card | ProjectCard widget | project_flow_test | DONE |
| 06.12 | Create Project Screen | CreateProjectScreen | project_flow_test | DONE |
| 06.13 | Router | AppRoutes + GoRouter for project | project_bible_route_test | DONE |
| 06.14 | Dashboard Quick Actions | Quick Actions → New Project | dashboard test | DONE |
| 06.15 | Recent Projects Dashboard | Recent Projects on dashboard | dashboard test | DONE |
| 06.16 | Project Folder sebenarnya | `ProjectPaths` + `ProjectPackageService` | project_package_service_test | DONE |
| 06.17 | Project Manifest | `ProjectManifest` (JSON round-trip, schema version) | project_persistence_test | DONE |
| 06.18 | Jangan simpan Project di SharedPreferences | Uses ProjectRegistryService (Drift-based registry) | project_persistence_test | DONE |
| 06.19 | Test Flow | `test/features/projects/*`, `test/core/project_package/*` | 7 project tests pass | DONE |

## Sprint 07 — Data Persistence (24 steps)

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 07.1 | Tambahkan SQLite | Drift (`sqlite3_flutter_libs`) | pubspec.yaml | DONE |
| 07.2 | Struktur Persistence | `lib/core/persistence/` | present | DONE |
| 07.3 | Project Directory | `ProjectPaths` | project_persistence_test | DONE |
| 07.4 | Struktur Project | `ProjectFileService` creates complete structure | project_persistence_test | DONE |
| 07.5 | Project Manifest | `ProjectManifest` (schema version + JSON round-trip) | project_persistence_test | DONE |
| 07.6 | Manifest Service | `ProjectManifestService` | project_persistence_test | DONE |
| 07.7 | Project File Service | `ProjectFileService` | project_persistence_test | DONE |
| 07.8 | Database pertama | `ProjectDatabaseService` creates DB with metadata | project_persistence_test | DONE |
| 07.9 | Create transactional | `ProjectCreationService` with rollback on failure | project_flow_test | DONE |
| 07.10 | Project Creation Service | `ProjectCreationService` | project_flow_test | DONE |
| 07.11 | Project Registry | `ProjectRegistryService` (persist + reload + multiple projects) | project_persistence_test | DONE |
| 07.12 | Recovery tambahan | `ProjectRecoveryService` | project_persistence_test | DONE |
| 07.13 | Autosave | — | pending explicit test | PARTIAL |
| 07.14 | Dirty State | `ProjectMutationState` | project_mutation_state_test | DONE |
| 07.15 | Ctrl+S | `CallbackShortcuts` bindings in AppBoot/app | top_bar_command_test | DONE |
| 07.16 | App Preferences | `SharedPreferences` + `ThemeStorage` | theme tests | DONE |
| 07.17 | Last Project | Registry-based last opened | present | DONE |
| 07.18 | Backup Structure | `ProjectRecoveryService` keeps backup | project_persistence_test | DONE |
| 07.19 | Project Health Check | `ProjectHealthService` validates package/manifest/DB | project_persistence_test | DONE |
| 07.20 | Migration Engine | Drift schema migration (schema version + guarded migration) | migration tests | DONE |
| 07.21 | Project Lock | `project_lock_test` | project_lock_test | DONE |
| 07.22 | Android | `android/` platform directory | present | DONE (structure) |
| 07.23 | Project Package masa depan | `ProjectPackage` (canonical portable package) | project_package_test | DONE |
| 07.24 | Testing | 22 persistence + project tests pass | all pass | DONE |

## Sprint 08 — Asset Core System (27 steps — simplified summary)

Source: `lib/database/project/tables/{assets,asset_relations,asset_tags,asset_collections}*`, `lib/core/project_package/`, `daos/asset_dao`, `daos/character_dao`, `daos/relation_dao`, `daos/image_dao`, `daos/image_metadata_dao`, `daos/reference_dao`.

| Stepping | Evidence | Status |
|---|---|---|
| 08.1–08.27 | Tables exist for asset/character/identity/reference; DAOs exist; character/relation/reference/wardrobe/weapon creation tests pass; AssetType enum present; tags/collections tables present; full suite green | DONE (representative; no dedicated asset_test.dart suite file) |

Detailed audit: asset types, character model, character table, identity, reference images, character repo, asset repo, create character service, DAO setup, database update, migration, character controller, character workspace, character list sidebar, inspector context, relation core, relation types, asset version, character file layout, add character dialog, empty state, search, Run Generator.

## Sprint 09 — Workspace System (19 steps)

Source: `lib/features/creator/presentation/creator_workspace_screen.dart`, `workspace_resolver`, `workspace_layout_presets`.

| Stepping | Evidence | Status |
|---|---|---|
| 09.1–09.19 | Creator workspace sections, character workspace, identity/references/turnaround/color/silhouette/accessories cards, inspector, mobile adaptation, persistence, sheet tabs, visual test | DONE (creator_workspace_test + dispersion across features) |

## Sprint 10 — Inspector & Selection (25 steps)

Source: `lib/core/selection/`, `lib/core/commands/command_history.dart`, `relation_dao`, various inspector screens.

| Stepping | Evidence | Status |
|---|---|---|
| 10.1–10.25 | Selection model + provider, explorer/inspector/workspace resolver, character/environment/weapon inspectors, relation model, relation DAO, relation repository, delete safety, selection history, context menu, relation graph preview, mobile inspector | DONE (weapon inspector test; relation tests; no dedicated selection_test.dart suite) |

## Sprint 11 — Wardrobe (25 steps)

| Step | Evidence | Status |
|---|---|---|
| 11.1–11.25 | Wardrobe model, table, components, colors, material library, variant system, references, create transaction, folder, workspace, header, product view, specification, components, fabric swatches, resolver, inspector, character relation, primary/default, detail sheet mode, export, Android, migration, test scenario | DONE (wardrobe_creation_test, wardrobe_delete_test, wardrobe_workspace_test: 6 tests pass) |

## Sprint 12 — Weapon (28 steps)

| Step | Evidence | Status |
|---|---|---|
| 12.1–12.28 | Weapon model, table, components, dimensions, color palette, energy/core, variant, references, directory, create flow, workspace, header, technical view, specification, components, dimensions, energy, workspace screen, resolver, inspector, character relation, dual weapon, geometry lock, detail sheet mode, search, character loadout, migration, test | DONE (weapon_creation_test, weapon_inspector_test, weapon_workspace_test, relation_persistence_test: 12 tests pass) |

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
