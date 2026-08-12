import 'package:drift/drift.dart';

class WeaponEnergyProfiles extends Table {
  TextColumn get weaponId => text()();
  TextColumn get energyType => text().withDefault(const Constant(''))();
  TextColumn get coreType => text().withDefault(const Constant(''))();
  TextColumn get activation => text().withDefault(const Constant(''))();
  TextColumn get emissionColor => text().withDefault(const Constant(''))();
  TextColumn get behavior => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {weaponId};
}
