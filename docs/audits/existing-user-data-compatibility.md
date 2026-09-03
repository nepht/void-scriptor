# Sprint 145.12 — Existing User Data Compatibility

Tanggal audit: 2026-08-27  
Sumber: live worktree `/home/nepht/Projects/void_scriptor_multiplatform`  
Metode: inspeksi read-only terhadap manifest, registry, database migration, persistence services, dan test tree.

## Compatibility layers

| Layer | Current contract | Legacy behavior observed | Future/corrupt behavior | Evidence/status |
|---|---|---|---|---|
| Project package manifest | `ProjectManifest` serializes `format`, `schemaVersion`, `projectId`, timestamps, application metadata, database filename, and tags | `fromJson` accepts legacy `id` when `projectId` is absent; legacy `version` fallback exists beside `projectVersion` | Manifest schema above `VoidProjectFormat.currentSchema` throws `FormatException`; malformed required values can fail parsing | Source inspection of `lib/core/persistence/project_manifest.dart`; compatibility boundary VERIFIED, fixture matrix VERIFIED (2026-08-31, project_compatibility_fixtures_test 8/8) |
| Project registry | JSON object with `schemaVersion: 1` and `projects` list | Missing registry file loads as empty list | Unsupported registry schema throws `FormatException`; malformed JSON throws | `lib/core/persistence/project_registry_service.dart`; local behavior VERIFIED, fixture matrix VERIFIED (2026-08-31, project_compatibility_fixtures_test 8/8) |
| Project database | Drift `ProjectDatabase.currentSchemaVersion = 59` (56 saat audit 2026-08-27) | Ordered `onUpgrade` blocks are present from earlier versions | Old/current/future/corrupt DB matrix terkonsolidasi dan tersertifikasi via 145.40: schema_migration_fixtures_test (CURRENT v59, OLD v53 no-silent-discard, CORRUPT tanpa crash, FUTURE manifest 99, HALF-APPLIED v54..v59, exhaustive invariants v1..v58) | `lib/database/project/project_database.dart`; schema contract VERIFIED (live currentSchemaVersion = 59), compatibility certification VERIFIED(domain) via 145.40 matrix |
| Migration history | `ProjectMigrationHistory` table is registered in the database | Existing migration records can be retained per project | Rollback/forward recovery behavior across every supported old version is not proven by this audit | Generated/database table inventory; forward recovery v1..v59 VERIFIED(domain) via 145.40 exhaustive invariants gate |
| Project open lifecycle | Manifest is read and ID must equal requested `projectId` before database open | Legacy manifest key fallback is handled by parser | ID mismatch throws `StateError`; open failure must not silently create replacement project | `lib/core/persistence/project_open_service.dart`; VERIFIED local boundary |
| Atomic metadata writes | Manifest and registry use `ProjectRecoveryService.atomicWrite` | Previous target is preserved as `.bak` during replacement | Restore is available when target is missing; interrupted write matrix not complete | `project_manifest_service.dart`, `project_recovery_service.dart`; VERIFIED local boundary |
| Portable project format | `VoidProjectFormat` and workspace import/export services exist | Version/source compatibility is represented in code and tests | Corrupt package, missing required files, Checksum/corrupt/rollback matrix teruji eksplisit via 145.33: archive_integrity_test (checksum fail-closed), portable_corrupt_input_test (7 kasus), portable_collision_rollback_test, portable_import_transaction_test, portable_secret_exclusion_test, portable_archive_security_test | `lib/core/project_package/void_project_format.dart`, workspace services/tests; portable matrix VERIFIED(domain) via 145.33 (b805ffe, e8769c8, 991dd53, 1484982, fb57534) |
| User-owned content | Structured records use project-local Drift DB; file assets use project-relative paths where required | Existing records should remain readable through repository/domain parsers | Destructive downgrade and silent discard are forbidden; complete sample-data inventory is not available | Data ownership map and database/repository inventory; policy VERIFIED, sample certification PARTIAL |

## Version inventory

- Application/package project format: `VoidProjectFormat` is the source of format name/current schema; manifest parser accepts current and older supported schema values unless newer than current.
- Manifest registry: schema `1` in `ProjectRegistryService`.
- Project database: Drift schema 56 saat audit 2026-08-27; live saat rekonsiliasi 2026-09-04 = 59 (currentSchemaVersion, lib/database/project/project_database.dart).
- Database migration history: `ProjectMigrationHistory` table is registered in the project database.
- Repository/workspace import/export: live services and test files exist, but this audit does not claim every format version or failure branch is covered.
- No new migration is proposed by this step. D-SCHEMA-01 remains OPEN.

## Compatibility rules before refactor

1. Open an existing package only after validating manifest identity and supported schema.
2. Never downgrade destructively or overwrite a user package during compatibility probing.
3. Preserve the original package/database before migration or conversion; use a disposable copy for fixture tests.
4. Future schema must fail clearly and must not be treated as an empty project.
5. Corrupt manifest/database/package must produce a visible failure or recovery state, never a silently initialized replacement.
6. Legacy aliases (`id`/`projectId`, `version`/`projectVersion`) remain until a deliberate compatibility migration is specified and tested.
7. Database migrations must be additive/ordered according to the live schema contract; do not infer migration numbers from historical sprint text.
8. Binary files and references remain project-relative/canonical; do not convert Desktop/Downloads absolute paths into canonical user data.
9. Compatibility tests must use disposable directories and must not modify real user projects.
10. Do not claim Windows/native compatibility from a source test or a debug build alone.

## Required fixture matrix not yet certified

| Fixture | Required assertion | Current status |
|---|---|---|
| Missing manifest | Clear missing-project/recovery state; no empty replacement | VERIFIED - fixtures test missing manifest surfaces FileSystemException |
| Legacy manifest with `id` and `version` | Parses to canonical identity/version | CERTIFIED - project_compatibility_fixtures_test legacy manifest aliases |
| Current manifest and current-schema DB | Opens, preserves identity, reads content | Local paths/services exist; CERTIFIED - schema_migration_fixtures_test CURRENT v59 + OLD v53 forward migration (fresh 76 PASS, 2026-09-04) |
| Future manifest schema | Rejects with explicit unsupported-schema error | CERTIFIED - project_compatibility_fixtures_test future manifest ditolak sebelum DB tersentuh + FUTURE manifest 99 (schema fixtures) |
| Corrupt JSON manifest/registry | Rejects without destructive write | CERTIFIED - project_compatibility_fixtures_test corrupt registry JSON, original bytes preserved |
| Old database schema | Ordered migration, backup, invariant preservation | CERTIFIED - exhaustive invariants v1..v58 + HALF-APPLIED + OLD v53 (schema_migration_fixtures_test) |
| Future database schema | Refuses unsupported open/migration safely | CERTIFIED - FUTURE manifest 99 ditolak + DB future-schema guard SchemaVersionTooNewException (d76d596, project_database_future_schema_guard_test 3 PASS) |
| Corrupt SQLite/package | Recovery path and no silent data loss | Package layer CERTIFIED - portable_corrupt_input_test 7 kasus + fixture CORRUPT DB tanpa crash; process/OS failure tetap 145.42 |
| Interrupted import/export/restore | Transactional rollback and retained source | Owned partly by 145.42; remaining work is blocked by ownership |
| Missing drive/permission loss | Visible recoverable state and no replacement project | Owned by 145.42; not executed here |

## Evidence boundaries

### VERIFIED

- Live source location and database schema ownership are known.
- Manifest has explicit version/schema identity and future-schema rejection.
- Registry has explicit schema version and unsupported-version rejection.
- Project open validates manifest ID before database open.
- Atomic write/backup/restore primitives exist.

### PARTIAL

- Full old/current/future/corrupt fixture matrix. (CLOSED via 145.40, lihat update block 2026-09-04)
- All migration-version restart and invariant tests. (CLOSED via 145.40 exhaustive invariants v1..v58 + HALF-APPLIED)
- Portable import/export checksum and rollback certification. (CLOSED via 145.33 matrix)
- User sample-data inventory across real packages.

### BLOCKED / DEFERRED

- Process kill, power loss, disk full, permission loss, drive removal, and interrupted transfer scenarios remain under 145.42's ownership.
- Native Windows compatibility beyond the fresh debug build remains separate from local source evidence.
- No credentials, real user package, or production data was accessed or copied.

## Decision

`145.12 Existing User Data Compatibility` berstatus **VERIFIED — audit and compatibility rules verified, audit rows reconciled 2026-09-04 dgn bukti landed 145.40/145.33; sisa scope terdelegasi tetap tercatat**. Tidak ada code, schema, migration, database, atau user data yang diubah. Langkah berikutnya yang aman adalah `145.13 Product Promise Lock`, yang memerlukan keputusan scope produk, bukan implementasi persistence baru.

## Evidence paths

- `lib/core/persistence/project_manifest.dart`
- `lib/core/persistence/project_manifest_service.dart`
- `lib/core/persistence/project_registry_service.dart`
- `lib/core/persistence/project_open_service.dart`
- `lib/core/persistence/project_recovery_service.dart`
- `lib/core/project_package/void_project_format.dart`
- `lib/database/project/project_database.dart`
- `lib/database/project/project_database.g.dart`
- `lib/features/workspaces/application/workspace_import_service.dart`
- `lib/features/workspaces/application/workspace_export_service.dart`

---

## Update fixture matrix certification — 2026-08-31 (nephthys)

Gap yang tersisa pada audit 2026-08-27: fixture matrix manifest/registry/open
belum di-certify sebagai acceptance test. Run ini menambahkan
`test/core/persistence/project_compatibility_fixtures_test.dart` (8 test) yang
mengunci perilaku berikut sebagai contract (semua langsung PASS — behavior
sudah ada di production code, baru sekarang di-lock sebagai acceptance):

| Fixture | Assertion | Status |
|---|---|---|
| Legacy manifest `id`/`version`/string-`database` aliases | Parses to canonical identity/version/databaseFilename | VERIFIED |
| Future manifest schema (`currentSchema + 1`) | Rejected with `FormatException` | VERIFIED |
| Missing manifest file | `FileSystemException` surfaces; no silent default project | VERIFIED |
| Missing registry file | Loads as empty; does NOT create a file | VERIFIED |
| Corrupt registry JSON | Load fails; original bytes preserved (no destructive overwrite) | VERIFIED |
| Future registry schema (`2`) | Rejected with `FormatException` | VERIFIED |
| Manifest ID mismatch on open | `StateError` before database open | VERIFIED |
| Future-schema manifest on open | `FormatException`; database never touched | VERIFIED |

Evidence:
- `flutter test test/core/persistence/project_compatibility_fixtures_test.dart` → 8/8 PASS
- `flutter analyze` → No issues found!
- `flutter test` (full) → 3200/3200 PASS (termasuk 8 test baru)
- Windows debug build: PASS (build/windows/x64/runner/Debug/void_scriptor.exe); native UI proof tetap gate terpisah

Masih di luar scope langkah ini (dimiliki langkah lain):
- Full old/current/future/corrupt **database** migration matrix → 145.40
- Process kill/power loss/disk full/permission loss/drive removal →
  145.42
- User sample-data inventory across real packages → butuh data user nyata,
  tidak boleh dikarang dari source-only
- Native Windows compatibility → gate terpisah (build/native proof)


---

## Update 2026-09-04 (nephthys cron, rekonsiliasi baris audit dengan bukti landed)

Temuan: tabel audit 2026-08-27 masih menyimpan angka schema 56 dan label
fixture matrix PARTIAL / not certified, padahal bukti 145.40 (schema+migration
fixtures) dan 145.33 (portable) sudah landed dan tersertifikasi di ledger.
Rekonsiliasi doc-only, tanpa kode produksi/test baru:

- Row Project database: currentSchemaVersion 56 adalah observasi 2026-08-27;
  live saat rekonsiliasi = 59.
- Row Manifest/Registry: fixture matrix naik PARTIAL -> VERIFIED (matrix 8/8
  terbukti 2026-08-31, fresh ulang run ini).
- Row Migration history + Portable: forward recovery v1..v59 dan matrix
  checksum/corrupt/collision/transaction/secret/security naik ke
  VERIFIED(domain) per 145.40 + 145.33.
- Required fixture matrix: 5 baris (missing manifest, legacy manifest,
  future manifest, current DB, old DB, future DB, corrupt package) naik ke
  CERTIFIED dengan test pemberi bukti eksplisit.
- Tetap di luar step ini: process/power/disk/permission/drive failure matrix
  (145.42), sample-data inventory user nyata, native Windows proof
  (gate terpisah).

Bukti fresh (Windows host, HEAD 49a1173):
- flutter test 8 file compatibility+fixtures+portable -> 93 PASS / 0 FAIL
  (All tests passed!).
- dart run tool/roadmap_guard.dart -> PASS (pre-run).
