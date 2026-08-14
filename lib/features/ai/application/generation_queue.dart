import 'dart:async';
import '../domain/generation_job.dart';

typedef GenerationJobExecutor = Future<void> Function(GenerationJob job);
typedef GenerationJobCanceller = Future<void> Function(GenerationJob job);

class GenerationQueue {
  GenerationQueue({
    this.maxConcurrentJobs = 2,
    required this.executor,
    this.canceller,
  }) : assert(maxConcurrentJobs > 0);
  final int maxConcurrentJobs;
  final GenerationJobExecutor executor;
  final GenerationJobCanceller? canceller;
  final List<GenerationJob> _pending = [];
  final Map<String, GenerationJob> _jobs = {};
  final Map<String, GenerationJobStatus> _statuses = {};
  final Set<String> _cancelled = {};
  bool _draining = false;

  void enqueue(GenerationJob job) {
    _jobs[job.id] = job;
    _pending.add(job);
    _statuses[job.id] = job.status;
  }

  bool retry(String jobId) {
    final job = _jobs[jobId];
    if (job == null || _statuses[jobId] != GenerationJobStatus.failed) {
      return false;
    }
    _cancelled.remove(jobId);
    final retryJob = job.copyWith(
      status: GenerationJobStatus.queued,
      progress: 0,
      error: null,
    );
    _jobs[jobId] = retryJob;
    _statuses[jobId] = GenerationJobStatus.queued;
    _pending.add(retryJob);
    return true;
  }

  Future<bool> cancel(String jobId) async {
    final job = _jobs[jobId];
    final wasPending = _pending.any((candidate) => candidate.id == jobId);
    final wasRunning = _statuses[jobId] == GenerationJobStatus.running;
    _pending.removeWhere((candidate) => candidate.id == jobId);
    if (!wasPending && !wasRunning) {
      return false;
    }
    _cancelled.add(jobId);
    _statuses[jobId] = GenerationJobStatus.cancelled;
    if (wasRunning && job != null) {
      await canceller?.call(job);
    }
    return true;
  }

  GenerationJobStatus? statusOf(String jobId) => _statuses[jobId];

  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      final active = <Future<void>>{};
      while (_pending.isNotEmpty || active.isNotEmpty) {
        while (_pending.isNotEmpty && active.length < maxConcurrentJobs) {
          _pending.sort((a, b) => b.priority.index.compareTo(a.priority.index));
          final job = _pending.removeAt(0);
          if (_cancelled.contains(job.id)) {
            continue;
          }
          _statuses[job.id] = GenerationJobStatus.running;
          final future = _execute(job);
          active.add(future);
          future.whenComplete(() => active.remove(future));
        }
        if (active.isNotEmpty) await Future.any(active);
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _execute(GenerationJob job) async {
    try {
      await executor(job);
      if (!_cancelled.contains(job.id)) {
        _statuses[job.id] = GenerationJobStatus.completed;
      }
    } catch (_) {
      if (!_cancelled.contains(job.id)) {
        _statuses[job.id] = GenerationJobStatus.failed;
      }
    }
  }
}
