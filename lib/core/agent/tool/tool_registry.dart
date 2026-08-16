import 'agent_tool.dart';

/// Registry of agent tools (Step 39.3).
class ToolRegistry {
  final Map<String, AgentTool> _tools = {};

  void register(AgentTool tool) => _tools[tool.name] = tool;

  AgentTool? lookup(String name) => _tools[name];

  ToolResult invoke(String name, Map<String, dynamic> args) {
    final tool = _tools[name];
    if (tool == null) {
      return ToolResult(success: false, output: 'Unknown tool: $name');
    }
    // deterministic echo of args as the tool output
    return ToolResult(success: true, output: args.toString());
  }
}
