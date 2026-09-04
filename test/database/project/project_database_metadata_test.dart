import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';

void main() {
  test('initialize repairs stale schema metadata and is idempotent', () async {
    final database = ProjectDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.initialize();
    await database
        .into(database.projectMetadata)
        .insertOnConflictUpdate(
          ProjectMetadataCompanion.insert(key: 'schemaVersion', value: '1'),
        );

    await database.initialize();
    final rows = await (database.select(
      database.projectMetadata,
    )..where((row) => row.key.equals('schemaVersion'))).get();

    expect(rows, hasLength(1));
    expect(rows.single.value, ProjectDatabase.currentSchemaVersion.toString());
  });
}
