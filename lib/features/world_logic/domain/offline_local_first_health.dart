/// Offline and local-first health contract for Sprint 114.18.
///
/// Dependency-free model that compares offline core workflows against
/// queued-action recovery across the six canonical signals: offline_open,
/// offline_edit, offline_search, local_analysis, local_export, and
/// queue_recovery. `queue_recovery` is the root recovery signal: queued
/// offline actions must honestly replay and settle before a failed local
/// workflow counts as resolved. An absent observation set stays BLOCKED
/// without health claims. Real network-drop sessions, airplane-mode
/// native validation, and public distribution remain external gates and
/// are not claimed here.
enum OfflineSignal {
  offlineOpen,
  offlineEdit,
  offlineSearch,
  localAnalysis,
  localExport,
  queueRecovery,
}

enum OfflineOutcome { ok, failed, recovered }

enum OfflineLocalFirstState { pass, fail, blocked }

class OfflineObservation {
  const OfflineObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final OfflineSignal signal;
  final OfflineOutcome outcome;
  final String note;
}

class OfflineLocalFirstReport {
  const OfflineLocalFirstReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final OfflineLocalFirstState state;
  final List<OfflineObservation> observations;
  final List<OfflineSignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class OfflineLocalFirstHealth {
  static const List<OfflineSignal> canonicalSignals = <OfflineSignal>[
    OfflineSignal.offlineOpen,
    OfflineSignal.offlineEdit,
    OfflineSignal.offlineSearch,
    OfflineSignal.localAnalysis,
    OfflineSignal.localExport,
    OfflineSignal.queueRecovery,
  ];

  OfflineLocalFirstReport evaluate(List<OfflineObservation>? observations) {
    if (observations == null || observations.isEmpty) {
      return const OfflineLocalFirstReport(
        state: OfflineLocalFirstState.blocked,
        observations: <OfflineObservation>[],
        coveredSignals: <OfflineSignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi offline/local-first; tidak ada klaim '
              'kesehatan; live offline telemetry DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <OfflineSignal>{
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

    // Aturan lintas-sinyal hanya dinilai saat cakupan lengkap; cakupan
    // belum lengkap sudah gagal lewat invalidasi `signals`.
    final violations = <String>[];
    if (invalid.isEmpty) {
      OfflineOutcome outcomeOf(OfflineSignal signal) =>
          observations.firstWhere((o) => o.signal == signal).outcome;

      final queueOutcome = outcomeOf(OfflineSignal.queueRecovery);
      final queueFailed = queueOutcome == OfflineOutcome.failed;
      final queueRecovered = queueOutcome == OfflineOutcome.recovered;

      const workflowSignals = <OfflineSignal, String>{
        OfflineSignal.offlineOpen: 'offline_open',
        OfflineSignal.offlineEdit: 'offline_edit',
        OfflineSignal.offlineSearch: 'offline_search',
        OfflineSignal.localAnalysis: 'local_analysis',
        OfflineSignal.localExport: 'local_export',
      };

      var anyWorkflowOk = false;
      for (final entry in workflowSignals.entries) {
        final outcome = outcomeOf(entry.key);
        if (outcome == OfflineOutcome.ok) {
          anyWorkflowOk = true;
        }
        if (outcome == OfflineOutcome.failed && !queueRecovered) {
          violations.add('${entry.value}_unrecovered');
        }
      }
      if (queueFailed && anyWorkflowOk) {
        violations.add('queue_recovery_ignored');
      }
    }

    return OfflineLocalFirstReport(
      state: invalid.isEmpty && violations.isEmpty
          ? OfflineLocalFirstState.pass
          : OfflineLocalFirstState.fail,
      observations: List<OfflineObservation>.unmodifiable(observations),
      coveredSignals: List<OfflineSignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations.toSet()),
      notes: const <String>[
        'Verifikasi kontrak lokal atas enam sinyal offline/local-first; '
            'sesi offline nyata, mode pesawat native, dan publikasi '
            'distribusi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
