import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/background_worker.dart';

void main() {
  test('CPU worker executes computation outside the caller contract', () async {
    final result = await BackgroundWorker.runCpu(() => 21 * 2);
    expect(result, 42);
  });

  test('retry policy stops after bounded attempts', () {
    const policy = JobRetryPolicy(maxAttempts: 2);
    expect(policy.canRetry(0), isTrue);
    expect(policy.canRetry(1), isTrue);
    expect(policy.canRetry(2), isFalse);
  });

  test('dependency graph exposes only tasks whose dependencies completed', () {
    final graph = JobDependencyGraph([
      const JobDependency(jobId: 'thumbnail', dependsOnId: 'import'),
      const JobDependency(jobId: 'index', dependsOnId: 'thumbnail'),
    ]);

    expect(graph.isReady('import', const {'import': 'completed'}), isTrue);
    expect(graph.isReady('thumbnail', const {'import': 'completed'}), isTrue);
    expect(graph.isReady('index', const {'import': 'completed'}), isFalse);
    expect(
      graph.isReady('index', const {
        'import': 'completed',
        'thumbnail': 'completed',
      }),
      isTrue,
    );
  });
}
