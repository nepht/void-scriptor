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
    : _dependencies = List.unmodifiable(dependencies);

  final List<JobDependency> _dependencies;

  bool isReady(String jobId, Map<String, String> statuses) => _dependencies
      .where((dependency) => dependency.jobId == jobId)
      .every((dependency) => statuses[dependency.dependsOnId] == 'completed');
}
