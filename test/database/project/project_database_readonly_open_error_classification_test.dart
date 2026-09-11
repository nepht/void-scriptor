import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

/// core-hunt run197 BUG-13 (Referee verdict REAL BUG, Low): the read-only
/// open leg called openProjectDatabaseReadOnly directly with no
/// classification, so a missing or corrupt database surfaced a raw
/// SqliteException instead of the typed open-failure family that the
/// read-write open() path guarantees. The fix routes openReadOnly through
/// the same classifier (classifyProjectDatabaseOpenError) plus the missing-
/// file guard.
void main() {
  late Directory root;
  setUp(() async => root = await Directory.systemTemp.createTemp('bug13-ro-'));
  tearDown(() => root.delete(recursive: true));

  test('openReadOnly on a missing file reports typed unavailable, not raw '
      'SqliteException', () async {
    final databasePath = p.join(root.path, 'absent.db');
    final service = ProjectDatabaseService();

    await expectLater(
      service.openReadOnly(databasePath),
      throwsA(isA<ProjectDatabaseUnavailableException>()),
    );
    // The failed open must not have silently created the file either.
    expect(File(databasePath).existsSync(), isFalse);
  });

  test('openReadOnly on a corrupt file reports typed unreadable, not raw '
      'SqliteException', () async {
    final databasePath = p.join(root.path, 'corrupt.db');
    // Non-database bytes: sqlite3 defers the header read until the first
    // query, surfacing SQLITE_NOTADB (26) which the contract classifies as
    // unreadable, not unavailable.
    await File(
      databasePath,
    ).writeAsBytes(List<int>.filled(4096, 0x5A, growable: false));
    final service = ProjectDatabaseService();

    Object? error;
    try {
      final database = await service.openReadOnly(databasePath);
      await database.close();
    } on Object catch (e) {
      error = e;
    }
    expect(
      error,
      isA<ProjectDatabaseUnreadableException>(),
      reason:
          'expected typed unreadable; raw SqliteException means the '
          'classification bypass (run197 BUG-13) is still open',
    );
  });

  test(
    'openReadOnly on a real healthy database still opens successfully',
    () async {
      final databasePath = p.join(root.path, 'project.db');
      final service = ProjectDatabaseService();
      await service.create(databasePath);

      final database = await service.openReadOnly(databasePath);
      expect(database, isA<ProjectDatabase>());
      await database.close();
    },
  );
}
