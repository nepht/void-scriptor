import 'dart:convert';
import 'dart:io';

enum Sprint116ResilienceStatus { pass, fail, blocked }

/// One recorded attempt inside a retry loop.
///
/// [theoreticalDelayMs] is the delay the policy asks for before attempt
/// [attemptIndex]; [actualDelayMs] is what the loop really waited. Comparing
/// the two is what makes jitter verifiable instead of merely declared.
class Sprint116RetryAttempt {
  const Sprint116RetryAttempt({
    required this.attemptIndex,
    required this.errorState,
    required this.theoreticalDelayMs,
    required this.actualDelayMs,
    required this.delaySource,
    this.providerRetryAfterSeconds,
    this.idempotencyKey = '',
  });

  final int attemptIndex;
  final String errorState;
  final int theoreticalDelayMs;
  final int actualDelayMs;
  final String delaySource;
  final int? providerRetryAfterSeconds;
  final String idempotencyKey;
}

/// Circuit-breaker snapshot for one provider operation.
class Sprint116CircuitRecord {
  const Sprint116CircuitRecord({
    required this.breakerId,
    required this.state,
    required this.consecutiveFailures,
    required this.failureThreshold,
    required this.openDurationMs,
    required this.openedAtEpochMs,
  });

  final String breakerId;
  final String state;
  final int consecutiveFailures;
  final int failureThreshold;
  final int openDurationMs;
  final int openedAtEpochMs;
}

/// A provider-aware retry policy plus the attempts it actually produced.
class Sprint116RetryPolicy {
  const Sprint116RetryPolicy({
    required this.policyId,
    required this.providerId,
    required this.operationId,
    required this.idempotent,
    required this.maxAttempts,
    required this.baseDelayMs,
    required this.maxDelayMs,
    required this.jitterRatio,
    required this.cancellationSupported,
    required this.attempts,
    required this.source,
    this.idempotencyKey = '',
    this.cancelledAtAttemptIndex,
    this.breaker,
    this.evidenceRef,
  });

  final String policyId;
  final String providerId;
  final String operationId;
  final bool idempotent;
  final String idempotencyKey;
  final int maxAttempts;
  final int baseDelayMs;
  final int maxDelayMs;
  final double jitterRatio;
  final bool cancellationSupported;
  final int? cancelledAtAttemptIndex;
  final List<Sprint116RetryAttempt> attempts;
  final Sprint116CircuitRecord? breaker;
  final String source;
  final String? evidenceRef;
}

class Sprint116ResilienceReport {
  Sprint116ResilienceReport({
    required this.state,
    required this.invalidRecords,
    required this.policies,
    required this.coveredAreas,
  });

  final Sprint116ResilienceStatus state;
  final List<String> invalidRecords;
  final List<Sprint116RetryPolicy> policies;
  final List<String> coveredAreas;

  String get externalGates => Sprint116ResilienceContract.externalGates;
}

abstract final class Sprint116ResilienceContract {
  static const String canonicalStep = '116.43';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The seven acceptance areas of step 116.43.
  static const List<String> requiredAreas = <String>[
    'idempotency',
    'bounded_retry',
    'exponential_backoff',
    'jitter',
    'retry_after',
    'cancellation',
    'circuit_breaker',
  ];

  /// Where a retry delay came from. `retry_after` is the provider's own
  /// instruction and outranks anything we compute locally.
  static const List<String> delaySources = <String>[
    'none',
    'exponential_backoff',
    'retry_after',
  ];

  static const List<String> breakerStates = <String>[
    'closed',
    'open',
    'half_open',
  ];

  static const List<String> supportedSources = <String>[
    'synthetic_local',
    'live',
  ];

  /// An unbounded retry loop is a denial-of-service amplifier, not resilience.
  static const int maxAllowedAttempts = 10;

  /// Delay the policy asks for before the given attempt, doubling each time
  /// and clamped to [maxDelayMs] so growth is provably finite.
  static int theoreticalDelayMs({
    required int baseDelayMs,
    required int maxDelayMs,
    required int attemptIndex,
  }) {
    if (attemptIndex <= 0) return 0;
    var delay = baseDelayMs;
    for (var step = 1; step < attemptIndex; step++) {
      if (delay >= maxDelayMs) return maxDelayMs;
      delay *= 2;
    }
    return delay > maxDelayMs ? maxDelayMs : delay;
  }
}

class Sprint116ResilienceCertification {
  /// Certifies retry policies against the seven-area resilience contract.
  ///
  /// Manifest fixtures are consulted only when [policies] is omitted, so an
  /// explicit policy set can never borrow fixture data to pass.
  Sprint116ResilienceReport certify({
    List<Sprint116RetryPolicy>? policies,
    bool requireCoverage = false,
  }) {
    final effective = policies ?? _readManifestPolicies();

    if (effective.isEmpty) {
      return Sprint116ResilienceReport(
        state: Sprint116ResilienceStatus.blocked,
        invalidRecords: const <String>['policies'],
        policies: const <Sprint116RetryPolicy>[],
        coveredAreas: const <String>[],
      );
    }

    final invalid = <String>[];
    final covered = <String>[];

    for (var index = 0; index < effective.length; index++) {
      final policy = effective[index];
      final id = policy.policyId.trim();

      if (id.isEmpty) {
        // Without an identity the record cannot be attributed, so it is
        // rejected on identity alone rather than by guessing a key.
        invalid.add('policy_id:$index');
        continue;
      }

      // Areas this policy fails, so one defect yields one marker per area
      // instead of one marker per offending attempt.
      final failed = <String>{};
      // Areas this policy supplies positive evidence for.
      final evidence = <String>{};

      if (policy.providerId.trim().isEmpty ||
          policy.operationId.trim().isEmpty) {
        failed.add('provider_aware');
      }

      // A retried write without a stable key can apply the same side effect
      // twice, so a non-idempotent operation is not certifiable without one.
      if (policy.idempotencyKey.trim().isEmpty) {
        failed.add('idempotency');
      } else {
        evidence.add('idempotency');
      }

      if (_certifyBoundedRetry(policy)) {
        evidence.add('bounded_retry');
      } else {
        failed.add('bounded_retry');
      }

      if (!policy.cancellationSupported) {
        failed.add('cancellation');
      } else if (policy.cancelledAtAttemptIndex != null) {
        evidence.add('cancellation');
      }

      _certifyBreaker(policy, failed, evidence);

      for (final attempt in policy.attempts) {
        _certifyAttempt(policy, attempt, failed, evidence);
      }

      final source = policy.source.trim();
      final evidenceRef = policy.evidenceRef?.trim();
      if (!Sprint116ResilienceContract.supportedSources.contains(source) ||
          (source == 'live' && (evidenceRef == null || evidenceRef.isEmpty))) {
        failed.add('no_mock_values');
      }

      for (final area in failed) {
        invalid.add('$area:$id');
      }
      for (final area in evidence) {
        if (!covered.contains(area)) covered.add(area);
      }
    }

    if (requireCoverage) {
      for (final area in Sprint116ResilienceContract.requiredAreas) {
        if (!covered.contains(area)) {
          invalid.add('area_coverage:$area');
        }
      }
    }

    return Sprint116ResilienceReport(
      state: invalid.isEmpty
          ? Sprint116ResilienceStatus.pass
          : Sprint116ResilienceStatus.fail,
      invalidRecords: invalid,
      policies: effective,
      coveredAreas: covered,
    );
  }

  bool _certifyBoundedRetry(Sprint116RetryPolicy policy) {
    final maxAttempts = policy.maxAttempts;
    // A retry loop with no ceiling is a denial-of-service amplifier aimed at
    // the provider, not resilience.
    if (maxAttempts < 1 ||
        maxAttempts > Sprint116ResilienceContract.maxAllowedAttempts) {
      return false;
    }
    if (policy.baseDelayMs <= 0) return false;
    // A ceiling below the base delay would deny the very first retry.
    if (policy.maxDelayMs < policy.baseDelayMs) return false;
    if (policy.attempts.length > maxAttempts) return false;
    return true;
  }

  void _certifyBreaker(
    Sprint116RetryPolicy policy,
    Set<String> failed,
    Set<String> evidence,
  ) {
    final breaker = policy.breaker;
    if (breaker == null) {
      failed.add('circuit_breaker');
      return;
    }

    final state = breaker.state.trim();
    if (!Sprint116ResilienceContract.breakerStates.contains(state)) {
      failed.add('circuit_breaker');
      return;
    }
    if (breaker.failureThreshold <= 0 || breaker.openDurationMs <= 0) {
      failed.add('circuit_breaker');
      return;
    }
    // A closed circuit that has already reached its failure threshold is a
    // snapshot the breaker should have opened on.
    if (state == 'closed' &&
        breaker.consecutiveFailures >= breaker.failureThreshold) {
      failed.add('circuit_breaker');
      return;
    }
    // While the circuit is open the connector must fail fast rather than spend
    // the very quota that opened it.
    if (state == 'open' &&
        policy.attempts.any((attempt) => attempt.attemptIndex > 0)) {
      failed.add('circuit_breaker');
      return;
    }

    evidence.add('circuit_breaker');
  }

  void _certifyAttempt(
    Sprint116RetryPolicy policy,
    Sprint116RetryAttempt attempt,
    Set<String> failed,
    Set<String> evidence,
  ) {
    // An operation that declares itself idempotent must prove it per attempt;
    // otherwise a retried write is indistinguishable from a double submit.
    if (policy.idempotent &&
        attempt.attemptIndex > 0 &&
        attempt.idempotencyKey.trim().isEmpty) {
      failed.add('idempotency');
    }

    if (attempt.attemptIndex <= 0) return;

    final cancelledAt = policy.cancelledAtAttemptIndex;
    if (cancelledAt != null && attempt.attemptIndex > cancelledAt) {
      failed.add('cancellation');
      return;
    }

    final source = attempt.delaySource.trim();
    if (!Sprint116ResilienceContract.delaySources.contains(source)) {
      failed.add('exponential_backoff');
      return;
    }

    // Cancellation and the first attempt legitimately wait for nothing.
    if (source == 'none') {
      if (attempt.actualDelayMs != 0) failed.add('exponential_backoff');
      return;
    }

    // The provider's own retry_after always wins: backing off on our local
    // schedule would keep hitting a limit that is still in force.
    if (attempt.errorState.trim() == 'rate_limited' ||
        source == 'retry_after') {
      if (_certifyRetryAfter(attempt, source)) {
        evidence.add('retry_after');
      } else {
        failed.add('retry_after');
      }
      return;
    }

    // The recorded delay must be the one the policy actually prescribes,
    // otherwise backoff growth is unverifiable.
    final expected = Sprint116ResilienceContract.theoreticalDelayMs(
      baseDelayMs: policy.baseDelayMs,
      maxDelayMs: policy.maxDelayMs,
      attemptIndex: attempt.attemptIndex,
    );
    final theoretical = attempt.theoreticalDelayMs;
    final actual = attempt.actualDelayMs;
    if (theoretical <= 0 || actual <= 0 || theoretical != expected) {
      failed.add('exponential_backoff');
      return;
    }

    if (policy.jitterRatio <= 0 || policy.jitterRatio > 1) {
      failed.add('jitter');
      return;
    }

    final allowed = (expected * policy.jitterRatio).floor();
    final deviation = (actual - theoretical).abs();
    if (deviation == 0) {
      // A delay identical on every attempt synchronises every client into
      // the same retry instant, which is the opposite of jitter.
      failed.add('jitter');
      return;
    }
    if (deviation > allowed) {
      // Spread beyond the declared ratio is unbounded jitter, and a delay far
      // from the prescription is no longer the prescribed backoff.
      failed.add('jitter');
      failed.add('exponential_backoff');
      return;
    }

    evidence.add('exponential_backoff');
    evidence.add('jitter');
  }

  bool _certifyRetryAfter(Sprint116RetryAttempt attempt, String source) {
    final requested = attempt.providerRetryAfterSeconds;
    if (requested == null || requested <= 0) return false;
    // Honouring the provider means both naming the source and actually
    // waiting at least as long as the provider asked.
    if (source != 'retry_after') return false;
    return attempt.actualDelayMs >= requested * 1000;
  }

  Map<String, dynamic>? _readManifest() {
    final file = File(Sprint116ResilienceContract.manifestPath);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  List<Sprint116RetryPolicy> _readManifestPolicies() {
    final raw = _readManifest()?['policies'];
    if (raw is! List) return <Sprint116RetryPolicy>[];
    return raw
        .whereType<Map>()
        .map(
          (item) => Sprint116RetryPolicy(
            policyId: item['policy_id']?.toString() ?? '',
            providerId: item['provider_id']?.toString() ?? '',
            operationId: item['operation_id']?.toString() ?? '',
            idempotent: item['idempotent'] == true,
            idempotencyKey: item['idempotency_key']?.toString() ?? '',
            maxAttempts: (item['max_attempts'] as num?)?.toInt() ?? 0,
            baseDelayMs: (item['base_delay_ms'] as num?)?.toInt() ?? 0,
            maxDelayMs: (item['max_delay_ms'] as num?)?.toInt() ?? 0,
            jitterRatio: (item['jitter_ratio'] as num?)?.toDouble() ?? 0,
            cancellationSupported: item['cancellation_supported'] == true,
            cancelledAtAttemptIndex:
                (item['cancelled_at_attempt_index'] as num?)?.toInt(),
            attempts: _readManifestAttempts(item['attempts']),
            breaker: _readManifestBreaker(item['circuit_breaker']),
            source: item['source']?.toString() ?? '',
            evidenceRef: item['evidence_ref']?.toString(),
          ),
        )
        .toList(growable: false);
  }

  List<Sprint116RetryAttempt> _readManifestAttempts(Object? raw) {
    if (raw is! List) return const <Sprint116RetryAttempt>[];
    return raw
        .whereType<Map>()
        .map(
          (item) => Sprint116RetryAttempt(
            attemptIndex: (item['attempt_index'] as num?)?.toInt() ?? 0,
            errorState: item['error_state']?.toString() ?? '',
            theoreticalDelayMs:
                (item['theoretical_delay_ms'] as num?)?.toInt() ?? 0,
            actualDelayMs: (item['actual_delay_ms'] as num?)?.toInt() ?? 0,
            delaySource: item['delay_source']?.toString() ?? '',
            providerRetryAfterSeconds:
                (item['provider_retry_after_seconds'] as num?)?.toInt(),
            idempotencyKey: item['idempotency_key']?.toString() ?? '',
          ),
        )
        .toList(growable: false);
  }

  Sprint116CircuitRecord? _readManifestBreaker(Object? raw) {
    if (raw is! Map) return null;
    return Sprint116CircuitRecord(
      breakerId: raw['breaker_id']?.toString() ?? '',
      state: raw['state']?.toString() ?? '',
      consecutiveFailures: (raw['consecutive_failures'] as num?)?.toInt() ?? 0,
      failureThreshold: (raw['failure_threshold'] as num?)?.toInt() ?? 0,
      openDurationMs: (raw['open_duration_ms'] as num?)?.toInt() ?? 0,
      openedAtEpochMs: (raw['opened_at_epoch_ms'] as num?)?.toInt() ?? 0,
    );
  }
}
