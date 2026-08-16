import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/agent/tool/agent_tool.dart';
import 'package:void_scriptor/core/agent/tool/tool_registry.dart';
import 'package:void_scriptor/core/agent/agent/agent_definition.dart';
import 'package:void_scriptor/core/agent/runtime/agent_runtime.dart';
import 'package:void_scriptor/core/agent/orchestration/agent_orchestrator.dart';

void main() {
  test('AgentOrchestrator routes task by capability', () {
    final registry = ToolRegistry();
    registry.register(
      const AgentTool(name: 'search', description: 'Search', params: ['q']),
    );
    const researcher = AgentDefinition(
      id: 'a1',
      name: 'Researcher',
      systemPrompt: 'Research',
      toolNames: ['search'],
    );
    final orchestrator = AgentOrchestrator(registry: registry);
    orchestrator.registerAgent(researcher);

    final agent = orchestrator.route('search the warden');
    expect(agent, isNotNull);
    expect(agent!.name, 'Researcher');
  });

  test('AgentOrchestrator runs agent and aggregates result', () {
    final registry = ToolRegistry();
    registry.register(
      const AgentTool(name: 'search', description: 'Search', params: ['q']),
    );
    const researcher = AgentDefinition(
      id: 'a1',
      name: 'Researcher',
      systemPrompt: 'Research',
      toolNames: ['search'],
    );
    final orchestrator = AgentOrchestrator(registry: registry);
    orchestrator.registerAgent(researcher);

    final result = orchestrator.run(
      agentId: 'a1',
      task: 'search the warden',
      toolCalls: [
        const ToolCallSpec(toolName: 'search', args: {'q': 'warden'}),
      ],
    );
    expect(result.state, AgentState.done);
  });

  test('AgentOrchestrator returns null for unknown agent', () {
    final orchestrator = AgentOrchestrator(registry: ToolRegistry());
    expect(orchestrator.route('anything'), isNull);
  });
}
