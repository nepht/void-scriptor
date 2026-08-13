import 'package:drift/drift.dart';

class Factions extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get ideology => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get headquarters => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {assetId};
}
