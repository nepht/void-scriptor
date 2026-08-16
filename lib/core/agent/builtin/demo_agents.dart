import '../tool/agent_tool.dart';
import '../tool/tool_registry.dart';
import '../agent/agent_definition.dart';
import '../orchestration/agent_orchestrator.dart';

/// Built-in demo agent platform (Step 39.20).
class DemoAgents {
  DemoAgents._();

  static final ToolRegistry registry = ToolRegistry()
    ..register(
      const AgentTool(
        name: 'search',
        description: 'Search the knowledge base',
        params: ['query'],
      ),
    )
    ..register(
      const AgentTool(
        name: 'summarize',
        description: 'Summarize a body of text',
        params: ['text'],
      ),
    );

  static final AgentOrchestrator orchestrator =
      AgentOrchestrator(registry: registry)
        ..registerAgent(
          const AgentDefinition(
            id: 'researcher',
            name: 'Researcher',
            systemPrompt: 'You research the Void Cube universe.',
            toolNames: ['search'],
          ),
        )
        ..registerAgent(
          const AgentDefinition(
            id: 'editor',
            name: 'Editor',
            systemPrompt: 'You edit and summarize prose.',
            toolNames: ['summarize'],
          ),
        );
}
