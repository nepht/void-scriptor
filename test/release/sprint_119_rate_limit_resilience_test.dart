import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_rate_limit_resilience.dart';

void main() {
  group('119.10 Rate Limit & Resilience Contract', () {
    test(
      'parses retry-after seconds and HTTP-date without inventing values',
      () {
        final now = DateTime.utc(2026, 10, 14, 12);
        expect(RetryAfter.parse('3', now: now), const Duration(seconds: 3));
        expect(
          RetryAfter.parse('Wed, 14 Oct 2026 12:00:05 GMT', now: now),
          const Duration(seconds: 5),
        );
        expect(RetryAfter.parse('unknown', now: now), isNull);
        expect(RetryAfter.parse('-1', now: now), isNull);
      },
    );

    test(
      'calculates bounded exponential backoff with deterministic jitter',
      () {
        const policy = BackoffPolicy(
          base: Duration(milliseconds: 100),
          maximum: Duration(seconds: 2),
          jitterRatio: 0.25,
        );
        expect(
          policy.delayFor(0, jitter: 0),
          const Duration(milliseconds: 100),
        );
        expect(
          policy.delayFor(3, jitter: 0),
          const Duration(milliseconds: 800),
        );
        expect(policy.delayFor(8, jitter: 0), const Duration(seconds: 2));
        expect(
          policy.delayFor(0, jitter: 1),
          const Duration(milliseconds: 125),
        );
      },
    );

    test('opens and closes the circuit only through explicit transitions', () {
      final circuit = CircuitBreaker(failureThreshold: 2);
      expect(circuit.state, CircuitState.closed);
      circuit.recordFailure();
      expect(circuit.state, CircuitState.closed);
      circuit.recordFailure();
      expect(circuit.state, CircuitState.open);
      expect(circuit.allowRequest(), isFalse);
      circuit.reset();
      expect(circuit.state, CircuitState.closed);
      expect(circuit.allowRequest(), isTrue);
    });

    test(
      'accepts stable idempotency keys and rejects secret-shaped values',
      () {
        expect(IdempotencyKey.isValid('idem_01ABC-xyz'), isTrue);
        expect(IdempotencyKey.isValid('token=secret'), isFalse);
        expect(IdempotencyKey.isValid(''), isFalse);
      },
    );

    test('limits concurrent permits and releases them safely', () async {
      final limiter = ConcurrencyLimiter(1);
      final first = await limiter.acquire();
      var secondAcquired = false;
      final second = limiter.acquire().then((permit) {
        secondAcquired = true;
        return permit;
      });
      await Future<void>.delayed(Duration.zero);
      expect(secondAcquired, isFalse);
      first.release();
      (await second).release();
      expect(secondAcquired, isTrue);
    });

    test('reports provider health without treating unknown as healthy', () {
      const health = ProviderHealth(
        status: ProviderHealthStatus.unknown,
        observedAt: null,
        detail: 'no local observation',
      );
      expect(health.isAvailable, isFalse);
      expect(health.toJson()['status'], 'unknown');
    });

    test('validates the canonical manifest and rejects missing acceptance', () {
      expect(RateLimitResilienceContract.validateCanonicalManifest(), isEmpty);
      final missing = <String, dynamic>{
        'canonical_step': '119.10',
        'unknown_field_policy': 'REJECT',
        'acceptance': <String, dynamic>{},
      };
      expect(
        RateLimitResilienceContract.validateManifest(missing),
        containsAll(<String>[
          'acceptance_missing:retry_after',
          'acceptance_missing:health',
        ]),
      );
    });
  });
}
