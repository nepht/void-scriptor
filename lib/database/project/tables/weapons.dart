import 'package:drift/drift.dart';

class Weapons extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get weaponType => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get primaryMaterial => text().withDefault(const Constant(''))();
  TextColumn get secondaryMaterial => text().withDefault(const Constant(''))();
  TextColumn get energyType => text().withDefault(const Constant(''))();
  TextColumn get coreType => text().withDefault(const Constant(''))();
  RealColumn get lengthMm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {assetId};
}
