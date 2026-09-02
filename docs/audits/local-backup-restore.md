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
| Configurable location | VERIFIED (engine) | BackupLocationPolicy injectable (commit d8b99a8): optional customBackupRoot + configureCustomBackupRoot runtime; resolveBackupRoot fail-safe fallback ke internal default saat root hilang/invalid; snapshot eksternal disimpan sebagai path absolut di ProjectBackups.relativePath; retention prune lintas lokasi via _resolveBackupDirectory; backup_configurable_location_test 2 PASS RED-terverifikasi; UI pemilihan lokasi user tetap terbuka (settings surface, bukan engine acceptance) |
| Retention | VERIFIED (engine) | BackupRetentionService wired into controller.createBackup; per-category prune-oldest removes directory + ProjectBackups row via removeBackup; injectable policy default 20/50; retention_enforcement_test 2 PASS RED-verified (commit 5ce2c93); UI konfigurasi user tetap terbuka (row configurable location) |
| Hashes | VERIFIED | SHA-256 manifest/database/workspace checksums dan tamper rejection lulus |
| Restore preview | VERIFIED (engine) | RestorePreviewReport.compute read-only: names + schema versions + klasifikasi current/migrationForward/blocked + warnings; 3 PASS RED-terverifikasi (commit da68cf1); konsumsi UI di screen belum ada (engine-first, objective 145.34 = verification) |
| Alternate destination | VERIFIED (engine) | restoreToAlternateDestination salin backup ke package UUID baru di destinationRoot tanpa menyentuh live project/backup; tolak schema lebih baru; rollback saat gagal; test 3 PASS (commit da68cf1); integrasi registry/UI belum ada |
| Schema migration | VERIFIED (classification) | preview mengklasifikasi migrationForward utk schema lama dan alternate-destination restore mempertahankan user_version lama (forward migration saat open, flow open-migration sendiri sudah dibuktikan fixtures 145.40 OLD v53-to-v59) |
| Failure recovery | PARTIAL (diperkuat) | Emergency backup dan manifest/database rollback ada; workspace copy-stage failure injection kini teruji (backup_copy_stage_failure_test: Windows file-lock harness membuat workspace delete stage gagal deterministik -> rollback manifest+db terverifikasi, 2 PASS RED-terverifikasi commit d8b99a8); invalid custom root (file) terbukti tidak crash dan tidak menulis parsial; injeksi stage assets-copy dan emergency-backup-failure belum ada |
| Free access | UNVERIFIABLE | Tidak ada entitlement/access-control test pada backup flow |
| Native interaction | UNVERIFIABLE | Native Windows click-through tetap blocked oleh `snapshot_id_required` |

## Safety boundary

Semua verification memakai temporary project directories. Tidak ada backup aktual yang dipindah, dihapus, atau ditimpa. Tidak ada schema migration baru.

## Verdict

**PARTIAL — integrity-protected local backup/restore, retention engine, restore preview, alternate destination, dan migration-aware classification sudah runnable dan teruji; configurable location, comprehensive failure injection, dan Free-access proof masih terbuka.**

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

## Update 2026-09-03 cron b (nephthys cron: restore preview + alternate destination)
- Gap 'restore preview' + 'alternate destination' CLOSED: ProjectBackupRestorePreview (lib/features/project_resilience/application/project_backup_restore_preview.dart), file domain baru - tidak menyentuh project_recovery_services.dart milik sibling 145.33/145.34.
- compute(): read-only RestorePreviewReport - currentName/backupName dari manifest project.json, currentSchemaVersion/backupSchemaVersion dari SQLite user_version, klasifikasi current / migrationForward / blocked (backup > app schema) + warnings (manifest tak terbaca).
- restoreToAlternateDestination(): salin backup ke package UUID baru di destinationRoot (manifest/database/assets/workspaces), live project dan backup asli tidak tersentuh; tolak schema lebih baru dari aplikasi; rollback hapus target saat gagal. Schema lebih lama = forward migration saat open berikutnya (semantik sama dengan restore in-place).
- RED terverifikasi (Undefined name ProjectBackupRestorePreview + RestoreCompatibility). Bug produksi terselamatkan RED: import barrel platform stub (readProjectDatabaseSchemaVersion selalu null) - ditemukan via probe differential (dart CLI roundtrip 53 PASS; flutter_tester roundtrip 53 PASS; reader repo pada file sama 53 PASS; test FAILED Actual null) lalu fix ke ProjectDatabaseService().schemaVersion (conditional io/web import, pola production project_database_service.dart).
- Bukti: focused 3 PASS; project_resilience suite 111 PASS; scoped analyze No issues; format 2 file 0 sisa; git diff --check PASS; windows debug build PASS 38.5s; full suite digate di run ini.
- Commit: da68cf1 (2 file, +313).


## Update 2026-09-03 cron d (nephthys: configurable location + failure injection)

- Gap 'Configurable location' CLOSED at the engine boundary: new
  `BackupLocationPolicy` (lib/features/project_resilience/application/backup_location_policy.dart).
  Optional user-selected custom backup root; `resolveBackupRoot` is
  fail-safe: missing custom root (USB unplugged) or an invalid root (path
  is a file) falls back to the package-internal `backups/` directory so a
  backup is never blocked and never written partially into a broken
  location. External snapshots are stored as absolute paths in
  `ProjectBackups.relativePath`; internal snapshots keep the existing
  package-relative form; retention pruning resolves both via
  `_resolveBackupDirectory` so the oldest backup is pruned across both
  locations (cross-location retention proven by test 2).
- Gap 'Failure recovery' STRENGTHENED: `backup_copy_stage_failure_test.dart`
  injects a deterministic Windows file-lock on a live workspace file so the
  restore's workspace delete stage fails; test proves the emergency
  rollback returns the live manifest to its pre-restore state (name
  unchanged) and the live workspace file survives. A second injection
  (custom root is a file) proves createBackup neither crashes nor writes
  into the invalid location. RED first: `backupLocationPolicy` /
  `BackupLocationPolicy` undefined (compile fail), then fail-safe behavior
  assertions corrected against the real contract (backups/ exists from
  package creation; Directory.existsSync is false for a file path).
- Design decisions: fail-safe over throw (a backup must always exist
  somewhere); no UI in this slice (settings surface remains open,
  grouped with the user-validation boundary).
- Gates: focused 4 PASS; project_resilience suite 115 PASS; scoped
  `dart analyze` No issues (2 lints fixed: prefer_initializing_formals,
  unused p_join helper); `dart format` clean; full `flutter test`
  3431 PASS / 0 FAIL; `flutter build windows --debug` PASS (27.7s);
  `git diff --check` PASS; roadmap guard PASS pre+post (pointer stays
  145.27). Commit d8b99a8 (5 owned files; project_recovery_services.dart
  staged mine-only via HEAD-transform so the sibling's uncommitted
  integrity engine (~108 lines) stayed untouched and uncommitted).
- Remaining for 145.34: assets-copy-stage and emergency-backup-failure
  injection, settings UI for location + retention, Free-access proof
  (no entitlement hook exists to test), native interaction (UNVERIFIABLE
  from cron).

### Update 2026-09-03 cron 07:xx (nephthys) - Free-access proof landed

- Gap `Free access` audit row naik dari UNVERIFIABLE ke VERIFIED (domain).
- Bukti: `test/features/project_resilience/backup_free_access_test.dart` 2 PASS - (1) journey tanpa akun: ProjectSessionManager.open + ProjectResilienceController.createBackup x2 + ProjectBackupRestorePreview.compute (compatibility current) + in-place restore (manifest name dipulihkan) + restoreToAlternateDestination (package baru, manifest intact) - seluruh flow berjalan tanpa parameter akun/plan, dan tidak ada konsep plan/tier/entitlement di lib sama sekali; (2) guard statis: token banned (premium/paywall/subscription/entitlement/licensing/monetization/requirePlan/currentPlan/core-auth/features-account/features-collaboration) di-scan di lib/features/project_resilience + lib/core/persistence - zero violation.
- RED terverifikasi sebelum slice: audit row Free access = UNVERIFIABLE (tidak ada entitlement/access-control test pada backup flow); implementasi produksi tidak berubah - PASS-first evidence closure mengikuti preseden 145.25g/145.30j.
- Gerbang: focused 2 PASS, project_resilience 117 PASS (+2), analyze No issues (97.2s), diff --check PASS, guard PASS pre-state; full suite + windows build digate run ini.
