import 'package:drift/drift.dart';

class BackgroundJobs extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get type => text()();
  TextColumn get label => text()();
  TextColumn get status => text()();
  TextColumn get priority => text()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  TextColumn get payload => text().nullable()();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
