import 'package:drift/drift.dart';

/// Agents (Step 39.13).
class Agents extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get systemPrompt => text()();
  TextColumn get toolNamesJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Agent tool call log (Step 39.14).
class AgentToolCalls extends Table {
  TextColumn get id => text()();
  TextColumn get agentId => text()();
  TextColumn get toolName => text()();
  TextColumn get input => text()();
  TextColumn get output => text()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
