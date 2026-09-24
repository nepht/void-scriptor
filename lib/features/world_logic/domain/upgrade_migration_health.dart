/// Upgrade & migration health contract for Sprint 114.10.
///
/// Dependency-free model that monitors the six canonical migration
/// signals: migration success, migration duration, warnings, repair
/// requirement, rollback result, and integrity (data comparison)
/// result per source version. An absent observation set stays BLOCKED
/// without health claims. Live upgrade telemetry, production database
/// schema verification, end-user update channels, and public
/// distribution remain external gates and are not claimed here.
enum UpgradeMigrationSignal {
  migrationSuccess,
  migrationDuration,
  warnings,
  repairRequired,
  rollbackResult,
  integrityResult,
}

enum UpgradeMigrationOutcome { ok, failed, recovered }

enum UpgradeMigrationHealthState { pass, fail, blocked }

class UpgradeMigrationObservation {
  const UpgradeMigrationObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final UpgradeMigrationSignal signal;
  final UpgradeMigrationOutcome outcome;
  final String note;
}

class UpgradeMigrationHealthReport {
  const UpgradeMigrationHealthReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final UpgradeMigrationHealthState state;
  final List<UpgradeMigrationObservation> observations;
  final List<UpgradeMigrationSignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class UpgradeMigrationHealth {
  static const List<UpgradeMigrationSignal> canonicalSignals =
      <UpgradeMigrationSignal>[
        UpgradeMigrationSignal.migrationSuccess,
        UpgradeMigrationSignal.migrationDuration,
        UpgradeMigrationSignal.warnings,
        UpgradeMigrationSignal.repairRequired,
        UpgradeMigrationSignal.rollbackResult,
        UpgradeMigrationSignal.integrityResult,
      ];

  UpgradeMigrationHealthReport evaluate(
    List<UpgradeMigrationObservation>? observations,
  ) {
    if (observations == null || observations.isEmpty) {
      return const UpgradeMigrationHealthReport(
        state: UpgradeMigrationHealthState.blocked,
        observations: <UpgradeMigrationObservation>[],
        coveredSignals: <UpgradeMigrationSignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi upgrade/migrasi; tidak ada klaim kesehatan; '
              'live migration telemetry DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <UpgradeMigrationSignal>{
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

    bool hasOutcome(
      UpgradeMigrationSignal signal,
      UpgradeMigrationOutcome outcome,
    ) => observations.any((o) => o.signal == signal && o.outcome == outcome);

    final migrationSucceeded = hasOutcome(
      UpgradeMigrationSignal.migrationSuccess,
      UpgradeMigrationOutcome.ok,
    );
    final migrationFailed = hasOutcome(
      UpgradeMigrationSignal.migrationSuccess,
      UpgradeMigrationOutcome.failed,
    );
    final violations = <String>[];
    if (migrationSucceeded &&
        hasOutcome(
          UpgradeMigrationSignal.integrityResult,
          UpgradeMigrationOutcome.failed,
        )) {
      violations.add('integrity_failure_ignored');
    }
    if (migrationSucceeded &&
        hasOutcome(
          UpgradeMigrationSignal.repairRequired,
          UpgradeMigrationOutcome.failed,
        )) {
      violations.add('repair_required_ignored');
    }
    if (migrationFailed &&
        hasOutcome(
          UpgradeMigrationSignal.rollbackResult,
          UpgradeMigrationOutcome.failed,
        )) {
      violations.add('migration_unrecovered');
    }

    return UpgradeMigrationHealthReport(
      state: invalid.isEmpty && violations.isEmpty
          ? UpgradeMigrationHealthState.pass
          : UpgradeMigrationHealthState.fail,
      observations: List<UpgradeMigrationObservation>.unmodifiable(
        observations,
      ),
      coveredSignals: List<UpgradeMigrationSignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Verifikasi kontrak lokal atas enam sinyal upgrade/migrasi; '
            'telemetri produksi, verifikasi skema end-to-end, dan '
            'distribusi publik DEFERRED-EXTERNAL.',
      ],
    );
  }
}
