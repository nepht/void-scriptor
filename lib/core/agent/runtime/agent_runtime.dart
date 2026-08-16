import '../tool/tool_registry.dart';
import '../agent/agent_definition.dart';
import '../agent/agent_memory.dart';

class ToolCallSpec {
  const ToolCallSpec({required this.toolName, required this.args});

  final String toolName;
  final Map<String, dynamic> args;
}

class AgentRunResult {
  AgentRunResult({
    required this.state,
    required this.toolCalls,
    required this.memory,
  });

  final AgentState state;
  final List<String> toolCalls;
  final AgentMemory memory;
}

/// Agent runtime: deterministic tool dispatch loop (Step 39.7–39.9).
class AgentRuntime {
  AgentRuntime({required this.registry});

  final ToolRegistry registry;

  AgentRunResult run({
    required AgentDefinition agent,
    required String task,
    required List<ToolCallSpec> toolCalls,
  }) {
    final memory = AgentMemory();
    memory.appendTurn(role: 'user', content: task);
    final executed = <String>[];

    for (final spec in toolCalls) {
      final tool = registry.lookup(spec.toolName);
      if (tool == null) {
        memory.appendTurn(
          role: 'assistant',
          content: 'failed: unknown tool ${spec.toolName}',
        );
        return AgentRunResult(
          state: AgentState.failed,
          toolCalls: executed,
          memory: memory,
        );
      }
      final result = registry.invoke(spec.toolName, spec.args);
      executed.add(spec.toolName);
      memory.appendTurn(
        role: 'assistant',
        content: 'called ${spec.toolName}: ${result.output}',
      );
    }

    return AgentRunResult(
      state: AgentState.done,
      toolCalls: executed,
      memory: memory,
    );
  }
}
