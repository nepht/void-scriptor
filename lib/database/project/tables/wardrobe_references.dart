import 'package:drift/drift.dart';

class WardrobeReferences extends Table {
  TextColumn get id => text()();
  TextColumn get wardrobeId => text()();
  TextColumn get referenceType => text()();
  TextColumn get filePath => text()();
  IntColumn get priority => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
