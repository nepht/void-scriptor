# Sprint 145.10 — Dependency and Coupling Map

Tanggal audit: 2026-08-27  
Sumber: live worktree `/home/nepht/Projects/void_scriptor_multiplatform`  
Metode: inspeksi source read-only dan pencarian import; tidak ada refactor pada langkah audit ini.

## Ringkasan arsitektur aktual

```text
main/bootstrap
  -> app router + auth/session
      -> desktop shell
          -> top bar / explorer / workspace / inspector / status
              -> feature services + repositories
                  -> project paths / project registry / project session
                      -> Drift project database + filesystem

optional AI / cloud / publishing / community
  -> feature and core adapters
  -> tidak boleh menjadi dependency startup Core MVP
```

Diagram ini adalah ringkasan coupling yang teramati, bukan kontrak baru.

## Dependency map

| Boundary | Source evidence | Dependency direction | Risk / consequence | Status |
|---|---|---|---|---|
| Bootstrap → router/auth/features | `lib/app/routing/app_router.dart` mengimpor auth, dashboard, projects, AI, assets, references, Bible, resilience, publishing, plugin, XR, metaverse, dan panel lain | App composition mengetahui banyak feature | Router menjadi orchestration hub; perubahan route dapat memengaruhi banyak feature | VERIFIED observation; refactor DEFERRED |
| Desktop shell → feature UI | `lib/app/shell/desktop/void_desktop_shell.dart` mengimpor Explorer, Inspector, Workspace, persistence providers, mutation runtime, dan routing | Shell mengorkestrasi feature panels dan app commands | Shell coupling tinggi; callback/navigation regression harus dijaga | VERIFIED observation |
| Top bar → Explorer selection | `VoidDesktopShell` memetakan menu ke `explorerAssetTypeForMenu`, `focusExplorerAsset`, lalu route workspace | UI shell → shared selection intent → workspace | Menjaga typed selection lebih penting daripada sekadar `push('/workspace')` | VERIFIED source/test |
| Core persistence → Projects feature | `lib/core/persistence/project_registry_service.dart` mengimpor `features/projects/domain/project_model.dart` | Core → feature | Melanggar dependency direction Core-without-features; registry tidak dapat dipakai tanpa domain feature | VERIFIED coupling; corrective refactor NOT STARTED |
| Core selection → Assets feature | `lib/core/selection/selection_model.dart` mengimpor `features/assets/domain/asset_type.dart` | Core → feature | Selection contract terikat pada enum feature; pemindahan AssetType dapat mematahkan workspace/navigation | VERIFIED coupling; corrective refactor NOT STARTED |
| Core commands → Resilience feature | `lib/core/commands/command_type_registry.dart` mengimpor `features/project_resilience/application/command_history_repository.dart` untuk `CommandHistoryRecord` | Core command registry → feature application | Command replay/history boundary tidak independen dari resilience feature | VERIFIED coupling; corrective refactor NOT STARTED |
| Project open → manifest + Drift | `lib/core/persistence/project_open_service.dart` memakai `ProjectManifestService`, `ProjectPaths`, `ProjectDatabaseService`, `ProjectDatabase` | Persistence service → filesystem + database | Open lifecycle adalah seam kritis; perubahan harus menjaga manifest ID validation, DB open, sink privacy, dan close | VERIFIED observation |
| Project registry → filesystem recovery | `ProjectRegistryService` memakai `ProjectPaths` atau injected root, dan `ProjectRecoveryService.atomicWrite` | Registry → path/recovery infrastructure | Atomic registry writes dan schema version 1 adalah compatibility boundary | VERIFIED local |
| Workspace → database/registry/AI | Shell/workspace panels menerima database, registry, event bus, dan optional AI registry melalui composition | Feature UI → application/data services | Risiko UI bypass repository atau membuat startup bergantung pada provider | PARTIAL; perlu audit per panel |
| Optional providers → AI UI | AI registry/provider layer dipakai secara eksplisit oleh AI panel/workspace | UI → provider-neutral registry | Provider live/network/credential behavior bukan bukti Core readiness | VERIFIED local boundary; external UNVERIFIABLE |
| Cloud/collaboration/publishing/community → Core | Route dan feature tersedia di source, tetapi backend/provider/platform gates terpisah | Non-Core → shared app surface | Harus tetap feature-gated/deferred dan tidak menjadi startup dependency | PARTIAL; boundary contract perlu 145.22 |

## Startup and save coupling

### Startup

- `app_router.dart` membangun daftar route dan mengimpor banyak feature pada compile-time.
- `VoidDesktopShell` membaca `projectSessionProvider`; bila session tersedia, mutation runtime dipasang melalui `ValueListenableBuilder`.
- `ProjectOpenService.open()` membaca manifest, memvalidasi `manifest.id`, membuka database, lalu mengirim creative terms ke sink secara best-effort.
- Sink diagnostics gagal tidak menghentikan pembukaan proyek, sesuai kontrak privacy boundary yang teramati.
- Optional providers tidak boleh dipanggil sebagai prasyarat pembukaan Core project.

### Save and mutation

- Shell mendaftarkan shortcut Save/Undo/Redo melalui `ProjectMutationRuntime` dan `ProjectSession.save()`/bus.
- Top bar menerima `canUndo`, `canRedo`, dan callback mutation dari shell.
- Persistence ownership berada pada session/database/recovery services; UI tidak boleh memindahkan atomic write ke widget.
- Explorer creation harus mempertahankan urutan service → persistence/provider invalidation → typed selection → resolver.

## Cycles and boundary findings

### Confirmed direct architectural violations

Tiga import berikut teramati sebagai `core → features`:

1. `lib/core/persistence/project_registry_service.dart` → `features/projects/domain/project_model.dart`
2. `lib/core/selection/selection_model.dart` → `features/assets/domain/asset_type.dart`
3. `lib/core/commands/command_type_registry.dart` → `features/project_resilience/application/command_history_repository.dart`

Ini bukan alasan untuk melakukan refactor spontan pada langkah 145.10. Refactor membutuhkan contract-first tests, ownership agreement, dan regresi terhadap router/persistence/selection.

### Tidak terbukti dari audit ini

- Tidak ada klaim bahwa seluruh dependency graph bebas cycle; inspeksi ini belum menjalankan graph analyzer.
- Tidak ada klaim bahwa semua feature telah dipisahkan dari startup; compile-time imports tidak sama dengan runtime initialization.
- Tidak ada klaim backend/cloud/provider production readiness.
- Tidak ada klaim clean-clone reproducibility; known uncommitted dependency closure tetap dicatat di protection list.

## No-break rules for future refactor

1. Pertahankan public route factories dan route labels selama migrasi boundary.
2. Pertahankan typed `SelectionModel` dan mapping asset-to-workspace; jangan menggantinya dengan generic route push.
3. Pertahankan injected `ProjectPaths` dan `ProjectRecoveryService.atomicWrite` untuk test filesystem deterministik.
4. Pertahankan manifest ID validation sebelum database open.
5. Pertahankan best-effort diagnostics sink agar privacy instrumentation tidak menjadi blocker open.
6. Jangan memindahkan tipe domain ke Core hanya untuk menghapus import tanpa memeriksa ownership dan schema compatibility.
7. Jangan mengubah schema/migration; D-SCHEMA-01 tetap OPEN.
8. Pisahkan local Core evidence dari provider, cloud, payment, hardware, signing, dan hosted CI evidence.

## Decision

`145.10 Dependency and Coupling Map` berstatus **VERIFIED sebagai audit lokal**. Temuan utama adalah tiga direct `core → features` coupling dan dua orchestration hubs (router/shell). Tidak ada refactor produksi yang dilakukan karena langkah ini meminta pemetaan, sedangkan corrective boundary contract belum ditetapkan. Langkah aman berikutnya: `145.11 Data Ownership Map`, setelah memastikan tidak ada agen lain yang sedang mengerjakannya.

## Update 2026-09-04 cron run11 (nephthys, rekonsiliasi baris stale pasca Sprint 145.19)

Rekonsiliasi berbasis bukti live @7746f80 (Windows host):

- **Tiga direct core-to-features violations di atas SUDAH DISELESAIKAN** oleh Sprint 145.19 (commit c0b8b7d "refactor(core): sprint 145.19 core dependency direction via ADR-0001"; ledger VERIFIED 2026-08-31): ProjectModel, AssetType, CommandHistoryRecord+Status dipindah ke lib/core/domain/ dengan path lama dipertahankan sebagai compatibility export; Drift repository tetap feature-owned. ADR: docs/adr/ADR-0001-core-shared-type-ownership.md.
- Status ketiga baris "Core -> Projects/Assets/Resilience feature" pada tabel Dependency map: corrective refactor NOT STARTED -> **corrective refactor LANDED via Sprint 145.19 (c0b8b7d)**.
- Bukti fresh run ini:
  - Import scan lib/core ke features/ pada live tree: **0 import aktif**; satu-satunya kemunculan string adalah komentar provenance di lib/core/domain/*.dart (hasil move 145.19).
  - test/core/architecture/core_dependency_direction_test.dart -> **PASS** ("lib/core does not import or export lib/features"), dijalankan segar @HEAD.
  - lib/core/selection/selection_model.dart kini mengimpor ../domain/asset_type.dart (core-local); lib/core/commands/command_type_registry.dart mengimpor ../domain/command_history.dart; lib/core/persistence/project_registry_service.dart mengimpor ../domain/project_model.dart.
- Baris lain tetap akurat sebagai observasi historis 2026-08-27: orchestration hubs (router/shell) tidak berubah struktural; "Workspace -> database/registry/AI" PARTIAL dan "Cloud/collaboration boundary 145.22" PARTIAL tetap jujur (145.22 capability gate VERIFIED di ledger; CloudSyncService tidak dikomposisi di production).
- Tidak ada kode produksi/test/schema yang diubah oleh update ini (doc-only evidence closure). File ini diadopsi ke git karena dikutip ledger 145.10 sejak 2026-08-27 namun masih untracked - pola yang sama dengan data-ownership-map.md pada run10 (7746f80).
## Evidence

- `lib/app/routing/app_router.dart` dibaca dari live source.
- `lib/app/shell/desktop/void_desktop_shell.dart` dibaca dari live source.
- `lib/core/persistence/project_open_service.dart` dibaca dari live source.
- `lib/core/persistence/project_registry_service.dart`, `lib/core/selection/selection_model.dart`, dan `lib/core/commands/command_type_registry.dart` dibaca dari live source.
- Import scan pada `lib/core` menemukan tiga direct `core → features` import.
- Tidak ada source code, generated file, schema, atau test yang diubah oleh langkah ini.
- `git diff --check` dijalankan setelah artefak dokumentasi dibuat.
