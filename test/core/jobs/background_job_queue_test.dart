import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/background_job.dart';
import 'package:void_scriptor/core/jobs/background_job_queue.dart';

void main() {
  test('priority weight orders critical above high above normal above low', () {
    expect(
      priorityWeight(BackgroundJobPriority.critical),
      greaterThan(priorityWeight(BackgroundJobPriority.high)),
    );
    expect(
      priorityWeight(BackgroundJobPriority.high),
      greaterThan(priorityWeight(BackgroundJobPriority.normal)),
    );
    expect(
      priorityWeight(BackgroundJobPriority.normal),
      greaterThan(priorityWeight(BackgroundJobPriority.low)),
    );
  });

  test(
    'queue executes higher priority jobs first with bounded concurrency',
    () async {
      final started = <String>[];
      final release = <String, Completer<void>>{};
      final queue = BackgroundJobQueue(maxConcurrentJobs: 1);

      for (final id in ['low', 'critical', 'normal']) {
        release[id] = Completer<void>();
        queue.enqueue(
          _Task(
            _job(id, switch (id) {
              'low' => BackgroundJobPriority.low,
              'critical' => BackgroundJobPriority.critical,
              _ => BackgroundJobPriority.normal,
            }),
            onExecute: (context) async {
              started.add(id);
              release[id]!.complete();
              while (!context.isCancelled()) {
                await Future<void>.delayed(const Duration(milliseconds: 1));
                break;
              }
            },
          ),
        );
      }

      final drain = queue.drain();
      await release['critical']!.future;
      expect(started, ['critical']);
      await queue.cancel('critical');
      await drain;
    },
  );

  test('duplicate task keys are coalesced', () {
    final queue = BackgroundJobQueue();
    final task = _Task(
      _job('one', BackgroundJobPriority.normal),
      taskKey: 'thumbnail:a:256',
    );

    expect(queue.enqueue(task), isTrue);
    expect(
      queue.enqueue(
        _Task(_job('two', BackgroundJobPriority.high), taskKey: task.taskKey),
      ),
      isFalse,
    );
    expect(queue.pendingTaskKeys, ['thumbnail:a:256']);
  });

  test(
    'cancelling a queued task marks it cancelled and never executes it',
    () async {
      var executed = false;
      final queue = BackgroundJobQueue();
      final task = _Task(
        _job('queued', BackgroundJobPriority.normal),
        onExecute: (_) async => executed = true,
      );

      queue.enqueue(task);
      expect(await queue.cancel(task.id), isTrue);
      await queue.drain();

      expect(executed, isFalse);
      expect(queue.jobOf(task.id)!.status, BackgroundJobStatus.cancelled);
    },
  );

  test('running task receives cooperative cancellation context', () async {
    final started = Completer<void>();
    final stopped = Completer<void>();
    final queue = BackgroundJobQueue();
    final task = _Task(
      _job('running', BackgroundJobPriority.normal),
      onExecute: (context) async {
        started.complete();
        while (!context.isCancelled()) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        stopped.complete();
      },
    );

    queue.enqueue(task);
    final draining = queue.drain();
    await started.future;
    expect(await queue.cancel(task.id), isTrue);
    await stopped.future;
    await draining;

    expect(queue.jobOf(task.id)!.status, BackgroundJobStatus.cancelled);
  });

  test('resource limits prevent two CPU tasks from running at once', () async {
    var active = 0;
    var peak = 0;
    final queue = BackgroundJobQueue(
      maxConcurrentJobs: 4,
      resourceLimits: const {JobResource.cpu: 1},
    );

    for (final id in ['a', 'b']) {
      queue.enqueue(
        _Task(
          _job(id, BackgroundJobPriority.normal),
          resources: const {JobResource.cpu},
          onExecute: (_) async {
            active++;
            peak = active > peak ? active : peak;
            await Future<void>.delayed(const Duration(milliseconds: 5));
            active--;
          },
        ),
      );
    }

    await queue.drain();
    expect(peak, 1);
  });
}

BackgroundJob _job(String id, BackgroundJobPriority priority) => BackgroundJob(
  id: id,
  projectId: 'project-1',
  type: BackgroundJobType.custom,
  label: id,
  status: BackgroundJobStatus.queued,
  priority: priority,
  createdAt: DateTime(2026),
);

class _Task implements BackgroundTask {
  _Task(
    this._jobModel, {
    this.onExecute,
    this.taskKey,
    Set<JobResource>? resources,
  }) : resources = resources ?? const {};

  final BackgroundJob _jobModel;
  final Future<void> Function(JobContext context)? onExecute;
  @override
  final String? taskKey;
  @override
  final Set<JobResource> resources;

  @override
  BackgroundJob get job => _jobModel;

  @override
  String get id => _jobModel.id;

  @override
  BackgroundJobType get type => job.type;

  @override
  Future<void> execute(JobContext context) =>
      onExecute?.call(context) ?? Future<void>.value();

  @override
  Future<void> cancel() async {}
}
