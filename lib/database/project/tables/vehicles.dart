import 'package:drift/drift.dart';

class Vehicles extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get manufacturer => text().withDefault(const Constant(''))();
  TextColumn get role => text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {assetId};
}

class VehicleSpecifications extends Table {
  TextColumn get vehicleId => text()();
  RealColumn get lengthMeters => real().nullable()();
  RealColumn get widthMeters => real().nullable()();
  RealColumn get heightMeters => real().nullable()();
  IntColumn get crew => integer().nullable()();
  IntColumn get passengers => integer().nullable()();
  TextColumn get propulsion => text().withDefault(const Constant(''))();
  TextColumn get powerSource => text().withDefault(const Constant(''))();
  TextColumn get maximumSpeed => text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {vehicleId};
}

class VehicleComponents extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VehicleWeaponMounts extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get weaponId => text()();
  TextColumn get mountName => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VehicleVariants extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get referenceSetId => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
