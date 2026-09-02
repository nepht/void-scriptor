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
