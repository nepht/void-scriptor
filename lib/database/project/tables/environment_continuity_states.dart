import 'package:drift/drift.dart';

class EnvironmentContinuityStates extends Table {
  TextColumn get id => text()();
  TextColumn get environmentId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
