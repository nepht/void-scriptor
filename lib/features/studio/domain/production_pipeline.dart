enum DelegationMode { human, agent, hybrid }

enum ProductionTaskStatus { pending, completed }

class ProductionTask {
  ProductionTask({
    required this.id,
    required this.name,
    this.dependsOn,
    required this.mode,
  });

  final String id;
  final String name;
  final String? dependsOn;
  final DelegationMode mode;
  ProductionTaskStatus status = ProductionTaskStatus.pending;
}

class ProductionBreakdown {
  ProductionBreakdown(this.goal);
  final String goal;
  final List<ProductionTask> _tasks = [];

  ProductionTask addTask(
    String name, {
    String? dependsOn,
    DelegationMode mode = DelegationMode.hybrid,
  }) {
    final task = ProductionTask(
      id: 'task-${_tasks.length}',
      name: name,
      dependsOn: dependsOn,
      mode: mode,
    );
    _tasks.add(task);
    return task;
  }

  bool isBlocked(String id) {
    final task = _tasks.firstWhere((item) => item.id == id);
    final dependency = task.dependsOn;
    if (dependency == null) return false;
    return _tasks.firstWhere((item) => item.id == dependency).status !=
        ProductionTaskStatus.completed;
  }

  void complete(String id) =>
      _tasks.firstWhere((item) => item.id == id).status =
          ProductionTaskStatus.completed;
}

class ProductionDirector {
  ProductionDirector({this.maxDelegationDepth = 3});
  final int maxDelegationDepth;

  ProductionBreakdown breakdown(String goal) => ProductionBreakdown(goal);

  bool delegate(String task, {required DelegationMode mode, int depth = 0}) =>
      task.trim().isNotEmpty && depth <= maxDelegationDepth;
}
