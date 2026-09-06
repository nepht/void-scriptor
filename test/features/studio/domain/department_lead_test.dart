import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/organization_agent.dart';

void main() {
  test('assigns a department lead with explicit authority and lifecycle', () {
    final tree = OrganizationTree.withDefaults('studio-1');
    const lead = DepartmentLead(
      id: 'lead-1',
      agentId: 'agent-1',
      departmentId: 'studio-1-narrative',
      authority: LeadAuthority.approveDepartmentWork,
    );

    tree.assignLead(lead);

    expect(tree.leadFor('studio-1-narrative'), lead);
    expect(lead.lifecycle, LeadLifecycle.active);
    expect(lead.canApproveDepartmentWork, isTrue);
  });

  test('rejects duplicate active leads for one department', () {
    final tree = OrganizationTree.withDefaults('studio-1');
    tree.assignLead(
      const DepartmentLead(
        id: 'lead-1',
        agentId: 'agent-1',
        departmentId: 'studio-1-narrative',
      ),
    );

    expect(
      () => tree.assignLead(
        const DepartmentLead(
          id: 'lead-2',
          agentId: 'agent-2',
          departmentId: 'studio-1-narrative',
        ),
      ),
      throwsStateError,
    );
  });

  test('repository roundtrips department lead assignments', () async {
    final repository = InMemoryDepartmentLeadRepository();
    const lead = DepartmentLead(
      id: 'lead-1',
      agentId: 'agent-1',
      departmentId: 'department-1',
    );

    await repository.save(lead);

    expect(await repository.findByDepartment('department-1'), lead);
  });
}
