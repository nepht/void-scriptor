import 'dart:async';

import 'background_job.dart';

class BackgroundJobQueue {
  BackgroundJobQueue({
    this.maxConcurrentJobs = 2,
    Map<JobResource, int> resourceLimits = const {},
  }) : _resourceLimits = Map.unmodifiable(resourceLimits),
       assert(maxConcurrentJobs > 0) {
    // core-hunt-20260906 BUG-49: a limit <= 0 can never be satisfied, so
    // any task requiring that resource would spin drain() forever at
    // Duration.zero while burning CPU. Reject it up front instead.
    for (final entry in _resourceLimits.entries) {
      if (entry.value <= 0) {
        throw ArgumentError.value(
          entry.value,
          'resourceLimits[${entry.key}]',
          'must be greater than 0; a satisfiable limit is required',
        );
      }
    }
  }

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
  Future<void>? _drainLoop;
  BackgroundJobPriority? _pauseThreshold;

  Stream<BackgroundJob> get updates => _updates.stream;
  Iterable<String> get pendingTaskKeys =>
      _pending.map((task) => task.taskKey).whereType<String>();
  Iterable<BackgroundJob> get jobs => _jobs.values;
  BackgroundJob? jobOf(String id) => _jobs[id];

  bool enqueue(BackgroundTask task) {
    final key = task.taskKey;
    // core-hunt-20260906 BUG-48: the taskKey dedup below deliberately
    // treats completed/failed/cancelled as re-enqueueable, but the id
    // check ignored terminal status, so a finished id could never run
    // again and the maps grew without bound. The id check now follows
    // the same terminal-state rule; a terminal id is replaced on
    // re-enqueue instead of blocking forever.
    final existingJob = _jobs[task.id];
    final idIsTerminal =
        existingJob != null &&
        (existingJob.status == BackgroundJobStatus.completed ||
            existingJob.status == BackgroundJobStatus.failed ||
            existingJob.status == BackgroundJobStatus.cancelled);
    if (!idIsTerminal && _tasks.containsKey(task.id)) return false;
    if (idIsTerminal) {
      _tasks.remove(task.id);
      _tokens.remove(task.id);
      _jobs.remove(task.id);
      _pending.removeWhere((candidate) => candidate.id == task.id);
    }
    if (key != null &&
        _tasks.values.any(
          (candidate) =>
              candidate.taskKey == key &&
              _jobs[candidate.id]?.status != BackgroundJobStatus.completed &&
              _jobs[candidate.id]?.status != BackgroundJobStatus.failed &&
              _jobs[candidate.id]?.status != BackgroundJobStatus.cancelled,
        )) {
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

  /// Drains every pending and active task, returning only once the queue is
  /// genuinely empty.
  ///
  /// A concurrent caller joins the SAME loop instead of receiving an
  /// already-complete future. Returning early would let a caller believe the
  /// queue is drained while tasks are still queued or running, so it could
  /// close a database, a lock, or a session underneath live work. The loop
  /// itself is still re-entrant safe: it re-reads `_pending`/`_active` every
  /// iteration, so work enqueued by a task during the drain is still picked up.
  Future<void> drain() {
    final running = _drainLoop;
    if (running != null) return running;
    final loop = _drainUntilEmpty();
    _drainLoop = loop;
    return loop.whenComplete(() {
      if (identical(_drainLoop, loop)) _drainLoop = null;
    });
  }

  Future<void> _drainUntilEmpty() async {
    while (_active.isNotEmpty || _hasRunnablePending()) {
      _scheduleAvailable();
      if (_active.isNotEmpty) {
        await Future.any(_active.values);
      } else if (_hasRunnablePending()) {
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  bool _hasRunnablePending() =>
      _pending.any((task) => !_isPaused(_jobs[task.id]!.priority));

  /// Pauses scheduling of jobs at or below [priority] (Step 26.71).
  ///
  /// Critical user tasks (export/backup) above the threshold keep running.
  void pause(BackgroundJobPriority priority) {
    _pauseThreshold = priority;
  }

  /// Resumes scheduling for all previously paused jobs.
  void resume() {
    _pauseThreshold = null;
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
      final job = _jobs[task.id]!;
      if (_isPaused(job.priority)) continue;
      final weight = priorityWeight(job.priority);
      if (weight > bestWeight) {
        bestIndex = i;
        bestWeight = weight;
      }
    }
    return bestIndex;
  }

  bool _isPaused(BackgroundJobPriority priority) {
    final threshold = _pauseThreshold;
    if (threshold == null) return false;
    return priorityWeight(priority) <= priorityWeight(threshold);
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
