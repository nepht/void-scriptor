import 'package:drift/drift.dart';

class WardrobeComponents extends Table {
  TextColumn get id => text()();
  TextColumn get wardrobeId => text()();
  TextColumn get name => text()();
  TextColumn get componentType => text()();
  TextColumn get material => text().withDefault(const Constant(''))();
  TextColumn get fabric => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
