enum AgentState { idle, running, done, failed }

/// Agent definition (Step 39.4).
class AgentDefinition {
  const AgentDefinition({
    required this.id,
    required this.name,
    required this.systemPrompt,
    this.toolNames = const [],
  });

  final String id;
  final String name;
  final String systemPrompt;
  final List<String> toolNames;
}

class AgentTurn {
  const AgentTurn({required this.role, required this.content});

  final String role;
  final String content;
}
