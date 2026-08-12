import 'package:drift/drift.dart';

class Characters extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get displayName => text()();
  TextColumn get alias => text().withDefault(const Constant(''))();
  TextColumn get biography => text().withDefault(const Constant(''))();
  TextColumn get personality => text().withDefault(const Constant(''))();
  TextColumn get gender => text().withDefault(const Constant(''))();
  IntColumn get age => integer().nullable()();
  RealColumn get heightCm => real().nullable()();
  TextColumn get hair => text().withDefault(const Constant(''))();
  TextColumn get eyes => text().withDefault(const Constant(''))();
  TextColumn get skin => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {assetId};
}
