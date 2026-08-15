import 'package:drift/drift.dart';

class JobDependencies extends Table {
  TextColumn get jobId => text()();
  TextColumn get dependsOnId => text()();

  @override
  Set<Column<Object>> get primaryKey => {jobId, dependsOnId};
}
