import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/organization_agent.dart';

void main() {
  test('builds an organization tree with departments', () {
    final tree = OrganizationTree();
    final root = tree.addOrganization('Void Studio');
    final department = tree.addDepartment(root.id, 'Narrative');
    expect(tree.childrenOf(root.id).single.name, 'Narrative');
    expect(department.parentId, root.id);
  });

  test('provides default departments for a new studio', () {
    final tree = OrganizationTree.withDefaults('studio-1');
    expect(
      tree.departments.map((item) => item.name),
      containsAll(<String>['Narrative', 'Visual', 'Production']),
    );
  });

  test('agent has a role but is not an AI model', () {
    const agent = StudioAgent(
      id: 'agent-1',
      name: 'Director',
      role: AgentRole.director,
    );
    expect(agent.isAiModel, isFalse);
    expect(agent.role, AgentRole.director);
  });
}
