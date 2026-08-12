import 'package:drift/drift.dart';

class WeaponMeasurements extends Table {
  TextColumn get id => text()();
  TextColumn get weaponId => text()();
  TextColumn get label => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
