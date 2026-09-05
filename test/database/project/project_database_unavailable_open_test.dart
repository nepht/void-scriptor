import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Sprint 145.42 (Data Safety Failure Matrix) - drive removal / storage
/// yang tidak lagi terjangkau pada layer database SQLite.
///
/// Risiko yang dibuktikan: saat drive proyek dilepas (atau path storage
/// hilang), [ProjectDatabaseService.open] saat ini membocorkan
/// PathNotFoundException mentah dari pembuatan direktori drift, dan
/// SQLITE_CANTOPEN dari sqlite3 diklasifikasikan salah sebagai
/// ProjectDatabaseUnreadableException (korut) padahal file bisa saja
/// sehat - hanya tidak terjangkau. Keduanya harus dilaporkan sebagai
/// satu keadaan bertipe: storage unavailable, bukan database korut.
void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-dbunavail-'),
  );
  tearDown(() => root.delete(recursive: true));

  test('production open on a removed drive reports a typed unavailable '
      'exception instead of a raw path error', () async {
    // Analog drive removal: huruf drive yang tidak ada di host ini.
    String? missingDrive;
    for (final letter in ['Q', 'X', 'Y', 'Z', 'W', 'V']) {
      if (!Directory('$letter:/').existsSync()) {
        missingDrive = letter;
        break;
      }
    }
    // Tidak ada drive bebas di host (praktis mustahil): lewati, jangan
    // gagal palsu.
    if (missingDrive == null) return;

    final service = ProjectDatabaseService();
    await expectLater(
      service.open('$missingDrive:/void_scriptor_unavailable/project.db'),
      throwsA(isA<ProjectDatabaseUnavailableException>()),
    );
  });

  test('production open on a path that cannot be a database (directory '
      'target) reports unavailable, not unreadable', () async {
    final obstacle = Directory('${root.path}/not-a-db-target')
      ..createSync(recursive: true);

    final service = ProjectDatabaseService();
    await expectLater(
      service.open(obstacle.path),
      throwsA(isA<ProjectDatabaseUnavailableException>()),
    );
    await expectLater(
      service.open(obstacle.path),
      throwsA(isNot(isA<ProjectDatabaseUnreadableException>())),
    );
  });
}
