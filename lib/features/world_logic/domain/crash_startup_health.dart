/// Crash & startup health contract for Sprint 114.11.
///
/// Dependency-free model that detects crash loops, startup failures,
/// project-open failures, and recovery behavior across the five
/// canonical signals: crash_rate, startup_failure,
/// project_open_failure, crash_loop, and recovery_success. An absent
/// observation set stays BLOCKED without health claims. Live crash
/// telemetry, native GUI startup sessions, hardware restarts, and
/// public distribution remain external gates and are not claimed
/// here.
enum CrashStartupSignal {
  crashRate,
  startupFailure,
  projectOpenFailure,
  crashLoop,
  recoverySuccess,
}

enum CrashStartupOutcome { ok, failed, recovered }

enum CrashStartupHealthState { pass, fail, blocked }

class CrashStartupObservation {
  const CrashStartupObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final CrashStartupSignal signal;
  final CrashStartupOutcome outcome;
  final String note;
}

class CrashStartupHealthReport {
  const CrashStartupHealthReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final CrashStartupHealthState state;
  final List<CrashStartupObservation> observations;
  final List<CrashStartupSignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class CrashStartupHealth {
  static const List<CrashStartupSignal> canonicalSignals = <CrashStartupSignal>[
    CrashStartupSignal.crashRate,
    CrashStartupSignal.startupFailure,
    CrashStartupSignal.projectOpenFailure,
    CrashStartupSignal.crashLoop,
    CrashStartupSignal.recoverySuccess,
  ];

  CrashStartupHealthReport evaluate(
    List<CrashStartupObservation>? observations,
  ) {
    if (observations == null || observations.isEmpty) {
      return const CrashStartupHealthReport(
        state: CrashStartupHealthState.blocked,
        observations: <CrashStartupObservation>[],
        coveredSignals: <CrashStartupSignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi crash/startup; tidak ada klaim kesehatan; '
              'live crash telemetry DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <CrashStartupSignal>{
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

    bool hasOutcome(CrashStartupSignal signal, CrashStartupOutcome outcome) =>
        observations.any((o) => o.signal == signal && o.outcome == outcome);

    final violations = <String>[];
    if (hasOutcome(CrashStartupSignal.crashRate, CrashStartupOutcome.ok) &&
        hasOutcome(CrashStartupSignal.crashLoop, CrashStartupOutcome.failed)) {
      violations.add('crash_loop_ignored');
    }
    if (hasOutcome(
          CrashStartupSignal.startupFailure,
          CrashStartupOutcome.failed,
        ) &&
        hasOutcome(
          CrashStartupSignal.recoverySuccess,
          CrashStartupOutcome.failed,
        )) {
      violations.add('startup_unrecovered');
    }
    if (hasOutcome(
          CrashStartupSignal.projectOpenFailure,
          CrashStartupOutcome.failed,
        ) &&
        hasOutcome(
          CrashStartupSignal.recoverySuccess,
          CrashStartupOutcome.failed,
        )) {
      violations.add('project_open_unrecovered');
    }
    if (hasOutcome(CrashStartupSignal.crashLoop, CrashStartupOutcome.failed) &&
        hasOutcome(
          CrashStartupSignal.recoverySuccess,
          CrashStartupOutcome.failed,
        )) {
      violations.add('crash_loop_unrecovered');
    }

    return CrashStartupHealthReport(
      state: invalid.isEmpty && violations.isEmpty
          ? CrashStartupHealthState.pass
          : CrashStartupHealthState.fail,
      observations: List<CrashStartupObservation>.unmodifiable(observations),
      coveredSignals: List<CrashStartupSignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Verifikasi kontrak lokal atas lima sinyal crash/startup; '
            'telemetri crash produksi, sesi startup native GUI, restart '
            'perangkat keras, dan distribusi publik DEFERRED-EXTERNAL.',
      ],
    );
  }
}
