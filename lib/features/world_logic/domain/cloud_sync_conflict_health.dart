/// Cloud sync and conflict health contract for Sprint 114.15.
///
/// Dependency-free model that checks sync completion, offline queue age,
/// transfer failures, retry recovery, conflict rate, conflict resolution,
/// and duplicate effects across the seven canonical signals: sync_success,
/// queue_age, transfer_failure, retry_success, conflict_rate,
/// resolution_success, and duplicate_effect. An absent observation set
/// stays BLOCKED without health claims. Live cloud sync telemetry over
/// production workspaces, real network fault injection, and public
/// distribution remain external gates and are not claimed here.
enum CloudSyncSignal {
  syncSuccess,
  queueAge,
  transferFailure,
  retrySuccess,
  conflictRate,
  resolutionSuccess,
  duplicateEffect,
}

enum CloudSyncOutcome { ok, failed, recovered }

enum CloudSyncConflictState { pass, fail, blocked }

class CloudSyncObservation {
  const CloudSyncObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final CloudSyncSignal signal;
  final CloudSyncOutcome outcome;
  final String note;
}

class CloudSyncConflictReport {
  const CloudSyncConflictReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final CloudSyncConflictState state;
  final List<CloudSyncObservation> observations;
  final List<CloudSyncSignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class CloudSyncConflictHealth {
  static const List<CloudSyncSignal> canonicalSignals = <CloudSyncSignal>[
    CloudSyncSignal.syncSuccess,
    CloudSyncSignal.queueAge,
    CloudSyncSignal.transferFailure,
    CloudSyncSignal.retrySuccess,
    CloudSyncSignal.conflictRate,
    CloudSyncSignal.resolutionSuccess,
    CloudSyncSignal.duplicateEffect,
  ];

  CloudSyncConflictReport evaluate(List<CloudSyncObservation>? observations) {
    if (observations == null || observations.isEmpty) {
      return const CloudSyncConflictReport(
        state: CloudSyncConflictState.blocked,
        observations: <CloudSyncObservation>[],
        coveredSignals: <CloudSyncSignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi cloud sync; tidak ada klaim kesehatan; live '
              'cloud sync telemetry DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <CloudSyncSignal>{
      for (final observation in observations) observation.signal,
    };
    final invalid = <String>[];
    if (covered.length != canonicalSignals.length ||
        !canonicalSignals.every(covered.contains)) {
      invalid.add('signals');
    }
    if (observations.any((o) => o.note.trim().isEmpty)) {
      invalid.add('notes');
    }

    bool hasOutcome(CloudSyncSignal signal, CloudSyncOutcome outcome) =>
        observations.any((o) => o.signal == signal && o.outcome == outcome);

    bool failed(CloudSyncSignal signal) =>
        hasOutcome(signal, CloudSyncOutcome.failed);

    final syncOk = hasOutcome(CloudSyncSignal.syncSuccess, CloudSyncOutcome.ok);
    final syncFailed = failed(CloudSyncSignal.syncSuccess);
    final transferFailed = failed(CloudSyncSignal.transferFailure);
    final retryOk = hasOutcome(
      CloudSyncSignal.retrySuccess,
      CloudSyncOutcome.ok,
    );
    final retryRecovered = hasOutcome(
      CloudSyncSignal.retrySuccess,
      CloudSyncOutcome.recovered,
    );
    final retryWorked = retryOk || retryRecovered;
    final conflictFailed = failed(CloudSyncSignal.conflictRate);
    final resolutionFailed = failed(CloudSyncSignal.resolutionSuccess);

    final violations = <String>[];
    if (syncOk && transferFailed) {
      violations.add('transfer_failure_ignored');
    }
    if (syncOk && failed(CloudSyncSignal.queueAge)) {
      violations.add('stale_queue_ignored');
    }
    if (syncOk && failed(CloudSyncSignal.duplicateEffect)) {
      violations.add('duplicate_effects_ignored');
    }
    if (transferFailed && !retryWorked) {
      violations.add('transfer_unrecovered');
    }
    if (syncFailed && !retryWorked) {
      violations.add('sync_unrecovered');
    }
    if (conflictFailed && resolutionFailed) {
      violations.add('conflict_unresolved');
    }

    return CloudSyncConflictReport(
      state: invalid.isEmpty && violations.isEmpty
          ? CloudSyncConflictState.pass
          : CloudSyncConflictState.fail,
      observations: List<CloudSyncObservation>.unmodifiable(observations),
      coveredSignals: List<CloudSyncSignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Verifikasi kontrak lokal atas tujuh sinyal cloud sync; live cloud '
            'sync telemetry, injeksi fault jaringan nyata, dan publikasi '
            'distribusi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
