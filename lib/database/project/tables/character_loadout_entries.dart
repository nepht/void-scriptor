import 'package:drift/drift.dart';

class CharacterLoadoutEntries extends Table {
  TextColumn get id => text()();
  TextColumn get modeId => text()();
  TextColumn get assetId => text()();
  TextColumn get slot => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
