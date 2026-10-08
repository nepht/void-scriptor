/// Fail-closed post-release health baseline for roadmap step 118.4 --
/// Post-Release Health Baseline.
///
/// Objective (external canonical `sprint_118.json`): freeze the baseline for
/// connection, reauth, quota, sync, backup, AI, billing, crash, performance, and
/// support, each carrying the six canonical fields `signal`, `baseline`,
/// `threshold`, `source`, `window`, and `limitations`.
///
/// The canonical contract is blunt about the situation this baseline is written
/// against. Sprint 118 runs on the delayed corrective path: the 118.2 charter
/// froze a 42-day observation window that is declared and *not* executed, and
/// the 118.3 snapshot froze an empty released subset (`CERTIFIED: 0` of `32`
/// registered). A baseline that freezes "the health of the release" therefore
/// has exactly one honest shape: a declared reference for each area, anchored to
/// committed evidence, observing nothing because no release ran.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.3 snapshot anchor must be a genuine frozen snapshot
///   (`pass` on `CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A baseline built on
///   a snapshot that did not freeze describes a release nobody recorded.
/// * The baseline's release state must agree with the snapshot anchor. A baseline
///   that silently claims `GA_RELEASED` while the snapshot says `GA_DELAYED` is
///   not a baseline.
/// * On the delayed path no entry may claim an observed value: with no release,
///   an observation describes a release that never happened. This is refused by
///   name, per signal.
/// * Every canonical area must be present exactly once. A baseline that drops the
///   support area, invents a `telepathy` area, or duplicates `connection` is not
///   a freeze.
/// * Every entry must carry every canonical field non-empty and declare at least
///   one limitation, so the baseline states the boundary it was frozen under
///   instead of implying live availability.
/// * Every entry's `window` must be positive and may never exceed the charter's
///   declared observation window; a baseline that monitors longer than the
///   charter is not frozen against it.
/// * Every entry's `threshold` must be well formed (`<operator>:<number>` with a
///   known operator), and every entry's `source` must be a committed, readable
///   evidence file. A threshold the gate cannot parse is not a threshold.
///
/// Live observation, telemetry scraping, connector certification, provider
/// exposure, release authorization, and publication remain `DEFERRED-EXTERNAL`;
/// this baseline freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a baseline evaluation can rest in. `blocked` is the honest
/// resting state for "this baseline cannot yet be trusted", and it is distinct
/// from `fail`, which means the baseline contradicts its own evidence.
enum Sprint118BaselineState { pass, fail, blocked }

/// One frozen health-baseline entry: the declared reference for a single health
/// area, with the boundary it was frozen under.
class Sprint118HealthBaselineEntry {
  const Sprint118HealthBaselineEntry({
    required this.signal,
    required this.baseline,
    required this.threshold,
    required this.source,
    required this.window,
    required this.limitations,
    this.observed = false,
  });

  /// The health area, drawn from the canonical area vocabulary.
  final String signal;

  /// The declared baseline reference value, e.g. `no_live_observation`.
  final String baseline;

  /// The threshold in `<operator>:<number>` form, e.g. `gte:0.95`.
  final String threshold;

  /// The committed evidence file this baseline is anchored to.
  final String source;

  /// The measurement window in minutes.
  final int window;

  /// The limitations the baseline was frozen under. At least one is required so
  /// the baseline cannot imply live availability.
  final List<String> limitations;

  /// Whether the entry claims an observed value. On the delayed path this must
  /// stay `false`.
  final bool observed;
}

/// The frozen baseline. `entries` is the declared reference for each canonical
/// health area; on the delayed path no entry may claim an observation.
class Sprint118PostReleaseHealthBaseline {
  const Sprint118PostReleaseHealthBaseline({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118HealthBaselineEntry> entries;

  List<String> get signals => <String>[
    for (final entry in entries) entry.signal,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed 118.3 snapshot and 118.2 charter actually say. A baseline
/// is only as honest as the witnesses it is anchored to.
class Sprint118HealthBaselineAnchor {
  const Sprint118HealthBaselineAnchor({
    required this.snapshotState,
    required this.snapshotVerdict,
    required this.releaseState,
    required this.charterWindowMinutes,
    required this.readableSources,
  });

  final String snapshotState;
  final String snapshotVerdict;
  final String releaseState;
  final int charterWindowMinutes;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the baseline is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118HealthBaselineReport {
  const Sprint118HealthBaselineReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.baselineSignals = const <String>[],
    this.observedCount = 0,
  });

  final Sprint118BaselineState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> baselineSignals;
  final int observedCount;

  /// Whether the baseline may be treated as a frozen record. Only a genuine
  /// `pass` allows it.
  bool get baselineFrozen => state == Sprint118BaselineState.pass;

  String get externalGates => Sprint118BaselineContract.externalGates;
}

/// The fixed vocabulary of step 118.4, kept in one place so the loader, the gate,
/// and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118BaselineContract {
  const Sprint118BaselineContract._();

  static const String canonicalStep = '118.4';
  static const String title = 'Post-Release Health Baseline';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.3 snapshot this baseline is anchored to.
  static const String snapshotManifestPath =
      'docs/planning/v1.3/sprint_118_certified_connector_snapshot.json';

  /// The committed 118.2 charter that declares the observation window.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.3 snapshot anchor must carry for the baseline
  /// to be trustworthy.
  static const String requiredSnapshotVerdict =
      'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL';
  static const String requiredSnapshotState = 'pass';
  static const String delayedReleaseState = 'GA_DELAYED';
  static const String releasedReleaseState = 'GA_RELEASED';

  /// The six canonical entry fields from `sprint_118.json` step 118.4.
  static const List<String> requiredFields = <String>[
    'signal',
    'baseline',
    'threshold',
    'source',
    'window',
    'limitations',
  ];

  /// The ten canonical health areas from `sprint_118.json` step 118.4.
  static const List<String> canonicalAreas = <String>[
    'connection',
    'reauth',
    'quota',
    'sync',
    'backup',
    'ai',
    'billing',
    'crash',
    'performance',
    'support',
  ];

  /// The comparison operators a threshold may use.
  static const List<String> thresholdOperators = <String>[
    'gt',
    'gte',
    'lt',
    'lte',
    'eq',
  ];

  /// The charter's declared observation window, in minutes: 42 days.
  static const int charterWindowMinutes = 42 * 24 * 60;

  /// The committed evidence sources the canonical baseline is anchored to, one
  /// per area, in canonical-area order.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.2/sprint_115_connection_health_state_machine.json',
    'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
    'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
    'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json',
    'docs/planning/v1.2/sprint_115_cloud_transfer_sync_controls.json',
    'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json',
    'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
    'docs/planning/v1.2/sprint_114_crash_startup_health.json',
    'docs/planning/v1.2/sprint_114_performance_responsiveness_health.json',
    'docs/planning/v1.3/sprint_117_support_incident_readiness.json',
  ];

  /// The canonical baseline, declared here as the single source of truth. The
  /// gate evaluates exactly this object, and the emitter writes exactly this
  /// object, so the record cannot be made to agree with itself. With the release
  /// delayed, every entry declares a reference and observes nothing.
  static const Sprint118PostReleaseHealthBaseline
  canonicalBaseline = Sprint118PostReleaseHealthBaseline(
    releaseState: delayedReleaseState,
    entries: <Sprint118HealthBaselineEntry>[
      Sprint118HealthBaselineEntry(
        signal: 'connection',
        baseline: 'no_live_observation',
        threshold: 'gte:0.95',
        source:
            'docs/planning/v1.2/sprint_115_connection_health_state_machine.json',
        window: 60,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118HealthBaselineEntry(
        signal: 'reauth',
        baseline: 'no_live_observation',
        threshold: 'gte:0.95',
        source:
            'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
        window: 60,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118HealthBaselineEntry(
        signal: 'quota',
        baseline: 'no_live_observation',
        threshold: 'eq:1.0',
        source:
            'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118HealthBaselineEntry(
        signal: 'sync',
        baseline: 'no_live_observation',
        threshold: 'eq:0.0',
        source:
            'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json',
        window: 60,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118HealthBaselineEntry(
        signal: 'backup',
        baseline: 'no_live_observation',
        threshold: 'gte:1.0',
        source:
            'docs/planning/v1.2/sprint_115_cloud_transfer_sync_controls.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118HealthBaselineEntry(
        signal: 'ai',
        baseline: 'no_live_observation',
        threshold: 'gte:0.95',
        source:
            'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118HealthBaselineEntry(
        signal: 'billing',
        baseline: 'no_live_observation',
        threshold: 'gte:1.0',
        source:
            'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118HealthBaselineEntry(
        signal: 'crash',
        baseline: 'no_live_observation',
        threshold: 'lte:0.01',
        source: 'docs/planning/v1.2/sprint_114_crash_startup_health.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118HealthBaselineEntry(
        signal: 'performance',
        baseline: 'no_live_observation',
        threshold: 'lte:1.0',
        source:
            'docs/planning/v1.2/sprint_114_performance_responsiveness_health.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118HealthBaselineEntry(
        signal: 'support',
        baseline: 'no_live_observation',
        threshold: 'lte:48',
        source: 'docs/planning/v1.3/sprint_117_support_incident_readiness.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
    ],
  );

  /// Whether a threshold string is `<known-operator>:<number>`. A threshold the
  /// gate cannot parse is refused rather than assumed.
  static bool thresholdWellFormed(String threshold) {
    final parts = threshold.split(':');
    if (parts.length != 2) return false;
    if (!thresholdOperators.contains(parts[0])) return false;
    final value = parts[1].trim();
    if (value.isEmpty) return false;
    return num.tryParse(value) != null;
  }
}

/// Reads the committed 118.3 snapshot and 118.2 charter. Never invents: an
/// unreadable witness yields `null`, which the gate reports as blocked rather
/// than as a pass.
class Sprint118HealthBaselineLoader {
  const Sprint118HealthBaselineLoader();

  Sprint118HealthBaselineAnchor? loadAnchor() {
    final snapshot = _readJsonObject(
      Sprint118BaselineContract.snapshotManifestPath,
    );
    if (snapshot == null) return null;
    final charter = _readJsonObject(
      Sprint118BaselineContract.charterManifestPath,
    );
    if (charter == null) return null;

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final charterWindowMinutes = durationDays > 0
        ? durationDays * 24 * 60
        : Sprint118BaselineContract.charterWindowMinutes;

    final readable = <String>[
      for (final source in Sprint118BaselineContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118HealthBaselineAnchor(
      snapshotState: _text(snapshot['state']),
      snapshotVerdict: _text(snapshot['verdict']),
      releaseState: _text(snapshot['release_state']),
      charterWindowMinutes: charterWindowMinutes,
      readableSources: readable,
    );
  }

  static Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String _text(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class Sprint118PostReleaseHealthBaselineGate {
  const Sprint118PostReleaseHealthBaselineGate();

  /// Evaluate the canonical baseline against committed evidence. This is the
  /// entry point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118HealthBaselineReport evaluate() => evaluateWith(
    const Sprint118HealthBaselineLoader().loadAnchor(),
    Sprint118BaselineContract.canonicalBaseline,
  );

  Sprint118HealthBaselineReport evaluateWith(
    Sprint118HealthBaselineAnchor? anchor,
    Sprint118PostReleaseHealthBaseline baseline,
  ) {
    if (anchor == null) {
      return Sprint118HealthBaselineReport(
        state: Sprint118BaselineState.blocked,
        verdict: 'SPRINT_118_BASELINE_EVIDENCE_UNREADABLE',
        releaseState: baseline.releaseState,
        missingFields: List<String>.from(
          Sprint118BaselineContract.requiredFields,
        ),
        blockers: const <String>['committed_baseline_evidence_unreadable'],
        openItems: const <String>['committed_baseline_evidence_unreadable'],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];

    // (1) The 118.3 snapshot anchor must be a genuine frozen pass. A baseline
    // written against an unfrozen snapshot describes a release nobody recorded.
    if (anchor.snapshotState !=
            Sprint118BaselineContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118BaselineContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (2) The release state must agree with the snapshot anchor.
    if (anchor.releaseState != baseline.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'baseline=${baseline.releaseState}',
      );
    }

    // (3) Every canonical area must be present exactly once.
    final declaredAreas = <String, int>{};
    for (final entry in baseline.entries) {
      declaredAreas[entry.signal] = (declaredAreas[entry.signal] ?? 0) + 1;
    }
    for (final area in Sprint118BaselineContract.canonicalAreas) {
      final count = declaredAreas[area] ?? 0;
      if (count == 0) {
        violations.add('baseline_area_missing:$area');
      } else if (count > 1) {
        violations.add('baseline_duplicate_area:$area');
      }
    }
    for (final signal in declaredAreas.keys) {
      if (!Sprint118BaselineContract.canonicalAreas.contains(signal)) {
        violations.add('baseline_unknown_area:$signal');
      }
    }

    // (4) On the delayed path no entry may claim an observation: with no
    // release, an observation describes a release that never happened.
    final delayed =
        baseline.releaseState == Sprint118BaselineContract.delayedReleaseState;
    for (final entry in baseline.entries) {
      if (delayed && entry.observed) {
        violations.add(
          'baseline_claims_observation_without_release:${entry.signal}',
        );
      }
    }

    // (5) Every entry must carry every canonical field non-empty and declare at
    // least one limitation, so the baseline states its boundary.
    if (Sprint118BaselineContract.requiredFields.length != 6) {
      violations.add('contract_field_count_not_six');
    }
    for (final entry in baseline.entries) {
      final signal = entry.signal;
      if (entry.baseline.trim().isEmpty) {
        violations.add('entry_blank_baseline:$signal');
      }
      if (entry.source.trim().isEmpty) {
        violations.add('entry_blank_source:$signal');
      }
      if (entry.threshold.trim().isEmpty) {
        violations.add('entry_blank_threshold:$signal');
      }
      if (entry.limitations.isEmpty) {
        violations.add('entry_no_limitations:$signal');
      }
      if (entry.window <= 0) {
        violations.add('entry_nonpositive_window:$signal:${entry.window}');
      } else if (entry.window > anchor.charterWindowMinutes) {
        violations.add(
          'entry_window_exceeds_charter:$signal:${entry.window}:'
          '${anchor.charterWindowMinutes}',
        );
      }
      if (entry.threshold.trim().isNotEmpty &&
          !Sprint118BaselineContract.thresholdWellFormed(entry.threshold)) {
        violations.add('entry_malformed_threshold:$signal:${entry.threshold}');
      }
      if (entry.source.trim().isNotEmpty &&
          !anchor.readableSources.contains(entry.source)) {
        violations.add('entry_unreadable_source:$signal:${entry.source}');
      }
    }

    final openItems = <String>[...violations, ...blockers];
    final signals = baseline.signals;

    if (violations.isNotEmpty) {
      return Sprint118HealthBaselineReport(
        state: Sprint118BaselineState.fail,
        verdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        releaseState: baseline.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: openItems,
        baselineSignals: signals,
        observedCount: baseline.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118HealthBaselineReport(
        state: Sprint118BaselineState.blocked,
        verdict: 'SPRINT_118_BASELINE_BLOCKED_UPSTREAM',
        releaseState: baseline.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: openItems,
        baselineSignals: signals,
        observedCount: baseline.observedCount,
      );
    }
    return Sprint118HealthBaselineReport(
      state: Sprint118BaselineState.pass,
      verdict: 'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL',
      releaseState: baseline.releaseState,
      baselineSignals: signals,
      observedCount: baseline.observedCount,
    );
  }
}
