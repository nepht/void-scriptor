/// A tool an agent can invoke (Step 39.1).
class AgentTool {
  const AgentTool({
    required this.name,
    required this.description,
    this.params = const [],
  });

  final String name;
  final String description;
  final List<String> params;
}

/// Result of a tool invocation (Step 39.2).
class ToolResult {
  const ToolResult({required this.success, required this.output});

  final bool success;
  final String output;
}
