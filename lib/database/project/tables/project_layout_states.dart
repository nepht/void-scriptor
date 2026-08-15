import 'package:drift/drift.dart';

class ProjectLayoutStates extends Table {
  TextColumn get projectId => text()();
  TextColumn get json => text()();

  @override
  Set<Column<Object>> get primaryKey => {projectId};
}
