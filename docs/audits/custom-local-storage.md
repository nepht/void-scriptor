# Sprint 145.31 — Custom Local Storage

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json`, item `145.31`.  
Status: **PARTIAL**.

## Kontrak kanonik

`Mendukung user-selected C:/D:/USB after permission/free-space/removal tests, missing-drive state, relink, and no empty replacement project.`

## Evidence yang tersedia

### Root dan package path

- `lib/core/persistence/project_paths.dart`
  - menerima `rootDirectory` override untuk test;
  - memilih Documents, App Support, lalu temp fallback;
  - membuat root project writable;
  - membentuk path project stabil `<id>.voidproject`;
  - membentuk path manifest dan database project-local.
- `lib/core/project_package/project_package.dart`
  - menyediakan root package, database, assets, recovery, backup, cache, dan trash directories.
- `lib/features/projects/presentation/project_controller.dart`
  - membuat package menggunakan root yang resolved;
  - mendaftarkan project melalui registry.

### Registry dan atomic metadata

- `ProjectRegistryService` menyimpan `localPath` dan menggunakan `ProjectRecoveryService.atomicWrite`.
- `ProjectRecoveryService` menulis `.tmp`, mempertahankan `.bak`, rename atomic, dan restore backup.
- Ini membuktikan metadata registry yang tahan replacement, bukan custom-storage health lifecycle penuh.

### Health/open dan relink seam

- `ProjectHealthService` dapat memeriksa manifest/database package.
- `ProjectOpenService` membuka project berdasarkan `projectId` dan `ProjectPaths`.
- Relokasi/import coordinator yang ada dapat mendaftarkan copy pada lokasi baru.
- **Batas:** belum ada explicit custom-location manager yang mendeteksi path hilang lalu menawarkan relink tanpa membuat replacement project.

## Verification terbaru

Command awal memasukkan path test yang tidak ada:

```text
flutter test ... test/features/projects/presentation/project_controller_test.dart ...
```

Result:

```text
BLOCKED — test/features/projects/presentation/project_controller_test.dart does not exist
```

Ini adalah kesalahan path test, bukan failure production.

Command koreksi:

```bash
flutter test \
  test/core/persistence/project_persistence_test.dart \
  test/features/project_resilience/portable_project_service_test.dart
```

Result:

```text
All tests passed! — 18 tests
```

Covered behavior:

- manifest JSON round-trip dan schema rejection;
- complete project folder structure;
- registry save/reload dan multi-project isolation;
- fallback ketika Documents tidak writable;
- project-local manifest/database path;
- health check package lengkap;
- open/close project database;
- atomic registry replacement dan backup restore;
- portable export/import dan relocated-copy registration.

## Gap terhadap acceptance

| Acceptance | Status | Reason |
|---|---|---|
| User-selected C:/D:/USB | PARTIAL | `CustomStorageLocationStore` persisted schema-v1 (c9da6dc) + wiring ProjectPaths/PackageService (b826cec) landed; UI folder picker belum |
| Permission test | VERIFIED (seam) | `StorageHealthProbe` injectable: driveMissing/notADirectory/permissionDenied/notEnoughSpace (c9da6dc) |
| Free-space test | VERIFIED (host) | `HostDriveSpaceReader` + `PlatformDriveSpaceReader` via PowerShell Get-PSDrive; shortage nyata terukur (95fee4a) |
| Drive removal | UNVERIFIABLE | Tidak ada removable-drive harness; tidak menyentuh drive aktual |
| Missing-drive state | VERIFIED (domain+wiring) | `load()` melaporkan `missingDrive`; `ProjectPaths.root()` fallback default tanpa crash (c9da6dc/b826cec) |
| Relink | VERIFIED (storage-level) | relink flow end-to-end bind-hapus-relink-healthy (95fee4a); guard no-empty-replacement (c9da6dc); UI flow belum |
| No empty replacement project | VERIFIED (domain) | Relink tanpa paket proyek terikat ditolak `StateError` (c9da6dc); fallback missing drive tidak membuat proyek kosong (b826cec) |
| Registry persistence | VERIFIED | Atomic `.tmp`/`.bak` replacement dan reload lulus |
| Package persistence | VERIFIED | Package structure, manifest, database, health, open, dan import evidence lulus |

## Safety boundary

Audit read-only terhadap lokasi aktual. Test memakai temporary directories. Tidak ada pemindahan project, penghapusan data, pengisian disk, perubahan drive letter, atau permission mutation.

## Verdict

**PARTIAL — project path/package persistence dan registry atomicity tersedia, tetapi custom storage lifecycle C:/D:/USB belum acceptance-complete.**

Langkah lanjutan yang diperlukan:

1. definisikan model custom storage location dan persisted registry location;
2. tambahkan health probe injectable untuk writable/free-space/drive-present;
3. buat RED tests untuk missing-drive dan relink tanpa empty replacement;
4. implementasikan recovery state serta user-facing relink flow;
5. verifikasi Windows drive/permission behavior pada disposable test roots, bukan project aktif.

145.42 tetap tidak disentuh karena berada di bawah eksekutor lain.


## Update 2026-09-02 (cron): custom storage location domain landed

Commit c9da6dc menambahkan domain layer acceptance gap 145.31:

- `lib/core/persistence/custom_storage_location.dart`:
  - `CustomStorageLocation.normalizeLocation` (trim, strip trailing separator, tolak kosong);
  - `probe` membedakan `driveMissing` / `notADirectory` / `permissionDenied` (via injectable `StorageHealthProbe`) / `notEnoughSpace` (guard `minFreeBytes` = 1 MiB);
  - `nearestExistingAncestor` membedakan leaf directory yang hilang (bisa diadopsi jika drive hidup) dari drive yang benar-benar hilang (ditolak);
  - `CustomStorageLocationStore`: registry persisten schema v1 (atomic `.tmp` rename), `setActiveLocation` validasi sebelum persist (drive hilang ditolak), `bindProject`, `relinkLocation` menolak target tanpa paket proyek terikat (no-empty-replacement-project).
- `test/core/persistence/custom_storage_location_test.dart`: 8 kontrak domain (RED terverifikasi - semua simbol undefined sebelum implementasi).

Bukti eksekusi: focused 8 PASS; regression `test/core/persistence/` + portable 36 PASS; `flutter analyze` No issues; `flutter build windows --debug` PASS 20.1s; `git diff --check` PASS.

Status boundary:

| Acceptance | Status | Evidence |
|---|---|---|
| User-selected C:/D:/USB | PARTIAL | Domain model + probe + persisted store + wiring ProjectPaths/PackageService landed (c9da6dc/95fee4a/b826cec); UI folder picker belum |
| Permission test | VERIFIED (seam) | `StorageHealthProbe` injectable teruji; probe default menulis `.vs_write_probe` lalu hapus |
| Free-space test | VERIFIED (host) | `HostDriveSpaceReader`/`PlatformDriveSpaceReader` (PowerShell Get-PSDrive): freeBytes host nyata + shortage nyata (95fee4a) |
| Drive removal | UNVERIFIABLE | Tidak menyentuh drive fisik; missing-drive disimulasikan via penghapusan direktori |
| Missing-drive state | VERIFIED (domain) | `load()` melaporkan `missingDrive` saat lokasi aktif hilang |
| Relink | VERIFIED (storage-level) | relink flow end-to-end bind-hapus-relink-healthy (95fee4a); alur relink UI/pemindahan data belum |
| No empty replacement project | VERIFIED (domain) | Relink tanpa paket proyek terikat ditolak dengan StateError |
| Registry persistence | VERIFIED | Atomic `.tmp` rename + reload lulus |

145.31 tetap PARTIAL: UI pemilihan lokasi, pengukuran free-space host-akurat, alur relink end-to-end, dan integrasi `ProjectPaths`/`ProjectPackageService` ke lokasi kustom belum ada.

## Update 2026-09-03 (cron): free-space host-akurat + relink end-to-end

Commit 95fee4a menutup dua gap 145.31 di level domain:

- `HostDriveSpaceReader` (interface) + `PlatformDriveSpaceReader`: Windows membaca free bytes host-nyata via PowerShell `Get-PSDrive -Name <drive>.Free`; budget tidak diketahui (-1) mempertahankan standing offer 1 GiB konservatif; non-Windows melaporkan unknown (tidak berbohong soal free space).
- `DefaultStorageProbe` (seam publik, `spaceReader` injectable) dibungkus `probe()`; `_Probe.checkWith` memisahkan writable-check dari interpretasi budget. `probe` kini melaporkan `freeBytes` host sungguhan dan memicu `notEnoughSpace` saat shortage nyata (sebelumnya selalu 1 GiB).
- Test baru `test/core/persistence/host_drive_space_reader_test.dart` 4 PASS (RED terverifikasi: `HostDriveSpaceReader`/`DefaultStorageProbe` undefined): reader host-nyata >= 0 (demonstrasi C: free ~57 GB), notEnoughSpace pada 512 KiB terinjeksi, ok pada 5 MiB terinjeksi, dan alur relink end-to-end: bind project -> hapus lokasi lama -> relink ke target yang memuat paket terikat -> status `healthy` + `boundProjectId` utuh.

Bukti gerbang: focused 4 PASS; regression test/core/persistence 38 PASS; analyze No issues; `dart format` 0 changed; `git diff --check` PASS; full suite 3417 PASS / 0 FAIL (12:20); `flutter build windows --debug` PASS 21.8s; roadmap guard PASS pre+post (pointer tetap 145.27).

Status boundary 145.31 terbaru: Free-space test PARTIAL -> VERIFIED (domain, host-akurat di Windows; matrix multi-drive belum); Relink PARTIAL -> VERIFIED (domain end-to-end; relink UI pemindahan data tetap open). Sisa 145.31: UI pemilihan lokasi, wiring ProjectPaths/PackageService ke lokasi kustom.


## Update 2026-09-03 (nephthys cron, 145.31 wiring ProjectPaths/PackageService)

- Gap 145.31 "wiring ProjectPaths/PackageService ke lokasi kustom" ditutup
  (commit slice ini). RED terverifikasi: `flutter test
  test/core/persistence/project_paths_custom_location_wiring_test.dart` gagal
  kompilasi - `customStorageStore`, `fallbackRootDirectory`,
  `customStorageStoreProvider`, `rootOverride` undefined.
- Implementasi minimal:
  - `lib/core/persistence/project_paths.dart`: `ProjectPaths` kini menerima
    `customStorageStore` + `fallbackRootDirectory`. `root()` konsultasi store
    lebih dulu: lokasi custom aktif + healthy -> jadi project home; lokasi
    missing (`missingDrive`) -> fallback default (Documents chain), tanpa
    crash; tanpa store -> perilaku lama utuh. Getter `rootOverride` +
    `rootDirectoryFile()` (file mesin-lokal di samping root efektif).
  - `lib/core/persistence/custom_storage_location.dart`: store kini cache
    state hasil `load()` (`cachedState`), dipakai wiring path sinkron.
  - `lib/features/projects/presentation/project_persistence_providers.dart`:
    `customStorageStoreProvider` (FutureProvider; registry file
    `storage_locations.json` di samping root efektif) + `projectPathsProvider`
    mem-baca store, sehingga seluruh konsumen `projectPathsProvider`
    (ProjectPackageService create/open, session manager, controller) otomatis
    mengikuti lokasi custom aktif tanpa perubahan callsite.
- Bukti: test/core/persistence/project_paths_custom_location_wiring_test.dart
  5 PASS (root custom; package service + registry mengikuti custom root tanpa
  folder Projects default; missing drive fallback + status missingDrive; tanpa
  custom location tetap Documents chain; round-trip schema/binding).
- Status boundary 145.31 terbaru: Wiring ProjectPaths/PackageService
  PARTIAL -> VERIFIED (domain/storage-level; ProjectPackageService menerima
  rootDirectory dari paths provider). Sisa 145.31: UI pemilihan lokasi
  (butuh keputusan UI Choi; screen projects concurrent).
- Bukti gerbang: focused 5 PASS; regresi core/persistence + features/projects
  59 PASS; analyze No issues; format 1 file (test) 0 issue; `git diff --check`
  PASS; full suite 3422 PASS / 0 FAIL (~12 menit); `flutter build windows
  --debug` PASS; roadmap guard PASS pre (exit 0, pointer 145.27).
## Update 2026-09-03b (nephthys cron, evidence-closure tabel Gap 145.31)

Tabel Gap audit 2026-08-27 dan tabel status 2026-09-02 direkonsiliasi dengan
slice yang sudah landed (semua komit milik sendiri): c9da6dc (store domain +
probe seam), 95fee4a (free-space host-akurat + relink end-to-end), b826cec
(wiring ProjectPaths/PackageService). Baris yang berubah:

- User-selected C:/D:/USB: BLOCKED -> PARTIAL (engine + wiring ada; UI folder
  picker tetap open).
- Permission test: PARTIAL -> VERIFIED (seam `StorageHealthProbe`).
- Free-space test: BLOCKED/PARTIAL -> VERIFIED (host-akurat).
- Missing-drive state: BLOCKED -> VERIFIED (domain + wiring fallback).
- Relink: PARTIAL -> VERIFIED (storage-level end-to-end); UI flow tetap open.
- No empty replacement project: PARTIAL -> VERIFIED (domain guard).

Bukti fresh HEAD 7c61688 (run ini): `flutter test
test/core/persistence/custom_storage_location_test.dart
test/core/persistence/host_drive_space_reader_test.dart
test/core/persistence/project_paths_custom_location_wiring_test.dart` =
17 PASS / All tests passed! (exit 0).

Sisa 145.31 (tidak berubah): UI pemilihan lokasi (keputusan UI Choi),
drive removal pada perangkat fisik (UNVERIFIABLE dari cron), native
interaction (UNVERIFIABLE dari cron). Pointer tetap 145.27.
