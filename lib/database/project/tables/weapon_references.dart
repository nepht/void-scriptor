import 'package:drift/drift.dart';

class WeaponReferences extends Table {
  TextColumn get id => text()();
  TextColumn get weaponId => text()();
  TextColumn get referenceType => text()();
  TextColumn get filePath => text()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  BoolColumn get primaryReference =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
