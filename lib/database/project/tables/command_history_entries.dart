import 'package:drift/drift.dart';

class CommandHistoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get commandType => text()();
  TextColumn get label => text()();
  TextColumn get payload => text()();
  TextColumn get undoPayload => text().nullable()();
  IntColumn get sequence => integer().withDefault(const Constant(0))();
  TextColumn get source => text().withDefault(const Constant('user'))();
  TextColumn get status => text().withDefault(const Constant('applied'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
