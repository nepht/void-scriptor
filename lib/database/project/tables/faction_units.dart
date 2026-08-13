import 'package:drift/drift.dart';

class FactionUnits extends Table {
  TextColumn get id => text()();
  TextColumn get factionId => text()();
  TextColumn get parentUnitId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
