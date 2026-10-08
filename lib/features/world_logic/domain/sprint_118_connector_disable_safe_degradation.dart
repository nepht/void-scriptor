/// Fail-closed connector-disable and safe-degradation review for roadmap step
/// 118.25 -- Connector Disable & Safe Degradation.
///
/// Objective (external canonical `sprint_118.json`): make sure a misbehaving
/// connector can be turned off without damaging the Account Center or local
/// data. The canonical acceptance list is exactly six items:
/// `per_connector_kill_switch`, `safe_queue_stop`, `cached_state`,
/// `local_data_preserved`, `user_message`, and `recovery_path`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze a 42-day window that is declared
/// and not executed, and the 118.4 baseline froze a declared reference for each
/// health area without observing anything. A disable-and-degrade review written
/// against that state therefore has exactly one honest shape: declare a
/// reference for each of the six canonical acceptance items, anchored to
/// committed evidence, and observe nothing live.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`) and the 118.2
///   charter must be complete with a positive window. A review anchored to an
///   unfrozen baseline or an incomplete charter describes a release nobody
///   recorded.
/// * The committed 117.8 provider rollback drill must be a genuine pass
///   (`PROVIDER_ROLLBACK_DRILL_DEFINED_LOCAL`) with a non-empty control
///   vocabulary. A disable path with no committed control set is not a path.
/// * The committed 116.50 staged beta rollout must not claim an executed
///   rollout (`live_rollout_executed == false`). On the delayed path a live
///   rollout is a disable that never ran.
/// * Every canonical acceptance item must be present exactly once. A review that
///   drops `recovery_path`, invents a `telepathy` item, or duplicates
///   `cached_state` is not a review.
/// * No entry may claim a live connector disable, a touched local data store, a
///   sent user message, or a live observation: on the delayed path those
///   describe behavior that never ran. This is refused by name, per item.
/// * Every entry must carry a non-empty detail, a reference state drawn from the
///   committed witness vocabularies, a committed readable source, and at least
///   one limitation, so the review states the disable path it was written under
///   instead of implying live availability.
///
/// **A connector is never claimed disabled without a release.** Every entry
/// declares whether it claims a live disable, and the gate refuses any entry
/// that does. **A disable never touches local data.** Every entry declares
/// whether local data was touched, and the gate refuses any entry that says so.
///
/// The acceptance vocabulary is the six-item canonical list, the reference-state
/// vocabulary is *derived from committed witnesses* (the 117.8 rollback-drill
/// `required_controls`, the 118.17 outage-recovery `canonical_signals`, the
/// 115.43 token-expiry `acceptance`, the 116.44 offline-cached-metadata
/// `acceptance_areas`, and the 116.50 rollout `required_fields`), and the source
/// for each item is a committed manifest, not copied by hand, so the review and
/// its witnesses cannot drift apart silently.
///
/// Live connector disable, queue stop, cache invalidation, user messaging,
/// recovery execution, connector certification, provider exposure, release
/// authorization, and publication remain `DEFERRED-EXTERNAL`; this review
/// freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a disable review can rest in. `blocked` is the honest
/// resting state for "this review cannot yet be trusted", and it is distinct
/// from `fail`, which means the review contradicts its own evidence.
enum Sprint118ConnectorDisableState { pass, fail, blocked }

/// One frozen disable-review entry: the declared reference for a single
/// canonical acceptance item, with the disable path it was frozen under.
///
/// `connectorDisabled`, `localDataTouched`, `messageSent`, and `observed` are
/// deliberately *not* among the five required fields; they are the flags the
/// gate refuses when set, so that a reference disable path can be recorded
/// while never being read as a live disable, a local-data touch, a sent message,
/// or a live observation.
class Sprint118ConnectorDisableEntry {
  const Sprint118ConnectorDisableEntry({
    required this.acceptance,
    required this.referenceState,
    required this.source,
    required this.detail,
    required this.limitations,
    this.connectorDisabled = false,
    this.localDataTouched = false,
    this.messageSent = false,
    this.observed = false,
  });

  /// The canonical acceptance item, drawn from the six-item vocabulary.
  final String acceptance;

  /// The declared reference state, drawn from the committed witness
  /// vocabularies.
  final String referenceState;

  /// The committed evidence file this entry is anchored to.
  final String source;

  /// A non-empty description of the disable path this entry freezes.
  final String detail;

  /// The limitations the entry was frozen under. At least one is required so the
  /// entry cannot imply live availability.
  final List<String> limitations;

  /// Whether the entry claims a live connector disable. On the delayed path this
  /// must stay `false`: a connector is never claimed disabled without a release.
  final bool connectorDisabled;

  /// Whether the entry claims local data was touched. Must stay `false`: a
  /// disable never damages local data.
  final bool localDataTouched;

  /// Whether the entry claims a user message was sent live. On the delayed path
  /// this must stay `false`.
  final bool messageSent;

  /// Whether the entry claims a live observation. On the delayed path this must
  /// stay `false`.
  final bool observed;

  /// The five required fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'acceptance': acceptance,
    'reference_state': referenceState,
    'source': source,
    'detail': detail,
    'limitations': limitations.join(','),
  };
}

/// The frozen disable review. `entries` is the declared reference for each
/// canonical acceptance item; on the delayed path no entry may claim an
/// observation.
class Sprint118ConnectorDisableReview {
  const Sprint118ConnectorDisableReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118ConnectorDisableEntry> entries;

  List<String> get acceptanceItems => <String>[
    for (final entry in entries) entry.acceptance,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed witnesses actually say. A review is only as honest as the
/// witnesses it is anchored to.
class Sprint118ConnectorDisableAnchor {
  const Sprint118ConnectorDisableAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.drillState,
    required this.drillVerdict,
    required this.drillControls,
    required this.rolloutLiveExecuted,
    required this.outageSignals,
    required this.reauthAcceptance,
    required this.cachedAcceptance,
    required this.rolloutFields,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;
  final String drillState;
  final String drillVerdict;

  /// The control vocabulary the committed 117.8 rollback drill declares.
  final List<String> drillControls;

  /// Whether the committed 116.50 rollout witness claims an executed rollout.
  /// On the delayed path this must stay `false`.
  final bool rolloutLiveExecuted;

  /// The signal vocabulary the committed 118.17 outage-recovery review declares.
  final List<String> outageSignals;

  /// The acceptance vocabulary the committed 115.43 token-expiry UX declares.
  final List<String> reauthAcceptance;

  /// The acceptance vocabulary the committed 116.44 offline-cached-metadata
  /// certification declares.
  final List<String> cachedAcceptance;

  /// The field vocabulary the committed 116.50 rollout witness declares.
  final List<String> rolloutFields;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118ConnectorDisableReport {
  const Sprint118ConnectorDisableReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredAcceptance = const <String>[],
    this.observedCount = 0,
  });

  final Sprint118ConnectorDisableState state;
  final String verdict;
  final String releaseState;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredAcceptance;
  final int observedCount;

  /// Whether the review may be treated as a frozen record. Only a genuine `pass`
  /// allows it.
  bool get reviewVerified => state == Sprint118ConnectorDisableState.pass;

  String get externalGates => Sprint118ConnectorDisableContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.25.
abstract final class Sprint118ConnectorDisableContract {
  const Sprint118ConnectorDisableContract._();

  static const String canonicalStep = '118.25';
  static const String title = 'Connector Disable & Safe Degradation';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_connector_disable_safe_degradation.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this review is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter this review is anchored to.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 117.8 provider rollback drill witness that declares the
  /// control vocabulary and the kill-switch/queue-stop controls.
  static const String drillManifestPath =
      'docs/planning/v1.3/sprint_117_provider_rollback_drill.json';

  /// The committed 116.50 staged beta rollout witness that declares the
  /// kill-switch scope, the communication templates, and the live-rollout
  /// signal.
  static const String rolloutManifestPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';

  /// The committed 118.17 provider outage recovery review that declares the
  /// cached-state/kill-switch/queue-recovery signal vocabulary.
  static const String outageReviewManifestPath =
      'docs/planning/v1.3/sprint_118_provider_outage_recovery_review.json';

  /// The committed 115.43 token-expiry UX witness that declares the
  /// local-data-preserved acceptance vocabulary.
  static const String tokenExpiryManifestPath =
      'docs/planning/v1.2/sprint_115_token_expiry_reauthentication_ux.json';

  /// The committed 116.44 offline cached-metadata certification witness that
  /// declares the stale-state/cache-clear acceptance vocabulary.
  static const String cachedMetadataManifestPath =
      'docs/planning/v1.2/sprint_116_offline_cached_metadata_certification.json';

  /// The committed 117.6 support incident readiness witness that declares the
  /// recovery-guide path.
  static const String readinessManifestPath =
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  /// The verdict and state the 117.8 rollback drill witness must carry.
  static const String requiredDrillVerdict =
      'PROVIDER_ROLLBACK_DRILL_DEFINED_LOCAL';
  static const String requiredDrillState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The marker an entry declares when no committed witness names a reference
  /// state for its acceptance item. A review that uses it records an honest
  /// upstream gap rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The six canonical acceptance items declared by external canonical step
  /// 118.25.
  static const List<String> requiredAcceptance = <String>[
    'per_connector_kill_switch',
    'safe_queue_stop',
    'cached_state',
    'local_data_preserved',
    'user_message',
    'recovery_path',
  ];

  /// The canonical field set each entry must carry, so a review cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'acceptance',
    'reference_state',
    'source',
    'detail',
    'limitations',
  ];

  /// The committed evidence file each canonical item is anchored to.
  static const List<String> canonicalSources = <String>[
    drillManifestPath,
    drillManifestPath,
    cachedMetadataManifestPath,
    tokenExpiryManifestPath,
    rolloutManifestPath,
    readinessManifestPath,
  ];

  /// Union of the committed witness vocabularies, de-duplicated in first-seen
  /// order, plus the honest no-reference marker. The reference states are
  /// derived from the witnesses rather than copied into a live reader.
  static List<String> stateVocabulary(List<List<String>> vocabularies) {
    final seen = <String>{};
    final result = <String>[];
    for (final vocabulary in vocabularies) {
      for (final value in vocabulary) {
        if (seen.add(value)) result.add(value);
      }
    }
    if (seen.add(noReferenceState)) result.add(noReferenceState);
    return result;
  }

  /// The committed source for a canonical acceptance item, or `''` if unknown.
  static String sourceFor(String acceptance) {
    final index = requiredAcceptance.indexOf(acceptance);
    return index < 0 ? '' : canonicalSources[index];
  }

  static const canonicalReview = Sprint118ConnectorDisableReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118ConnectorDisableEntry>[
      Sprint118ConnectorDisableEntry(
        acceptance: 'per_connector_kill_switch',
        referenceState: 'kill_switch',
        source: drillManifestPath,
        detail:
            'A misbehaving connector is disabled by its own kill switch '
            'without affecting the Account Center',
        limitations: <String>[
          'live_connector_disable_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118ConnectorDisableEntry(
        acceptance: 'safe_queue_stop',
        referenceState: 'queue_stop',
        source: drillManifestPath,
        detail:
            'Queued connector work is stopped safely instead of running while '
            'a connector is disabled',
        limitations: <String>['live_queue_stop_deferred', 'synthetic_local'],
      ),
      Sprint118ConnectorDisableEntry(
        acceptance: 'cached_state',
        referenceState: 'cached_state',
        source: cachedMetadataManifestPath,
        detail:
            'Disabling a connector keeps its cached state readable and labeled '
            'stale rather than deleting it',
        limitations: <String>[
          'live_cache_invalidation_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118ConnectorDisableEntry(
        acceptance: 'local_data_preserved',
        referenceState: 'local_data_preserved',
        source: tokenExpiryManifestPath,
        detail:
            'Disabling a connector never touches local project data or the '
            'Account Center',
        limitations: <String>['live_local_scan_deferred', 'synthetic_local'],
      ),
      Sprint118ConnectorDisableEntry(
        acceptance: 'user_message',
        referenceState: 'communication',
        source: rolloutManifestPath,
        detail:
            'The disable is explained to the user through a committed message '
            'template rather than silent failure',
        limitations: <String>['live_message_send_deferred', 'synthetic_local'],
      ),
      Sprint118ConnectorDisableEntry(
        acceptance: 'recovery_path',
        referenceState: 'artifact_rollback',
        source: readinessManifestPath,
        detail:
            'A committed recovery path exists so the connector can be restored '
            'after the disable',
        limitations: <String>[
          'live_recovery_execution_deferred',
          'synthetic_local',
        ],
      ),
    ],
  );
}

/// Reads the committed witnesses for step 118.25. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118ConnectorDisableLoader {
  const Sprint118ConnectorDisableLoader();

  Sprint118ConnectorDisableAnchor? loadAnchor() {
    final baseline = _read(
      Sprint118ConnectorDisableContract.baselineManifestPath,
    );
    final charter = _read(
      Sprint118ConnectorDisableContract.charterManifestPath,
    );
    final drill = _read(Sprint118ConnectorDisableContract.drillManifestPath);
    final rollout = _read(
      Sprint118ConnectorDisableContract.rolloutManifestPath,
    );
    final outage = _read(
      Sprint118ConnectorDisableContract.outageReviewManifestPath,
    );
    final tokenExpiry = _read(
      Sprint118ConnectorDisableContract.tokenExpiryManifestPath,
    );
    final cached = _read(
      Sprint118ConnectorDisableContract.cachedMetadataManifestPath,
    );
    final readiness = _read(
      Sprint118ConnectorDisableContract.readinessManifestPath,
    );
    if (baseline == null ||
        charter == null ||
        drill == null ||
        rollout == null ||
        outage == null ||
        tokenExpiry == null ||
        cached == null ||
        readiness == null) {
      return null;
    }

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);

    final sources = <String>{
      Sprint118ConnectorDisableContract.baselineManifestPath,
      Sprint118ConnectorDisableContract.charterManifestPath,
      Sprint118ConnectorDisableContract.drillManifestPath,
      Sprint118ConnectorDisableContract.rolloutManifestPath,
      Sprint118ConnectorDisableContract.outageReviewManifestPath,
      Sprint118ConnectorDisableContract.tokenExpiryManifestPath,
      Sprint118ConnectorDisableContract.cachedMetadataManifestPath,
      Sprint118ConnectorDisableContract.readinessManifestPath,
    };

    return Sprint118ConnectorDisableAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: durationDays > 0 ? durationDays * 24 * 60 : 0,
      drillState: _text(drill['state']),
      drillVerdict: _text(drill['verdict']),
      drillControls: _strings(drill['required_controls']),
      rolloutLiveExecuted: rollout['live_rollout_executed'] == true,
      outageSignals: _strings(outage['canonical_signals']),
      reauthAcceptance: _strings(tokenExpiry['acceptance']),
      cachedAcceptance: _strings(cached['acceptance_areas']),
      rolloutFields: _strings(rollout['required_fields']),
      readableSources: <String>[
        for (final path in sources)
          if (File(path).existsSync()) path,
      ],
    );
  }

  static Map<String, dynamic>? _read(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final value = jsonDecode(file.readAsStringSync());
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  static List<String> _strings(Object? value) => value is List
      ? <String>[
          for (final item in value)
            if (item is String) item,
        ]
      : const <String>[];

  static int _int(Object? value) => value is int ? value : 0;
}

/// The fail-closed connector-disable review gate for step 118.25.
class Sprint118ConnectorDisableGate {
  const Sprint118ConnectorDisableGate();

  Sprint118ConnectorDisableReport evaluate() => evaluateWith(
    const Sprint118ConnectorDisableLoader().loadAnchor(),
    Sprint118ConnectorDisableContract.canonicalReview,
  );

  Sprint118ConnectorDisableReport evaluateWith(
    Sprint118ConnectorDisableAnchor? anchor,
    Sprint118ConnectorDisableReview review,
  ) {
    if (anchor == null) {
      return Sprint118ConnectorDisableReport(
        state: Sprint118ConnectorDisableState.blocked,
        verdict: 'SPRINT_118_CONNECTOR_DISABLE_EVIDENCE_UNREADABLE',
        releaseState: review.releaseState,
        blockers: const <String>[
          'committed_connector_disable_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_connector_disable_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    final vocabulary =
        Sprint118ConnectorDisableContract.stateVocabulary(<List<String>>[
          anchor.drillControls,
          anchor.outageSignals,
          anchor.reauthAcceptance,
          anchor.cachedAcceptance,
          anchor.rolloutFields,
        ]);

    // (1) The 118.4 baseline anchor must be a genuine frozen pass.
    if (anchor.baselineState !=
            Sprint118ConnectorDisableContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118ConnectorDisableContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint118ConnectorDisableContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118ConnectorDisableContract.requiredCharterVerdict ||
        anchor.charterWindowMinutes <= 0) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The 117.8 rollback drill witness must be a genuine pass. A disable
    // path with no committed control set is not a path.
    if (anchor.drillState !=
            Sprint118ConnectorDisableContract.requiredDrillState ||
        anchor.drillVerdict !=
            Sprint118ConnectorDisableContract.requiredDrillVerdict) {
      blockers.add('rollback_drill_not_defined:${anchor.drillVerdict}');
    }
    if (anchor.drillControls.isEmpty) {
      blockers.add('rollback_drill_controls_missing');
    }

    // (4) The release state must agree with the baseline anchor.
    if (anchor.releaseState != review.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'review=${review.releaseState}',
      );
    }

    // (5) On the delayed path a live rollout is a disable that never ran.
    final delayed =
        review.releaseState ==
        Sprint118ConnectorDisableContract.delayedReleaseState;
    if (delayed && anchor.rolloutLiveExecuted) {
      violations.add('rollout_claimed_live_on_delayed_path');
    }

    // (6) Every canonical acceptance item must be present exactly once, and each
    // entry must carry all five required fields non-blank, a reference state
    // drawn from a committed witness, a committed readable source, and at least
    // one limitation.
    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.acceptance] = (declared[entry.acceptance] ?? 0) + 1;
    }
    for (final entry in review.entries) {
      final acceptance = entry.acceptance;
      if (!Sprint118ConnectorDisableContract.requiredAcceptance.contains(
        acceptance,
      )) {
        violations.add('acceptance_unknown:$acceptance');
      }
      for (final field in Sprint118ConnectorDisableContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$acceptance');
        }
      }
      if (entry.referenceState.trim().isEmpty ||
          !vocabulary.contains(entry.referenceState)) {
        violations.add('reference_state_invalid:$acceptance');
      }
      if (entry.referenceState ==
          Sprint118ConnectorDisableContract.noReferenceState) {
        openItems.add('upstream_state_vocabulary_gap:$acceptance');
      }
      if (entry.source.trim().isEmpty ||
          !anchor.readableSources.contains(entry.source)) {
        violations.add('source_unreadable:$acceptance');
      }
      // A connector is never claimed disabled without a release.
      if (entry.connectorDisabled) {
        violations.add('connector_disable_claimed_without_release:$acceptance');
      }
      // A disable never touches local data.
      if (entry.localDataTouched) {
        violations.add('local_data_touched_by_disable:$acceptance');
      }
      // A user message is never claimed sent live on the delayed path.
      if (entry.messageSent) {
        violations.add('user_message_claimed_sent_without_release:$acceptance');
      }
      // No live observation on the delayed path.
      if (entry.observed) {
        violations.add('live_observation_claimed:$acceptance');
      }
    }
    for (final acceptance in declared.keys) {
      if (declared[acceptance]! > 1) {
        violations.add('acceptance_duplicate:$acceptance');
      }
    }
    for (final acceptance
        in Sprint118ConnectorDisableContract.requiredAcceptance) {
      if (!declared.containsKey(acceptance)) {
        violations.add('acceptance_missing:$acceptance');
      }
    }

    // (8) Every committed evidence source must be readable.
    for (final source
        in Sprint118ConnectorDisableContract.canonicalSources.toSet()) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('required_source_unreadable:$source');
      }
    }

    final allItems = <String>[...violations, ...blockers, ...openItems];
    final acceptanceItems = review.acceptanceItems;

    // An untrustworthy anchor short-circuits: if a committed witness is not a
    // genuine pass, the entry-level findings cannot be trusted either, so the
    // honest answer is `blocked`, not `fail`.
    if (blockers.isNotEmpty) {
      return Sprint118ConnectorDisableReport(
        state: Sprint118ConnectorDisableState.blocked,
        verdict: 'SPRINT_118_CONNECTOR_DISABLE_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredAcceptance: acceptanceItems,
        observedCount: review.observedCount,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118ConnectorDisableReport(
        state: Sprint118ConnectorDisableState.fail,
        verdict: 'SPRINT_118_CONNECTOR_DISABLE_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredAcceptance: acceptanceItems,
        observedCount: review.observedCount,
      );
    }
    return Sprint118ConnectorDisableReport(
      state: Sprint118ConnectorDisableState.pass,
      verdict: 'CONNECTOR_DISABLE_SAFE_DEGRADATION_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allItems,
      declaredAcceptance: acceptanceItems,
      observedCount: review.observedCount,
    );
  }
}
