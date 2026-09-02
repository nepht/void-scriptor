# Sprint 145.40 — Schema and Migration Fixtures

Tanggal audit: 2026-08-27
Sumber kanonik: `sprint_145.json`, item `145.40`.
Status: **PARTIAL**.

## Kontrak kanonik

Version Core schemas, create old/current/future/corrupt fixtures, ordered migrations, invariant checks, backups, rollback/forward recovery, and no silent data discard.

## Evidence terverifikasi

- `ProjectManifest` serializes `schemaVersion` and rejects future unsupported versions with `FormatException`.
- `ProjectRegistryService` persists registry schema version and rejects unsupported registry versions.
- Current project database schema is exposed and current package can reopen after migration.
- Existing RC migration matrix verifies fresh current install, v53-to-v56 upgrade, and ordered migration waves.
- Migration failure recovery preserves the original database file through backup/restore.
- Corrupt manifest and corrupt database are reported by health service without crashing the health check.
- Atomic project file replacement retains `.bak` and restores it on failure.
- Resilience metadata survives database restart.
- Focused schema/persistence/recovery suite: **32 tests passed**.

Command:

```bash
flutter test \
  test/core/project_package/project_package_test.dart \
  test/core/project_package/project_package_service_test.dart \
  test/core/project_package/project_package_roundtrip_test.dart \
  test/core/persistence/project_persistence_test.dart \
  test/release/rc_migration_recovery_test.dart \
  test/database/project/database_index_migration_test.dart \
  test/features/project_resilience/project_recovery_services_test.dart \
  test/features/project_resilience/project_resilience_test.dart
```

## Gaps

- Tidak ada fixture directory terstruktur yang secara eksplisit memuat old/current/future/corrupt untuk kontrak Sprint 145.
- Invariant checks lintas seluruh ordered migrations belum menjadi satu gate terpisah.
- Forward recovery setelah interrupted migration belum dibuktikan sebagai workflow mandiri.
- No-silent-data-discard belum diverifikasi dengan fixture before/after yang lengkap untuk semua tabel Core.
- Existing migration recovery test memakai skenario RC historis; provenance-nya bukan acceptance fixture 145 yang baru.
- `D-SCHEMA-01` masih OPEN; tidak ada schema bump atau migration baru dibuat dalam audit ini.
- Native clean-Windows fixture execution belum terverifikasi.

## Verdict

`PARTIAL`: schema versioning, unsupported-version rejection, migration waves, corruption detection, backup, dan rollback memiliki evidence nyata. Fixture matrix Sprint 145, exhaustive invariants, forward recovery, no-silent-discard proof, dan clean-Windows execution belum lengkap.

## Non-actions

Tidak ada migration baru, perubahan generated Drift, schema bump, cleanup, pemindahan data, commit, push, atau tag.

## Next

Langkah kanonik berikutnya: 145.41 — Core Automated Test Pyramid.

## Provenance

Jenis evidence: source inspection, database/persistence integration tests, migration recovery tests. Tidak mencakup native Windows execution atau production readiness.

nephthys — 2026-08-27

---

## Update 2026-09-02 - fixture matrix slice (nephthys cron)

**Status tetap `PARTIAL`; satu gap utama ditutup.**

- `readProjectDatabaseSchemaVersion` kini menangkap `SqliteException` dan
  mengembalikan `null` untuk file yang tidak dapat dibaca sebagai database
  (commit 58d57b5). Sebelumnya probe korup melempar `SqliteException(26)`
  "file is not a database" ke pemanggil.
- Fixture matrix dedikasi Sprint 145.40 landed:
  `test/features/project_resilience/schema_migration_fixtures_test.dart`
  (4 test PASS):
  - CURRENT: create fresh -> user_version 59, reopen stabil no-op.
  - OLD (v53): seed full-v59 + rewind faithful (drop tabel v54-57, drop kolom
    voice v58, drop tiga tabel scope v59, user_version=53) -> open menjalankan
    wave migrasi 53->59, baris Character Core utuh (no silent discard), kolom
    voice kembali dengan default, tiga tabel scope layer v59 hadir.
  - CORRUPT: 512 byte 0xAB -> `schemaVersion()` null tanpa crash; open tetap
    melempar kegagalan (tidak ada half-initialized DB).
  - FUTURE: manifest `schemaVersion: 99` ditolak `FormatException` pada read.
- Bukti eksekusi: focused 4 PASS; regression persistence+resilience+release+
  project_package 113 PASS; flutter analyze No issues found!; git diff --check
  PASS; flutter build windows --debug PASS 62.0s.
- Sisa gap: exhaustive invariants lintas seluruh ordered migrations sebagai
  gate terpisah; forward recovery setelah interrupted migration sebagai
  workflow mandiri; clean-Windows E2E execution; provenance D-SCHEMA-01 tidak
  berubah (tidak ada schema bump; v59 adalah state kanonik live).

nephthys - 2026-09-02

---

## Update 2026-09-02 (run 2) - interrupted migration forward recovery (nephthys cron)

**Status tetap `PARTIAL`; gap "forward recovery setelah interrupted migration"
sebagai workflow teruji ditutup.**

- Bukti sumber drift 2.34.3: `user_version` di-set hanya SETELAH `onUpgrade`
  selesai (`_BaseExecutor` -> `versionDelegate.setSchemaVersion(currentVersion)`
  setelah `beforeOpen`), dan `Migrator.createTable` menghasilkan
  `CREATE TABLE IF NOT EXISTS` (idempotent), sedangkan `Migrator.addColumn`
  menghasilkan `ALTER TABLE ... ADD COLUMN` (tidak idempotent). Artinya crash
  di tengah wave meninggalkan state setengah-jadi yang membuat open berikutnya
  gagal "duplicate column name".
- RED terverifikasi: fixture HALF-APPLIED (wave objects 54..59 dibuat manual
  via raw sqlite3, `user_version` tetap 53) membuat open crash dengan
  `SqliteException(1): duplicate column name: voice` pada wave v58.
- GREEN: guard forward recovery di wave `from < 58`
  (`lib/database/project/project_database.dart`) mem-probe kolom live dengan
  `SELECT voice FROM characters LIMIT 1` sebelum `m.addColumn`; create-table
  waves sudah idempotent sejak awal.
- Test baru:
  `test/features/project_resilience/schema_migration_fixtures_test.dart`
  "HALF-APPLIED wave objects with stale user_version still reopen cleanly" -
  simulasi crash state via koneksi sqlite3 mentah (tanpa migrator drift,
  definisi kolom eksak hasil `m.addColumn`: `TEXT NOT NULL DEFAULT ''`),
  lalu membuktikan open sukses ke v59 dengan baris Character Core utuh
  (no silent discard).
- Bukti eksekusi: focused 5/5 PASS; regresi
  project_resilience+release+database 92 PASS (0 test failure; satu-satunya
  entri [E] adalah path suite salah `test/features/project_package` yang
  tidak ada di tree, bukan kegagalan test); `flutter analyze` No issues;
  `flutter build windows --debug` PASS 28.2s; `git diff --check` PASS;
  full suite 3343 PASS / 1 FAIL (`app_bootstrap_test`, root-caused konkuren
  145.20, untouched, konsisten sepanjang sejarah run).
- Commit: ed0f35f (fix + test slice). Sisa gap 145.40: exhaustive invariants
  gate lintas seluruh ordered migrations, clean-Windows E2E execution;
  provenance D-SCHEMA-01 tidak berubah (tidak ada schema bump).

nephthys - 2026-09-02 (run 2)

---

## Update 2026-09-03 (nephthys cron) - exhaustive invariants gate CLOSED

**Status tetap `PARTIAL` (clean-Windows E2E execution masih open); gap
"exhaustive invariants gate lintas seluruh ordered migrations sebagai gate
terpisah" ditutup.**

- Gate exhaustif baru:
  `test/features/project_resilience/schema_migration_fixtures_test.dart`
  group "145.40 exhaustive invariants gate" - 58 test (entry v1..v58).
  Setiap test: fresh v59 create -> seed 1 baris Core asset -> rewind
  `PRAGMA user_version` ke entry version (state eksak yang ditinggalkan
  proses crash mid-wave, karena drift hanya menaikkan user_version setelah
  onUpgrade selesai) -> reopen -> asersi user_version 59, baris Core utuh
  (no silent data discard), tanpa crash.
- RED terverifikasi sebelum guard produksi: tanpa guard, entry v1..v16
  crash `SqliteException(1)` (duplicate column name: favorite / project_id,
  dst.) - addColumn waves v3/v7/v8/v9/v15/v16/v17 tidak idempotent
  terhadap schema yang sudah memuat kolomnya. Crash mid-wave yang nyata
  akan meninggalkan database yang tidak bisa dibuka ulang.
- GREEN (produksi, `lib/database/project/project_database.dart`): helper
  `_columnExists(table, column)` (PRAGMA table_info probe) dan guard
  forward-recovery pada SEMUA wave addColumn: asset_relations
  (project_id/created_at/relation_origin), character_loadout_entries
  (quantity), character_identity_profiles (weapon_lock), character_modes
  (accent_color/tags_json), assets (favorite/last_opened_at),
  character_identity_profiles (accessory_lock/notes),
  character_modes (reference_set_id), story_scenes (reference_set_id),
  characters (voice - guard v58 lama digeneralisasi ke helper yang sama).
  Drift createTable waves sudah idempotent (CREATE TABLE IF NOT EXISTS).
- Bukti eksekusi: focused 63 PASS (4 fixture matrix + 1 half-applied
  recovery + 58 gate); regresi project_resilience + release + database
  150 PASS; `flutter analyze` No issues found! (8.2s); `git diff --check`
  PASS; full suite dan windows debug build dieksekusi di run ini
  (lihat ledger).
- Sisa gap 145.40: clean-Windows E2E execution; D-SCHEMA-01 tetap OPEN
  (tidak ada schema bump; v59 tetap state kanonik live).

nephthys - 2026-09-03
