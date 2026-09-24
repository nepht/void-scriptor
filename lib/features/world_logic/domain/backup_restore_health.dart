/// Backup & restore health contract for Sprint 114.14.
///
/// Dependency-free model that checks backup completion, encryption,
/// restore, media manifest integrity, cross-workspace link integrity,
/// and recovery time across the six canonical signals: backup_success,
/// encryption_success, restore_success, media_integrity,
/// link_integrity, and recovery_time. An absent observation set stays
/// BLOCKED without health claims. Live backup telemetry over
/// production workspaces, destructive fault tests on user data,
/// hardware verification, and public distribution remain external
/// gates and are not claimed here.
enum BackupRestoreSignal {
  backupSuccess,
  encryptionSuccess,
  restoreSuccess,
  mediaIntegrity,
  linkIntegrity,
  recoveryTime,
}

enum BackupRestoreOutcome { ok, failed, recovered }

enum BackupRestoreState { pass, fail, blocked }

class BackupRestoreObservation {
  const BackupRestoreObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final BackupRestoreSignal signal;
  final BackupRestoreOutcome outcome;
  final String note;
}

class BackupRestoreReport {
  const BackupRestoreReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final BackupRestoreState state;
  final List<BackupRestoreObservation> observations;
  final List<BackupRestoreSignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class BackupRestoreHealth {
  static const List<BackupRestoreSignal> canonicalSignals =
      <BackupRestoreSignal>[
        BackupRestoreSignal.backupSuccess,
        BackupRestoreSignal.encryptionSuccess,
        BackupRestoreSignal.restoreSuccess,
        BackupRestoreSignal.mediaIntegrity,
        BackupRestoreSignal.linkIntegrity,
        BackupRestoreSignal.recoveryTime,
      ];

  BackupRestoreReport evaluate(List<BackupRestoreObservation>? observations) {
    if (observations == null || observations.isEmpty) {
      return const BackupRestoreReport(
        state: BackupRestoreState.blocked,
        observations: <BackupRestoreObservation>[],
        coveredSignals: <BackupRestoreSignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi backup/restore; tidak ada klaim kesehatan; '
              'live backup telemetry DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <BackupRestoreSignal>{
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

    bool hasOutcome(BackupRestoreSignal signal, BackupRestoreOutcome outcome) =>
        observations.any((o) => o.signal == signal && o.outcome == outcome);

    bool failed(BackupRestoreSignal signal) =>
        hasOutcome(signal, BackupRestoreOutcome.failed);

    final backupFailed = failed(BackupRestoreSignal.backupSuccess);
    final restoreFailed = failed(BackupRestoreSignal.restoreSuccess);
    final recoveryTimeOk = hasOutcome(
      BackupRestoreSignal.recoveryTime,
      BackupRestoreOutcome.ok,
    );
    final violations = <String>[];
    if (!backupFailed && failed(BackupRestoreSignal.encryptionSuccess)) {
      violations.add('encryption_failure_ignored');
    }
    if (backupFailed && restoreFailed) {
      violations.add('backup_restore_unrecovered');
    }
    if (failed(BackupRestoreSignal.mediaIntegrity) && restoreFailed) {
      violations.add('media_unrecovered');
    }
    if (failed(BackupRestoreSignal.linkIntegrity) && restoreFailed) {
      violations.add('links_unrepaired');
    }
    if (recoveryTimeOk && restoreFailed) {
      violations.add('recovery_claim_without_restore');
    }
    if (restoreFailed && !recoveryTimeOk) {
      violations.add('restore_unrecovered');
    }

    return BackupRestoreReport(
      state: invalid.isEmpty && violations.isEmpty
          ? BackupRestoreState.pass
          : BackupRestoreState.fail,
      observations: List<BackupRestoreObservation>.unmodifiable(observations),
      coveredSignals: List<BackupRestoreSignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Verifikasi kontrak lokal atas enam sinyal backup/restore; live '
            'backup telemetry, fault test destruktif atas data pengguna, '
            'verifikasi perangkat keras, dan publikasi distribusi '
            'DEFERRED-EXTERNAL.',
      ],
    );
  }
}
