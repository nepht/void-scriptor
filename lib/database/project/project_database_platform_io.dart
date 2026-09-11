import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'project_database.dart';

Future<ProjectDatabase> openProjectDatabase(String databasePath) async {
  // core-hunt run197 BUG-16: the catch-close-rethrow contract now lives in
  // the shared platform-agnostic helper so the web seam mirrors it exactly.
  final database = ProjectDatabase(NativeDatabase(File(databasePath)));
  return await initializeDatabaseOrClose(database);
}

Future<ProjectDatabase> openProjectDatabaseReadOnly(String databasePath) async {
  final raw = sqlite.sqlite3.open(databasePath, mode: sqlite.OpenMode.readOnly);
  final database = ProjectDatabase(
    NativeDatabase.opened(raw, enableMigrations: false),
  );
  // core-hunt run197 BUG-13 companion: a failed probe query (missing table,
  // corrupt header) used to leak the raw read-only handle, keeping the file
  // locked on Windows after the caller received the classified error.
  // Mirror openProjectDatabase's hardening: close, then rethrow.
  try {
    await database.customSelect('SELECT 1').getSingle();
    return database;
  } on Object {
    await database.close();
    rethrow;
  }
}

Future<void> createProjectDatabase(String databasePath) async {
  final database = ProjectDatabase(NativeDatabase(File(databasePath)));
  try {
    await database.initialize();
  } finally {
    await database.close();
  }
}

Future<int?> readProjectDatabaseSchemaVersion(String databasePath) async {
  final file = File(databasePath);
  if (!await file.exists()) return null;
  final database = sqlite.sqlite3.open(
    databasePath,
    mode: sqlite.OpenMode.readOnly,
  );
  try {
    return database.select('PRAGMA user_version').single['user_version']
        as int?;
  } on sqlite.SqliteException {
    // Sprint 145.40: a corrupt database is reported as unreadable
    // (null) instead of crashing the caller that only probes the
    // schema version.
    return null;
  } finally {
    database.close();
  }
}

/// Sprint 145.42 write-probe execution (moved behind the platform seam so
/// the ffi singleton stays out of the web compile, 145.44 CI Build Web
/// release). Purity contract lives on [ProjectDatabaseService.probeWrite].
Future<void> probeProjectDatabaseWrite(String databasePath) async {
  final raw = sqlite.sqlite3.open(databasePath);
  try {
    raw.execute('BEGIN IMMEDIATE');
    raw.execute(
      'CREATE TABLE IF NOT EXISTS __scriptor_write_probe '
      '(id INTEGER PRIMARY KEY)',
    );
    raw.execute('DROP TABLE __scriptor_write_probe');
    // COMMIT adalah pernyataan terakhir: setelah titik ini tidak ada
    // langkah cleanup yang bisa tertinggal; sebelum titik ini semua
    // perubahan masih bisa di-rollback.
    raw.execute('COMMIT');
  } on sqlite.SqliteException {
    try {
      raw.execute('ROLLBACK');
    } on sqlite.SqliteException {
      // best-effort: koneksi ditutup di finally.
    }
    rethrow;
  } finally {
    try {
      // VACUUM merebut kembali halaman kosong dari freelist,
      // mengembalikan ukuran file utama ke posisi sebelum probe.
      // Untuk database kecil (page size 4 KiB) ini hanya satu
      // halaman dan selesai cepat.
      raw.execute('VACUUM');
      raw.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    } on sqlite.SqliteException {
      // best-effort saat probe gagal
    }
    raw.close();
  }
}
