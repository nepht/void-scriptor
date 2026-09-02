# Sprint 145.34 — Local Backup and Restore

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json`, item `145.34`.  
Status: **PARTIAL**.

## Kontrak kanonik

`Memverifikasi configurable location, retention, hashes, restore preview, alternate destination, schema migration, failure recovery, and Free access.`

## Implementasi yang terverifikasi

`lib/features/project_resilience/application/project_recovery_services.dart` menyediakan `ProjectBackupService` yang:

- membuat backup lokal di package backup directory;
- menyalin manifest, database, assets, dan workspaces;
- menulis SHA-256 untuk manifest/database dan checksum setiap workspace file;
- menolak backup yang incomplete atau metadata/checksum-nya invalid;
- membuat emergency `pre-restore` backup sebelum restore;
- mencoba mengembalikan manifest/database dari emergency backup jika write restore gagal.

`ProjectResilienceController` menambahkan checkpoint WAL sebelum backup, registrasi metadata backup ke `project_backups`, dan create-backup action pada resilience UI.

`ProjectVersionControlService` juga menyediakan snapshot JSON, list, compare, restore callback, dan prune berbasis jumlah retention. Ini adalah version snapshot service terpisah dari full project backup service.

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

Evidence yang lulus:

- full backup restore memulihkan manifest/database/assets/workspaces;
- SHA-256 database tamper rejection;
- workspace checksum tamper rejection;
- emergency backup dibuat sebelum restore;
- WAL checkpoint dipanggil dari controller sebelum backup;
- snapshot create/compare/restore/prune teruji pada resilience suite sebelumnya.

## Evidence boundary

| Acceptance | Status | Evidence / gap |
|---|---|---|
| Configurable location | BLOCKED | Service memakai package backup directory; destination policy belum injectable/user-configurable |
| Retention | VERIFIED (engine) | BackupRetentionService wired into controller.createBackup; per-category prune-oldest removes directory + ProjectBackups row via removeBackup; injectable policy default 20/50; retention_enforcement_test 2 PASS RED-verified (commit 5ce2c93); UI konfigurasi user tetap terbuka (row configurable location) |
| Hashes | VERIFIED | SHA-256 manifest/database/workspace checksums dan tamper rejection lulus |
| Restore preview | BLOCKED | UI hanya menampilkan jumlah backup dan action create; preview contents/diff belum ada |
| Alternate destination | BLOCKED | Restore selalu ke package yang sama; destination lain belum didukung |
| Schema migration | PARTIAL | Backup menyimpan schema version; migration-aware restore/open belum diuji sebagai flow |
| Failure recovery | PARTIAL | Emergency backup dan manifest/database rollback ada; failure injection untuk semua copy stages belum ada |
| Free access | UNVERIFIABLE | Tidak ada entitlement/access-control test pada backup flow |
| Native interaction | UNVERIFIABLE | Native Windows click-through tetap blocked oleh `snapshot_id_required` |

## Safety boundary

Semua verification memakai temporary project directories. Tidak ada backup aktual yang dipindah, dihapus, atau ditimpa. Tidak ada schema migration baru.

## Verdict

**PARTIAL — integrity-protected local backup/restore dan snapshot retention primitive sudah runnable, tetapi configurable location, preview, alternate destination, migration-aware restore, comprehensive failure injection, dan Free-access proof belum tersedia.**

Next canonical step: `145.35 Clean Manuscript Export`.

145.42 tetap tidak disentuh karena milik eksekutor lain.

## Update 2026-09-03 (nephthys cron: retention enforcement wiring)

- Retention acceptance CLOSED at the engine boundary: `BackupRetentionService`
  (Step 24.26 domain, previously never called in production) is now wired into
  `ProjectResilienceController.createBackup`. Each recorded backup triggers
  `_enforceBackupRetention()`: per-category (automatic/manual) prune-oldest via
  `selectForPrune`, removing both the on-disk backup directory and its
  `ProjectBackups` row through the new `ProjectResilienceRepository.removeBackup`.
- Policy is injectable: `ProjectResilienceController(session, {retentionPolicy})`
  with default `BackupRetentionPolicy(maxAutomatic: 20, maxManual: 50)`.
- Test: `test/features/project_resilience/backup_retention_enforcement_test.dart`
  2 PASS (RED verified first: `retentionPolicy` undefined on controller; then
  3 manual backups with maxManual=2 leave exactly 'second'+'third' rows and 2
  on-disk directories; default policy preserves all four and reports maxManual 50).
- Evidence boundary note: user-facing retention configuration UI remains open
  (grouped with the BLOCKED configurable-location row); this slice proves the
  policy enforcement path, not a settings surface.
- Gates this slice: focused 2 PASS; project_resilience suite 108 PASS; scoped
  `dart analyze` No issues on the 3 owned files; scoped `dart format` clean;
  `git diff --check` PASS; commit 5ce2c93 (3 owned files only).
