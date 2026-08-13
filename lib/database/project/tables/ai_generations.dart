import 'package:drift/drift.dart';

class AiGenerations extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get promptHistoryId => text()();
  TextColumn get provider => text()();
  TextColumn get model => text()();
  TextColumn get status => text()();
  TextColumn get outputPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
