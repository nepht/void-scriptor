/// Task dependency and hierarchy model (Steps 26.77, 26.78, 26.79).
///
/// A user-facing task (e.g. "Import 50 References") owns derived children
/// ("Calculate hashes", "Generate thumbnails") that the Task Center collapses
/// beneath the parent so the user sees a comprehensible tree, not a flat list
/// of implementation jobs.
class JobDependency {
  const JobDependency({required this.jobId, required this.dependsOnId});

  final String jobId;
  final String dependsOnId;
}

enum TaskKind { user, derived }

class TaskNode {
  TaskNode({required this.id, required this.label, required this.kind});

  final String id;
  String label;
  TaskKind kind;
  final List<TaskNode> children = [];
}

class TaskHierarchy {
  final Map<String, TaskNode> _nodes = {};

  void attach(String id, {required String label}) {
    final existing = _nodes[id];
    if (existing != null) {
      existing.label = label;
      return;
    }
    _nodes[id] = TaskNode(id: id, label: label, kind: TaskKind.user);
  }

  void attachChild(
    String parentId,
    String id, {
    required String label,
    required TaskKind kind,
  }) {
    if (id == parentId) {
      // Self-parenting is a no-op, never a cycle.
      attach(id, label: label);
      return;
    }
    final parent = _nodes.putIfAbsent(
      parentId,
      () => TaskNode(id: parentId, label: parentId, kind: TaskKind.user),
    );
    if (_isDescendant(_nodes[id] ?? parent, parentId)) {
      // core-hunt-20260906 BUG-56: re-parenting under own descendant would
      // close a cycle (the moved node's subtree contains the new parent);
      // refuse instead of corrupting the tree.
      return;
    }
    // core-hunt-20260906 BUG-56: a node's identity must survive re-attach.
    // The old code built a fresh TaskNode, leaving a stale orphan in the
    // previous parent's children and duplicating the id across the tree.
    // Detach from every current parent, then mutate the existing node
    // in place (label/kind update included) so one object backs every
    // reference.
    final existing = _nodes[id];
    if (existing != null) {
      for (final node in _nodes.values) {
        node.children.remove(existing);
      }
      existing
        ..label = label
        ..kind = kind;
      parent.children.add(existing);
      return;
    }
    final child = TaskNode(id: id, label: label, kind: kind);
    _nodes[id] = child;
    parent.children.add(child);
  }

  bool _isDescendant(TaskNode candidate, String ancestorId) {
    for (final child in candidate.children) {
      if (child.id == ancestorId) return true;
      if (_isDescendant(child, ancestorId)) return true;
    }
    return false;
  }

  TaskKind? taskKindOf(String id) => _nodes[id]?.kind;

  List<TaskNode> get tree => _nodes.values
      .where((node) => !_nodes.values.any((c) => c.children.contains(node)))
      .toList();
}
