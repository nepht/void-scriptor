import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';

/// Persists agents and tool calls (Step 39.15).
class AgentRepository {
  AgentRepository({required this.database});

  final ProjectDatabase database;

  Future<void> saveAgent({
    required String id,
    required String name,
    required String systemPrompt,
    required List<String> toolNames,
  }) async {
    await database
        .into(database.agents)
        .insertOnConflictUpdate(
          AgentsCompanion.insert(
            id: id,
            name: name,
            systemPrompt: systemPrompt,
            toolNamesJson: Value(jsonEncode(toolNames)),
          ),
        );
  }

  Future<List<Agent>> listAgents() async =>
      database.select(database.agents).get();

  Future<void> logToolCall({
    required String id,
    required String agentId,
    required String toolName,
    required String input,
    required String output,
  }) async {
    await database
        .into(database.agentToolCalls)
        .insert(
          AgentToolCallsCompanion.insert(
            id: id,
            agentId: agentId,
            toolName: toolName,
            input: input,
            output: output,
            timestamp: DateTime.now().toUtc(),
          ),
        );
  }

  Future<List<AgentToolCall>> listToolCalls(String agentId) async {
    final query = database.select(database.agentToolCalls)
      ..where((row) => row.agentId.equals(agentId))
      ..orderBy([(row) => OrderingTerm.desc(row.timestamp)]);
    return query.get();
  }
}
