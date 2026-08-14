import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/background_job.dart';
import 'package:void_scriptor/core/jobs/background_job_controller.dart';
import 'package:void_scriptor/core/jobs/background_job_queue.dart';
import 'package:void_scriptor/core/jobs/task_center_screen.dart';

void main() {
  testWidgets('Task Center shows active jobs and cancel action', (
    tester,
  ) async {
    final queue = BackgroundJobQueue();
    final controller = BackgroundJobController(queue);
    addTearDown(controller.dispose);
    controller.enqueue(_Task());

    await tester.pumpWidget(
      MaterialApp(home: TaskCenterScreen(controller: controller)),
    );

    expect(find.text('TASK CENTER'), findsOneWidget);
    expect(find.text('Tasks 1'), findsOneWidget);
    expect(find.text('Generate thumbnails'), findsOneWidget);
    expect(find.byTooltip('Cancel task'), findsOneWidget);

    await tester.tap(find.byTooltip('Cancel task'));
    await tester.pump();
    expect(controller.jobs.single.status, BackgroundJobStatus.cancelled);
  });
}

class _Task implements BackgroundTask {
  @override
  final BackgroundJob job = BackgroundJob(
    id: 'thumbnail-1',
    projectId: 'project-1',
    type: BackgroundJobType.thumbnail,
    label: 'Generate thumbnails',
    status: BackgroundJobStatus.queued,
    priority: BackgroundJobPriority.high,
    createdAt: DateTime(2026),
  );
  @override
  String get id => job.id;
  @override
  BackgroundJobType get type => job.type;
  @override
  String? get taskKey => 'thumbnail:asset-1:256';
  @override
  Set<JobResource> get resources => const {JobResource.cpu, JobResource.disk};
  @override
  Future<void> execute(JobContext context) async {}
  @override
  Future<void> cancel() async {}
}
