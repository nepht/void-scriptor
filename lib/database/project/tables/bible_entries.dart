import 'package:drift/drift.dart';

class BibleEntries extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get canonStatus => text().withDefault(const Constant('canon'))();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
