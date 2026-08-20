class StudioOperationPlan {
  const StudioOperationPlan(this.goal);
  final String goal;
  bool dryRun() => goal.trim().isNotEmpty;
}

class SoloCreatorTemplate {
  static const defaultDepartments = ['Narrative', 'Visual', 'Production'];
}

class StudioCheckpoint {
  const StudioCheckpoint(this.activeTasks);
  final List<String> activeTasks;
}

class StudioScheduler {
  StudioScheduler({required this.maxConcurrent}) : _active = {};
  final int maxConcurrent;
  final Set<String> _active;
  bool isStopped = false;

  bool schedule(String task) {
    if (isStopped || _active.length >= maxConcurrent || !_active.add(task)) {
      return false;
    }
    return true;
  }

  StudioCheckpoint checkpoint() =>
      StudioCheckpoint(_active.toList(growable: false));
  void emergencyStop() {
    isStopped = true;
  }

  void resume(StudioCheckpoint checkpoint) {
    _active
      ..clear()
      ..addAll(checkpoint.activeTasks);
    isStopped = false;
  }
}

class LeastPrivilege {
  const LeastPrivilege();
  bool allows(String action) => action == 'read';
}

class PromptInjectionBoundary {
  const PromptInjectionBoundary();
  bool accept(String input) {
    final normalized = input.toLowerCase();
    return !normalized.contains('ignore previous') &&
        !normalized.contains('disregard instructions');
  }
}
