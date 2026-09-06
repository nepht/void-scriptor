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
      final code = error.extendedResultCode & 0xFF;
      // SQLITE_BUSY (extended result code 5) berarti file sehat tetapi
      // writer lain sedang memegang SHARED+RESERVED. Probe schema
      // readOnly berhasil, jadi bukan future-schema dan bukan korup.
      if (code == 5) {
        throw ProjectDatabaseLockedException(databasePath, error);
      }
      // SQLITE_READONLY (8): file atau direktori write-protected.
      // File masih schema-valid (probe readOnly berhasil), namun drift
      // initialize() menulis project_metadata saat pertama kali
      // membuka koneksi - permukaan yang sama dengan permission loss
      // tingkat media dan storage penuh (SQLITE_FULL). Buka harus
      // gagal dengan klasifikasi write-failure, bukan dikira korut.
      if (code == 8 || code == 13 || code == 778) {
        throw ProjectDatabaseWriteFailedException(databasePath, error);
      }
      // SQLITE_CANTOPEN (14): file tidak bisa dibuka/dibuat - storage
      // tidak terjangkau, bukan bukti database korut.
      if (code == 14) {
        throw ProjectDatabaseUnavailableException(databasePath, error);
      }
      throw ProjectDatabaseUnreadableException(databasePath, error);
    }
  }

  Future<ProjectDatabase> openReadOnly(String databasePath) =>
      openProjectDatabaseReadOnly(databasePath);

  Future<int?> schemaVersion(String databasePath) =>
      readProjectDatabaseSchemaVersion(databasePath);

  /// Sprint 145.42 (Data Safety Failure Matrix) - probe tulis opsional
  /// yang mengeksekusi mutasi atomik dalam transaksi ROLLBACK untuk
  /// memastikan storage di balik [databasePath] benar-benar menerima
  /// tulisan. Berhasil diam, melempar
  /// [ProjectDatabaseWriteFailedException] ketika media menolak (read-
  /// only attribute, permission loss, disk full). TIDAK memodifikasi
  /// data aplikasi - probe di-rollback setelah eksekusi.
  Future<void> probeWrite(String databasePath) async {
    final walSidecar = File('$databasePath-wal');
    final shmSidecar = File('$databasePath-shm');
    final raw = sqlite.sqlite3.open(databasePath);
    try {
      // Memaksa satu mutasi durable ke file utama, lalu membersihkannya
      // di transaksi kedua. Journal DELETE (default sqlite3) tidak
      // menyentuh file tanpa COMMIT, jadi rollback tidak berguna di
      // sini - kita harus menulis dan menghapus.
      raw.execute('PRAGMA journal_mode = WAL');
      raw.execute('BEGIN IMMEDIATE');
      raw.execute(
        'CREATE TABLE IF NOT EXISTS __scriptor_write_probe '
        '(id INTEGER PRIMARY KEY)',
      );
      raw.execute(
        'INSERT OR REPLACE INTO __scriptor_write_probe (id) '
        'VALUES (1)',
      );
      raw.execute('COMMIT');
      raw.execute('BEGIN IMMEDIATE');
      raw.execute('DELETE FROM __scriptor_write_probe');
      raw.execute('COMMIT');
      raw.execute('DROP TABLE IF EXISTS __scriptor_write_probe');
    } on sqlite.SqliteException catch (error) {
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
    // Pasca-close: hapus sidecar kosong jika WAL sempat diaktifkan
    // atau file jurnal DELETE tidak ter-reclaim otomatis.
    for (final sidecar in [walSidecar, shmSidecar]) {
      if (sidecar.existsSync()) {
        try {
          sidecar.deleteSync();
        } on FileSystemException {
          // best-effort
        }
      }
    }
  }
}
