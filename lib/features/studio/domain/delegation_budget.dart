enum AgentStatus { idle, running, blocked, failed }

class StudioTask {
  const StudioTask({required this.id, required this.priority});
  final String id;
  final int priority;
}

class DelegationEngine {
  const DelegationEngine({required this.maxDepth});
  final int maxDepth;

  List<String> decompose(String task, {required int depth}) {
    if (depth > maxDepth || task.trim().isEmpty) return const [];
    return ['$task.part1', '$task.part2'];
  }
}

class StudioTaskQueue {
  StudioTaskQueue({required this.capacity}) : _tasks = [];
  final int capacity;
  final List<StudioTask> _tasks;
  AgentStatus status = AgentStatus.idle;

  bool enqueue(StudioTask task) {
    if (_tasks.length >= capacity) return false;
    _tasks.add(task);
    return true;
  }

  StudioTask? next() => _tasks.isEmpty ? null : _tasks.removeAt(0);
}

class StudioBudget {
  const StudioBudget({required this.computeUnits, required this.projectUnits});
  final int computeUnits;
  final int projectUnits;

  bool gate({required int compute, required int project}) =>
      compute <= computeUnits && project <= projectUnits;
}
