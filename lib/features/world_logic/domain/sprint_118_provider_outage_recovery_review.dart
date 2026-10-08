/// Fail-closed provider outage & recovery review for roadmap step 118.17 --
/// Provider Outage & Recovery Review.
///
/// Objective (external canonical `sprint_118.json`): monitor timeout, circuit
/// breaker, retry-after, queue recovery, cached states, kill switch, and
/// provider recovery. The canonical signal list is exactly seven items:
/// `timeout`, `circuit_breaker`, `retry_after`, `queue_recovery`,
/// `cached_state`, `kill_switch`, and `provider_recovery`.
///
/// This is the review the delayed corrective path (Sprint 118 on `GA_DELAYED`)
/// registers *before* any live observation runs. The gate answers a single
/// question: does the declared review carry, for every canonical outage signal,
/// a reference state drawn from the committed outage/recovery witnesses, a
/// committed readable evidence source, a positive window bounded by the
/// charter, and a stated limitation -- while claiming no live observation?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A review built on
///   a baseline that did not freeze describes outage readings nobody measured.
/// * The committed 118.2 charter anchor must be complete
///   (`CHARTER_COMPLETE_LOCAL`); the review is bound to the charter's declared
///   observation window.
/// * The review's release state must agree with the baseline anchor.
/// * On the delayed path no signal may claim an observation: with no release, an
///   observation describes a live outage, a real breaker trip, a real retry-after
///   header, or a real queue drain that was never observed. Refused by name, per
///   signal.
/// * Every canonical signal must be present exactly once, must carry a
///   non-blank reference state, a committed readable source, a positive window
///   no larger than the charter window, and at least one stated limitation.
/// * Every reference state must be drawn from the committed 116.43 retry,
///   backoff & circuit breaker certification, the committed 114.25 provider &
///   external dependency health, the committed 114.18 offline & local-first
///   health, the committed 117.8 provider rollback drill, and the committed
///   116.44 offline & cached metadata certification, so the review and the
///   outage/recovery contracts cannot drift apart.
///
/// All seven canonical signals have a witness state, so no `no_reference_state`
/// marker is needed and no upstream gap is recorded: `timeout` and
/// `provider_recovery` draw from the 114.25 provider & external dependency
/// health (`timeout`, `fallback_success`), `circuit_breaker` and `retry_after`
/// from the 116.43 retry, backoff & circuit breaker certification,
/// `queue_recovery` from the 114.18 offline & local-first health, `cached_state`
/// from the 116.44 offline & cached metadata certification (`stale_state`), and
/// `kill_switch` from the 117.8 provider rollback drill. The marker remains
/// available for any signal the witnesses cannot yet name.
///
/// Live provider outage injection, real circuit-breaker trips, live retry-after
/// header reads, real queue drain/restart, live kill-switch engagement, release
/// authorization, and publication remain `DEFERRED-EXTERNAL`; this review
/// freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a provider outage & recovery review can rest in. `blocked`
/// is the honest resting state for "this review cannot yet be trusted", and it
/// is distinct from `fail`, which means the review contradicts its own evidence.
enum Sprint118ProviderOutageRecoveryState { pass, fail, blocked }

/// One outage/recovery entry: the declared reference for a single canonical
/// signal, with the boundary it was frozen under.
class Sprint118ProviderOutageRecoveryEntry {
  const Sprint118ProviderOutageRecoveryEntry({
    required this.signal,
    required this.referenceState,
    required this.source,
    required this.window,
    required this.limitations,
    this.observed = false,
  });

  /// The outage/recovery signal, drawn from the canonical signal vocabulary.
  final String signal;

  /// The declared reference state, drawn from the committed outage/recovery
  /// witness vocabulary, or the declared `no_reference_state` marker when the
  /// witness declares no state for this signal.
  final String referenceState;

  /// The committed evidence file this reference is anchored to.
  final String source;

  /// The measurement window in minutes.
  final int window;

  /// The limitations the reference was frozen under. At least one is required so
  /// the review cannot imply live outages, breaker trips, or queue drains.
  final List<String> limitations;

  /// Whether the entry claims an observed value. On the delayed path this must
  /// stay `false`.
  final bool observed;
}

/// The declared review. `entries` is the review surface for the delayed
/// corrective path; on that path no entry may claim an observation.
class Sprint118ProviderOutageRecoveryReview {
  const Sprint118ProviderOutageRecoveryReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118ProviderOutageRecoveryEntry> entries;

  List<String> get signals => <String>[
    for (final entry in entries) entry.signal,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed 118.4 baseline, 118.2 charter, and outage/recovery
/// witnesses actually say. A review is only as honest as the witnesses it reads.
class Sprint118ProviderOutageRecoveryAnchor {
  const Sprint118ProviderOutageRecoveryAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.witnessRetryBackoffCircuitBreaker,
    required this.witnessProviderDependency,
    required this.witnessOfflineLocalFirst,
    required this.witnessRollbackDrill,
    required this.witnessOfflineCachedMetadata,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;

  /// The acceptance areas the committed 116.43 retry, backoff & circuit breaker
  /// certification declares.
  final List<String> witnessRetryBackoffCircuitBreaker;

  /// The signals the committed 114.25 provider & external dependency health
  /// declares.
  final List<String> witnessProviderDependency;

  /// The required evidence the committed 114.18 offline & local-first health
  /// declares.
  final List<String> witnessOfflineLocalFirst;

  /// The required controls the committed 117.8 provider rollback drill
  /// declares.
  final List<String> witnessRollbackDrill;

  /// The acceptance areas the committed 116.44 offline & cached metadata
  /// certification declares.
  final List<String> witnessOfflineCachedMetadata;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is well-formed; `blocked` means
/// it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118ProviderOutageRecoveryReport {
  const Sprint118ProviderOutageRecoveryReport({
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

  final Sprint118ProviderOutageRecoveryState state;
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
  bool get reviewVerified => state == Sprint118ProviderOutageRecoveryState.pass;

  String get externalGates =>
      Sprint118ProviderOutageRecoveryContract.externalGates;
}

/// The fixed vocabulary of step 118.17, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118ProviderOutageRecoveryContract {
  const Sprint118ProviderOutageRecoveryContract._();

  static const String canonicalStep = '118.17';
  static const String title = 'Provider Outage & Recovery Review';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_provider_outage_recovery_review.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this review is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter that declares the observation window.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 116.43 retry, backoff & circuit breaker certification that
  /// declares the retry, backoff, and breaker acceptance areas this review
  /// references.
  static const String retryBackoffCircuitBreakerManifestPath =
      'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json';

  /// The committed 114.25 provider & external dependency health that declares
  /// the timeout, throttling, and fallback signals this review references.
  static const String providerDependencyManifestPath =
      'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json';

  /// The committed 114.18 offline & local-first health that declares the queue
  /// recovery evidence this review references.
  static const String offlineLocalFirstManifestPath =
      'docs/planning/v1.2/sprint_114_offline_local_first_health.json';

  /// The committed 117.8 provider rollback drill that declares the kill switch
  /// and cached-state controls this review references.
  static const String rollbackDrillManifestPath =
      'docs/planning/v1.3/sprint_117_provider_rollback_drill.json';

  /// The committed 116.44 offline & cached metadata certification that declares
  /// the stale cached-state acceptance area this review references.
  static const String offlineCachedMetadataManifestPath =
      'docs/planning/v1.2/sprint_116_offline_cached_metadata_certification.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The five canonical entry fields from `sprint_118.json` step 118.17.
  static const List<String> requiredFields = <String>[
    'signal',
    'reference_state',
    'source',
    'window',
    'limitations',
  ];

  /// The seven canonical outage/recovery signals the objective names.
  static const List<String> outageRecoverySignals = <String>[
    'timeout',
    'circuit_breaker',
    'retry_after',
    'queue_recovery',
    'cached_state',
    'kill_switch',
    'provider_recovery',
  ];

  /// The declared marker for a signal the committed outage/recovery witnesses
  /// have no state for. It is honest on the delayed path: it declares no
  /// reference state rather than inventing one.
  static const String noReferenceState = 'no_reference_state';

  /// The charter's declared observation window, in minutes: 42 days.
  static const int charterWindowMinutes = 42 * 24 * 60;

  /// The committed evidence source registered for each canonical signal, in
  /// canonical-signal order.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json',
    'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json',
    'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json',
    'docs/planning/v1.2/sprint_114_offline_local_first_health.json',
    'docs/planning/v1.2/sprint_116_offline_cached_metadata_certification.json',
    'docs/planning/v1.3/sprint_117_provider_rollback_drill.json',
    'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json',
  ];

  /// The distinct union of the committed outage/recovery witness vocabularies,
  /// in witness order.
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
    final index = outageRecoverySignals.indexOf(signal);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical review, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry declares a reference and observes nothing. Every one
  /// of the seven canonical signals draws its reference state from the committed
  /// outage/recovery witness vocabulary, so no `no_reference_state` marker is
  /// needed and no upstream gap is recorded.
  static const Sprint118ProviderOutageRecoveryReview
  canonicalReview = Sprint118ProviderOutageRecoveryReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118ProviderOutageRecoveryEntry>[
      Sprint118ProviderOutageRecoveryEntry(
        signal: 'timeout',
        referenceState: 'timeout',
        source:
            'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118ProviderOutageRecoveryEntry(
        signal: 'circuit_breaker',
        referenceState: 'circuit_breaker',
        source:
            'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118ProviderOutageRecoveryEntry(
        signal: 'retry_after',
        referenceState: 'retry_after',
        source:
            'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118ProviderOutageRecoveryEntry(
        signal: 'queue_recovery',
        referenceState: 'queue_recovery',
        source: 'docs/planning/v1.2/sprint_114_offline_local_first_health.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118ProviderOutageRecoveryEntry(
        signal: 'cached_state',
        referenceState: 'stale_state',
        source:
            'docs/planning/v1.2/sprint_116_offline_cached_metadata_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118ProviderOutageRecoveryEntry(
        signal: 'kill_switch',
        referenceState: 'kill_switch',
        source: 'docs/planning/v1.3/sprint_117_provider_rollback_drill.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118ProviderOutageRecoveryEntry(
        signal: 'provider_recovery',
        referenceState: 'fallback_success',
        source:
            'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, and outage/recovery
/// witnesses. Never invents: an unreadable witness yields `null`, which the gate
/// reports as blocked rather than as a pass.
class Sprint118ProviderOutageRecoveryLoader {
  const Sprint118ProviderOutageRecoveryLoader();

  Sprint118ProviderOutageRecoveryAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118ProviderOutageRecoveryContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118ProviderOutageRecoveryContract.charterManifestPath,
    );
    if (charter == null) return null;
    final retryBackoff = _readJsonObject(
      Sprint118ProviderOutageRecoveryContract
          .retryBackoffCircuitBreakerManifestPath,
    );
    if (retryBackoff == null) return null;
    final providerDependency = _readJsonObject(
      Sprint118ProviderOutageRecoveryContract.providerDependencyManifestPath,
    );
    if (providerDependency == null) return null;
    final offlineLocalFirst = _readJsonObject(
      Sprint118ProviderOutageRecoveryContract.offlineLocalFirstManifestPath,
    );
    if (offlineLocalFirst == null) return null;
    final rollbackDrill = _readJsonObject(
      Sprint118ProviderOutageRecoveryContract.rollbackDrillManifestPath,
    );
    if (rollbackDrill == null) return null;
    final offlineCachedMetadata = _readJsonObject(
      Sprint118ProviderOutageRecoveryContract.offlineCachedMetadataManifestPath,
    );
    if (offlineCachedMetadata == null) return null;

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final charterWindowMinutes = durationDays > 0
        ? durationDays * 24 * 60
        : Sprint118ProviderOutageRecoveryContract.charterWindowMinutes;

    final readable = <String>[
      for (final source
          in Sprint118ProviderOutageRecoveryContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118ProviderOutageRecoveryAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: charterWindowMinutes,
      witnessRetryBackoffCircuitBreaker: _stringList(
        retryBackoff['acceptance_areas'],
      ),
      witnessProviderDependency: _stringList(providerDependency['signals']),
      witnessOfflineLocalFirst: _stringList(
        offlineLocalFirst['required_evidence'],
      ),
      witnessRollbackDrill: _stringList(rollbackDrill['required_controls']),
      witnessOfflineCachedMetadata: _stringList(
        offlineCachedMetadata['acceptance_areas'],
      ),
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

class Sprint118ProviderOutageRecoveryGate {
  const Sprint118ProviderOutageRecoveryGate();

  /// Evaluate the canonical review against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118ProviderOutageRecoveryReport evaluate() => evaluateWith(
    const Sprint118ProviderOutageRecoveryLoader().loadAnchor(),
    Sprint118ProviderOutageRecoveryContract.canonicalReview,
  );

  Sprint118ProviderOutageRecoveryReport evaluateWith(
    Sprint118ProviderOutageRecoveryAnchor? anchor,
    Sprint118ProviderOutageRecoveryReview review,
  ) {
    if (anchor == null) {
      return Sprint118ProviderOutageRecoveryReport(
        state: Sprint118ProviderOutageRecoveryState.blocked,
        verdict: 'SPRINT_118_PROVIDER_OUTAGE_RECOVERY_EVIDENCE_UNREADABLE',
        releaseState: review.releaseState,
        missingFields: List<String>.from(
          Sprint118ProviderOutageRecoveryContract.requiredFields,
        ),
        blockers: const <String>[
          'committed_provider_outage_recovery_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_provider_outage_recovery_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A review
    // written against an unfrozen baseline describes outage readings nobody
    // measured.
    if (anchor.baselineState !=
            Sprint118ProviderOutageRecoveryContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118ProviderOutageRecoveryContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be complete. A review bound to an
    // incomplete charter has no declared window to respect.
    if (anchor.charterState !=
            Sprint118ProviderOutageRecoveryContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118ProviderOutageRecoveryContract.requiredCharterVerdict) {
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
    // release, an observation describes a live outage, a real breaker trip, a
    // real retry-after header, or a real queue drain that was never observed.
    final delayed =
        review.releaseState ==
        Sprint118ProviderOutageRecoveryContract.delayedReleaseState;
    if (delayed) {
      for (final entry in review.entries) {
        if (entry.observed) {
          violations.add(
            'outage_claims_observation_without_release:${entry.signal}',
          );
        }
      }
    }

    // (5) The committed witness vocabulary must be present, so the review has
    // something to draw its reference states from.
    final witnessIncomplete =
        anchor.witnessRetryBackoffCircuitBreaker.isEmpty ||
        anchor.witnessProviderDependency.isEmpty ||
        anchor.witnessOfflineLocalFirst.isEmpty ||
        anchor.witnessRollbackDrill.isEmpty ||
        anchor.witnessOfflineCachedMetadata.isEmpty;
    if (witnessIncomplete) {
      blockers.add('upstream_outage_recovery_vocabulary_missing');
    }
    final vocabulary =
        Sprint118ProviderOutageRecoveryContract.stateVocabulary(<List<String>>[
          anchor.witnessRetryBackoffCircuitBreaker,
          anchor.witnessProviderDependency,
          anchor.witnessOfflineLocalFirst,
          anchor.witnessRollbackDrill,
          anchor.witnessOfflineCachedMetadata,
        ]);

    // (6) Every canonical signal must be present exactly once, and each entry
    // must carry its declared fields.
    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.signal] = (declared[entry.signal] ?? 0) + 1;
    }
    for (final entry in review.entries) {
      final signal = entry.signal;
      if (!Sprint118ProviderOutageRecoveryContract.outageRecoverySignals
          .contains(signal)) {
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
      // than failed. The declared `no_reference_state` marker records an honest
      // upstream gap instead of inventing a state.
      if (entry.referenceState.trim().isNotEmpty && !witnessIncomplete) {
        if (entry.referenceState ==
            Sprint118ProviderOutageRecoveryContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$signal');
        } else if (!vocabulary.contains(entry.referenceState)) {
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
        in Sprint118ProviderOutageRecoveryContract.outageRecoverySignals) {
      if (!declared.containsKey(signal)) {
        violations.add('signal_missing:$signal');
      }
    }

    // (7) Every committed review-evidence source must be readable.
    for (final source
        in Sprint118ProviderOutageRecoveryContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final signals = review.signals;

    if (violations.isNotEmpty) {
      return Sprint118ProviderOutageRecoveryReport(
        state: Sprint118ProviderOutageRecoveryState.fail,
        verdict: 'SPRINT_118_PROVIDER_OUTAGE_RECOVERY_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118ProviderOutageRecoveryReport(
        state: Sprint118ProviderOutageRecoveryState.blocked,
        verdict: 'SPRINT_118_PROVIDER_OUTAGE_RECOVERY_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    return Sprint118ProviderOutageRecoveryReport(
      state: Sprint118ProviderOutageRecoveryState.pass,
      verdict: 'PROVIDER_OUTAGE_RECOVERY_REVIEW_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allOpen,
      declaredSignals: signals,
      observedCount: review.observedCount,
    );
  }
}
