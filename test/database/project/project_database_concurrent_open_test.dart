import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/database/project/project_database.dart'
    hide CharacterIdentityProfile;
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Sprint 145.42 (Data Safety Failure Matrix) - concurrent open pada layer
/// database SQLite.
///
/// Risiko yang dibuktikan: dua koneksi penulis yang menunjuk file yang
/// sama akan membuat drift `BEGIN IMMEDIATE` gagal dengan SQLITE_BUSY
/// (extended result code 5). Jalur produksi [ProjectDatabaseService.open]
/// saat ini menerjemahkan setiap [sqlite.SqliteException] dari
/// inisialisasi drift menjadi [ProjectDatabaseUnreadableException] - itu
/// klasifikasi salah karena file sehat, hanya terkunci. Probe readOnly
/// untuk schema version TIDAK menunggu lock, jadi guard
/// `SchemaVersionTooNewException` tidak berlaku di sini.
void main() {
  late Directory root;
  setUp(
    () async => root = await Directory.systemTemp.createTemp('hermes-dblock-'),
  );
  tearDown(() => root.delete(recursive: true));

  test('production open throws a typed locked exception when another writer '
      'is already holding the database file', () async {
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final writer = sqlite.sqlite3.open(dbPath);
    writer.execute(
      'PRAGMA user_version = ${ProjectDatabase.currentSchemaVersion - 1}',
    );
    // Koneksi idle tidak memegang lock - sqlite3 melepas SHARED setelah
    // statement selesai. Transaksi BEGIN IMMEDIATE eksplisit memegang
    // RESERVED sampai COMMIT/ROLLBACK, jadi writer kedua pasti kena
    // SQLITE_BUSY secara deterministik.
    writer.execute('BEGIN IMMEDIATE');

    await expectLater(
      service.open(dbPath),
      throwsA(isA<ProjectDatabaseLockedException>()),
    );
    writer.execute('ROLLBACK');
    writer.close();
  });

  test('after the contending writer releases the file the production open '
      'recovers and the migration completes', () async {
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final writer = sqlite.sqlite3.open(dbPath);
    writer.execute(
      'PRAGMA user_version = ${ProjectDatabase.currentSchemaVersion - 1}',
    );
    // Koneksi idle tidak memegang lock - sqlite3 melepas SHARED setelah
    // statement selesai. Transaksi BEGIN IMMEDIATE eksplisit memegang
    // RESERVED sampai COMMIT/ROLLBACK, jadi writer kedua pasti kena
    // SQLITE_BUSY secara deterministik.
    writer.execute('BEGIN IMMEDIATE');

    await expectLater(
      service.open(dbPath),
      throwsA(isA<ProjectDatabaseLockedException>()),
    );

    writer.execute('ROLLBACK');
    writer.close();
    final database = await service.open(dbPath);
    addTearDown(database.close);
    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], ProjectDatabase.currentSchemaVersion);
  });
}
