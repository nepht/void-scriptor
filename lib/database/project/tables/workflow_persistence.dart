import 'package:drift/drift.dart';

/// Sprint 103 / 103.22 — workflow persistence (schema v56).
///
/// Definitions and run records live in the canonical per-project database;
/// no second persistence engine. Payloads are stored as JSON text so the
/// canonical in-code models remain the source of truth.

class WorkflowDefinitions extends Table {
  TextColumn get definitionId => text()();
  IntColumn get version => integer()();
  TextColumn get name => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {definitionId, version};
}

class WorkflowRunRecords extends Table {
  TextColumn get executionId => text()();
  TextColumn get definitionId => text()();
  IntColumn get definitionVersion => integer()();
  TextColumn get state => text()();
  TextColumn get checkpointJson => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {executionId};
}
