/// Install & update health contract for Sprint 114.9.
///
/// Dependency-free model that monitors the six canonical install/update
/// signals: install success, download failure, signature failure,
/// insufficient space, retry success, and update completion. An absent
/// observation set stays BLOCKED without health claims. Live installer
/// telemetry, CDN download behavior, certificate trust, and public
/// distribution remain external gates and are not claimed here.
enum InstallUpdateSignal {
  installSuccess,
  downloadFailure,
  signatureFailure,
  insufficientSpace,
  retrySuccess,
  updateCompletion,
}

enum InstallUpdateOutcome { ok, failed, recovered }

enum InstallUpdateHealthState { pass, fail, blocked }

class InstallUpdateObservation {
  const InstallUpdateObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final InstallUpdateSignal signal;
  final InstallUpdateOutcome outcome;
  final String note;
}

class InstallUpdateHealthReport {
  const InstallUpdateHealthReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final InstallUpdateHealthState state;
  final List<InstallUpdateObservation> observations;
  final List<InstallUpdateSignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class InstallUpdateHealth {
  static const List<InstallUpdateSignal> canonicalSignals =
      <InstallUpdateSignal>[
        InstallUpdateSignal.installSuccess,
        InstallUpdateSignal.downloadFailure,
        InstallUpdateSignal.signatureFailure,
        InstallUpdateSignal.insufficientSpace,
        InstallUpdateSignal.retrySuccess,
        InstallUpdateSignal.updateCompletion,
      ];

  InstallUpdateHealthReport evaluate(
    List<InstallUpdateObservation>? observations,
  ) {
    if (observations == null || observations.isEmpty) {
      return const InstallUpdateHealthReport(
        state: InstallUpdateHealthState.blocked,
        observations: <InstallUpdateObservation>[],
        coveredSignals: <InstallUpdateSignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi install/update; tidak ada klaim kesehatan; '
              'live install/download telemetry DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <InstallUpdateSignal>{
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

    bool hasOutcome(InstallUpdateSignal signal, InstallUpdateOutcome outcome) =>
        observations.any((o) => o.signal == signal && o.outcome == outcome);

    final updateCompleted = hasOutcome(
      InstallUpdateSignal.updateCompletion,
      InstallUpdateOutcome.ok,
    );
    final violations = <String>[];
    if (updateCompleted &&
        hasOutcome(
          InstallUpdateSignal.signatureFailure,
          InstallUpdateOutcome.failed,
        )) {
      violations.add('signature_failure_ignored');
    }
    if (updateCompleted &&
        hasOutcome(
          InstallUpdateSignal.insufficientSpace,
          InstallUpdateOutcome.failed,
        )) {
      violations.add('space_check_ignored');
    }
    if (updateCompleted &&
        hasOutcome(
          InstallUpdateSignal.downloadFailure,
          InstallUpdateOutcome.failed,
        ) &&
        !hasOutcome(
          InstallUpdateSignal.retrySuccess,
          InstallUpdateOutcome.ok,
        )) {
      violations.add('download_failure_ignored');
    }

    return InstallUpdateHealthReport(
      state: invalid.isEmpty && violations.isEmpty
          ? InstallUpdateHealthState.pass
          : InstallUpdateHealthState.fail,
      observations: List<InstallUpdateObservation>.unmodifiable(observations),
      coveredSignals: List<InstallUpdateSignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Verifikasi kontrak lokal atas enam sinyal install/update; '
            'telemetry, kepercayaan sertifikat, dan distribusi publik '
            'DEFERRED-EXTERNAL.',
      ],
    );
  }
}
