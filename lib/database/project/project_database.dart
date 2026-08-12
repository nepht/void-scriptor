import 'package:drift/drift.dart';

part 'project_database.g.dart';

class ProjectMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [ProjectMetadata])
class ProjectDatabase extends _$ProjectDatabase {
  ProjectDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  Future<void> initialize() async {
    await customStatement(
      'INSERT OR IGNORE INTO project_metadata (key, value) VALUES (?, ?)',
      ['schemaVersion', '1'],
    );
  }
}
