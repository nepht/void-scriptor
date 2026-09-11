import 'dart:io';

import 'package:sqlite3/common.dart' as sqlite;

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
/// with 0xFF; bug-hunt run197 BUG-11: extended VARIANTS of a handled
/// family must classify with their family, never fall through to
/// corruption).
///
/// Family decisions use the **primary** code (`resultCode` =
/// `extendedResultCode & 0xFF`): per sqlite.org/rescode.html every
/// extended result code is `primary | (n << 8)` and refines - never
/// contradicts - its primary family (SQLITE_BUSY_SNAPSHOT 517 and
/// SQLITE_BUSY_RECOVERY 261 are BUSY; SQLITE_LOCKED_SHAREDCACHE 262 is
/// LOCKED; SQLITE_READONLY_DIRECTORY 1032 is READONLY; SQLITE_CANTOPEN_
/// FULLPATH 782 is CANTOPEN). Masking is safe here because none of the
/// corruption codes (SQLITE_CORRUPT 11, SQLITE_NOTADB 26) collides with
/// the handled families (5/6/8/10/13/14).
Exception classifyProjectDatabaseOpenError(
  String databasePath,
  sqlite.SqliteException error,
) {
  final primary = error.resultCode; // extendedResultCode & 0xFF
  // SQLITE_BUSY (5) / SQLITE_LOCKED (6), including every extended variant:
  // the file is healthy but another connection holds a lock. The read-only
  // schema probe succeeded, so this is neither future-schema nor corruption.
  if (primary == 5 || primary == 6) {
    return ProjectDatabaseLockedException(databasePath, error);
  }
  // SQLITE_READONLY (8) / SQLITE_FULL (13), including every extended
  // variant (SQLITE_READONLY_RECOVERY 264, ...): the file is schema-valid
  // but drift initialization writes project_metadata on first open - the
  // same surface as media-level permission loss and a full storage volume.
  if (primary == 8 || primary == 13) {
    return ProjectDatabaseWriteFailedException(databasePath, error);
  }
  // SQLITE_IOERR family (primary 10: 266/522/778/1034/...): media-level
  // I/O failure while opening or writing - a write failure, not proof of
  // corruption.
  if (primary == 10) {
    return ProjectDatabaseWriteFailedException(databasePath, error);
  }
  // SQLITE_CANTOPEN (14), including every extended variant
  // (270/526/782/1038): the file cannot be opened/created - storage is
  // unreachable, not proof of corruption.
  if (primary == 14) {
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

  /// core-hunt run197 BUG-13: the read-only leg used to bypass the open
  /// classification wrapper, leaking a raw SqliteException for missing,
  /// corrupt, or BUSY databases on this path. Mirror open()'s typed
  /// contract: missing file -> unavailable, SqliteException ->
  /// classifyProjectDatabaseOpenError. A web UnsupportedError is a
  /// platform-capability gap, not a storage state, and propagates
  /// unchanged (same contract as probeProjectDatabaseWrite on web).
  Future<ProjectDatabase> openReadOnly(String databasePath) async {
    if (!File(databasePath).existsSync()) {
      throw ProjectDatabaseUnavailableException(
        databasePath,
        StateError('database file does not exist'),
      );
    }
    try {
      return await openProjectDatabaseReadOnly(databasePath);
    } on FileSystemException catch (error) {
      throw ProjectDatabaseUnavailableException(databasePath, error);
    } on sqlite.SqliteException catch (error) {
      throw classifyProjectDatabaseOpenError(databasePath, error);
    }
  }

  Future<int?> schemaVersion(String databasePath) =>
      readProjectDatabaseSchemaVersion(databasePath);

  /// Sprint 145.42 (Data Safety Failure Matrix) - probe tulis opsional
  /// yang memverifikasi storage di balik [databasePath] benar-benar
  /// menerima tulisan. Berhasil diam, melempar
  /// [ProjectDatabaseWriteFailedException] ketika media menolak (read-
  /// only attribute, permission loss, disk full).
  ///
  /// Kontrak purity (bug-hunt run94 BUG-07/BUG-08) dipertahankan oleh
  /// implementasi platform di [probeProjectDatabaseWrite]:
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
  ///
  /// Eksekusi berada di belakang seam platform: ffi singleton sqlite3
  /// tidak tersedia di web (145.44 CI Build Web release), sementara
  /// klasifikasi [SqliteException] pada open() tetap dibagikan lewat
  /// package:sqlite3/common.dart.
  Future<void> probeWrite(String databasePath) async {
    try {
      await probeProjectDatabaseWrite(databasePath);
    } on sqlite.SqliteException catch (error) {
      // Setiap SqliteException dari jalur tulis adalah klasifikasi
      // media tulis: SQLITE_READONLY (8) = file/direktori write-
      // protected; SQLITE_FULL (13) = disk penuh; SQLITE_IOERR_WRITE
      // (778) = I/O error saat fsync; SQLITE_CANTOPEN (14) = WAL
      // sidecar tidak bisa dibuat. Bukan korup dan bukan storage
      // hilang - database sendiri bisa saja sehat.
      throw ProjectDatabaseWriteFailedException(databasePath, error);
    }
  }
}
