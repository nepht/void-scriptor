abstract interface class ProjectOwnedTask {
  String get id;
  Future<void> cancel();
}

class ProjectTaskOwner {
  ProjectTaskOwner(this.projectId);

  final String projectId;
  final Map<String, ({ProjectOwnedTask task, bool persistent})> _tasks = {};

  void attach(ProjectOwnedTask task, {required bool persistent}) {
    _tasks[task.id] = (task: task, persistent: persistent);
  }

  Future<void> close() async {
    final transient = _tasks.values
        .where((entry) => !entry.persistent)
        .map((entry) => entry.task.cancel());
    await Future.wait(transient);
    _tasks.clear();
  }
}

class MemoryCachePolicy {
  const MemoryCachePolicy({this.maxPreviewItems = 100});

  final int maxPreviewItems;
  bool shouldEvict(int itemCount) => itemCount > maxPreviewItems;
}

class PerformanceMetrics {
  final Map<String, Duration> _durations = {};

  void record(String phase, Duration duration) => _durations[phase] = duration;
  Duration? durationOf(String phase) => _durations[phase];

  Duration get total => _durations.values.fold(
    Duration.zero,
    (total, duration) => total + duration,
  );
}
