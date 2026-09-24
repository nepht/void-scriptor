/// Platform compatibility health contract for Sprint 114.19.
///
/// Dependency-free model that compares compatibility health across the
/// seven canonical dimensions: platform, os_version, hardware,
/// filesystem, input, rendering, and package. `package` is the root
/// recovery signal: a failed compatibility dimension only counts as
/// resolved when a rebuilt or repaired package honestly recovers it.
/// An absent observation set stays BLOCKED without health claims. Real
/// multi-platform native validation, hardware matrices, hosted CI, and
/// public distribution remain external gates and are not claimed here.
enum PlatformSignal {
  platform,
  osVersion,
  hardware,
  filesystem,
  input,
  rendering,
  package,
}

enum PlatformOutcome { ok, failed, recovered }

enum PlatformCompatibilityState { pass, fail, blocked }

class PlatformObservation {
  const PlatformObservation({
    required this.signal,
    required this.outcome,
    required this.note,
  });

  final PlatformSignal signal;
  final PlatformOutcome outcome;
  final String note;
}

class PlatformCompatibilityReport {
  const PlatformCompatibilityReport({
    required this.state,
    required this.observations,
    required this.coveredSignals,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final PlatformCompatibilityState state;
  final List<PlatformObservation> observations;
  final List<PlatformSignal> coveredSignals;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class PlatformCompatibilityHealth {
  static const List<PlatformSignal> canonicalSignals = <PlatformSignal>[
    PlatformSignal.platform,
    PlatformSignal.osVersion,
    PlatformSignal.hardware,
    PlatformSignal.filesystem,
    PlatformSignal.input,
    PlatformSignal.rendering,
    PlatformSignal.package,
  ];

  PlatformCompatibilityReport evaluate(
    List<PlatformObservation>? observations,
  ) {
    if (observations == null || observations.isEmpty) {
      return const PlatformCompatibilityReport(
        state: PlatformCompatibilityState.blocked,
        observations: <PlatformObservation>[],
        coveredSignals: <PlatformSignal>[],
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada observasi kompatibilitas platform; tidak ada klaim '
              'kesehatan; validasi platform native DEFERRED-EXTERNAL.',
        ],
      );
    }

    final covered = <PlatformSignal>{
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

    // Aturan lintas-dinensi hanya dinilai saat cakupan lengkap; cakupan
    // belum lengkap sudah gagal lewat invalidasi `signals`.
    final violations = <String>[];
    if (invalid.isEmpty) {
      PlatformOutcome outcomeOf(PlatformSignal signal) =>
          observations.firstWhere((o) => o.signal == signal).outcome;

      final packageOutcome = outcomeOf(PlatformSignal.package);
      final packageFailed = packageOutcome == PlatformOutcome.failed;
      final packageRecovered = packageOutcome == PlatformOutcome.recovered;

      const dimensionSignals = <PlatformSignal, String>{
        PlatformSignal.platform: 'platform',
        PlatformSignal.osVersion: 'os_version',
        PlatformSignal.hardware: 'hardware',
        PlatformSignal.filesystem: 'filesystem',
        PlatformSignal.input: 'input',
        PlatformSignal.rendering: 'rendering',
      };

      var anyDimensionOk = false;
      for (final entry in dimensionSignals.entries) {
        final outcome = outcomeOf(entry.key);
        if (outcome == PlatformOutcome.ok) {
          anyDimensionOk = true;
        }
        if (outcome == PlatformOutcome.failed && !packageRecovered) {
          violations.add('${entry.value}_unrecovered');
        }
      }
      if (packageFailed && anyDimensionOk) {
        violations.add('package_recovery_ignored');
      }
    }

    return PlatformCompatibilityReport(
      state: invalid.isEmpty && violations.isEmpty
          ? PlatformCompatibilityState.pass
          : PlatformCompatibilityState.fail,
      observations: List<PlatformObservation>.unmodifiable(observations),
      coveredSignals: List<PlatformSignal>.unmodifiable(
        canonicalSignals.where(covered.contains),
      ),
      invalidFields: List<String>.unmodifiable(invalid.toSet()),
      violations: List<String>.unmodifiable(violations.toSet()),
      notes: const <String>[
        'Verifikasi kontrak lokal atas tujuh dimensi kompatibilitas '
            'platform; validasi native lintas-platform, matriks perangkat '
            'keras, dan publikasi distribusi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
