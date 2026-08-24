import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/workflow/workflow_policies.dart';

/// Sprint 103 / 103.17-103.19 — retry, timeout, and failure policies.
void main() {
  group('RetryPolicy (103.17)', () {
    test('defaults are bounded and audited', () {
      const p = WorkflowRetryPolicy();
      expect(p.maxAttempts, greaterThanOrEqualTo(1));
      expect(p.maxAttempts, lessThanOrEqualTo(5));
      expect(p.backoff, isA<Duration>());
      expect(p.retryableErrors, isNotEmpty);
    });

    test('only retryable errors may retry; attempts are bounded', () {
      const p = WorkflowRetryPolicy(maxAttempts: 3);
      expect(p.shouldRetry(errorCode: 'transient.network', attempt: 1), isTrue);
      expect(
        p.shouldRetry(errorCode: 'transient.network', attempt: 3),
        isFalse,
      );
      expect(
        p.shouldRetry(errorCode: 'validation.invalid', attempt: 1),
        isFalse,
      );
    });

    test('idempotency requirement is explicit', () {
      const p = WorkflowRetryPolicy(idempotent: false);
      expect(
        p.shouldRetry(errorCode: 'transient.io', attempt: 1),
        isFalse,
        reason: 'non-idempotent steps must never auto-retry',
      );
    });
  });

  group('TimeoutPolicy (103.18)', () {
    test('per-step timeout is mandatory and positive', () {
      const p = WorkflowTimeoutPolicy(perStep: Duration(minutes: 10));
      expect(p.perStep, isA<Duration>());
      expect(p.perStep.inMilliseconds, greaterThan(0));
    });

    test('workflow-level timeout is optional', () {
      expect(
        const WorkflowTimeoutPolicy(
          perStep: Duration(minutes: 1),
        ).workflowTimeout,
        isNull,
      );
      expect(
        const WorkflowTimeoutPolicy(
          perStep: Duration(minutes: 1),
          workflowTimeout: Duration(hours: 2),
        ).workflowTimeout,
        equals(const Duration(hours: 2)),
      );
    });
  });

  group('FailurePolicy (103.19)', () {
    test('all five canonical policies exist by name', () {
      expect(
        WorkflowFailurePolicy.values.map((v) => v.name).toSet(),
        equals({
          'stop',
          'retry',
          'skipIfOptional',
          'rollbackSupportedChanges',
          'requireUserDecision',
        }),
      );
    });

    test('optional steps default to skip-if-optional semantics', () {
      expect(
        WorkflowFailurePolicy.forStep(optional: true),
        same(WorkflowFailurePolicy.skipIfOptional),
      );
      expect(
        WorkflowFailurePolicy.forStep(optional: false),
        same(WorkflowFailurePolicy.stop),
      );
    });
  });
}
