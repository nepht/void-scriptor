import 'dart:async';

import 'background_job.dart';

class BackgroundJobQueue {
  BackgroundJobQueue({
    this.maxConcurrentJobs = 2,
    Map<JobResource, int> resourceLimits = const {},
  }) : _resourceLimits = Map.unmodifiable(resourceLimits),
       assert(maxConcurrentJobs > 0);

  final int maxConcurrentJobs;
  final Map<JobResource, int> _resourceLimits;
  final List<BackgroundTask> _pending = [];
  final Map<String, BackgroundTask> _tasks = {};
  final Map<String, BackgroundJob> _jobs = {};
  final Map<String, _CancellationToken> _tokens = {};
  final Map<JobResource, int> _activeResources = {};
  final Map<String, Future<void>> _active = {};
  final StreamController<BackgroundJob> _updates =
      StreamController<BackgroundJob>.broadcast(sync: true);
  bool _draining = false;

  Stream<BackgroundJob> get updates => _updates.stream;
  Iterable<String> get pendingTaskKeys =>
      _pending.map((task) => task.taskKey).whereType<String>();
  BackgroundJob? jobOf(String id) => _jobs[id];

  bool enqueue(BackgroundTask task) {
    final key = task.taskKey;
    if (_tasks.containsKey(task.id) ||
        (key != null &&
            _tasks.values.any(
              (candidate) =>
                  candidate.taskKey == key &&
                  _jobs[candidate.id]?.status !=
                      BackgroundJobStatus.completed &&
                  _jobs[candidate.id]?.status != BackgroundJobStatus.failed &&
                  _jobs[candidate.id]?.status != BackgroundJobStatus.cancelled,
            ))) {
      return false;
    }
    _tasks[task.id] = task;
    _tokens[task.id] = _CancellationToken();
    _jobs[task.id] = _jobFor(task, BackgroundJobStatus.queued);
    _pending.add(task);
    _publish(task.id);
    return true;
  }

  Future<bool> cancel(String id) async {
    final task = _tasks[id];
    final job = _jobs[id];
    if (task == null || job == null) return false;
    if (job.status == BackgroundJobStatus.queued) {
      _pending.removeWhere((candidate) => candidate.id == id);
      _tokens[id]!.cancelled = true;
      _setStatus(id, BackgroundJobStatus.cancelled);
      await task.cancel();
      return true;
    }
    if (job.status == BackgroundJobStatus.running) {
      _tokens[id]!.cancelled = true;
      _setStatus(id, BackgroundJobStatus.cancelled);
      await task.cancel();
      return true;
    }
    return false;
  }

  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_pending.isNotEmpty || _active.isNotEmpty) {
        _scheduleAvailable();
        if (_active.isNotEmpty) {
          await Future.any(_active.values);
        } else if (_pending.isNotEmpty) {
          await Future<void>.delayed(Duration.zero);
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> dispose() async {
    await _updates.close();
  }

  void _scheduleAvailable() {
    while (_active.length < maxConcurrentJobs) {
      final index = _nextRunnableIndex();
      if (index == -1) return;
      final task = _pending.removeAt(index);
      _reserve(task.resources);
      _setStatus(task.id, BackgroundJobStatus.running);
      final future = _run(task);
      _active[task.id] = future;
      future.whenComplete(() {
        _active.remove(task.id);
        _release(task.resources);
      });
    }
  }

  int _nextRunnableIndex() {
    var bestIndex = -1;
    var bestWeight = -1;
    for (var i = 0; i < _pending.length; i++) {
      final task = _pending[i];
      if (!_fits(task.resources)) continue;
      final weight = priorityWeight(_jobs[task.id]!.priority);
      if (weight > bestWeight) {
        bestIndex = i;
        bestWeight = weight;
      }
    }
    return bestIndex;
  }

  Future<void> _run(BackgroundTask task) async {
    final token = _tokens[task.id]!;
    final context = JobContext(
      reportProgress: (value) {
        if (!token.cancelled &&
            _jobs[task.id]?.status == BackgroundJobStatus.running) {
          _jobs[task.id] = _jobs[task.id]!.copyWith(
            progress: value.clamp(0, 1),
          );
          _publish(task.id);
        }
      },
      isCancelled: () => token.cancelled,
    );
    try {
      await task.execute(context);
      if (!token.cancelled &&
          _jobs[task.id]?.status == BackgroundJobStatus.running) {
        _jobs[task.id] = _jobs[task.id]!.copyWith(
          status: BackgroundJobStatus.completed,
          progress: 1,
        );
        _publish(task.id);
      }
    } catch (error) {
      if (!token.cancelled &&
          _jobs[task.id]?.status == BackgroundJobStatus.running) {
        _jobs[task.id] = _jobs[task.id]!.copyWith(
          status: BackgroundJobStatus.failed,
          error: error.toString(),
        );
        _publish(task.id);
      }
    }
  }

  bool _fits(Set<JobResource> resources) => resources.every((resource) {
    final limit = _resourceLimits[resource];
    return limit == null || (_activeResources[resource] ?? 0) < limit;
  });

  void _reserve(Set<JobResource> resources) {
    for (final resource in resources) {
      _activeResources[resource] = (_activeResources[resource] ?? 0) + 1;
    }
  }

  void _release(Set<JobResource> resources) {
    for (final resource in resources) {
      final next = (_activeResources[resource] ?? 1) - 1;
      if (next == 0) {
        _activeResources.remove(resource);
      } else {
        _activeResources[resource] = next;
      }
    }
  }

  BackgroundJob _jobFor(BackgroundTask task, BackgroundJobStatus status) =>
      task.job.copyWith(status: status);

  void _setStatus(String id, BackgroundJobStatus status) {
    _jobs[id] = _jobs[id]!.copyWith(status: status);
    _publish(id);
  }

  void _publish(String id) {
    if (!_updates.isClosed) _updates.add(_jobs[id]!);
  }
}

class _CancellationToken {
  bool cancelled = false;
}
