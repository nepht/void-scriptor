class OrganizationNode {
  const OrganizationNode({required this.id, required this.name, this.parentId});

  final String id;
  final String name;
  final String? parentId;
}

class OrganizationTree {
  OrganizationTree() : _nodes = [], _leads = <DepartmentLead>[];

  OrganizationTree.withDefaults(String studioId)
    : _nodes = [
        OrganizationNode(
          id: '$studioId-narrative',
          name: 'Narrative',
          parentId: studioId,
        ),
        OrganizationNode(
          id: '$studioId-visual',
          name: 'Visual',
          parentId: studioId,
        ),
        OrganizationNode(
          id: '$studioId-production',
          name: 'Production',
          parentId: studioId,
        ),
      ],
      _leads = <DepartmentLead>[];

  final List<OrganizationNode> _nodes;
  final List<DepartmentLead> _leads;
  List<OrganizationNode> get departments => List.unmodifiable(_nodes);

  OrganizationNode addOrganization(String name) {
    final node = OrganizationNode(
      id: 'organization-${_nodes.length}',
      name: name,
    );
    _nodes.add(node);
    return node;
  }

  OrganizationNode addDepartment(String parentId, String name) {
    final node = OrganizationNode(
      id: 'department-${_nodes.length}',
      name: name,
      parentId: parentId,
    );
    _nodes.add(node);
    return node;
  }

  List<OrganizationNode> childrenOf(String parentId) =>
      _nodes.where((node) => node.parentId == parentId).toList(growable: false);

  void assignLead(DepartmentLead lead) {
    if (_leads.any(
      (current) =>
          current.departmentId == lead.departmentId &&
          current.lifecycle == LeadLifecycle.active,
    )) {
      throw StateError('An active lead is already assigned to this department');
    }
    _leads.add(lead);
  }

  DepartmentLead? leadFor(String departmentId) {
    for (final lead in _leads.reversed) {
      if (lead.departmentId == departmentId &&
          lead.lifecycle == LeadLifecycle.active) {
        return lead;
      }
    }
    return null;
  }
}

enum LeadAuthority { coordinateDepartment, approveDepartmentWork }

enum LeadLifecycle { active, suspended, retired }

class DepartmentLead {
  const DepartmentLead({
    required this.id,
    required this.agentId,
    required this.departmentId,
    this.authority = LeadAuthority.coordinateDepartment,
    this.lifecycle = LeadLifecycle.active,
  });

  final String id;
  final String agentId;
  final String departmentId;
  final LeadAuthority authority;
  final LeadLifecycle lifecycle;

  bool get canApproveDepartmentWork =>
      authority == LeadAuthority.approveDepartmentWork &&
      lifecycle == LeadLifecycle.active;

  @override
  bool operator ==(Object other) =>
      other is DepartmentLead &&
      other.id == id &&
      other.agentId == agentId &&
      other.departmentId == departmentId &&
      other.authority == authority &&
      other.lifecycle == lifecycle;

  @override
  int get hashCode =>
      Object.hash(id, agentId, departmentId, authority, lifecycle);
}

abstract interface class DepartmentLeadRepository {
  Future<void> save(DepartmentLead lead);
  Future<DepartmentLead?> findByDepartment(String departmentId);
}

class InMemoryDepartmentLeadRepository implements DepartmentLeadRepository {
  final Map<String, DepartmentLead> _leads = <String, DepartmentLead>{};

  @override
  Future<void> save(DepartmentLead lead) async {
    _leads[lead.departmentId] = lead;
  }

  @override
  Future<DepartmentLead?> findByDepartment(String departmentId) async =>
      _leads[departmentId];
}

enum AgentRole { director, writer, artist, reviewer }

class StudioAgent {
  const StudioAgent({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final AgentRole role;
  bool get isAiModel => false;
}
