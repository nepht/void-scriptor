enum ToolRisk { readOnly, write, destructive }

enum ToolInvocationStatus { completed, approvalRequired, unknownTool, failed }

typedef AgentToolExecutor =
    Future<ToolResult> Function(Map<String, dynamic> args);

class AgentTool {
  const AgentTool({
    required this.name,
    required this.description,
    this.params = const [],
    this.risk = ToolRisk.readOnly,
    this.executor,
  });

  final String name;
  final String description;
  final List<String> params;
  final ToolRisk risk;
  final AgentToolExecutor? executor;
}

class ToolResult {
  const ToolResult({
    required this.success,
    required this.output,
    this.status = ToolInvocationStatus.completed,
  });

  const ToolResult.success(String output) : this(success: true, output: output);

  final bool success;
  final String output;
  final ToolInvocationStatus status;
}

class ToolInvocationResult {
  const ToolInvocationResult({required this.status, this.output = ''});

  final ToolInvocationStatus status;
  final String output;
}

extension ToolResultFactory on ToolResult {
  static ToolResult success(String output) =>
      ToolResult(success: true, output: output);
}
