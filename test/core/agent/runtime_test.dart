import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/agent/tool/agent_tool.dart';
import 'package:void_scriptor/core/agent/tool/tool_registry.dart';
import 'package:void_scriptor/core/agent/agent/agent_definition.dart';
import 'package:void_scriptor/core/agent/runtime/agent_runtime.dart';

void main() {
  test('AgentRuntime runs task and dispatches tools', () {
    final registry = ToolRegistry();
    registry.register(
      const AgentTool(name: 'search', description: 'Search', params: ['q']),
    );
    const agent = AgentDefinition(
      id: 'a1',
      name: 'Researcher',
      systemPrompt: 'Research',
      toolNames: ['search'],
    );
    final runtime = AgentRuntime(registry: registry);
    final result = runtime.run(
      agent: agent,
      task: 'find the warden',
      toolCalls: [
        const ToolCallSpec(toolName: 'search', args: {'q': 'warden'}),
      ],
    );
    expect(result.state, AgentState.done);
    expect(result.toolCalls, hasLength(1));
  });

  test('AgentRuntime records tool calls in memory', () {
    final registry = ToolRegistry();
    registry.register(
      const AgentTool(name: 'search', description: 'Search', params: ['q']),
    );
    const agent = AgentDefinition(
      id: 'a1',
      name: 'Researcher',
      systemPrompt: 'Research',
      toolNames: ['search'],
    );
    final runtime = AgentRuntime(registry: registry);
    final result = runtime.run(
      agent: agent,
      task: 'find the warden',
      toolCalls: [
        const ToolCallSpec(toolName: 'search', args: {'q': 'warden'}),
      ],
    );
    expect(result.memory.turns, hasLength(2));
  });

  test('AgentRuntime fails on missing tool', () {
    final registry = ToolRegistry();
    const agent = AgentDefinition(
      id: 'a1',
      name: 'Researcher',
      systemPrompt: 'Research',
      toolNames: ['missing'],
    );
    final runtime = AgentRuntime(registry: registry);
    final result = runtime.run(
      agent: agent,
      task: 'do it',
      toolCalls: [const ToolCallSpec(toolName: 'missing', args: {})],
    );
    expect(result.state, AgentState.failed);
  });
}
