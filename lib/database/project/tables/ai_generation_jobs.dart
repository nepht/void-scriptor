import 'package:drift/drift.dart';

class AiGenerationJobs extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get providerId => text()();
  TextColumn get modelId => text().nullable()();
  TextColumn get promptHistoryId => text()();
  TextColumn get status => text()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  TextColumn get error => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
