import 'package:drift/drift.dart';

class WeaponPreservationProfiles extends Table {
  TextColumn get weaponId => text()();
  BoolColumn get geometryLock => boolean().withDefault(const Constant(true))();
  BoolColumn get materialLock => boolean().withDefault(const Constant(true))();
  BoolColumn get colorLock => boolean().withDefault(const Constant(true))();
  BoolColumn get coreLock => boolean().withDefault(const Constant(true))();
  BoolColumn get scaleLock => boolean().withDefault(const Constant(true))();
  BoolColumn get effectLock => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {weaponId};
}
