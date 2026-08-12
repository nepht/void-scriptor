import 'package:drift/drift.dart';

class EnvironmentProps extends Table {
  TextColumn get id => text()();
  TextColumn get environmentId => text()();
  TextColumn get zoneId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get propType => text().withDefault(const Constant(''))();
  TextColumn get state => text().withDefault(const Constant(''))();
  TextColumn get positionNote => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
