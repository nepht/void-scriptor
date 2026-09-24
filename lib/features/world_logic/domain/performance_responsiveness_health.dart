/// Performance and responsiveness health contract for Sprint 114.16.
///
/// Dependency-free model that compares startup, editor latency, search,
/// graph, simulation, export duration, and background contention against
/// the frozen baselines across the seven canonical signals: startup,
/// editor_latency, search_latency, graph_latency, simulation_latency,
/// export_duration, and background_contention. An absent observation set
/// stays BLOCKED without health claims. Live performance telemetry on
/// production hardware, profile-mode FrameTiming, native GUI cold-start
/// measurement, and public distribution remain external gates and are
/// not claimed here.
enum PerformanceSignal {
  startup,
  editorLatency,
  searchLatency,
  graphLatency,
  simulationLatency,
  exportDuration,
  backgroundContention,
}

enum PerformanceOutcome { ok, failed, recovered }

enum PerformanceState { pass, fail, blocked }

class PerformanceObservation {
  const PerformanceObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final PerformanceSignal signal;
  final PerformanceOutcome outcome;
  final String note;
}

class PerformanceReport {
  const PerformanceReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final PerformanceState state;
  final List<PerformanceObservation> observations;
  final List<PerformanceSignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class PerformanceResponsivenessHealth {
  static const List<PerformanceSignal> canonicalSignals = <PerformanceSignal>[
    PerformanceSignal.startup,
    PerformanceSignal.editorLatency,
    PerformanceSignal.searchLatency,
    PerformanceSignal.graphLatency,
    PerformanceSignal.simulationLatency,
    PerformanceSignal.exportDuration,
    PerformanceSignal.backgroundContention,
  ];

  PerformanceReport evaluate(List<PerformanceObservation>? observations) {
    if (observations == null || observations.isEmpty) {
      return const PerformanceReport(
        state: PerformanceState.blocked,
        observations: <PerformanceObservation>[],
        coveredSignals: <PerformanceSignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi performa; tidak ada klaim kesehatan; live '
              'performance telemetry DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <PerformanceSignal>{
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
      PerformanceOutcome outcomeOf(PerformanceSignal signal) =>
          observations.firstWhere((o) => o.signal == signal).outcome;

      final contentionOutcome = outcomeOf(
        PerformanceSignal.backgroundContention,
      );
      final contentionFailed = contentionOutcome == PerformanceOutcome.failed;
      final contentionRecovered =
          contentionOutcome == PerformanceOutcome.recovered;

      const workSignals = <PerformanceSignal, String>{
        PerformanceSignal.startup: 'startup',
        PerformanceSignal.editorLatency: 'editor_latency',
        PerformanceSignal.searchLatency: 'search_latency',
        PerformanceSignal.graphLatency: 'graph_latency',
        PerformanceSignal.simulationLatency: 'simulation_latency',
        PerformanceSignal.exportDuration: 'export_duration',
      };

      var anyWorkOk = false;
      for (final entry in workSignals.entries) {
        final outcome = outcomeOf(entry.key);
        if (outcome == PerformanceOutcome.ok) {
          anyWorkOk = true;
        }
        if (outcome == PerformanceOutcome.failed && !contentionRecovered) {
          violations.add('${entry.value}_unrecovered');
        }
      }
      if (contentionFailed && anyWorkOk) {
        violations.add('contention_ignored');
      }
    }

    return PerformanceReport(
      state: invalid.isEmpty && violations.isEmpty
          ? PerformanceState.pass
          : PerformanceState.fail,
      observations: List<PerformanceObservation>.unmodifiable(observations),
      coveredSignals: List<PerformanceSignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations.toSet()),
      notes: const <String>[
        'Verifikasi kontrak lokal atas tujuh sinyal performa; pengukuran '
            'performa native GUI/mesin produksi, profile-mode FrameTiming, '
            'dan publikasi distribusi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
