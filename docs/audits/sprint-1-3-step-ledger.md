# Sprint 1–3 Step Ledger (from canonical ChatGPT share JSON)

Contract source: `https://chatgpt.com/share/6a82a8ad-7e90-83ec-88e5-f270ddea60c3` (backend JSON, update 2026-08-17). Step titles are the canonical blueprint headings; status is derived from live source, focused tests, and gates on 2026-08-18.

## Sprint 01 — Project Foundation (20 steps)

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 01.1 | Menentukan Platform Utama | `pubspec.yaml` (android, ios, linux, macos, web, windows) | Fresh `flutter devices`: Linux WSL2 detected; `platform_capabilities_test.dart`: 3 passed; CI defines Linux/Web/Android/Windows/macOS/iOS simulator build jobs. Native targets other than Linux remain unverified locally. | VERIFIED-PARTIAL |
| 01.2 | Memilih Teknologi | `pubspec.yaml` + `pubspec.lock` (Flutter, Riverpod, GoRouter, Drift, SQLite, secure storage, path provider, shared preferences) | Fresh `flutter pub get` succeeded with lockfile unchanged; source usage search found the declared architecture packages; `flutter analyze`: No issues found; `git diff --check`: pass. A guessed dependency-policy test path was absent and is not counted as evidence. | VERIFIED-LOCAL |
| 01.3 | Struktur Project | `lib/{app,core,database,design_system,features,shared}`, `assets/`, `docs/`, `test/`, `integration_test/` | Fresh current-HEAD inventory: all ten required directories present; 909 Dart files under `lib`, 518 test files, and 0 Dart files under `integration_test`; required test domains (`app`, `architecture`, `core`, `database`, `design_system`, `features`, `shared`) present; `git diff --check`: pass. Structure is verified, integration coverage remains unverified. | VERIFIED-LOCAL |
| 01.4 | Membuat Repository | `.git` origin `github.com/nepht/void-scriptor.git` | Fresh current-HEAD audit: origin `https://github.com/nepht/void-scriptor.git`; branch `master`; HEAD `4298284ea9576e7807026e1482fd16ff5dc7a7c8`; upstream `origin/master`; ahead/behind `0/92`; working tree is intentionally dirty and concurrent changes are preserved. | VERIFIED-LOCAL |
| 01.5 | Setup Development Environment | WSL `~/toolchain/flutter/bin/flutter` | Fresh canonical toolchain check: Flutter `3.44.9` stable, Dart `3.12.2`, executable paths `/home/nepht/toolchain/flutter/bin/flutter` and `/home/nepht/toolchain/flutter/bin/dart`; repository `git diff --check` passed after correcting the working directory. | VERIFIED-LOCAL |
| 01.6 | Membuat Core Architecture | `lib/core/` 27 modules | Fresh inventory: `lib/core/` contains exactly 27 first-level module directories, matching the canonical requirement; `git diff --check`: pass. | VERIFIED-LOCAL |
| 01.7 | Membuat Core Module | `lib/core/{auth,commands,database,events,plugin,...}` | Live mapping reconciled: named directories exist; `auth` has 3 Dart files, `commands` 9, `plugin` 15; project database lives under `lib/database/project/`; event infrastructure is implemented as `CommandEventBus` in `lib/core/commands/command_event_bus.dart` and integrated by `ProjectMutationRuntime`; empty `lib/core/database`/`events` directories are compatibility paths, not missing runtime behavior. | VERIFIED-LOCAL — PATH COMPATIBILITY NOTE |
| 01.8 | Membuat App Initialization | `lib/main.dart` → `ProviderScope(VoidScriptorApp())` | Fresh `flutter test test/app/bootstrap/app_bootstrap_test.dart`: 1 test passed; `flutter analyze`: No issues found; `git diff --check`: pass. | VERIFIED-LOCAL |
| 01.9 | Membuat Configuration System | `ThemeSettingsScreen` + `themeControllerProvider` + `ThemePreferenceStore`, security settings, AI provider settings, plugin settings | Current-HEAD focused configuration run passed 10 tests across theme persistence/screen, security UI, and provider adapter boundaries; analyzer clean and diff check passed. Theme/app config and security UI are verified; plugin settings remain intentionally partial because durable persistence contract is not established. | VERIFIED-LOCAL — THEME/SECURITY; PARTIAL PLUGIN SETTINGS |
| 01.10 | Membuat Environment System | `lib/database/project/tables/environments*.dart` + `environment_dao` | Current-HEAD focused run of four actual environment suites (`environment_model`, `environment_persistence`, `environment_relation`, `environment_workspace`): 6 tests passed; persistence restart and narrow workspace paths passed; analyzer clean and diff check passed. | VERIFIED-LOCAL |
| 01.11 | Membuat Logging System | `audit_log`, `plugin_logger`, `slow_query_log` | Current-HEAD focused run of `audit_log_test.dart`, `plugin_sdk_test.dart`, and `performance_diagnostics_test.dart`: 11 tests passed; audit ring buffer, plugin logger/settings, and slow-query record/ignore/order/clear behavior verified; analyzer clean and diff check passed. | VERIFIED-LOCAL |
| 01.12 | Membuat Error Handling | `section_error_boundary`, `project_recovery_service` | Current-HEAD focused run of `section_error_boundary_test.dart` and `project_recovery_services_test.dart`: 5 tests passed; async UI fallback, crash-session lock, clean close, backup restore, cache clear, and trash restore paths passed; analyzer clean and diff check passed. | VERIFIED-LOCAL |
| 01.13 | Membuat Database Awal | `lib/database/project/` (Drift, 90+ tables) | Current-HEAD database/resilience focused run passed 11 tests: metadata repair/idempotence, schema/migration 54, visible clips, composite query plan, hot-query indexes, and recovery persistence; analyzer clean and diff check passed. | VERIFIED-LOCAL — CORE DATABASE; BROADER LIFECYCLE DEBT REMAINS |
| 01.14 | Membuat API Foundation | `lib/core/network` | Added provider-neutral `ApiRequest`, `ApiResponse`, injectable `ApiTransport`, and validating `ApiClient` in `lib/core/network/api_client.dart`; focused TDD test observed RED before implementation, then 2 tests passed; `flutter analyze`: No issues found; `git diff --check`: pass. No external endpoint is claimed. | VERIFIED-LOCAL — TRANSPORT CONTRACT ONLY |
| 01.15 | Membuat UI Awal | `lib/app/{bootstrap,routing,shell,adaptive}` | Current-HEAD UI/shell/adaptive focused run passed 41 tests across routing, desktop/mobile shell, adaptive boundaries, dashboard, and theme-screen integration; analyzer clean and diff check passed. | VERIFIED-LOCAL |
| 01.16 | Membuat Theme Engine | `lib/design_system/theme/` | Same current-HEAD run covered theme controller, persisted mode loading/saving, mode menu, light theme application, design-system widgets, and dashboard rendering: 41 tests passed; analyzer clean and diff check passed. | VERIFIED-LOCAL |
| 01.17 | Membuat Asset Folder System | `assets/{backgrounds,brands,logos,translations}` | Current-HEAD inventory: backgrounds=1, brands=380, logos=1, translations=0; `asset_decode_test.dart` passed 3 tests for logo/background/WebP brand assets; analyzer clean and diff check passed. Representative assets are verified; translations remain partial because no locale/resource contract is defined. | VERIFIED-LOCAL — REPRESENTATIVE ASSETS; TRANSLATIONS PARTIAL |
| 01.18 | Membuat Testing Framework | `test/{app,architecture,core,database,design_system,features,shared}` | Fixed the testWidgets I/O boundary with `tester.runAsync`, awaited the Riverpod session future, and removed StoryInspector overflow; focused inspector/story regression passed 5 tests. Fresh full `flutter test` completed with 1,391 tests passed; `flutter analyze`: No issues found; `git diff --check`: pass. | VERIFIED-LOCAL — FULL SUITE 1,391 PASSED |
| 01.19 | Membuat Documentation System | `docs/{audits,sprints}` | Current-HEAD inventory: `docs/audits` has 16 files, `docs/sprints` has 27 files, `MASTER_SPRINT.md` has 1,231 lines, and the required directories exist; `git diff --check` passed. Content completeness and step coverage beyond the maintained ledgers are not inferred from file count. | VERIFIED-PARTIAL |
| 01.20 | Membuat First Build | web release, linux debug, android apk debug | Current-HEAD build gate passed: `flutter build linux --debug` produced `build/linux/x64/debug/bundle/void_scriptor`; `flutter build web --release` produced `build/web`; analyzer and diff check passed. Web emitted non-blocking icon-font/Wasm dry-run warnings. Android, macOS, and iOS remain unverified in this fresh gate. | VERIFIED-PARTIAL — ANDROID/MACOS/IOS UNVERIFIED |

## Sprint 02 — Design System (11 items)

| Item | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 02.1 | Warna utama | `lib/design_system/colors/void_colors.dart`, `void_colors_light.dart` | Fresh inventory found both color files; combined Sprint 02 regression passed 72 tests including theme, shell, and dashboard rendering. | VERIFIED-LOCAL |
| 02.2 | Spacing | `lib/design_system/spacing/void_spacing.dart` | Fresh source inventory found the spacing token file; design-system/widget regression passed. | VERIFIED-LOCAL |
| 02.3 | Radius | `lib/design_system/radius/void_radius.dart` | Fresh source inventory found radius tokens; `VoidCard` regression passed. | VERIFIED-LOCAL |
| 02.4 | Typography | `lib/design_system/typography/void_typography.dart` | Fresh source inventory found typography tokens; theme/dashboard regression passed. | VERIFIED-LOCAL |
| 02.5 | Theme Engine | `lib/design_system/theme/void_theme.dart`, `void_theme_context.dart` | Theme/platform persistence, appearance menu, and app light-theme tests were included in a fresh 72-test run; analyzer and diff check passed. | VERIFIED-LOCAL |
| 02.6 | Breakpoint Multiplatform | `lib/app/adaptive/void_breakpoints.dart`, `void_resolver.dart` | Fresh adaptive tests passed phone/tablet/compact-desktop/desktop boundaries. Tokens 600/1024/1440/1920 exist; resolver uses 1920 as a declared desktop token but not as a fifth category. | VERIFIED-LOCAL — TOKEN/RESOLVER NOTE |
| 02.7 | Adaptive Scaffold | `lib/app/adaptive/void_adaptive_scaffold.dart` | Fresh adaptive scaffold tests passed phone, tablet/compact, and desktop layouts; no test exceptions reported. | VERIFIED-LOCAL |
| 02.8 | Komponen Card pertama | `lib/design_system/widgets/void_card.dart` | Fresh `void_card_test.dart` passed in the 72-test regression. | VERIFIED-LOCAL |
| 02.9 | Void Button | `lib/design_system/widgets/void_button.dart` | Fresh `void_button_test.dart` passed in the 72-test regression. | VERIFIED-LOCAL |
| 02.10 | Root App | `lib/app/void_app.dart`, `void_scriptor_app.dart` | Fresh root app test and shell/routing regression passed; analyzer clean. | VERIFIED-LOCAL |
| 02.11 | Dashboard pertama | `lib/features/dashboard/presentation/dashboard_screen.dart` | Fresh dashboard suite passed wide rendering and narrow Android viewport behavior. | VERIFIED-LOCAL |

## Sprint 03 — Adaptive Application Shell (13 steps)

| Step | Requirement | Source | Test / Evidence | Status |
|---|---|---|---|---|
| 03.1 | Struktur file | `lib/app/adaptive/`, `lib/app/shell/` | Fresh inventory found 4 adaptive files and 6 shell files; current shell/adaptive/routing regression passed 38 tests. | VERIFIED-LOCAL |
| 03.2 | Masukkan logo | `lib/design_system/widgets/branding/void_logo.dart` + `assets/logos/` | Fresh inventory found `VoidLogo` and one actual asset `assets/logos/void_scriptor_logo.png`; asset decode test exists and shell tests render the logo path. | VERIFIED-LOCAL — VISUAL GUI AUDIT DEFERRED |
| 03.3 | VoidLogo | `void_logo.dart` | Fresh source inventory and desktop/mobile shell tests verify the logo widget integration. | VERIFIED-LOCAL |
| 03.4 | Top Navigation Desktop | `lib/app/shell/desktop/void_top_bar.dart` | `void_top_bar_command_test.dart` passed; top-bar command state and desktop shell rendering verified. | VERIFIED-LOCAL |
| 03.5 | Explorer Panel kiri | `lib/app/shell/desktop/` | Desktop shell regression passed with explorer/workspace composition. | VERIFIED-LOCAL |
| 03.6 | Inspector kanan | `lib/app/shell/desktop/` | Desktop shell regression passed the inspector branch/composition. | VERIFIED-LOCAL |
| 03.7 | Workspace tengah | `lib/app/shell/desktop/` | Desktop shell regression passed supplied workspace/dashboard content. | VERIFIED-LOCAL |
| 03.8 | Status Bar | `lib/app/shell/desktop/void_status_bar.dart` | `void_status_bar_test.dart` passed; dirty/command state and version label verified. | VERIFIED-LOCAL |
| 03.9 | Desktop Shell | `lib/app/shell/desktop/void_desktop_shell.dart` | Fresh desktop shell widget test passed. | VERIFIED-LOCAL |
| 03.10 | Mobile Shell | `lib/app/shell/mobile/void_mobile_shell.dart` | Fresh mobile shell test passed destinations and More actions. | VERIFIED-LOCAL |
| 03.11 | App Shell resolver | `lib/app/shell/void_app_shell.dart` | Fresh shell/adaptive tests passed app-shell paths and device resolver boundaries. | VERIFIED-LOCAL |
| 03.12 | Jadikan App Shell sebagai Home | `lib/app/routing/app_router.dart` | Fresh router and auth flow tests passed shell/home navigation. | VERIFIED-LOCAL |
| 03.13 | Test | `test/app/shell/*`, `test/app/adaptive/*` | Fresh focused shell/adaptive/routing/auth command passed 38 tests; analyzer and diff check passed before this ledger update. | VERIFIED-LOCAL |

## Sprint 04 — Authentication System (14 steps) — pending detailed audit

## Sprint 05 — Dashboard System (12 steps) — pending detailed audit

## Sprint 06 — Project Management (19 steps) — pending detailed audit

## Sprint 07 — Data Persistence (24 steps) — pending detailed audit

## Sprint 08 — Asset Core System (27 steps) — pending detailed audit

## Sprint 09 — Workspace System (19 steps) — pending detailed audit

## Sprint 10 — Inspector & Selection (25 steps) — pending detailed audit

## Sprint 11 — Wardrobe (25 steps) — pending detailed audit

## Sprint 12 — Weapon (28 steps) — pending detailed audit
