import 'agent_tool.dart';

/// Registry and safety boundary for agent tools.
class ToolRegistry {
  final Map<String, AgentTool> _tools = {};

  void register(AgentTool tool) => _tools[tool.name] = tool;

  AgentTool? lookup(String name) => _tools[name];

  List<AgentTool> get descriptors => List.unmodifiable(_tools.values);

  ToolResult invoke(String name, Map<String, dynamic> args) {
    final tool = _tools[name];
    if (tool == null) {
      return const ToolResult(
        success: false,
        output: 'Unknown tool',
        status: ToolInvocationStatus.unknownTool,
      );
    }
    return ToolResult(success: true, output: args.toString());
  }

  Future<ToolInvocationResult> invokeAsync(
    String name,
    Map<String, dynamic> args, {
    bool approve = false,
  }) async {
    final tool = _tools[name];
    if (tool == null) {
      return const ToolInvocationResult(
        status: ToolInvocationStatus.unknownTool,
      );
    }
    if (tool.risk != ToolRisk.readOnly && !approve) {
      return const ToolInvocationResult(
        status: ToolInvocationStatus.approvalRequired,
      );
    }
    final executor = tool.executor;
    if (executor == null) {
      return ToolInvocationResult(
        status: ToolInvocationStatus.completed,
        output: args.toString(),
      );
    }
    try {
      final result = await executor(args);
      return ToolInvocationResult(
        status: result.success
            ? ToolInvocationStatus.completed
            : ToolInvocationStatus.failed,
        output: result.output,
      );
    } catch (_) {
      return const ToolInvocationResult(
        status: ToolInvocationStatus.failed,
        output: 'Tool execution failed',
      );
    }
  }
}

extension ToolRegistryLegacy on ToolRegistry {
  ToolResult invokeLegacy(String name, Map<String, dynamic> args) =>
      invoke(name, args);
}
