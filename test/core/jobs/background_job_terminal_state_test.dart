import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/background_job.dart';
import 'package:void_scriptor/core/jobs/background_job_queue.dart';
import 'package:void_scriptor/core/jobs/background_worker.dart';

/// core-hunt-20260906 BUG-48/49/53: a finished task id could never be
/// re-enqueued (the id dedup ignores terminal status), drain() could spin
/// forever on a resource limit that no task can ever satisfy, and a
/// dependency in failed/cancelled state (or a dependency cycle) left the
/// dependent job pending forever.
void main() {
  group('core-hunt-20260906 terminal-state re-enqueue (BUG-48)', () {
    test('a completed task id can be re-enqueued and runs again', () async {
      var runs = 0;
      final queue = BackgroundJobQueue();
      final task = _Task(
        _job('snap', BackgroundJobPriority.normal),
        onExecute: (_) async => runs++,
        taskKey: 'thumbnail:a:256',
      );

      expect(queue.enqueue(task), isTrue);
      await queue.drain();
      expect(runs, 1);
      expect(queue.jobOf(task.id)!.status, BackgroundJobStatus.completed);

      final again = _Task(
        _job('snap', BackgroundJobPriority.normal),
        onExecute: (_) async => runs++,
        taskKey: 'thumbnail:a:256',
      );
      expect(
        queue.enqueue(again),
        isTrue,
        reason: 'BUG-48: completed state blocked re-enqueue of the same id',
      );
      await queue.drain();
      expect(runs, 2);
      expect(queue.jobOf(task.id)!.status, BackgroundJobStatus.completed);
    });

    test(
      'a failed task id can be re-enqueued (mirrors the taskKey allowance)',
      () async {
        var attempts = 0;
        final queue = BackgroundJobQueue();
        final failing = _Task(
          _job('retry-me', BackgroundJobPriority.normal),
          onExecute: (_) async {
            attempts++;
            throw StateError('boom');
          },
          taskKey: 'integrity:scan',
        );
        expect(queue.enqueue(failing), isTrue);
        await queue.drain();
        expect(queue.jobOf(failing.id)!.status, BackgroundJobStatus.failed);

        final retry = _Task(
          _job('retry-me', BackgroundJobPriority.normal),
          onExecute: (_) async => attempts++,
          taskKey: 'integrity:scan',
        );
        expect(queue.enqueue(retry), isTrue);
        await queue.drain();
        expect(attempts, 2);
        expect(queue.jobOf(retry.id)!.status, BackgroundJobStatus.completed);
      },
    );

    test('a live (queued) duplicate is still rejected on id and taskKey', () {
      final queue = BackgroundJobQueue();
      queue.enqueue(
        _Task(
          _job('live', BackgroundJobPriority.normal),
          taskKey: 'waveform:job',
        ),
      );
      expect(
        queue.enqueue(
          _Task(
            _job('live', BackgroundJobPriority.high),
            taskKey: 'waveform:job',
          ),
        ),
        isFalse,
        reason: 'same id while still queued must not double-enqueue',
      );
      expect(
        queue.enqueue(
          _Task(
            _job('other', BackgroundJobPriority.high),
            taskKey: 'waveform:job',
          ),
        ),
        isFalse,
        reason: 'taskKey coalescing must stay intact for live jobs',
      );
    });

    test(
      're-enqueue replaces history rather than accumulating duplicates',
      () async {
        final queue = BackgroundJobQueue();
        final first = _Task(
          _job('cycle', BackgroundJobPriority.normal),
          onExecute: (_) async {},
        );
        queue.enqueue(first);
        await queue.drain();
        queue.enqueue(
          _Task(
            _job('cycle', BackgroundJobPriority.normal),
            onExecute: (_) async {},
          ),
        );
        await queue.drain();
        final ids = queue.jobs.map((job) => job.id).toList();
        expect(ids.where((id) => id == 'cycle'), hasLength(1));
      },
    );
  });

  group('core-hunt-20260906 drain starvation guard (BUG-49)', () {
    test('a zero or negative resource limit is rejected at construction', () {
      expect(
        () => BackgroundJobQueue(resourceLimits: const {JobResource.cpu: 0}),
        throwsA(isA<ArgumentError>()),
        reason: 'BUG-49: limit 0 makes drain spin at Duration.zero forever',
      );
      expect(
        () => BackgroundJobQueue(resourceLimits: const {JobResource.disk: -2}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('legitimate resource contention still drains to completion', () async {
      var runs = 0;
      final queue = BackgroundJobQueue(
        resourceLimits: const {JobResource.cpu: 1},
      );
      for (final id in ['a', 'b']) {
        queue.enqueue(
          _Task(
            _job(id, BackgroundJobPriority.normal),
            onExecute: (_) async => runs++,
            resources: const {JobResource.cpu},
          ),
        );
      }
      await queue.drain().timeout(const Duration(seconds: 5));
      expect(runs, 2);
    });
  });

  group('core-hunt-20260906 dependency graph (BUG-53)', () {
    test('failed and cancelled dependencies count as done', () {
      final graph = JobDependencyGraph([
        const JobDependency(jobId: 'dependent', dependsOnId: 'failed-dep'),
        const JobDependency(jobId: 'dependent', dependsOnId: 'cancelled-dep'),
      ]);
      expect(
        graph.isReady('dependent', const {
          'failed-dep': 'failed',
          'cancelled-dep': 'cancelled',
        }),
        isTrue,
        reason:
            'BUG-53: failed/cancelled deps left the dependent pending forever',
      );
    });

    test('unknown dependency status still blocks (sibling contract)', () {
      final graph = JobDependencyGraph([
        const JobDependency(jobId: 'dependent', dependsOnId: 'untracked'),
      ]);
      expect(graph.isReady('dependent', const {}), isFalse);
    });

    test('pending/running dependencies still block the dependent', () {
      final graph = JobDependencyGraph([
        const JobDependency(jobId: 'dependent', dependsOnId: 'slow'),
      ]);
      expect(graph.isReady('dependent', const {'slow': 'running'}), isFalse);
      expect(graph.isReady('dependent', const {'slow': 'queued'}), isFalse);
      expect(graph.isReady('dependent', const {'slow': 'completed'}), isTrue);
    });

    test('a dependency cycle breaks the deadlock instead of stalling', () {
      final graph = JobDependencyGraph([
        const JobDependency(jobId: 'a', dependsOnId: 'b'),
        const JobDependency(jobId: 'b', dependsOnId: 'a'),
      ]);
      expect(
        graph.isReady('a', const {'a': 'queued', 'b': 'queued'}),
        isTrue,
        reason: 'BUG-53: cycles were undetected — both members stalled forever',
      );
      expect(graph.isReady('b', const {'a': 'queued', 'b': 'queued'}), isTrue);
    });

    test('a non-cyclic chain through a live dependency still blocks', () {
      final graph = JobDependencyGraph([
        const JobDependency(jobId: 'top', dependsOnId: 'mid'),
        const JobDependency(jobId: 'mid', dependsOnId: 'base'),
      ]);
      expect(
        graph.isReady('top', const {'mid': 'running', 'base': 'completed'}),
        isFalse,
      );
    });
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
