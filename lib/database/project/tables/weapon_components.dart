import 'package:drift/drift.dart';

class WeaponComponents extends Table {
  TextColumn get id => text()();
  TextColumn get weaponId => text()();
  TextColumn get name => text()();
  TextColumn get componentType => text()();
  TextColumn get material => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
