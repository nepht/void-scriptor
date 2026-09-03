# Sprint 145.9 — Working Feature Protection List

Tanggal audit: 2026-08-27  
Sumber: live worktree `/home/nepht/Projects/void_scriptor_multiplatform`  
Scope: inventaris read-only sebelum perubahan scope Core MVP.

## Batas bukti

Daftar ini melindungi perilaku yang telah memiliki bukti source/test/build saat audit. Label `VERIFIED` tidak berarti production-ready, native end-to-end, cloud-ready, atau release-ready. Native UI interaction tetap `UNVERIFIABLE` karena driver berhenti pada `snapshot_id_required`.

## Fitur dan no-break contract

| Fitur | Pemilik utama | Jalur pengguna | Data/dependency yang tidak boleh rusak | Bukti live | Status |
|---|---|---|---|---|---|
| Authenticated/local entry dan dashboard shell | `lib/app/void_app.dart`, `lib/app/routing/app_router.dart`, `lib/features/dashboard/` | Login/Guest/Offline → Dashboard → Studio | Auth-aware routes, session guard, dashboard route, shell composition | Full widget suite; Windows executable opens to login screen | VERIFIED source/test/build; native flow PARTIAL |
| Character creation | `lib/features/dashboard/presentation/dashboard_screen.dart`, `lib/features/dashboard/presentation/widgets/quick_actions.dart`, character create services | Dashboard `Create Character` → typed character selection → workspace | Character persistence, `AssetType.character`, shared selection provider, resolver branch | `test/app/shell/core_mvp_navigation_test.dart`; Explorer/navigation tests; full suite | VERIFIED source/test; native click-through UNVERIFIABLE |
| Story/Novel creation and workspace | `lib/features/explorer/presentation/explorer_panel.dart`, story services, workspace resolver | Explorer `+ Create Asset` → Story/Novel → selected Story workspace | Story asset persistence, typed selection, Story/Novel resolver branch | `test/features/explorer/explorer_panel_navigation_test.dart`; workspace tests; full suite | VERIFIED source/test; native click-through UNVERIFIABLE |
| Explorer selection and creation | `lib/features/explorer/presentation/explorer_panel.dart`, `explorer_story_group.dart` | Explorer item, generic `+`, type-specific create action | `explorerAssetFocusProvider`, provider invalidation, selection identity, workspace resolver | Explorer navigation suite; full suite; bounded `_ExplorerItem` regression | VERIFIED source/test |
| Top-bar and left navigation | `lib/app/shell/desktop/void_top_bar.dart`, desktop shell | Characters/Story/Projects/Assets/Resilience navigation | GoRouter destinations, functional Project resilience action, narrow-width layout | TopBar command tests; resilience/back-navigation tests; full suite | VERIFIED source/test; native visual interaction UNVERIFIABLE |
| Responsive desktop shell | TopBar, Explorer, workspace/status shell | Window near 1280px and wide desktop | No RenderFlex overflow; functional actions remain visible; Search only at wide breakpoint | Full `flutter test`: 2014 passed; focused routing/TopBar tests | VERIFIED source/test |
| Project resilience | `lib/core/persistence/`, `lib/core/security/`, project package services | Project open/close/recovery/health flows | Lock-aware session, project isolation, SQLite safety, relative trash paths | Existing resilience/database suites; full suite | VERIFIED local boundaries; failure matrix PARTIAL |
| Workspace persistence and resolver | `lib/features/workspace/presentation/workspace_resolver.dart`, workspace layout | Selected asset opens matching workspace | Asset type mapping, selection lifecycle, workspace mode | Workspace and navigation tests; full suite | VERIFIED source/test |
| Local database and asset persistence | `lib/database/project/`, asset/character/story services | Create/edit/reopen local project data | Drift schema v56, migrations, repositories, generated output | Full test suite; Windows code generation generated 3007 outputs | VERIFIED local; clean HEAD reproducibility caveat below |
| Autosave/repository save path | `lib/core/persistence/`, repository layer, app scaffold | Edit → save/autosave → reopen | Repository boundary, atomic save/recovery behavior, no silent loss | Focused persistence/resilience tests; full suite | VERIFIED local boundaries; failure matrix PARTIAL |
| AI optional boundary | `lib/core/ai/`, `lib/features/ai/` | Explicit AI panel/provider action | No startup dependency, provider registry, credential redaction, offline fallback | AI/provider focused tests and analyzer | VERIFIED local/provider boundary; external providers UNVERIFIABLE |
| Linux development build | Flutter Linux target | Build current source | WSL Flutter toolchain and generated source | `flutter build linux --debug` | VERIFIED |
| Windows debug artifact | Fresh WSL-derived snapshot | Build artifact launch | Snapshot dependency closure, codegen, Windows toolchain | `D:\VoidScriptor_Windows_Snapshots\void-windows-sprint-20260827-final`; pub get PASS; codegen 3007 outputs; Windows build PASS; executable present | VERIFIED build; runtime feature interaction PARTIAL |

## Explicit no-break rules

1. Jangan menghapus atau mengganti `selectionProvider`/`explorerAssetFocusProvider` tanpa memperbarui seluruh jalur Dashboard, top bar, left bar, Explorer, dan resolver.
2. Jangan mengubah breakpoint TopBar dengan menyembunyikan kontrol fungsional. `Project resilience` harus tetap tersedia pada desktop normal.
3. Jangan mengembalikan label Explorer ke `Row` tanpa batas horizontal; `_ExplorerItem` wajib mempertahankan `Expanded`, satu baris, dan ellipsis.
4. Jangan menganggap route `/workspace` sebagai bukti typed asset selection. Setiap entry point harus tetap membawa tipe/identitas yang sesuai.
5. Jangan menjadikan Windows mirror sebagai source of truth. Snapshot baru harus dibuat dari WSL dan dibuild secara independen.
6. Jangan menambahkan login, network, payment, cloud, atau provider sebagai dependency startup Core MVP.
7. Jangan melakukan migrasi schema baru pada D-SCHEMA-01 yang masih OPEN.
8. Jangan menghapus snapshot/build lama tanpa inventaris dan persetujuan batch spesifik.

## Known gaps protected from accidental closure

- Native Guest/Offline → Dashboard → Create Asset → workspace belum terbukti karena `snapshot_id_required`.
- Data safety failure matrix 145.42 masih dimiliki agen lain; sisa process kill, power loss, disk full, permission loss, drive removal, interrupted transfer, dan device validation belum boleh ditandai selesai.
- Clean clone dari HEAD murni memiliki temuan dependency closure historis: dua table source dan dua asset path yang belum terkomit pada baseline audit. Fresh dirty snapshot berhasil dibuild, tetapi ini bukan bukti clean-clone reproducibility.
- Global format gate tidak bersih karena 10 file concurrent/non-scope berubah saat full format; perubahan tersebut tidak boleh direstore secara massal.
- Cloud/server, live provider, signing, installer, hardware, dan hosted CI tetap terpisah dari bukti local development.

## Verification record

Commands/evidence yang tersedia pada audit ini:

- `flutter test` → `All tests passed — 2014 tests`.
- `flutter analyze` → `No issues found!`.
- `flutter build linux --debug` → bundle Linux berhasil.
- `git diff --check` → exit code 0.
- Windows snapshot gate → `pub get` PASS, build_runner PASS (`3007 outputs`), `flutter build windows --debug` PASS.
- Windows executable check → `WINDOWS_EXE_PRESENT`.
- Literal source scan untuk empty `onPressed`/`onTap` callback di `lib/features` → 0 matches.

## Decision

145.9 dapat ditandai `VERIFIED` sebagai protection inventory lokal. Ini bukan izin untuk menghapus scope non-Core, mengubah schema, atau menutup blocker native/failure-matrix. Langkah berikut yang aman adalah 145.10 Dependency and Coupling Map, kecuali agen pemiliknya sudah mengambil langkah tersebut.

## Update 2026-09-04 cron run11 (nephthys, rekonsiliasi baris stale pasca 145.19/145.22/145.40)

- Baris "Local database and asset persistence" menyebut "Drift schema v56": live tree @7746f80 adalah **v59** (currentSchemaVersion = 59 di lib/database/project/project_database.dart; guard future-schema DB landed d76d596 pada 145.33). Angka v56 dipertahankan sebagai konteks historis audit 2026-08-27 dan tidak mengubah contract baris.
- Gap "clean clone" (dua table source + dua asset path belum terkomit pada baseline audit) telah ditutup lewat adopsi 145.40 (9d3cf6b) + adopsi test 332e9ee (2026-09-04); enforcement arsitektur core-to-features PASS segar di live tree (test/core/architecture/core_dependency_direction_test.dart).
- Catatan "global format gate tidak bersih karena 10 file concurrent" tetap berlaku sebagai catatan proses historis.
- Konten audit asli tidak diubah; update block saja (doc-only).
