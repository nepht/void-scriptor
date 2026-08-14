import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';

enum CommandHistoryStatus { applied, undone, abandoned }

class CommandHistoryRecordInput {
  const CommandHistoryRecordInput({
    required this.id,
    required this.projectId,
    required this.commandType,
    required this.label,
    required this.payload,
    this.undoPayload,
    this.sequence = 0,
    this.source = 'user',
  });

  final String id;
  final String projectId;
  final String commandType;
  final String label;
  final Map<String, Object?> payload;
  final Map<String, Object?>? undoPayload;
  final int sequence;
  final String source;
}

class CommandHistoryRecord {
  const CommandHistoryRecord({
    required this.id,
    required this.projectId,
    required this.commandType,
    required this.label,
    required this.payload,
    required this.undoPayload,
    required this.sequence,
    required this.source,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String commandType;
  final String label;
  final Map<String, dynamic> payload;
  final Map<String, dynamic>? undoPayload;
  final int sequence;
  final String source;
  final CommandHistoryStatus status;
  final DateTime createdAt;
}

class CommandHistoryRepository {
  const CommandHistoryRepository(this.database);

  final ProjectDatabase database;

  Future<void> record(CommandHistoryRecordInput input) {
    return database
        .into(database.commandHistoryEntries)
        .insert(
          CommandHistoryEntriesCompanion.insert(
            id: input.id,
            projectId: input.projectId,
            commandType: input.commandType,
            label: input.label,
            payload: jsonEncode(input.payload),
            undoPayload: Value(
              input.undoPayload == null ? null : jsonEncode(input.undoPayload),
            ),
            sequence: Value(input.sequence),
            source: Value(input.source),
          ),
        );
  }

  Future<List<CommandHistoryRecord>> list(String projectId) async {
    final rows =
        await (database.select(database.commandHistoryEntries)
              ..where((row) => row.projectId.equals(projectId))
              ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  Future<void> markUndone(String id) => _mark(id, CommandHistoryStatus.undone);

  Future<void> markApplied(String id) =>
      _mark(id, CommandHistoryStatus.applied);

  Future<void> markAbandoned(String id) =>
      _mark(id, CommandHistoryStatus.abandoned);

  Future<void> _mark(String id, CommandHistoryStatus status) {
    return (database.update(database.commandHistoryEntries)
          ..where((row) => row.id.equals(id)))
        .write(CommandHistoryEntriesCompanion(status: Value(status.name)));
  }

  CommandHistoryRecord _map(CommandHistoryEntry row) {
    return CommandHistoryRecord(
      id: row.id,
      projectId: row.projectId,
      commandType: row.commandType,
      label: row.label,
      payload: Map<String, dynamic>.from(jsonDecode(row.payload) as Map),
      undoPayload: row.undoPayload == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(row.undoPayload!) as Map),
      sequence: row.sequence,
      source: row.source,
      status: CommandHistoryStatus.values.firstWhere(
        (value) => value.name == row.status,
        orElse: () => CommandHistoryStatus.applied,
      ),
      createdAt: row.createdAt,
    );
  }
}
