class OrganizationNode {
  const OrganizationNode({required this.id, required this.name, this.parentId});

  final String id;
  final String name;
  final String? parentId;
}

class OrganizationTree {
  OrganizationTree() : _nodes = [];

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
      ];

  final List<OrganizationNode> _nodes;
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
}

enum AgentRole { director, writer, artist, reviewer }

class StudioAgent {
  const StudioAgent({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final AgentRole role;
  bool get isAiModel => false;
}
