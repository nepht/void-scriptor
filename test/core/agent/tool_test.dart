import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/agent/tool/agent_tool.dart';
import 'package:void_scriptor/core/agent/tool/tool_registry.dart';

void main() {
  test('AgentTool holds name and description', () {
    const tool = AgentTool(
      name: 'search',
      description: 'Search the knowledge base',
      params: ['query'],
    );
    expect(tool.name, 'search');
    expect(tool.params, hasLength(1));
  });

  test('ToolRegistry registers and looks up', () {
    final registry = ToolRegistry();
    registry.register(
      const AgentTool(name: 'search', description: 'Search', params: ['q']),
    );
    expect(registry.lookup('search'), isNotNull);
    expect(registry.lookup('missing'), isNull);
  });

  test('ToolRegistry invokes registered tool', () {
    final registry = ToolRegistry();
    registry.register(
      const AgentTool(name: 'echo', description: 'Echo', params: ['input']),
    );
    final result = registry.invoke('echo', {'input': 'hello'});
    expect(result.success, isTrue);
    expect(result.output, contains('hello'));
  });
}
