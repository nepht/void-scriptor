import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/background_job.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-s26-lifecycle-'),
  );
  tearDown(() => root.delete(recursive: true));

  test(
    'session owns a job queue and cancels transient jobs on close',
    () async {
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Lifecycle');
      final manager = ProjectSessionManager();
      final session = await manager.open(package);

      final started = Completer<void>();
      final stopped = Completer<void>();
      session.jobs.enqueue(
        _LifecycleTask(
          _job('transient-scan', persistence: JobPersistence.transient),
          onExecute: (context) async {
            started.complete();
            while (!context.isCancelled()) {
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            stopped.complete();
          },
        ),
      );
      final draining = session.jobs.drain();
      await started.future;

      await session.close();
      await stopped.future;
      await draining;

      expect(
        session.jobs.jobOf('transient-scan')!.status,
        BackgroundJobStatus.cancelled,
      );
    },
  );

  test('session open records manifest and database phase metrics', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Metrics');
    final session = await ProjectSessionManager().open(package);
    addTearDown(session.close);

    expect(session.openMetrics.durationOf('manifest'), isNotNull);
    expect(session.openMetrics.durationOf('database'), isNotNull);
    expect(session.openMetrics.total, greaterThan(Duration.zero));
  });
}

BackgroundJob _job(
  String id, {
  JobPersistence persistence = JobPersistence.transient,
}) => BackgroundJob(
  id: id,
  projectId: 'project-1',
  type: BackgroundJobType.integrityScan,
  label: id,
  status: BackgroundJobStatus.queued,
  priority: BackgroundJobPriority.normal,
  createdAt: DateTime(2026),
  persistence: persistence,
);

class _LifecycleTask implements BackgroundTask {
  _LifecycleTask(this._jobModel, {required this.onExecute});

  final BackgroundJob _jobModel;
  final Future<void> Function(JobContext context) onExecute;

  @override
  BackgroundJob get job => _jobModel;

  @override
  String get id => _jobModel.id;

  @override
  BackgroundJobType get type => _jobModel.type;

  @override
  String? get taskKey => null;

  @override
  Set<JobResource> get resources => const {};

  @override
  Future<void> execute(JobContext context) => onExecute(context);

  @override
  Future<void> cancel() async {}
}
