import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/agent/tool/agent_tool.dart';
import 'package:void_scriptor/core/agent/tool/tool_registry.dart';

void main() {
  test('registry exposes descriptors without mutable internal state', () {
    final registry = ToolRegistry();
    registry.register(
      const AgentTool(
        name: 'read_project',
        description: 'Read project metadata',
        risk: ToolRisk.readOnly,
      ),
    );

    expect(registry.descriptors.single.name, 'read_project');
    expect(registry.descriptors.single.risk, ToolRisk.readOnly);
  });

  test('write tools require explicit approval before execution', () async {
    final registry = ToolRegistry();
    registry.register(
      AgentTool(
        name: 'rename_project',
        description: 'Rename the current project',
        risk: ToolRisk.write,
        executor: (args) async => ToolResult.success('renamed:${args['name']}'),
      ),
    );

    final denied = await registry.invokeAsync('rename_project', {'name': 'X'});
    expect(denied.status, ToolInvocationStatus.approvalRequired);

    final approved = await registry.invokeAsync('rename_project', {
      'name': 'X',
    }, approve: true);
    expect(approved.status, ToolInvocationStatus.completed);
    expect(approved.output, 'renamed:X');
  });

  test('unknown tools and executor failures are normalized', () async {
    final registry = ToolRegistry();
    expect(
      (await registry.invokeAsync('missing', const {})).status,
      ToolInvocationStatus.unknownTool,
    );
    registry.register(
      AgentTool(
        name: 'broken',
        description: 'Broken tool',
        executor: (_) async => throw StateError('internal detail'),
      ),
    );
    final result = await registry.invokeAsync('broken', const {});
    expect(result.status, ToolInvocationStatus.failed);
    expect(result.output, 'Tool execution failed');
  });
}
