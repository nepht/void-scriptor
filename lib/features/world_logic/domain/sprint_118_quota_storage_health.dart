/// Fail-closed Quota & Storage health review for roadmap step 118.9 --
/// Quota & Storage Health.
///
/// Objective (external canonical `sprint_118.json`): monitor quota accuracy,
/// refresh failures, stale data, partial totals, unit display, local scans, and
/// false precision. The canonical signal list is exactly seven items:
/// `quota_match`, `refresh_failure`, `stale_data`, `partial_total`,
/// `unit_issue`, `local_scan`, and `false_precision`.
///
/// This is the review the delayed corrective path (Sprint 118 on `GA_DELAYED`)
/// registers *before* any live observation runs. The gate answers a single
/// question: does the declared review carry, for every canonical quota/storage
/// signal, a reference state drawn from the committed quota/storage witnesses,
/// a committed readable evidence source, a positive window bounded by the
/// charter, and a stated limitation -- while claiming no live observation?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A review built on
///   a baseline that did not freeze describes quota readings nobody measured.
/// * The committed 118.2 charter anchor must be complete
///   (`CHARTER_COMPLETE_LOCAL`); the review is bound to the charter's declared
///   observation window.
/// * The review's release state must agree with the baseline anchor.
/// * On the delayed path no signal may claim an observation: with no release, an
///   observation describes a provider quota reading that was never fetched.
///   Refused by name, per signal.
/// * Every canonical signal must be present exactly once, must carry a
///   non-blank reference state, a committed readable source, a positive window
///   no larger than the charter window, and at least one stated limitation.
/// * Every reference state must be drawn from the committed quota contract
///   (116.41 acceptance), the committed provider quota adapter witness (115
///   acceptance), the committed local storage summary witness (115 acceptance),
///   and the committed cloud storage aggregation witness (115 acceptance), so
///   the review and the quota/storage contracts cannot drift apart.
///
/// Live provider quota reads, storage scans, credential access, connector
/// certification, provider exposure, release authorization, and publication
/// remain `DEFERRED-EXTERNAL`; this review freezes local declared state and
/// executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a quota/storage-health review can rest in. `blocked` is the
/// honest resting state for "this review cannot yet be trusted", and it is
/// distinct from `fail`, which means the review contradicts its own evidence.
enum Sprint118QuotaStorageHealthState { pass, fail, blocked }

/// One quota/storage entry: the declared reference for a single canonical
/// signal, with the boundary it was frozen under.
class Sprint118QuotaStorageHealthEntry {
  const Sprint118QuotaStorageHealthEntry({
    required this.signal,
    required this.referenceState,
    required this.source,
    required this.window,
    required this.limitations,
    this.observed = false,
  });

  /// The quota/storage signal, drawn from the canonical vocabulary.
  final String signal;

  /// The declared reference state, drawn from the committed quota/storage
  /// witness vocabulary.
  final String referenceState;

  /// The committed evidence file this reference is anchored to.
  final String source;

  /// The measurement window in minutes.
  final int window;

  /// The limitations the reference was frozen under. At least one is required so
  /// the review cannot imply live quota reads.
  final List<String> limitations;

  /// Whether the entry claims an observed value. On the delayed path this must
  /// stay `false`.
  final bool observed;
}

/// The declared review. `entries` is the review surface for the delayed
/// corrective path; on that path no entry may claim an observation.
class Sprint118QuotaStorageHealthReview {
  const Sprint118QuotaStorageHealthReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118QuotaStorageHealthEntry> entries;

  List<String> get signals => <String>[
    for (final entry in entries) entry.signal,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed 118.4 baseline, 118.2 charter, and quota/storage
/// witnesses actually say. A review is only as honest as the witnesses it
/// reads.
class Sprint118QuotaStorageHealthAnchor {
  const Sprint118QuotaStorageHealthAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.witnessQuotaAcceptance,
    required this.witnessAdapterAcceptance,
    required this.witnessLocalAcceptance,
    required this.witnessAggregationAcceptance,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;

  /// The acceptance items the committed 116.41 quota cross-provider contract
  /// declares.
  final List<String> witnessQuotaAcceptance;

  /// The acceptance items the committed 115 provider quota adapter witness
  /// declares.
  final List<String> witnessAdapterAcceptance;

  /// The acceptance items the committed 115 local storage summary witness
  /// declares.
  final List<String> witnessLocalAcceptance;

  /// The acceptance items the committed 115 cloud storage aggregation witness
  /// declares.
  final List<String> witnessAggregationAcceptance;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is well-formed; `blocked` means
/// it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118QuotaStorageHealthReport {
  const Sprint118QuotaStorageHealthReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredSignals = const <String>[],
    this.observedCount = 0,
  });

  final Sprint118QuotaStorageHealthState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredSignals;
  final int observedCount;

  /// Whether the review may be treated as well-formed. Only a genuine `pass`
  /// allows it.
  bool get reviewVerified => state == Sprint118QuotaStorageHealthState.pass;

  String get externalGates => Sprint118QuotaStorageHealthContract.externalGates;
}

/// The fixed vocabulary of step 118.9, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118QuotaStorageHealthContract {
  const Sprint118QuotaStorageHealthContract._();

  static const String canonicalStep = '118.9';
  static const String title = 'Quota & Storage Health';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_quota_storage_health.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this review is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter that declares the observation window.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 116.41 quota/usage cross-provider contract that declares the
  /// quota acceptance items this review references.
  static const String quotaContractManifestPath =
      'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json';

  /// The committed 115 provider quota adapter witness that declares the adapter
  /// acceptance items this review references.
  static const String quotaAdapterManifestPath =
      'docs/planning/v1.2/sprint_115_provider_quota_adapters.json';

  /// The committed 115 local storage summary witness that declares the local
  /// storage acceptance items this review references.
  static const String localStorageManifestPath =
      'docs/planning/v1.2/sprint_115_local_storage_summary.json';

  /// The committed 115 cloud storage aggregation witness that declares the
  /// aggregation acceptance items this review references.
  static const String aggregationManifestPath =
      'docs/planning/v1.2/sprint_115_cloud_storage_aggregation.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The five canonical entry fields from `sprint_118.json` step 118.9.
  static const List<String> requiredFields = <String>[
    'signal',
    'reference_state',
    'source',
    'window',
    'limitations',
  ];

  /// The seven canonical quota/storage signals the objective names.
  static const List<String> quotaStorageSignals = <String>[
    'quota_match',
    'refresh_failure',
    'stale_data',
    'partial_total',
    'unit_issue',
    'local_scan',
    'false_precision',
  ];

  /// The charter's declared observation window, in minutes: 42 days.
  static const int charterWindowMinutes = 42 * 24 * 60;

  /// The committed evidence source registered for each canonical signal, in
  /// canonical-signal order.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
    'docs/planning/v1.2/sprint_115_provider_quota_adapters.json',
    'docs/planning/v1.2/sprint_115_cloud_storage_aggregation.json',
    'docs/planning/v1.3/sprint_117_cloud_storage_quota_validation.json',
    'docs/planning/v1.2/sprint_115_storage_usage_cards.json',
    'docs/planning/v1.2/sprint_115_local_storage_summary.json',
    'docs/planning/v1.2/sprint_116_local_storage_certification.json',
  ];

  /// The distinct union of the committed quota/storage witness vocabularies, in
  /// witness order.
  static List<String> stateVocabulary(List<List<String>> vocabularies) {
    final seen = <String>{};
    final result = <String>[];
    for (final vocabulary in vocabularies) {
      for (final state in vocabulary) {
        if (seen.add(state)) result.add(state);
      }
    }
    return result;
  }

  /// The evidence source registered for a canonical signal.
  static String sourceFor(String signal) {
    final index = quotaStorageSignals.indexOf(signal);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical review, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry declares a reference and observes nothing. Each
  /// reference state is drawn from the committed quota contract (116.41), the
  /// committed provider quota adapter witness (115), the committed local storage
  /// summary witness (115), or the committed cloud storage aggregation witness
  /// (115).
  static const Sprint118QuotaStorageHealthReview
  canonicalReview = Sprint118QuotaStorageHealthReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118QuotaStorageHealthEntry>[
      Sprint118QuotaStorageHealthEntry(
        signal: 'quota_match',
        referenceState: 'raw_units',
        source:
            'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118QuotaStorageHealthEntry(
        signal: 'refresh_failure',
        referenceState: 'refresh',
        source: 'docs/planning/v1.2/sprint_115_provider_quota_adapters.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118QuotaStorageHealthEntry(
        signal: 'stale_data',
        referenceState: 'stale_indicator',
        source: 'docs/planning/v1.2/sprint_115_cloud_storage_aggregation.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118QuotaStorageHealthEntry(
        signal: 'partial_total',
        referenceState: 'partial_total',
        source:
            'docs/planning/v1.3/sprint_117_cloud_storage_quota_validation.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118QuotaStorageHealthEntry(
        signal: 'unit_issue',
        referenceState: 'display_units',
        source: 'docs/planning/v1.2/sprint_115_storage_usage_cards.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118QuotaStorageHealthEntry(
        signal: 'local_scan',
        referenceState: 'local_scan',
        source: 'docs/planning/v1.2/sprint_115_local_storage_summary.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118QuotaStorageHealthEntry(
        signal: 'false_precision',
        referenceState: 'no_false_precision',
        source:
            'docs/planning/v1.2/sprint_116_local_storage_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, and quota/storage
/// witnesses. Never invents: an unreadable witness yields `null`, which the gate
/// reports as blocked rather than as a pass.
class Sprint118QuotaStorageHealthLoader {
  const Sprint118QuotaStorageHealthLoader();

  Sprint118QuotaStorageHealthAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118QuotaStorageHealthContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118QuotaStorageHealthContract.charterManifestPath,
    );
    if (charter == null) return null;
    final quota = _readJsonObject(
      Sprint118QuotaStorageHealthContract.quotaContractManifestPath,
    );
    if (quota == null) return null;
    final adapter = _readJsonObject(
      Sprint118QuotaStorageHealthContract.quotaAdapterManifestPath,
    );
    if (adapter == null) return null;
    final localStorage = _readJsonObject(
      Sprint118QuotaStorageHealthContract.localStorageManifestPath,
    );
    if (localStorage == null) return null;
    final aggregation = _readJsonObject(
      Sprint118QuotaStorageHealthContract.aggregationManifestPath,
    );
    if (aggregation == null) return null;

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final charterWindowMinutes = durationDays > 0
        ? durationDays * 24 * 60
        : Sprint118QuotaStorageHealthContract.charterWindowMinutes;

    final readable = <String>[
      for (final source in Sprint118QuotaStorageHealthContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118QuotaStorageHealthAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: charterWindowMinutes,
      witnessQuotaAcceptance: _stringList(quota['required_acceptance']),
      witnessAdapterAcceptance: _stringList(adapter['acceptance']),
      witnessLocalAcceptance: _stringList(localStorage['acceptance']),
      witnessAggregationAcceptance: _stringList(aggregation['acceptance']),
      readableSources: readable,
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return <String>[
        for (final item in value)
          if (item is String) item,
      ];
    }
    return const <String>[];
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

class Sprint118QuotaStorageHealthGate {
  const Sprint118QuotaStorageHealthGate();

  /// Evaluate the canonical review against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118QuotaStorageHealthReport evaluate() => evaluateWith(
    const Sprint118QuotaStorageHealthLoader().loadAnchor(),
    Sprint118QuotaStorageHealthContract.canonicalReview,
  );

  Sprint118QuotaStorageHealthReport evaluateWith(
    Sprint118QuotaStorageHealthAnchor? anchor,
    Sprint118QuotaStorageHealthReview review,
  ) {
    if (anchor == null) {
      return Sprint118QuotaStorageHealthReport(
        state: Sprint118QuotaStorageHealthState.blocked,
        verdict: 'SPRINT_118_QUOTA_STORAGE_HEALTH_EVIDENCE_UNREADABLE',
        releaseState: review.releaseState,
        missingFields: List<String>.from(
          Sprint118QuotaStorageHealthContract.requiredFields,
        ),
        blockers: const <String>['committed_quota_storage_evidence_unreadable'],
        openItems: const <String>[
          'committed_quota_storage_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A review
    // written against an unfrozen baseline describes quota readings nobody
    // measured.
    if (anchor.baselineState !=
            Sprint118QuotaStorageHealthContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118QuotaStorageHealthContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be complete. A review bound to an
    // incomplete charter has no declared window to respect.
    if (anchor.charterState !=
            Sprint118QuotaStorageHealthContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118QuotaStorageHealthContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The release state must agree with the baseline anchor.
    if (anchor.releaseState != review.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'review=${review.releaseState}',
      );
    }

    // (4) On the delayed path no signal may claim an observation: with no
    // release, an observation describes a provider quota reading never fetched.
    final delayed =
        review.releaseState ==
        Sprint118QuotaStorageHealthContract.delayedReleaseState;
    if (delayed) {
      for (final entry in review.entries) {
        if (entry.observed) {
          violations.add(
            'quota_claims_observation_without_release:${entry.signal}',
          );
        }
      }
    }

    // (5) The committed witness vocabulary must be present, so the review has
    // something to draw its reference states from.
    final witnessIncomplete =
        anchor.witnessQuotaAcceptance.isEmpty ||
        anchor.witnessAdapterAcceptance.isEmpty ||
        anchor.witnessLocalAcceptance.isEmpty ||
        anchor.witnessAggregationAcceptance.isEmpty;
    if (witnessIncomplete) {
      blockers.add('upstream_quota_vocabulary_missing');
    }
    final vocabulary =
        Sprint118QuotaStorageHealthContract.stateVocabulary(<List<String>>[
          anchor.witnessQuotaAcceptance,
          anchor.witnessAdapterAcceptance,
          anchor.witnessLocalAcceptance,
          anchor.witnessAggregationAcceptance,
        ]);

    // (6) Every canonical signal must be present exactly once, and each entry
    // must carry its declared fields.
    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.signal] = (declared[entry.signal] ?? 0) + 1;
    }
    for (final entry in review.entries) {
      final signal = entry.signal;
      if (!Sprint118QuotaStorageHealthContract.quotaStorageSignals.contains(
        signal,
      )) {
        violations.add('signal_unknown:$signal');
      }
      if (entry.referenceState.trim().isEmpty) {
        violations.add('entry_blank_reference_state:$signal');
      }
      if (entry.source.trim().isEmpty) {
        violations.add('entry_blank_source:$signal');
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
      // A reference state is judged against the witness vocabulary unless the
      // witness is silent, in which case the review is blocked upstream rather
      // than failed.
      if (entry.referenceState.trim().isNotEmpty && !witnessIncomplete) {
        if (!vocabulary.contains(entry.referenceState)) {
          violations.add(
            'entry_unknown_reference_state:$signal:${entry.referenceState}',
          );
        }
      }
      if (entry.source.trim().isNotEmpty &&
          !anchor.readableSources.contains(entry.source)) {
        violations.add('entry_unreadable_source:$signal:${entry.source}');
      }
    }
    for (final signal in declared.keys) {
      if (declared[signal]! > 1) {
        violations.add('signal_duplicate:$signal');
      }
    }
    for (final signal
        in Sprint118QuotaStorageHealthContract.quotaStorageSignals) {
      if (!declared.containsKey(signal)) {
        violations.add('signal_missing:$signal');
      }
    }

    // (7) Every committed review-evidence source must be readable.
    for (final source in Sprint118QuotaStorageHealthContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final signals = review.signals;

    if (violations.isNotEmpty) {
      return Sprint118QuotaStorageHealthReport(
        state: Sprint118QuotaStorageHealthState.fail,
        verdict: 'SPRINT_118_QUOTA_STORAGE_HEALTH_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118QuotaStorageHealthReport(
        state: Sprint118QuotaStorageHealthState.blocked,
        verdict: 'SPRINT_118_QUOTA_STORAGE_HEALTH_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    return Sprint118QuotaStorageHealthReport(
      state: Sprint118QuotaStorageHealthState.pass,
      verdict: 'QUOTA_STORAGE_HEALTH_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allOpen,
      declaredSignals: signals,
      observedCount: review.observedCount,
    );
  }
}
