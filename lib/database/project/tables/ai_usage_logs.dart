import 'package:drift/drift.dart';

/// Tracks token usage and cost per generation (Step 28.6).
class AiUsageLogs extends Table {
  TextColumn get id => text()();
  TextColumn get generationId => text()();
  TextColumn get provider => text()();
  TextColumn get model => text()();
  IntColumn get promptTokens => integer()();
  IntColumn get completionTokens => integer()();
  RealColumn get cost => real()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
