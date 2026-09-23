/// Release Health Monitoring (Step 113.42).
///
/// Domain contract for the seven privacy-safe release-health signals —
/// `install_success`, `upgrade_success`, `crash_rate`,
/// `migration_failure`, `restore_failure`, `performance_regression`,
/// and `support_severity` — plus evaluation of monitoring readiness.
///
/// A signal may be DEFINED before any observation exists (pipeline not
/// yet shipping): monitoring passes when every canonical signal is
/// recorded and privacy-safe, fails when a signal is missing, leaks
/// identifiers, or has an observed breach, and never treats "defined"
/// as "observed" in its notes.
library;

/// Canonical signal names, in roadmap order.
const List<String> kReleaseHealthSignals = <String>[
  'install_success',
  'upgrade_success',
  'crash_rate',
  'migration_failure',
  'restore_failure',
  'performance_regression',
  'support_severity',
];

/// Evaluation outcome of release-health monitoring readiness.
enum ReleaseHealthState {
  /// Every signal is defined, privacy-safe, and shows no breach.
  pass,

  /// A signal is missing, not privacy-safe, or observed in breach.
  fail,

  /// Nothing was recorded — nothing to evaluate.
  blocked,
}

/// Observed status of one signal; null means not yet observed.
enum HealthStatus {
  /// Metric observed and within threshold.
  ok,

  /// Metric observed and outside threshold.
  breach,
}

/// One release-health signal definition with optional observation.
class HealthSignal {
  const HealthSignal({
    this.signal,
    this.threshold,
    this.direction,
    this.privacySafe,
    this.collection,
    this.observedStatus,
  });

  final String? signal;
  final String? threshold;

  /// `higher_is_better` or `lower_is_better`.
  final String? direction;
  final bool? privacySafe;
  final String? collection;

  /// Null when the pipeline has not reported this signal yet.
  final HealthStatus? observedStatus;

  static const Set<String> validDirections = <String>{
    'higher_is_better',
    'lower_is_better',
  };

  bool get isWellDefined =>
      signal != null &&
      signal!.trim().isNotEmpty &&
      threshold != null &&
      threshold!.trim().isNotEmpty &&
      direction != null &&
      validDirections.contains(direction) &&
      privacySafe == true &&
      collection != null &&
      collection!.trim().isNotEmpty;

  bool get isBreached => observedStatus == HealthStatus.breach;
}

/// Immutable release-health monitoring readiness snapshot.
class ReleaseHealthMonitoring {
  const ReleaseHealthMonitoring({this.signals, this.privacyMode});

  final List<HealthSignal>? signals;

  /// Aggregate-only mode label; must state no-PII explicitly.
  final String? privacyMode;

  /// Returns the canonical names of signals missing, malformed, or
  /// not privacy-safe (empty when the definition set is complete).
  static List<String> missingSignals(ReleaseHealthMonitoring monitoring) {
    final signals = monitoring.signals;
    if (signals == null || signals.isEmpty) {
      return List<String>.unmodifiable(kReleaseHealthSignals);
    }
    final missing = <String>[];
    for (final name in kReleaseHealthSignals) {
      final matches = signals
          .where((s) => s.signal == name)
          .toList(growable: false);
      if (matches.isEmpty) {
        missing.add(name);
        continue;
      }
      if (!matches.every((s) => s.isWellDefined)) missing.add(name);
    }
    return List<String>.unmodifiable(missing);
  }

  /// Evaluates monitoring readiness: null or empty is
  /// [ReleaseHealthState.blocked]; missing/non-private signals fail with
  /// their canonical names; an observed breach fails with the breaching
  /// signal's name; a complete privacy-safe set passes, with the defined
  /// count, observed count, and privacy mode in the notes.
  static ReleaseHealthEvaluation evaluate(ReleaseHealthMonitoring? monitoring) {
    if (monitoring == null ||
        monitoring.signals == null ||
        monitoring.signals!.isEmpty) {
      return const ReleaseHealthEvaluation(
        state: ReleaseHealthState.blocked,
        notes: <String>['no release health monitoring recorded'],
      );
    }

    final missing = missingSignals(monitoring);
    if (missing.isNotEmpty) {
      return ReleaseHealthEvaluation(
        state: ReleaseHealthState.fail,
        notes: <String>[
          'release health monitoring incomplete: '
              'missing or not privacy-safe ${missing.join(', ')}',
        ],
      );
    }

    final signals = monitoring.signals!;
    final breached = signals
        .where((s) => s.isBreached)
        .map((s) => s.signal!)
        .toSet()
        .toList(growable: false);
    if (breached.isNotEmpty) {
      return ReleaseHealthEvaluation(
        state: ReleaseHealthState.fail,
        notes: <String>['observed breach: ${breached.join(', ')}'],
      );
    }

    final observed = signals.where((s) => s.observedStatus != null).length;
    final mode = monitoring.privacyMode ?? 'unknown';
    return ReleaseHealthEvaluation(
      state: ReleaseHealthState.pass,
      notes: <String>[
        'signals defined: ${signals.length}',
        'observed: $observed/${signals.length}',
        'privacy: $mode',
      ],
    );
  }
}

/// Result of evaluating [ReleaseHealthMonitoring].
class ReleaseHealthEvaluation {
  const ReleaseHealthEvaluation({required this.state, required this.notes});

  final ReleaseHealthState state;
  final List<String> notes;
}
