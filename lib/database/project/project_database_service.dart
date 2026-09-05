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

class ProjectDatabaseService {
  Future<void> create(String databasePath) =>
      createProjectDatabase(databasePath);

  Future<ProjectDatabase> open(String databasePath) async {
    final onDisk = await readProjectDatabaseSchemaVersion(databasePath);
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
      // SQLITE_BUSY (extended result code 5) berarti file sehat tetapi
      // writer lain sedang memegang SHARED+RESERVED. Probe schema
      // readOnly berhasil, jadi bukan future-schema dan bukan korup.
      if ((error.extendedResultCode & 0xFF) == 5) {
        throw ProjectDatabaseLockedException(databasePath, error);
      }
      if ((error.extendedResultCode & 0xFF) == 14) {
        // SQLITE_CANTOPEN: file tidak bisa dibuka/dibuat - storage
        // tidak terjangkau, bukan bukti database korut.
        throw ProjectDatabaseUnavailableException(databasePath, error);
      }
      throw ProjectDatabaseUnreadableException(databasePath, error);
    }
  }

  Future<ProjectDatabase> openReadOnly(String databasePath) =>
      openProjectDatabaseReadOnly(databasePath);

  Future<int?> schemaVersion(String databasePath) =>
      readProjectDatabaseSchemaVersion(databasePath);
}
