import 'package:drift/drift.dart';

class WeaponColors extends Table {
  TextColumn get id => text()();
  TextColumn get weaponId => text()();
  TextColumn get name => text()();
  TextColumn get hexValue => text()();
  TextColumn get usage => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
