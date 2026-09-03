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
| Secret exclusion | VERIFIED (domain) | 2026-09-04 cron: `ArchiveSecretPolicy` (commit fb57534) - exporter melewatkan file secret saat staging (dotfiles `.env*` kecuali template `.example/.sample/.template`, basename `credentials*`/`secrets*`, extension kunci `.pem/.key/.p12/.pfx/.kdbx/.keystore/.jks`, basename kunci ssh) + scan konten teks via SecretScanner, `assertNoSecrets` fail-closed sebelum checksum; importer menolak arsip ber-entri secret walau checksum valid; `portable_secret_exclusion_test.dart` 5 PASS RED-terverifikasi |
| Transactional import | PARTIAL | Partial package dihapus; 2026-09-03c cron: registry-state atomicity + rollback terbukti test-only (commit 991dd53: post-extraction registry failure me-rollback package directory, registry kembali ke state pre-import; copy import aditif); existing-destination overwrite pada asCopy:false tetap non-atomic (risiko terdokumentasi, file engine concurrent) |
| Compatibility/migration | VERIFIED (domain+prod) | 2026-09-03 cron malam run2: guard future-schema DB CLOSED - ProjectDatabaseService.open memprobe PRAGMA user_version via platform schema-version reader; DB lebih baru dari v59 ditolak SchemaVersionTooNewException tanpa menyentuh file (probe corrupt = null = no-op; web null = no-op; openReadOnly sengaja tidak diguard agar diagnostics tetap bisa membaca DB future tanpa memigrasinya); project_database_future_schema_guard_test.dart 3 PASS RED-terverifikasi (commit d76d596). || 2026-09-03e cron: dua sumbu versi terbukti - manifest format (> 16 ditolak FormatException, portable_corrupt_input_test) dan database user_version (arsip DB v53 diimpor lalu dibuka lewat jalur produksi ProjectDatabaseService.open yang menjalankan migrasi maju 53->59 tanpa kehilangan baris Core; manifest lama schemaVersion 15 diterima; arsip v59 saat ini round-trip tanpa migrasi; portable_schema_compatibility_test.dart 3 PASS PASS-first) |
| Corrupted input | VERIFIED (domain) | Matrix 6 korupsi + kontrol positif lulus: missing manifest, missing database, truncated zip, non-zip, manifest malformed (checksum cocok dengan kontennya), manifest future schema 99 > 16 semua ditolak FormatException (portable_corrupt_input_test.dart 7 PASS, 2026-09-03d cron) |
| Rollback | PARTIAL | Cleanup on failure ada; 2026-09-03c cron: rollback registry-state + package directory terbukti test-only (991dd53); rollback terhadap existing destination (path overwrite asCopy:false) belum terbukti - file engine concurrent |
| Large project behavior | VERIFIED (domain) | 2026-09-03 cron: 250 aset + 2 blob 256 KiB + 60 workspace export/import/registry round-trip lulus (portable_large_project_test.dart 3 PASS, commit 7641236) |
| Registry relocation | VERIFIED | Coordinator mendaftarkan imported package dengan local path baru |
| Platform/native interaction | UNVERIFIABLE | Native Windows UI flow belum terbukti; driver sebelumnya `snapshot_id_required` |

## Safety boundary

Tidak ada project production yang dipindahkan atau dihapus. Semua test memakai temporary directories. Tidak ada schema migration baru dan tidak ada credential yang diproses.

## Verdict

**PARTIAL — portable archive round-trip, relocation, path safety, cleanup, archive integrity checksum, registry-state transactional import/rollback, large-project evidence, compatibility/migration (dua sumbu versi), guard future-schema database, dan secret exclusion (ekspor melewatkan + impor menolak, RED terverifikasi) sudah runnable; destination-collision rollback (asCopy:false overwrite non-atomic) dan native interaction belum tersedia.**

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

## Update 2026-09-03 cron malam run2 (nephthys, future-schema DB guard 145.33)

Slice: `lib/database/project/project_database_service.dart` (feat) +
`test/database/project/project_database_future_schema_guard_test.dart` (test)
- `ProjectDatabaseService.open` kini memprobe `PRAGMA user_version` lewat
  `readProjectDatabaseSchemaVersion` (platform dispatcher) SEBELUM membuka
  database produksi. DB dengan `user_version` lebih baru dari
  `ProjectDatabase.currentSchemaVersion` (59) ditolak dengan
  `SchemaVersionTooNewException` tanpa menyentuh file - tidak ada lagi
  penurunan diam-diam oleh gelombang migrasi drift.
- Keputusan desain: `openReadOnly` sengaja TIDAK diguard - diagnostics
  harus tetap bisa memeriksa DB future tanpa memigrasikannya; probe
  corrupt membaca null sehingga guard menjadi no-op di jalur CORRUPT;
  web reader mengembalikan null sehingga guard no-op di web.
- Risiko palung lain di `ProjectSessionManager.open` (lock release +
  lock file delete + close DB parsial + rethrow) sudah ditinjau dan tetap
  utuh ketika open gagal karena guard.
- Bukti: RED terverifikasi (`SchemaVersionTooNewException isn't a type`);
  focused 3 PASS; regresi project_resilience + database 148 PASS; FULL
  SUITE 3511 PASS / 0 FAIL (delta +3 eksak dari 3508); flutter analyze
  No issues found! (9.4s); windows debug build PASS (72.7s);
  git diff --check PASS.
- Sisa 145.33: secret exclusion (BLOCKED file concurrent),
  destination-collision rollback (asCopy:false), native interaction
  UNVERIFIABLE dari cron.

nephthys - 2026-09-03 cron malam run2

## Update 2026-09-04 (nephthys cron) - secret exclusion evidence closure

**Baris "Secret exclusion: BLOCKED" dinaikkan menjadi VERIFIED (domain); file engine
tetap milik slice concurrent, ditransformasi mine-only di atas HEAD (teknik yang sama
dengan slice archive integrity b805ffe), sibling changes dipreservasi.**

- Feat commit fb57534: `ArchiveSecretPolicy`
  (`lib/features/project_resilience/application/archive_secret_policy.dart`) +
  wiring di `portable_project_service.dart`:
  1. Exporter: `_copy` staging melewatkan file secret (filename-based policy);
     `assertNoSecrets` fail-closed sebagai backstop sebelum checksum dihitung
     (scan konten SecretScanner hanya untuk file teks, biner sqlite/gambar
     tidak diskan agar export sah tidak gagal false-positive).
  2. Importer: `assertArchiveHasNoSecrets(decoded)` menolak arsip ber-entri
     secret SEBELUM ekstraksi, terlepas dari validitas checksum.
- Policy filename-based: dotfile `.env` dan `.env.<x>` kecuali template
  `.example/.sample/.template`; basename `credentials`/`secrets` (+.json/.yaml);
  extension `.pem .key .p12 .pfx .kdbx .keystore .jks`; basename kunci ssh
  `id_rsa/id_dsa/id_ecdsa/id_ed25519`; folder dot `.aws/.ssh/.gcloud/.kube`.
  Aturan folder generik `keys/` sengaja TIDAK dipakai (terlalu luas, terbukti
  menelan `assets/keys/notes.txt` yang sah).
- Test `test/features/project_resilience/portable_secret_exclusion_test.dart`
  5 PASS (RED terverifikasi: `Undefined name 'ArchiveSecretPolicy'`):
  policy positif/negatif, export menghilangkan secret tapi menyimpan file
  sah, arsip bebas-secret tetap terimpor, arsip checksum-valid ber-entri
  `.env` ditolak FormatException (membuktikan rejection dari policy, bukan
  integrity check) tanpa meninggalkan direktori destination.
- Bukti gerbang: focused portable group 24 PASS; project_resilience suite
  142 PASS / 0 FAIL; scoped analyze No issues found!; windows debug build
  PASS 24.7s; `git diff --check` PASS; FULL SUITE 3516 PASS / 0 FAIL
  (delta +5 eksak dari 3511); roadmap_guard PASS pre+post (pointer tetap
  145.27).
- Sisa 145.33: destination-collision rollback (asCopy:false overwrite
  non-atomic, terdokumentasi sebagai risiko dengan UI produksi asCopy:true),
  native interaction (UNVERIFIABLE dari cron).

nephthys - 2026-09-04
