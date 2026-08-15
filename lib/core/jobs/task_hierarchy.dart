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
  final String label;
  final TaskKind kind;
  final List<TaskNode> children = [];
}

class TaskHierarchy {
  final Map<String, TaskNode> _nodes = {};

  void attach(String id, {required String label}) {
    _nodes.putIfAbsent(
      id,
      () => TaskNode(id: id, label: label, kind: TaskKind.user),
    );
  }

  void attachChild(
    String parentId,
    String id, {
    required String label,
    required TaskKind kind,
  }) {
    final parent = _nodes.putIfAbsent(
      parentId,
      () => TaskNode(id: parentId, label: parentId, kind: TaskKind.user),
    );
    final child = TaskNode(id: id, label: label, kind: kind);
    _nodes[id] = child;
    parent.children.add(child);
  }

  TaskKind? taskKindOf(String id) => _nodes[id]?.kind;

  List<TaskNode> get tree => _nodes.values
      .where((node) => !_nodes.values.any((c) => c.children.contains(node)))
      .toList();
}
