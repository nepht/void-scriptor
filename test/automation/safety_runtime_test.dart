import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/safety_runtime.dart';

/// Sprint 104 / 104.21-104.29 — safety runtime contracts.
void main() {
  final t0 = DateTime.utc(2026, 8, 25, 10, 0);

  group('104.21 approval gates', () {
    test('all five canonical gate types exist', () {
      expect(ApprovalGateType.values.length, 5);
      expect(
        ApprovalGateType.values.map((t) => t.name).toSet(),
        containsAll(['reauthentication', 'approveExternalTransfer']),
      );
    });
  });

  group('104.22 human-in-the-loop', () {
    test(
      'pausing without a checkpoint is refused (checkpoint_before_wait)',
      () {
        final runtime = HumanDecisionRuntime();
        expect(
          () => runtime.waitForHuman(
            requestId: 'h-1',
            gate: const ApprovalGate(
              gateId: 'g-1',
              type: ApprovalGateType.confirmation,
            ),
            checkpointPersisted: false,
            now: t0,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('decision is audited; expired requests deny by default', () {
      final runtime = HumanDecisionRuntime();
      final request = runtime.waitForHuman(
        requestId: 'h-2',
        gate: const ApprovalGate(
          gateId: 'g-1',
          type: ApprovalGateType.confirmation,
        ),
        checkpointPersisted: true,
        now: t0,
        timeout: const Duration(hours: 1),
      );
      expect(
        runtime.decide(
          request: request,
          decision: HumanDecision.approved,
          now: t0.add(const Duration(minutes: 30)),
        ),
        isTrue,
      );
      expect(runtime.audit.single, 'human:h-2:approved');

      final expired = runtime.waitForHuman(
        requestId: 'h-3',
        gate: const ApprovalGate(
          gateId: 'g-2',
          type: ApprovalGateType.reviewOutput,
        ),
        checkpointPersisted: true,
        now: t0,
        timeout: const Duration(hours: 1),
      );
      expect(
        runtime.decide(
          request: expired,
          decision: HumanDecision.approved,
          now: t0.add(const Duration(hours: 2)),
        ),
        isFalse,
      );
      expect(runtime.resolveTimeout(expired), isFalse);
      expect(runtime.audit.last, 'timeout:h-3:denied');
    });
  });

  group('104.23 rate limiting', () {
    test('fixed window across canonical scopes', () {
      final limiter = RateLimiter();
      for (var i = 0; i < 3; i++) {
        limiter.assertWithin(
          scope: RateScope.provider,
          subject: 'openai',
          maxPerWindow: 3,
          window: const Duration(minutes: 1),
          now: t0.add(Duration(seconds: i)),
        );
      }
      expect(
        () => limiter.assertWithin(
          scope: RateScope.provider,
          subject: 'openai',
          maxPerWindow: 3,
          window: const Duration(minutes: 1),
          now: t0.add(const Duration(seconds: 5)),
        ),
        throwsA(isA<RateLimitExceeded>()),
      );
      // A new window admits again.
      limiter.assertWithin(
        scope: RateScope.provider,
        subject: 'openai',
        maxPerWindow: 3,
        window: const Duration(minutes: 1),
        now: t0.add(const Duration(minutes: 2)),
      );
    });
  });

  group('104.24 concurrency control', () {
    test('project lock allows only one active run per project', () {
      final controller = ConcurrencyController(maxConcurrentRuns: 4);
      controller.acquire(projectId: 'p-1');
      expect(
        () => controller.acquire(projectId: 'p-1'),
        throwsA(isA<ConcurrencyDenied>()),
      );
      controller.release(projectId: 'p-1');
      controller.acquire(projectId: 'p-1');
    });

    test('global budget enforced across projects', () {
      final controller = ConcurrencyController(maxConcurrentRuns: 2);
      controller.acquire(projectId: 'p-1');
      controller.acquire(projectId: 'p-2');
      expect(
        () => controller.acquire(projectId: 'p-3'),
        throwsA(isA<ConcurrencyDenied>()),
      );
      controller.release(projectId: 'p-1');
      controller.acquire(projectId: 'p-3');
    });
  });

  group('104.25 idempotency', () {
    test('a retried key never re-runs the side effect', () async {
      var executions = 0;
      final store = IdempotencyStore();
      Future<String> action() async {
        executions++;
        return 'done';
      }

      await store.execute('export:p-1:v1', action, now: t0);
      expect(
        () => store.execute('export:p-1:v1', action, now: t0),
        throwsA(isA<StateError>()),
        reason: 'duplicate key must be visible, not silently re-run',
      );
      expect(store.hasEffect('export:p-1:v1'), isTrue);
      expect(executions, 1);
    });
  });

  group('104.26 duplicate suppression', () {
    test('same key inside the window is suppressed with the raw event id', () {
      final suppressor = DuplicateTriggerSuppressor(
        window: const Duration(minutes: 5),
      );
      final first = suppressor.submit(
        dedupeKey: 'job.completed:j-9',
        sourceEventId: 'evt-a',
        now: t0,
      );
      final duplicate = suppressor.submit(
        dedupeKey: 'job.completed:j-9',
        sourceEventId: 'evt-b',
        now: t0.add(const Duration(minutes: 2)),
      );
      expect(first.decision, SuppressionDecision.allowed);
      expect(duplicate.decision, SuppressionDecision.suppressed);
      expect(duplicate.sourceEventId, 'evt-b');
      // After the window the same logical event is admitted again.
      final later = suppressor.submit(
        dedupeKey: 'job.completed:j-9',
        sourceEventId: 'evt-c',
        now: t0.add(const Duration(minutes: 6)),
      );
      expect(later.decision, SuppressionDecision.allowed);
    });
  });

  group('104.27/104.28 saga + compensation', () {
    test('commits are recorded and compensations run in reverse', () async {
      final saga = WorkflowSaga();
      final order = <String>[];
      saga.registerCompensation('step-a', () async => order.add('undo-a'));
      saga.registerCompensation('step-b', () async => order.add('undo-b'));
      saga.commitStep('step-a', now: t0);
      saga.commitStep('step-b', now: t0.add(const Duration(seconds: 5)));

      await saga.compensateAll(now: t0.add(const Duration(seconds: 6)));
      expect(order, ['undo-b', 'undo-a'], reason: 'reverse commit order');
      expect(saga.commits.every((c) => c.compensated), isTrue);
      expect(saga.compensationAudit.first, startsWith('compensated:step-b'));
    });

    test('missing compensators are VISIBLE, never silent', () async {
      final saga = WorkflowSaga();
      saga.registerCompensation('has-undo', () async {});
      saga.commitStep('no-undo', now: t0);
      saga.commitStep('has-undo', now: t0);

      await expectLater(
        saga.compensateAll(now: t0),
        throwsA(isA<CompensationUnsupported>()),
      );
    });

    test('failed compensations are audited loudly', () async {
      final saga = WorkflowSaga();
      saga.registerCompensation('boom', () async => throw StateError('x'));
      saga.commitStep('boom', now: t0);

      await expectLater(
        saga.compensateAll(now: t0),
        throwsA(isA<StateError>()),
      );
      expect(saga.compensationAudit, contains('compensation_failed:boom'));
    });
  });

  group('104.29 observability', () {
    test('canonical signals aggregate without leaking content', () {
      final metrics = AutomationMetrics();
      metrics.recordTrigger();
      metrics.recordTrigger();
      metrics.recordRunStart();
      metrics.recordRunStart();
      metrics.recordRunSuccess(const Duration(milliseconds: 120));
      metrics.recordRunFailure(const Duration(milliseconds: 80));
      metrics.recordApprovalWait();
      metrics.recordRetry();
      metrics.recordResourceUsage(7);

      final snapshot = metrics.snapshot();
      expect(snapshot['trigger_count'], 2);
      expect(snapshot['run_count'], 2);
      expect((snapshot['success_rate'] as double).toStringAsFixed(1), '0.5');
      expect(snapshot['avg_duration_ms'], 100);
      expect(snapshot['approval_wait'], 1);
      expect(snapshot['retry_count'], 1);
      expect(snapshot['resource_usage'], 7);
      expect(
        snapshot.values.any((v) => v.toString().contains('secret')),
        isFalse,
      );
    });
  });
}
