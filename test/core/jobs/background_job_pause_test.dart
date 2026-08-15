import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/background_job.dart';
import 'package:void_scriptor/core/jobs/background_job_queue.dart';

void main() {
  test(
    'pausing stops low-priority jobs from scheduling; resume restarts',
    () async {
      final queue = BackgroundJobQueue(maxConcurrentJobs: 1);
      var lowRan = false;
      var highRan = false;

      queue.enqueue(
        _FakeTask(
          'low',
          priority: BackgroundJobPriority.low,
          onExecute: () async => lowRan = true,
        ),
      );
      queue.enqueue(
        _FakeTask(
          'high',
          priority: BackgroundJobPriority.critical,
          onExecute: () async => highRan = true,
        ),
      );

      queue.pause(BackgroundJobPriority.low);
      await queue.drain();

      // Critical job runs; low job is paused.
      expect(highRan, isTrue);
      expect(lowRan, isFalse);

      queue.resume();
      await queue.drain();
      expect(lowRan, isTrue);
    },
  );
}

class _FakeTask implements BackgroundTask {
  _FakeTask(this.id, {required this.priority, required this.onExecute});

  @override
  final String id;
  final BackgroundJobPriority priority;
  final Future<void> Function() onExecute;

  @override
  BackgroundJob get job => BackgroundJob(
    id: id,
    projectId: 'project-1',
    type: BackgroundJobType.import,
    label: id,
    status: BackgroundJobStatus.queued,
    priority: priority,
    createdAt: DateTime(2026),
  );

  @override
  BackgroundJobType get type => BackgroundJobType.import;

  @override
  String? get taskKey => null;

  @override
  Set<JobResource> get resources => const {};

  @override
  Future<void> execute(JobContext context) => onExecute();

  @override
  Future<void> cancel() async {}
}
