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
| Transactional import | PARTIAL | Partial package dihapus; existing destination collision/registration atomicity belum lengkap |
| Compatibility/migration | BLOCKED | Importer membaca schema version tetapi tidak menjalankan migration/compatibility policy |
| Corrupted input | PARTIAL | Missing manifest/database dan invalid ZIP ditolak; matrix corruption belum lengkap |
| Rollback | PARTIAL | Cleanup on failure ada; rollback terhadap existing project/registry state belum terbukti |
| Large project behavior | VERIFIED (domain) | 2026-09-03 cron: 250 aset + 2 blob 256 KiB + 60 workspace export/import/registry round-trip lulus (portable_large_project_test.dart 3 PASS, commit 7641236) |
| Registry relocation | VERIFIED | Coordinator mendaftarkan imported package dengan local path baru |
| Platform/native interaction | UNVERIFIABLE | Native Windows UI flow belum terbukti; driver sebelumnya `snapshot_id_required` |

## Safety boundary

Tidak ada project production yang dipindahkan atau dihapus. Semua test memakai temporary directories. Tidak ada schema migration baru dan tidak ada credential yang diproses.

## Verdict

**PARTIAL — portable archive round-trip, relocation, path safety, cleanup, dan archive integrity checksum sudah runnable; secret exclusion, migration compatibility, complete rollback, dan large-project evidence belum tersedia.**

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
