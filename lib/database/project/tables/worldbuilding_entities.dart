import 'package:drift/drift.dart';

class Species extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get origin => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get lifespan => text().withDefault(const Constant(''))();
  TextColumn get traits => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {assetId};
}

class Technologies extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get creator => text().withDefault(const Constant(''))();
  TextColumn get limitations => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {assetId};
}

class PowerSystems extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant(''))();
  TextColumn get rules => text().withDefault(const Constant(''))();
  TextColumn get limitations => text().withDefault(const Constant(''))();
  TextColumn get visualLanguage => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {assetId};
}

class PowerAbilities extends Table {
  TextColumn get id => text()();
  TextColumn get powerSystemId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get limitations => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
