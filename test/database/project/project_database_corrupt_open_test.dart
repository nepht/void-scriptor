import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Sprint 145.42 (Data Safety Failure Matrix) - corrupt database on the
/// production open path.
///
/// A database file that exists but is not a usable SQLite database must be
/// rejected with the domain exception [ProjectDatabaseUnreadableException]
/// (same contract family as [SchemaVersionTooNewException]) instead of
/// leaking a raw sqlite3 SqliteException out of drift initialization.
void main() {
  test(
    'open() rejects a corrupt database file with a domain exception',
    () async {
      final root = await Directory.systemTemp.createTemp('s14542-corrupt-db-');
      addTearDown(() => root.delete(recursive: true));
      final databasePath = p.join(root.path, 'project.db');
      File(databasePath).writeAsStringSync('not a sqlite database at all');

      await expectLater(
        ProjectDatabaseService().open(databasePath),
        throwsA(
          isA<ProjectDatabaseUnreadableException>()
              .having((e) => e.databasePath, 'databasePath', databasePath)
              .having((e) => e.cause, 'cause', isA<sqlite.SqliteException>()),
        ),
      );
    },
  );

  test(
    'open() still opens a healthy database created by the service',
    () async {
      final root = await Directory.systemTemp.createTemp('s14542-healthy-db-');
      addTearDown(() => root.delete(recursive: true));
      final databasePath = p.join(root.path, 'project.db');

      await ProjectDatabaseService().create(databasePath);
      final database = await ProjectDatabaseService().open(databasePath);

      expect(database, isNotNull);
      await database.close();
    },
  );
}
