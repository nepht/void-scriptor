import '../tool/tool_registry.dart';
import '../agent/agent_definition.dart';
import '../runtime/agent_runtime.dart';

/// Multi-agent orchestrator with task routing (Step 39.10–39.12).
class AgentOrchestrator {
  AgentOrchestrator({required this.registry});

  final ToolRegistry registry;
  final Map<String, AgentDefinition> _agents = {};
  late final AgentRuntime _runtime = AgentRuntime(registry: registry);

  void registerAgent(AgentDefinition agent) => _agents[agent.id] = agent;

  AgentDefinition? route(String task) {
    final lowered = task.toLowerCase();
    for (final agent in _agents.values) {
      for (final toolName in agent.toolNames) {
        if (lowered.contains(toolName)) return agent;
      }
    }
    return _agents.isNotEmpty ? _agents.values.first : null;
  }

  AgentRunResult run({
    required String agentId,
    required String task,
    required List<ToolCallSpec> toolCalls,
  }) {
    final agent = _agents[agentId];
    if (agent == null) {
      throw ArgumentError('Unknown agent: $agentId');
    }
    return _runtime.run(agent: agent, task: task, toolCalls: toolCalls);
  }
}
