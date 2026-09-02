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
| User-selected C:/D:/USB | BLOCKED | Tidak ada API/manager explicit untuk memilih dan menyimpan custom location |
| Permission test | PARTIAL | Fallback non-writable root terbukti; Windows permission-denied path belum diuji |
| Free-space test | BLOCKED | Tidak ada free-space policy/check atau failure-injection seam |
| Drive removal | UNVERIFIABLE | Tidak ada removable-drive harness; tidak menyentuh drive aktual |
| Missing-drive state | BLOCKED | Tidak ada persisted state khusus untuk lokasi hilang |
| Relink | PARTIAL | Root override dan relocated import/open seam ada; user-facing relink flow belum terbukti |
| No empty replacement project | PARTIAL | Stable UUID package dan registry path ada; missing-location guard belum terbukti end-to-end |
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
| User-selected C:/D:/USB | PARTIAL | Domain location model + probe + persisted store ada; UI pemilihan lokasi (folder picker + wiring ke ProjectPaths/PackageService) belum |
| Permission test | VERIFIED (seam) | `StorageHealthProbe` injectable teruji; probe default menulis `.vs_write_probe` lalu hapus |
| Free-space test | PARTIAL | `minFreeBytes` guard teruji via kontrak; pengukuran free-space host-akurat belum (probe default mengembalikan standing offer) |
| Drive removal | UNVERIFIABLE | Tidak menyentuh drive fisik; missing-drive disimulasikan via penghapusan direktori |
| Missing-drive state | VERIFIED (domain) | `load()` melaporkan `missingDrive` saat lokasi aktif hilang |
| Relink | PARTIAL | `relinkLocation` menolak target tanpa paket terikat dan memulihkan status; alur relink UI/pemindahan data belum |
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
