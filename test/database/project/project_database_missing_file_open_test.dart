import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Sprint 145.42 (Data Safety Failure Matrix) - missing database file on
/// an otherwise reachable storage location.
///
/// A null schema probe means the file does not exist. Historically the
/// production open path then let drift's NativeDatabase silently create a
/// fresh empty database at that path - a storage mutation nobody asked
/// for (run 86 finding). A missing file on reachable storage must be
/// reported as a typed unavailable state, and [ProjectDatabaseService.create]
/// must remain the only production path that creates a database file.
void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-dbmissing-'),
  );
  tearDown(() => root.delete(recursive: true));

  test('open() on a missing database file reports unavailable and does '
      'not silently create the file', () async {
    final databasePath = p.join(root.path, 'project.db');
    expect(File(databasePath).existsSync(), isFalse);

    final service = ProjectDatabaseService();
    await expectLater(
      service.open(databasePath),
      throwsA(isA<ProjectDatabaseUnavailableException>()),
    );

    // No silent storage mutation: the failed open must not have left a
    // freshly created (empty) database behind.
    expect(File(databasePath).existsSync(), isFalse);
  });

  test(
    'create() remains the only path that produces a database file',
    () async {
      final databasePath = p.join(root.path, 'project.db');

      await ProjectDatabaseService().create(databasePath);
      expect(File(databasePath).existsSync(), isTrue);

      final database = await ProjectDatabaseService().open(databasePath);
      expect(database, isNotNull);
      await database.close();
    },
  );
}
