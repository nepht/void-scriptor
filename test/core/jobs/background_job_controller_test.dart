import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/background_job.dart';
import 'package:void_scriptor/core/jobs/background_job_controller.dart';
import 'package:void_scriptor/core/jobs/background_job_queue.dart';

void main() {
  test('controller exposes queued jobs and reflects completion', () async {
    final queue = BackgroundJobQueue();
    final controller = BackgroundJobController(queue);
    addTearDown(controller.dispose);
    final task = _Task(_job('job-1'));

    expect(controller.enqueue(task), isTrue);
    expect(controller.jobs.single.status, BackgroundJobStatus.queued);
    await controller.drain();
    expect(controller.jobs.single.status, BackgroundJobStatus.completed);
  });

  test('controller cancels a queued job', () async {
    final queue = BackgroundJobQueue();
    final controller = BackgroundJobController(queue);
    addTearDown(controller.dispose);
    final task = _Task(_job('job-2'));

    controller.enqueue(task);
    expect(await controller.cancel(task.id), isTrue);
    expect(controller.jobs.single.status, BackgroundJobStatus.cancelled);
  });
}

BackgroundJob _job(String id) => BackgroundJob(
  id: id,
  projectId: 'project-1',
  type: BackgroundJobType.custom,
  label: 'Task $id',
  status: BackgroundJobStatus.queued,
  priority: BackgroundJobPriority.normal,
  createdAt: DateTime(2026),
);

class _Task implements BackgroundTask {
  _Task(this.job);
  @override
  final BackgroundJob job;
  @override
  String get id => job.id;
  @override
  BackgroundJobType get type => job.type;
  @override
  String? get taskKey => null;
  @override
  Set<JobResource> get resources => const {};
  @override
  Future<void> execute(JobContext context) async {}
  @override
  Future<void> cancel() async {}
}
