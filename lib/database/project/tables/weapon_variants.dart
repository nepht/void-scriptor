import 'package:drift/drift.dart';

class WeaponVariants extends Table {
  TextColumn get id => text()();
  TextColumn get weaponId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
