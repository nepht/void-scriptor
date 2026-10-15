/// Local, fail-closed async job and event contracts for roadmap step 119.11.
///
/// This file defines opaque job handles, normalized progress, gated
/// cancellation and resume, durable job state, strictly ordered event logs,
/// and idempotency-key deduplication. It does not start a background worker,
/// persist to a durable queue, or claim external durability, distributed
/// ordering, or provider-side job evidence.
library;

import 'dart:convert';
import 'dart:io';

/// Opaque, non-secret job handle.
///
/// Handles are references only: they never carry job payload, and diagnostics
/// never echo the raw value.
final class AsyncJobId {
  const AsyncJobId(this.value);

  static final RegExp _pattern = RegExp(
    r'^jobref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  final String value;

  /// Returns a handle for a well-formed `jobref:` value, otherwise `null`.
  static AsyncJobId? tryParse(String raw) =>
      _pattern.hasMatch(raw) ? AsyncJobId(raw) : null;

  @override
  String toString() => '[REDACTED]';
}

/// Normalized job progress in the closed `0..1` interval.
///
/// Out-of-range and non-finite input is clamped instead of trusted, so a
/// misreporting producer can never push progress outside the contract.
final class JobProgress {
  JobProgress(double fraction) : fraction = _normalize(fraction);

  static double _normalize(double value) {
    if (value.isNaN) return 0.0;
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
  }

  final double fraction;

  bool get isComplete => fraction >= 1.0;

  @override
  bool operator ==(Object other) =>
      other is JobProgress && other.fraction == fraction;

  @override
  int get hashCode => fraction.hashCode;

  @override
  String toString() => 'JobProgress(${fraction.toStringAsFixed(3)})';
}

/// Lifecycle state of a long-running job.
enum AsyncJobState { queued, running, paused, completed, cancelled, failed }

/// Durability rules for [AsyncJobState].
///
/// In-flight state is deliberately not durable: a restart must re-derive
/// running work rather than replay it as settled.
abstract final class DurableJobState {
  static const Set<AsyncJobState> durable = <AsyncJobState>{
    AsyncJobState.queued,
    AsyncJobState.paused,
    AsyncJobState.completed,
    AsyncJobState.cancelled,
    AsyncJobState.failed,
  };

  static bool isDurable(AsyncJobState state) => durable.contains(state);
}

/// Result of a gated job operation.
enum AsyncJobResult {
  deniedReauthentication,
  cancelled,
  resumed,
  unknownOperation,
}

/// Kind of event emitted by a long-running job.
enum AsyncJobEventKind {
  queued,
  progress,
  paused,
  resumed,
  cancelled,
  completed,
  failed,
}

/// A monotonic, deduplication-aware job event.
final class AsyncJobEvent {
  AsyncJobEvent({
    required this.kind,
    required this.sequence,
    required this.idempotencyKey,
    this.progress,
  }) : assert(sequence >= 0, 'sequence >= 0');

  final AsyncJobEventKind kind;

  /// Monotonic sequence number that establishes event ordering.
  final int sequence;

  /// Stable idempotency key used for duplicate prevention.
  final String idempotencyKey;

  /// Normalized progress in `0..1`, when the event reports progress.
  final double? progress;

  /// Serializes the event without echoing the idempotency key.
  String toRedactedJson() => jsonEncode(<String, Object?>{
    'kind': kind.name,
    'sequence': sequence,
    'idempotency_key': '[REDACTED]',
    'progress': progress,
  });
}

/// A single long-running job with durable state, normalized progress, and a
/// strictly ordered, deduplicated event log.
final class AsyncJob {
  AsyncJob({required this.id}) : _state = AsyncJobState.queued;

  final AsyncJobId id;

  AsyncJobState _state;
  JobProgress _progress = JobProgress(0);
  final List<AsyncJobEvent> _events = <AsyncJobEvent>[];
  final Set<String> _idempotencyKeys = <String>{};
  int _lastSequence = -1;

  AsyncJobState get state => _state;
  JobProgress get progress => _progress;
  List<AsyncJobEvent> get events => List<AsyncJobEvent>.unmodifiable(_events);

  /// Records [event], rejecting duplicates and stale sequences.
  ///
  /// Returns `false` instead of applying a duplicate idempotency key or a
  /// non-increasing sequence, so a retrying producer fails closed rather than
  /// corrupting progress.
  bool record(AsyncJobEvent event) {
    if (_idempotencyKeys.contains(event.idempotencyKey)) return false;
    if (event.sequence <= _lastSequence) return false;
    _idempotencyKeys.add(event.idempotencyKey);
    _lastSequence = event.sequence;
    _events.add(event);
    final reported = event.progress;
    if (reported != null) _progress = JobProgress(reported);
    return true;
  }

  /// Cancels the job, denied unless reauthentication is explicitly present.
  AsyncJobResult cancel({required bool reauthenticated}) {
    if (!reauthenticated) return AsyncJobResult.deniedReauthentication;
    _state = AsyncJobState.cancelled;
    return AsyncJobResult.cancelled;
  }

  /// Resumes the job, denied unless reauthentication is explicitly present.
  AsyncJobResult resume({required bool reauthenticated}) {
    if (!reauthenticated) return AsyncJobResult.deniedReauthentication;
    _state = AsyncJobState.running;
    return AsyncJobResult.resumed;
  }

  /// Durable snapshot for restart and replay. Carries no plaintext payload.
  Map<String, Object?> toDurableSnapshot() => <String, Object?>{
    'job_id': '[REDACTED]',
    'state': _state.name,
    'durable': DurableJobState.isDurable(_state),
    'progress': _progress.fraction,
    'last_sequence': _lastSequence,
    'event_count': _events.length,
  };
}

/// Manifest validation for the 119.11 contract.
abstract final class AsyncJobEventContract {
  static const String canonicalStep = '119.11';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_async_job_event_contract.json';
  static const List<String> requiredAcceptance = <String>[
    'job_id',
    'progress',
    'cancel',
    'resume',
    'durable_state',
    'event_order',
    'deduplication',
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
