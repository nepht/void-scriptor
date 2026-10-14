/// Local, fail-closed rate-limit and resilience contracts for roadmap step
/// 119.10.
///
/// This file defines retry-after parsing, bounded exponential backoff with
/// jitter, a circuit breaker, idempotency-key validation, a concurrency
/// limiter, and provider health reporting. It does not perform network I/O,
/// open a socket, schedule real retries against a live provider, or claim
/// external resilience evidence.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

/// Parses an HTTP `Retry-After` value into a bounded delay, or `null` when the
/// value cannot be trusted.
abstract final class RetryAfter {
  static Duration? parse(String value, {required DateTime now}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final seconds = int.tryParse(trimmed);
    if (seconds != null) {
      if (seconds < 0) return null;
      return Duration(seconds: seconds);
    }

    try {
      final date = HttpDate.parse(trimmed).toUtc();
      final delta = date.difference(now.toUtc());
      if (delta.isNegative) return Duration.zero;
      return delta;
    } on Object {
      return null;
    }
  }
}

/// Bounded exponential backoff with a configurable jitter fraction.
final class BackoffPolicy {
  const BackoffPolicy({
    this.base = const Duration(milliseconds: 200),
    this.maximum = const Duration(seconds: 30),
    this.jitterRatio = 0.0,
  }) : assert(jitterRatio >= 0 && jitterRatio <= 1, 'jitterRatio in 0..1');

  final Duration base;
  final Duration maximum;
  final double jitterRatio;

  /// Delay for a zero-based [attempt]. [jitter] must be in `0..1`; `0` is the
  /// deterministic base delay and `1` adds the full jitter fraction.
  Duration delayFor(int attempt, {double jitter = 0}) {
    final exponent = attempt < 0 ? 0 : attempt;
    final capped = _minDuration(
      Duration(microseconds: base.inMicroseconds * (1 << exponent)),
      maximum,
    );
    final boundedJitter = jitter.clamp(0.0, 1.0);
    final factor = 1 + jitterRatio * boundedJitter;
    return Duration(microseconds: (capped.inMicroseconds * factor).round());
  }

  static Duration _minDuration(Duration a, Duration b) => a <= b ? a : b;
}

enum CircuitState { closed, open }

/// Minimal fail-closed circuit breaker: it only changes state through explicit
/// transitions and denies requests while open.
final class CircuitBreaker {
  CircuitBreaker({required this.failureThreshold})
    : assert(failureThreshold > 0, 'failureThreshold > 0');

  final int failureThreshold;
  CircuitState _state = CircuitState.closed;
  int _failures = 0;

  CircuitState get state => _state;

  bool allowRequest() => _state == CircuitState.closed;

  void recordFailure() {
    _failures += 1;
    if (_failures >= failureThreshold) {
      _state = CircuitState.open;
    }
  }

  void reset() {
    _failures = 0;
    _state = CircuitState.closed;
  }
}

/// Validates stable idempotency keys and rejects secret-shaped values.
abstract final class IdempotencyKey {
  static final RegExp _pattern = RegExp(r'^[A-Za-z0-9._-]{8,128}$');

  static bool isValid(String value) {
    if (!_pattern.hasMatch(value)) return false;
    final lowered = value.toLowerCase();
    if (lowered.contains('token') ||
        lowered.contains('secret') ||
        lowered.contains('password') ||
        lowered.contains('credref')) {
      return false;
    }
    return true;
  }
}

/// A released concurrency permit.
final class ConcurrencyPermit {
  ConcurrencyPermit._(this._limiter);

  final ConcurrencyLimiter _limiter;
  bool _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _limiter._release();
  }
}

/// Bounds in-flight work to [maxConcurrent] permits, releasing waiters in
/// arrival order.
final class ConcurrencyLimiter {
  ConcurrencyLimiter(this.maxConcurrent)
    : assert(maxConcurrent > 0, 'maxConcurrent > 0');

  final int maxConcurrent;
  final Queue<Completer<ConcurrencyPermit>> _waiters =
      Queue<Completer<ConcurrencyPermit>>();
  int _active = 0;

  int get activeCount => _active;

  Future<ConcurrencyPermit> acquire() {
    final permit = ConcurrencyPermit._(this);
    if (_active < maxConcurrent) {
      _active += 1;
      return Future<ConcurrencyPermit>.value(permit);
    }
    final completer = Completer<ConcurrencyPermit>();
    _waiters.add(completer);
    return completer.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      final next = _waiters.removeFirst();
      next.complete(ConcurrencyPermit._(this));
      return;
    }
    if (_active > 0) _active -= 1;
  }
}

enum ProviderHealthStatus { unknown, available, degraded, unavailable }

/// Provider health observation. Absence of evidence is never reported as
/// healthy: only [ProviderHealthStatus.available] is considered available.
final class ProviderHealth {
  const ProviderHealth({
    required this.status,
    required this.observedAt,
    required this.detail,
  });

  final ProviderHealthStatus status;
  final DateTime? observedAt;
  final String detail;

  bool get isAvailable => status == ProviderHealthStatus.available;

  Map<String, Object?> toJson() => <String, Object?>{
    'status': status.name,
    'observed_at': observedAt?.toUtc().toIso8601String(),
    'detail': detail,
  };
}

/// Manifest validation for the 119.10 contract.
abstract final class RateLimitResilienceContract {
  static const String canonicalStep = '119.10';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_rate_limit_resilience.json';
  static const List<String> requiredAcceptance = <String>[
    'retry_after',
    'backoff',
    'jitter',
    'circuit_breaker',
    'idempotency',
    'concurrency',
    'health',
  ];

  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];
    if (manifest['canonical_step'] != canonicalStep) {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }
    final acceptance = manifest['acceptance'];
    if (acceptance is! Map<String, dynamic>) {
      return <String>['acceptance_missing'];
    }
    for (final name in requiredAcceptance) {
      if (!acceptance.containsKey(name)) {
        diagnostics.add('acceptance_missing:$name');
      }
    }
    return diagnostics;
  }

  static List<String> validateCanonicalManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) return <String>['manifest_missing'];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic>
          ? validateManifest(decoded)
          : <String>['manifest_root_invalid'];
    } on Object {
      return <String>['manifest_unreadable'];
    }
  }
}
