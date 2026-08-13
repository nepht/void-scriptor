import 'package:drift/drift.dart';

class AiGenerationInputs extends Table {
  TextColumn get id => text()();
  TextColumn get jobId => text()();
  TextColumn get inputType => text()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get filePath => text().nullable()();
  TextColumn get snapshotData => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
