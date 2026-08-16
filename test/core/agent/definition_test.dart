import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/agent/agent/agent_definition.dart';
import 'package:void_scriptor/core/agent/agent/agent_memory.dart';

void main() {
  test('AgentDefinition holds identity and tools', () {
    const agent = AgentDefinition(
      id: 'a1',
      name: 'Researcher',
      systemPrompt: 'You research the universe.',
      toolNames: ['search'],
    );
    expect(agent.name, 'Researcher');
    expect(agent.toolNames, ['search']);
  });

  test('AgentMemory stores working memory and turn log', () {
    final memory = AgentMemory();
    memory.set('topic', 'Void Cube');
    memory.appendTurn(role: 'user', content: 'find the warden');
    expect(memory.get('topic'), 'Void Cube');
    expect(memory.turns, hasLength(1));
  });

  test('AgentState enum values', () {
    expect(AgentState.values, hasLength(4));
    expect(AgentState.idle.name, 'idle');
  });
}
