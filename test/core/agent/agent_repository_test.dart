import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/agent/persistence/agent_repository.dart';

void main() {
  test('saveAgent and listAgents roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = AgentRepository(database: db);

    await repo.saveAgent(
      id: 'a1',
      name: 'Researcher',
      systemPrompt: 'Research',
      toolNames: ['search'],
    );
    final agents = await repo.listAgents();
    expect(agents, hasLength(1));
    expect(agents.first.name, 'Researcher');
    expect(jsonDecode(agents.first.toolNamesJson), ['search']);
  });

  test('logToolCall and listToolCalls roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = AgentRepository(database: db);

    await repo.logToolCall(
      id: 'c1',
      agentId: 'a1',
      toolName: 'search',
      input: '{}',
      output: '{}',
    );
    final calls = await repo.listToolCalls('a1');
    expect(calls, hasLength(1));
    expect(calls.first.toolName, 'search');
  });

  test('restart persistence keeps agents', () async {
    final dir = Directory.systemTemp.createTempSync('vs_agent_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/project.db');

    final db = ProjectDatabase(NativeDatabase(file));
    final repo = AgentRepository(database: db);
    await repo.saveAgent(
      id: 'a1',
      name: 'Researcher',
      systemPrompt: 'Research',
      toolNames: [],
    );
    await db.close();

    final db2 = ProjectDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final repo2 = AgentRepository(database: db2);
    expect((await repo2.listAgents()), hasLength(1));
  });
}
