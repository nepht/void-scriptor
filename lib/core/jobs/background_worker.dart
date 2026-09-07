import 'dart:async';
import 'dart:isolate';

class BackgroundWorker {
  const BackgroundWorker._();

  static Future<T> runCpu<T>(FutureOr<T> Function() operation) =>
      Isolate.run(operation);
}

class JobRetryPolicy {
  const JobRetryPolicy({this.maxAttempts = 2}) : assert(maxAttempts >= 0);

  final int maxAttempts;

  bool canRetry(int completedAttempts) => completedAttempts < maxAttempts;
}

class JobDependency {
  const JobDependency({required this.jobId, required this.dependsOnId});

  final String jobId;
  final String dependsOnId;
}

class JobDependencyGraph {
  JobDependencyGraph(Iterable<JobDependency> dependencies)
    : _dependencies = List.unmodifiable(dependencies) {
    // core-hunt-20260906 BUG-53: detect cycles eagerly — a cyclic graph
    // would otherwise leave every member pending forever (deadlock).
    _cyclicJobIds.addAll(_findCycleMembers());
  }

  final List<JobDependency> _dependencies;
  final Set<String> _cyclicJobIds = {};

  bool isReady(String jobId, Map<String, String> statuses) {
    // Cycle members are unblocked so the deadlock surfaces as a run that
    // fails visibly instead of a silent permanent stall.
    if (_cyclicJobIds.contains(jobId)) return true;
    return _dependencies
        .where((dependency) => dependency.jobId == jobId)
        .every((dependency) {
      final status = statuses[dependency.dependsOnId];
      // Failed/cancelled dependencies count as done: the dependent should
      // run and fail visibly rather than pend forever. An unknown status
      // (dependency not yet recorded) still blocks.
      return status == 'completed' ||
          status == 'failed' ||
          status == 'cancelled';
    });
  }

  Set<String> _findCycleMembers() {
    final dependents = <String, List<String>>{};
    for (final dependency in _dependencies) {
      dependents.putIfAbsent(dependency.jobId, () => []).add(dependency.dependsOnId);
    }

    final resolved = <String>{};
    var changed = true;
    while (changed) {
      changed = false;
      for (final entry in dependents.entries) {
        if (resolved.contains(entry.key)) continue;
        final allResolvable = entry.value.every(
          (dep) => !dependents.containsKey(dep) || resolved.contains(dep),
        );
        if (allResolvable) {
          resolved.add(entry.key);
          changed = true;
        }
      }
    }
    return dependents.keys.toSet().difference(resolved);
  }
}
