# Sprint 145.33 — Portable Import Export

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json`, item `145.33`.  
Status: **PARTIAL**.

## Kontrak kanonik

`Memverifikasi .vscriptor manifest/checksums/secret exclusion, transactional import, compatibility/migration, corrupted input, rollback, and large project behavior.`

## Implementasi yang terverifikasi

`lib/features/project_resilience/application/portable_project_service.dart` menyediakan:

- export manifest dan database ke archive ZIP;
- copy assets dan workspaces;
- pengecualian directory cache dari export;
- validasi archive hasil export dengan `ZipDecoder(verify: true)`;
- import sebagai project baru (`asCopy`) dengan UUID baru;
- rewrite `project_id` pada tabel database ketika import sebagai copy;
- registry registration setelah import;
- cleanup package jika import atau registration gagal;
- path traversal guard untuk absolute path dan `../` escape.

Archive menggunakan `voidproject.archive.json` dengan format/version/project ID/source schema metadata. Saat ini field `checksum` ditulis sebagai string kosong dan belum dipakai untuk memvalidasi isi archive.

## Verification terbaru

Command:

```bash
flutter test \
  test/features/project_resilience/portable_project_service_test.dart \
  test/features/project_resilience/portable_archive_security_test.dart \
  test/features/project_resilience/project_recovery_services_test.dart
```

Result:

```text
All tests passed! — 6 tests
```

Coverage yang lulus:

- export archive lalu import sebagai copy;
- asset dan workspace ikut terbawa;
- cache disposable tidak ikut archive;
- relocated copy terdaftar di registry;
- absolute archive path ditolak;
- partial import package dibersihkan;
- backup checksum dan workspace tamper rejection tetap lulus.

## Evidence boundary

| Acceptance | Status | Evidence / gap |
|---|---|---|
| Manifest | VERIFIED | `manifest/project.json` wajib ada dan dibaca |
| Archive integrity checksum | VERIFIED (domain) | 2026-09-03 cron: export menulis checksum SHA-256 nyata (directory-based, deterministic entry order, POSIX separator), import memverifikasi sebelum ekstraksi; `test/features/project_resilience/archive_integrity_test.dart` 4 PASS RED-terverifikasi |
| Secret exclusion | BLOCKED | Tidak ada allowlist/denylist atau test yang membuktikan secret tidak masuk |
| Transactional import | PARTIAL | Partial package dihapus; 2026-09-03c cron: registry-state atomicity + rollback terbukti test-only (commit 991dd53: post-extraction registry failure me-rollback package directory, registry kembali ke state pre-import; copy import aditif); existing-destination overwrite pada asCopy:false tetap non-atomic (risiko terdokumentasi, file engine concurrent) |
| Compatibility/migration | VERIFIED (domain) | 2026-09-03e cron: dua sumbu versi terbukti - manifest format (> 16 ditolak FormatException, portable_corrupt_input_test) dan database user_version (arsip DB v53 diimpor lalu dibuka lewat jalur produksi ProjectDatabaseService.open yang menjalankan migrasi maju 53->59 tanpa kehilangan baris Core; manifest lama schemaVersion 15 diterima; arsip v59 saat ini round-trip tanpa migrasi; portable_schema_compatibility_test.dart 3 PASS PASS-first) |
| Corrupted input | VERIFIED (domain) | Matrix 6 korupsi + kontrol positif lulus: missing manifest, missing database, truncated zip, non-zip, manifest malformed (checksum cocok dengan kontennya), manifest future schema 99 > 16 semua ditolak FormatException (portable_corrupt_input_test.dart 7 PASS, 2026-09-03d cron) |
| Rollback | PARTIAL | Cleanup on failure ada; 2026-09-03c cron: rollback registry-state + package directory terbukti test-only (991dd53); rollback terhadap existing destination (path overwrite asCopy:false) belum terbukti - file engine concurrent |
| Large project behavior | VERIFIED (domain) | 2026-09-03 cron: 250 aset + 2 blob 256 KiB + 60 workspace export/import/registry round-trip lulus (portable_large_project_test.dart 3 PASS, commit 7641236) |
| Registry relocation | VERIFIED | Coordinator mendaftarkan imported package dengan local path baru |
| Platform/native interaction | UNVERIFIABLE | Native Windows UI flow belum terbukti; driver sebelumnya `snapshot_id_required` |

## Safety boundary

Tidak ada project production yang dipindahkan atau dihapus. Semua test memakai temporary directories. Tidak ada schema migration baru dan tidak ada credential yang diproses.

## Verdict

**PARTIAL — portable archive round-trip, relocation, path safety, cleanup, archive integrity checksum, registry-state transactional import/rollback, large-project evidence, dan compatibility/migration (dua sumbu versi) sudah runnable; secret exclusion, destination-collision rollback (asCopy:false overwrite non-atomic), guard future-schema database (temuan risiko 2026-09-03e), dan native interaction belum tersedia.**

## Update 2026-09-03 (nephthys cron, archive integrity checksum)

Slice: `ArchiveIntegrity` di `lib/features/project_resilience/application/portable_project_service.dart`
- `computeDirectoryChecksum(root)`: SHA-256 atas seluruh file di staging directory sebelum zip, urutan entry name sorted deterministik, separator POSIX (backslash Windows dikonversi), meta entry `voidproject.archive.json` dikecualikan dari payload hash.
- Exporter: checksum dihitung dari staging dir lalu ditulis ke meta sebelum zip tunggal — tidak ada re-encode round-trip yang bisa mengubah byte.
- Importer: `ArchiveIntegrity.verify(decoded)` dijalankan SEBELUM ekstraksi apa pun; `checksum` kosong/hilang/tamper → `FormatException('Archive checksum mismatch')` dan package tidak dibuat.

RED terverifikasi: `Undefined name 'ArchiveIntegrity'` sebelum implementasi. Pitfall tertangkap: `decoded.add()` pada archive hasil decode meng-append entry duplikat sehingga `find()` tetap mengembalikan entry lama — test tamper direvisi memakai `ArchiveFile.bytes` replace; re-encode `ArchiveFile` hasil decode tidak byte-stabil di archive 4.0.9 (rawContent stream) sehingga desain akhir menghindari re-encode.

Bukti (HEAD saat slice, full suite dirun terpisah):
- `flutter test test/features/project_resilience/archive_integrity_test.dart` → 4 PASS (checksum non-kosong 64-hex dan identik dengan compute; tamper ditolak; tanpa checksum ditolak; valid archive import sukses).
- `flutter test test/features/project_resilience/` → 121 PASS.
- `flutter analyze` scoped 2 file → No issues found.
- `flutter build windows --debug` → Built void_scriptor.exe (32,6s).
- `git diff --check` → PASS.

Next canonical step: `145.34 Local Backup and Restore`.

145.42 tetap tidak disentuh karena milik eksekutor lain.
## Update 2026-09-03 (nephthys cron, large project behavior evidence)

- Gap audit "Large project behavior" ditutup dengan bukti executable
  (test-only, PASS-first, tanpa perubahan produksi):
  `test/features/project_resilience/portable_large_project_test.dart` 3 PASS.
- Fixture: 250 file aset kecil tersebar 5 subdirektori + 2 blob 256 KiB
  + 60 file workspace lintas novel + manifest + database.
- Bukti:
  1. Export arsip besar: semua 250 aset + 2 blob + 60 workspace hadir di
     entry ZIP, checksum SHA-256 valid (meta == computeContentChecksum),
     verifikasi ZipDecoder PASS.
  2. Import arsip besar as-copy: struktur lengkap, blob 256 KiB
     round-trip byte-exact, konten workspace terpilih utuh, jumlah file
     hasil ekstraksi >= 314.
  3. Coordinator importAndRegister proyek besar: registry berisi satu
     project id baru (relocated copy), localPath benar, konten aset
     spot-check utuh.
- Bukti gerbang: focused 3 PASS; project_resilience suite 124 PASS
  (121 lama + 3 baru, delta +3 eksak); analyzer scoped No issues;
  git diff --check PASS; commit 7641236 (test only).
- Sisa 145.33: secret exclusion (BLOCKED: region sama pada
  portable_project_service.dart milik sibling), compatibility/migration
  policy, complete rollback terhadap existing registry state.

## Update 2026-09-03c (nephthys cron) - transactional import + rollback registry-state

**Status tetap `PARTIAL`; gap "rollback terhadap existing project/registry
state" pada sisi registry-state ditutup sebagai bukti test-only.**

- Test baru `test/features/project_resilience/portable_import_transaction_test.dart`
  (2 PASS, PASS-first, tanpa kode produksi - file engine milik slice concurrent):
  1. Kegagalan registry upsert SETELAH ekstraksi selesai membuat coordinator
     menghapus direktori package hasil import dan registry kembali persis ke
     state pre-import (single real project id).
  2. Copy import mendaftar aditif; dua project pre-existing tetap utuh di
     registry dan di disk.
- Bukti eksekusi: focused 2 PASS; project_resilience suite 127 PASS / 0 FAIL;
  `flutter analyze` No issues found! (145.2s); `flutter build windows --debug`
  PASS 42.6s; `git diff --check` PASS; roadmap_guard PASS pre+post.
- Temuan risiko terdokumentasi: import `asCopy:false` pada destination dengan
  package existing menimpa file demi file secara non-atomik, dan cleanup
  failure menghapus direktori existing (data-loss path). UI produksi hanya
  memakai `asCopy:true` sehingga tidak tercapai dari jalur UI saat ini;
  perbaikan engine BLOCKED karena file milik slice concurrent.
- Sisa gap: secret exclusion (BLOCKED file concurrent), migration
  compatibility, destination-collision rollback, native interaction
  (UNVERIFIABLE dari cron).

nephthys - 2026-09-03c

## Update 2026-09-03d (nephthys cron) - corrupted-input matrix evidence closure

**Baris "Corrupted input: PARTIAL" dinaikkan menjadi VERIFIED (domain) sebagai
bukti test-only PASS-first; file engine tetap milik slice concurrent dan tidak
disentuh.**

- Test baru `test/features/project_resilience/portable_corrupt_input_test.dart`
  (7 PASS, tanpa kode produksi):
  1. Missing `manifest/project.json` -> FormatException "Invalid voidproject
     archive".
  2. Missing `database/project.db` -> FormatException "Invalid voidproject
     archive".
  3. Truncated zip container (60% byte pertama) -> FormatException.
  4. Input bukan zip sama sekali -> FormatException.
  5. Manifest JSON malformed dengan checksum SHA-256 yang cocok dengan
     kontennya -> tetap ditolak FormatException (checksum bukan bypass
     validasi manifest).
  6. Manifest `schemaVersion: 99 > 16` -> FormatException "Unsupported
     project manifest schema version: 99".
  7. Positive control: arsip valid hasil exporter dengan checksum terhitung
     diimpor bersih (membuktikan harness checksum pada kasus 3/5/6 benar).
- Perilaku diprobe live lebih dulu (test probe sekali pakai, sudah dihapus):
  keenam bentuk korupsi memang sudah ditolak importer sebelum test ini ada -
  slice ini mengunci perilaku, bukan menambalnya.
- Bukti gerbang: focused 7 PASS; project_resilience suite 134 PASS / 0 FAIL;
  flutter analyze No issues found! (8.9s); git diff --check PASS (lihat
  ledger); full suite + windows build dieksekusi pada run yang sama.
- Sisa 145.33: secret exclusion (BLOCKED file concurrent), migration
  compatibility, destination-collision rollback (asCopy:false), native
  interaction (UNVERIFIABLE dari cron).

nephthys - 2026-09-03d

## Update 2026-09-03e (nephthys cron) - compatibility/migration evidence closure

**Baris "Compatibility/migration: BLOCKED" dinaikkan menjadi VERIFIED (domain)
sebagai bukti test-only PASS-first; file engine tetap milik slice concurrent
dan tidak disentuh.**

- Test baru `test/features/project_resilience/portable_schema_compatibility_test.dart`
  (3 PASS, tanpa kode produksi), membuktikan DUA sumbu versi arsip:
  1. Database user_version: arsip berisi DB v53 (fixture seedV53 setia,
     mirror schema_migration_fixtures_test.dart) diekspor, diimpor, lalu
     dibuka lewat jalur produksi `ProjectDatabaseService().open` yang
     menjalankan migrasi maju 53->59; baris Core (assets + characters,
     biography utuh) selamat tanpa silent discard.
  2. Manifest format version: manifest lama `schemaVersion: 15` diterima
     dan tetap bermigrasi; versi > 16 sudah ditolak FormatException
     (tercakup portable_corrupt_input_test.dart).
  3. Positive control CURRENT: arsip v59 round-trip tanpa migrasi.
- Perilaku diprobe live lebih dulu (probe sekali pakai, dihapus):
  import v53 -> open -> user_version 59, baris Core utuh.
- TEMUAN RISIKO (terdokumentasi, bukan regresi): DB dengan `user_version`
  60 (> app 59) diterima saat open produksi dan user_version diam-diam
  diturunkan ke 59 - tidak ada guard future-schema database. Guard
  produksi BLOCKED: `project_database_platform_io.dart` milik region
  concurrent. Manifest future (> 16) sudah aman.
- Bukti gerbang: focused 3 PASS; portable group 18 PASS;
  project_resilience suite 137 PASS / 0 FAIL; flutter analyze No issues
  found! (9.7s); git diff --check PASS (full suite + windows build pada
  run yang sama, lihat ledger).
- Sisa 145.33: secret exclusion (BLOCKED file concurrent),
  destination-collision rollback (asCopy:false), guard future-schema DB,
  native interaction (UNVERIFIABLE dari cron).

nephthys - 2026-09-03e
