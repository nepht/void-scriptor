import 'dart:io';

import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'project_database.dart';
import 'project_database_platform.dart'
    if (dart.library.io) 'project_database_platform_io.dart'
    if (dart.library.js_interop) 'project_database_platform_web.dart';

/// Sprint 145.33 future-schema guard: opening a database whose user_version
/// is NEWER than [ProjectDatabase.currentSchemaVersion] would let the drift
/// migration wave rewrite and silently downgrade a file produced by a newer
/// schema. The production open path therefore refuses the file outright so
/// the user can upgrade the application first.
class SchemaVersionTooNewException implements Exception {
  SchemaVersionTooNewException(this.actualVersion, this.supportedVersion);

  final int actualVersion;
  final int supportedVersion;

  @override
  String toString() =>
      'SchemaVersionTooNewException: database schema v$actualVersion is '
      'newer than the supported v$supportedVersion; upgrade the '
      'application before opening this project';
}

/// Sprint 145.42 (Data Safety Failure Matrix) - concurrent open pada layer
/// database. Sebuah writer lain sedang menahan file (SHARED+RESERVED)
/// sehingga drift `BEGIN IMMEDIATE` gagal dengan SQLITE_BUSY (extended
/// result code 5). File sehat, hanya terkunci - bukan corruption. Probe
/// readOnly untuk schema version masih berhasil sehingga guard
/// [SchemaVersionTooNewException] tidak berlaku.
/// Storage proyek ada tetapi sedang tidak dapat dibuka untuk menulis:
/// writer lain memegang lock (SQLITE_BUSY). Database sendiri bisa saja
/// sehat.
class ProjectDatabaseLockedException implements Exception {
  ProjectDatabaseLockedException(this.databasePath, this.cause);

  final String databasePath;

  /// The underlying engine failure (e.g. SQLITE_BUSY).
  final Object cause;

  @override
  String toString() =>
      'ProjectDatabaseLockedException: database at $databasePath is '
      'locked by another writer ($cause)';
}

/// Sprint 145.42 (Data Safety Failure Matrix) - corrupt database on the
/// production open path. A database file that exists but cannot be opened
/// as SQLite (truncated write, disk corruption, bad device) must surface a
/// typed domain failure - the same contract family as
/// [SchemaVersionTooNewException] - instead of leaking a raw
/// [sqlite.SqliteException] out of drift initialization.
class ProjectDatabaseUnreadableException implements Exception {
  ProjectDatabaseUnreadableException(this.databasePath, this.cause);

  final String databasePath;

  /// The underlying engine failure (e.g. SQLITE_NOTADB).
  final Object cause;

  @override
  String toString() =>
      'ProjectDatabaseUnreadableException: database at $databasePath '
      'is not a readable SQLite database ($cause)';
}

/// Storage yang berisi database tidak lagi terjangkau: drive dilepas,
/// jalur storage hilang, atau target bukan file yang bisa dipakai
/// sebagai database (SQLITE_CANTOPEN / path error). Database pada
/// storage yang terjangkau bisa saja sehat - ini bukan klasifikasi
/// korup.
class ProjectDatabaseUnavailableException implements Exception {
  ProjectDatabaseUnavailableException(this.databasePath, this.cause);

  final String databasePath;

  final Object cause;

  @override
  String toString() =>
      'ProjectDatabaseUnavailableException: storage at $databasePath '
      'is not reachable ($cause)';
}

/// Sprint 145.42 (Data Safety Failure Matrix) - write failure pada layer
/// database SQLite yang hanya bisa diamati setelah koneksi read-write
/// berhasil dibuka. [ProjectDatabaseService.open] lolos karena probe
/// readOnly tidak butuh menulis; namun media write-protected,
/// permission loss, atau storage penuh baru memicu kegagalan saat
/// mutasi pertama. [probeWrite] mengekspos permukaan ini sebagai
/// keadaan bertipe yang terpisah dari [ProjectDatabaseUnreadableException]
/// (korut) dan [ProjectDatabaseUnavailableException] (storage tak
/// terjangkau) - database sendiri sehat, hanya media tulis yang tidak
/// tersedia.
class ProjectDatabaseWriteFailedException implements Exception {
  ProjectDatabaseWriteFailedException(this.databasePath, this.cause);

  final String databasePath;

  /// Underlying sqlite3 error code (8 = SQLITE_READONLY,
  /// 13 = SQLITE_FULL, 778 = SQLITE_IOERR_WRITE, dll).
  final Object cause;

  @override
  String toString() =>
      'ProjectDatabaseWriteFailedException: storage backing $databasePath '
      'rejected a write ($cause)';
}

/// Pure classification of sqlite result codes on the project open path
/// (bug-hunt run94 BUG-13: never compare extended codes after masking
/// with 0xFF).
///
/// Family decisions use the **unmasked** extended result code (SQLITE_BUSY
/// 5, SQLITE_READONLY 8, SQLITE_FULL 13, SQLITE_IOERR_WRITE 778,
/// SQLITE_CANTOPEN 14); the **primary** code is consulted only for the one
/// contract that loses meaning under masking: SQLITE_IOERR (primary 10).
/// 778 & 0xFF = 10, so the previous `code == 778` comparison against the
/// masked value could never match and the whole IOERR family
/// (10/266/522/778/1034/...) fell through to the corruption
/// classification even though the database itself may be healthy.
Exception classifyProjectDatabaseOpenError(
  String databasePath,
  sqlite.SqliteException error,
) {
  // SQLITE_BUSY (extended result code 5): the file is healthy but another
  // writer holds SHARED+RESERVED. The read-only schema probe succeeded,
  // so this is neither future-schema nor corruption.
  if (error.extendedResultCode == 5) {
    return ProjectDatabaseLockedException(databasePath, error);
  }
  // SQLITE_READONLY (8) / SQLITE_FULL (13): the file is schema-valid but
  // drift initialization writes project_metadata on first open - the same
  // surface as media-level permission loss and a full storage volume.
  if (error.extendedResultCode == 8 || error.extendedResultCode == 13) {
    return ProjectDatabaseWriteFailedException(databasePath, error);
  }
  // SQLITE_IOERR_WRITE (778) and the whole SQLITE_IOERR family
  // (primary 10): media-level I/O failure while opening or writing -
  // a write failure, not proof of corruption.
  if (error.extendedResultCode == 778 ||
      error.resultCode == 10 /* SQLITE_IOERR */ ) {
    return ProjectDatabaseWriteFailedException(databasePath, error);
  }
  // SQLITE_CANTOPEN (14): the file cannot be opened/created - storage is
  // unreachable, not proof of corruption.
  if (error.extendedResultCode == 14) {
    return ProjectDatabaseUnavailableException(databasePath, error);
  }
  return ProjectDatabaseUnreadableException(databasePath, error);
}

class ProjectDatabaseService {
  Future<void> create(String databasePath) =>
      createProjectDatabase(databasePath);

  Future<ProjectDatabase> open(String databasePath) async {
    final onDisk = await readProjectDatabaseSchemaVersion(databasePath);
    // Sprint 145.42: a missing database file is an unavailable
    // storage state, never a license to silently create an empty
    // database - ProjectDatabaseService.create() is the only
    // production creator.
    if (!File(databasePath).existsSync()) {
      throw ProjectDatabaseUnavailableException(
        databasePath,
        StateError('database file does not exist'),
      );
    }
    if (onDisk != null && onDisk > ProjectDatabase.currentSchemaVersion) {
      throw SchemaVersionTooNewException(
        onDisk,
        ProjectDatabase.currentSchemaVersion,
      );
    }
    try {
      return await openProjectDatabase(databasePath);
    } on FileSystemException catch (error) {
      // Drive dilepas / jalur storage hilang: drift membocorkan
      // PathNotFoundException mentah sebelum sqlite3 sempat membuka
      // file. Ini keadaan storage tak terjangkau, bukan korupsi.
      throw ProjectDatabaseUnavailableException(databasePath, error);
    } on sqlite.SqliteException catch (error) {
      throw classifyProjectDatabaseOpenError(databasePath, error);
    }
  }

  Future<ProjectDatabase> openReadOnly(String databasePath) =>
      openProjectDatabaseReadOnly(databasePath);

  Future<int?> schemaVersion(String databasePath) =>
      readProjectDatabaseSchemaVersion(databasePath);

  /// Sprint 145.42 (Data Safety Failure Matrix) - probe tulis opsional
  /// yang memverifikasi storage di balik [databasePath] benar-benar
  /// menerima tulisan. Berhasil diam, melempar
  /// [ProjectDatabaseWriteFailedException] ketika media menolak (read-
  /// only attribute, permission loss, disk full).
  ///
  /// Kontrak purity (bug-hunt run94 BUG-07/BUG-08):
  /// - CREATE + DROP tabel probe dalam SATU transaksi; COMMIT adalah
  ///   pernyataan terakhir sehingga tidak ada jendela crash yang
  ///   menyisakan tabel [__scriptor_write_probe] di database pengguna.
  ///   Kegagalan apa pun sebelum COMMIT di-rollback.
  /// - Mode jurnal pengguna TIDAK diubah (tanpa
  ///   PRAGMA journal_mode = WAL): mengubahnya adalah modifikasi
  ///   bentuk data aplikasi yang permanen.
  /// - Sidecar -wal/-shm TIDAK pernah dihapus: menghapus WAL milik
  ///   koneksi hidup membuang transaksi yang sudah di-commit.
  /// - VACUUM + wal_checkpoint(TRUNCATE) best-effort mengembalikan
  ///   ukuran file ke posisi sebelum probe.
  Future<void> probeWrite(String databasePath) async {
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
    } on sqlite.SqliteException catch (error) {
      try {
        raw.execute('ROLLBACK');
      } on sqlite.SqliteException {
        // best-effort: koneksi ditutup di finally.
      }
      // Setiap SqliteException dari jalur tulis adalah klasifikasi
      // media tulis: SQLITE_READONLY (8) = file/direktori write-
      // protected; SQLITE_FULL (13) = disk penuh; SQLITE_IOERR_WRITE
      // (778) = I/O error saat fsync; SQLITE_CANTOPEN (14) = WAL
      // sidecar tidak bisa dibuat. Bukan korup dan bukan storage
      // hilang - database sendiri bisa saja sehat.
      throw ProjectDatabaseWriteFailedException(databasePath, error);
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
}
