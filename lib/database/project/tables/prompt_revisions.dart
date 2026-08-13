import 'package:drift/drift.dart';

class PromptRevisions extends Table {
  TextColumn get id => text()();
  TextColumn get promptHistoryId => text()();
  IntColumn get revision => integer()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
