/// Fail-closed rollout progression decision for roadmap step 118.27 --
/// Rollout Progression Decision.
///
/// Objective (external canonical `sprint_118.json`): decide expand, hold,
/// reduce, disable connector, or rollback from health evidence. The canonical
/// decision list is exactly five items: `EXPAND`, `HOLD`, `REDUCE`,
/// `DISABLE_CONNECTOR`, and `ROLLBACK`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze a 42-day window that is declared
/// and not executed, the 118.4 baseline froze a declared reference for each
/// health area without observing anything, and the committed 117.45 approval
/// gate records `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`. No live rollout was
/// ever executed (117.44 `live_rollout_executed=false`). A progression decision
/// written against that state therefore has exactly one honest shape: enumerate
/// every canonical decision option, anchor each to committed health evidence,
/// and select `HOLD`, observing nothing live.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`) and the 118.2
///   charter must be complete with a positive window. A decision anchored to an
///   unfrozen baseline or an incomplete charter describes a release nobody
///   recorded.
/// * The committed 118.26 maintenance regression matrix must be a genuine pass
///   (`MAINTENANCE_REGRESSION_MATRIX_VERIFIED_LOCAL`). A progression decision
///   with no committed regression evidence is a guess.
/// * The committed 118.25 connector-disable review must be a genuine pass
///   (`CONNECTOR_DISABLE_SAFE_DEGRADATION_VERIFIED_LOCAL`). A decision to
///   disable a connector is only as honest as the committed disable path.
/// * The committed 117.45 approval gate must be readable and must record the
///   delay decision (`decision == delay`). The decision is read with the owner's
///   exact grammar, never case-folded or trimmed into agreement. If the approval
///   gate is not a delay, the progression-decision anchor is untrustworthy and
///   the honest answer is `blocked`, not `fail`.
/// * Every canonical decision option must be present exactly once. A record that
///   drops `REDUCE`, invents a `TELEPATHY` option, or duplicates `HOLD` is not a
///   decision.
/// * Every entry must carry a non-empty detail, a reference state drawn from the
///   committed witness vocabularies, a committed readable source, and at least
///   one limitation, so the record states the rollout path it was written under
///   instead of implying live availability.
/// * On the delayed path a live rollout, a live rollback, a live connector
///   disable, a live expansion, or an authorized release execution describe
///   behavior that never ran. This is refused by name, per entry.
///
/// **A rollout progression decision is never made without a live rollout.** When
/// no live rollout has executed, the only decision the evidence supports is
/// `HOLD`; any other selection is refused by name.
///
/// The decision vocabulary is the five-item canonical list, the reference-state
/// vocabulary is *derived from committed witnesses* (the 117.44 rollout-plan
/// `required_fields`, the 117.8 rollback-drill `required_controls`, the 118.25
/// connector-disable `required_acceptance`, the 118.26 regression
/// `required_suites`, and the 118.4 baseline `canonical_areas`), and the source
/// for each option is a committed manifest, not copied by hand, so the decision
/// and its witnesses cannot drift apart silently.
///
/// Live rollout execution, expansion, reduction, connector disable, rollback,
/// release authorization, and publication remain `DEFERRED-EXTERNAL`; this
/// decision freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a progression decision can rest in. `blocked` is the honest
/// resting state for "this decision cannot yet be trusted", and it is distinct
/// from `fail`, which means the decision contradicts its own evidence.
enum Sprint118RolloutProgressionState { pass, fail, blocked }

/// The five canonical rollout progression decisions declared by external
/// canonical step 118.27. Each carries the exact wire name the canonical source
/// declares, so the decision is never compared with a loosened grammar.
enum Sprint118RolloutDecision {
  expand('EXPAND'),
  hold('HOLD'),
  reduce('REDUCE'),
  disableConnector('DISABLE_CONNECTOR'),
  rollback('ROLLBACK');

  const Sprint118RolloutDecision(this.wireName);

  /// The exact canonical wire name.
  final String wireName;

  /// Resolves a canonical wire name to its decision, or `null` when the name is
  /// not one of the five canonical options.
  static Sprint118RolloutDecision? fromWire(String wire) {
    for (final decision in Sprint118RolloutDecision.values) {
      if (decision.wireName == wire) return decision;
    }
    return null;
  }
}

/// One frozen progression-decision entry: the declared reference for a single
/// canonical decision option, with the rollout path it was frozen under.
///
/// `expansionClaimed`, `rollbackClaimed`, `connectorDisableClaimed`, and
/// `observed` are deliberately *not* among the five required fields; they are
/// the flags the gate refuses when set, so that a reference decision option can
/// be recorded while never being read as a live expansion, a live rollback, a
/// live connector disable, or a live observation.
class Sprint118RolloutProgressionEntry {
  const Sprint118RolloutProgressionEntry({
    required this.decision,
    required this.referenceState,
    required this.source,
    required this.detail,
    required this.limitations,
    this.expansionClaimed = false,
    this.rollbackClaimed = false,
    this.connectorDisableClaimed = false,
    this.observed = false,
  });

  /// The canonical decision option, drawn from the five-item vocabulary.
  final String decision;

  /// The declared reference state, drawn from the committed witness
  /// vocabularies.
  final String referenceState;

  /// The committed evidence file this entry is anchored to.
  final String source;

  /// A non-empty description of the rollout path this entry freezes.
  final String detail;

  /// The limitations the entry was frozen under. At least one is required so the
  /// entry cannot imply live availability.
  final List<String> limitations;

  /// Whether the entry claims a live expansion. On the delayed path this must
  /// stay `false`: a rollout is never expanded without a release.
  final bool expansionClaimed;

  /// Whether the entry claims a live rollback. On the delayed path this must stay
  /// `false`: nothing rolled back a rollout that never ran.
  final bool rollbackClaimed;

  /// Whether the entry claims a live connector disable. On the delayed path this
  /// must stay `false`.
  final bool connectorDisableClaimed;

  /// Whether the entry claims a live observation. On the delayed path this must
  /// stay `false`.
  final bool observed;

  /// The five required fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'decision': decision,
    'reference_state': referenceState,
    'source': source,
    'detail': detail,
    'limitations': limitations.join(','),
  };
}

/// The frozen progression decision. `entries` is the declared reference for each
/// canonical decision option; `selectedDecision` is the one option the evidence
/// supports. On the delayed path no entry may claim an observation and the
/// selected decision must be `HOLD`.
class Sprint118RolloutProgressionDecision {
  const Sprint118RolloutProgressionDecision({
    required this.releaseState,
    required this.selectedDecision,
    required this.entries,
  });

  final String releaseState;
  final Sprint118RolloutDecision selectedDecision;
  final List<Sprint118RolloutProgressionEntry> entries;

  List<String> get decisionItems => <String>[
    for (final entry in entries) entry.decision,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed witnesses actually say. A decision is only as honest as
/// the witnesses it is anchored to.
class Sprint118RolloutProgressionAnchor {
  const Sprint118RolloutProgressionAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.regressionState,
    required this.regressionVerdict,
    required this.disableState,
    required this.disableVerdict,
    required this.approvalDecision,
    required this.approvalState,
    required this.executionAuthorized,
    required this.releaseBlocked,
    required this.liveRolloutExecuted,
    required this.rolloutFields,
    required this.drillControls,
    required this.disableAcceptance,
    required this.regressionSuites,
    required this.baselineAreas,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;
  final String regressionState;
  final String regressionVerdict;
  final String disableState;
  final String disableVerdict;

  /// The decision the committed 117.45 approval gate records, read with the
  /// owner's exact grammar (never case-folded or trimmed).
  final String approvalDecision;

  /// The approval state the committed 117.45 approval gate records.
  final String approvalState;

  /// Whether the committed 117.45 approval gate authorizes execution. On the
  /// delayed path this must stay `false`.
  final bool executionAuthorized;

  /// Whether the committed 117.45 approval gate records the release as blocked.
  final bool releaseBlocked;

  /// Whether the committed 117.44 rollout plan claims an executed rollout. On
  /// the delayed path this must stay `false`.
  final bool liveRolloutExecuted;

  /// The field vocabulary the committed 117.44 rollout plan declares.
  final List<String> rolloutFields;

  /// The control vocabulary the committed 117.8 rollback drill declares.
  final List<String> drillControls;

  /// The acceptance vocabulary the committed 118.25 connector-disable review
  /// declares.
  final List<String> disableAcceptance;

  /// The suite vocabulary the committed 118.26 regression matrix declares.
  final List<String> regressionSuites;

  /// The area vocabulary the committed 118.4 baseline declares.
  final List<String> baselineAreas;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the decision is a faithful freeze;
/// `blocked` means it cannot yet be trusted; `fail` means it contradicts its
/// evidence.
class Sprint118RolloutProgressionReport {
  const Sprint118RolloutProgressionReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.selectedDecision,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredDecisions = const <String>[],
    this.observedCount = 0,
  });

  final Sprint118RolloutProgressionState state;
  final String verdict;
  final String releaseState;

  /// The selected decision wire name, or `null` when the decision is not a
  /// genuine pass.
  final String? selectedDecision;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredDecisions;
  final int observedCount;

  /// Whether the decision may be treated as a frozen record. Only a genuine
  /// `pass` allows it.
  bool get decisionVerified => state == Sprint118RolloutProgressionState.pass;

  String get externalGates => Sprint118RolloutProgressionContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.27.
abstract final class Sprint118RolloutProgressionContract {
  const Sprint118RolloutProgressionContract._();

  static const String canonicalStep = '118.27';
  static const String title = 'Rollout Progression Decision';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_rollout_progression_decision.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this decision is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter this decision is anchored to.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.26 maintenance regression matrix this decision rests on.
  static const String regressionManifestPath =
      'docs/planning/v1.3/sprint_118_maintenance_regression_matrix.json';

  /// The committed 118.25 connector-disable review this decision rests on.
  static const String connectorDisableManifestPath =
      'docs/planning/v1.3/sprint_118_connector_disable_safe_degradation.json';

  /// The committed 117.45 approval gate that records the delay decision.
  static const String approvalGateManifestPath =
      'docs/planning/v1.3/sprint_117_ga_approval_gate.json';

  /// The committed 117.44 rollout plan that declares the rollout fields and the
  /// live-rollout signal.
  static const String rolloutPlanManifestPath =
      'docs/planning/v1.3/sprint_117_staged_ga_rollout_plan.json';

  /// The committed 117.8 provider rollback drill that declares the control
  /// vocabulary.
  static const String rollbackDrillManifestPath =
      'docs/planning/v1.3/sprint_117_provider_rollback_drill.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  /// The verdict and state the 118.26 regression matrix anchor must carry.
  static const String requiredRegressionVerdict =
      'MAINTENANCE_REGRESSION_MATRIX_VERIFIED_LOCAL';
  static const String requiredRegressionState = 'pass';

  /// The verdict and state the 118.25 connector-disable anchor must carry.
  static const String requiredDisableVerdict =
      'CONNECTOR_DISABLE_SAFE_DEGRADATION_VERIFIED_LOCAL';
  static const String requiredDisableState = 'pass';

  /// The decision the committed 117.45 approval gate must record. Read with the
  /// owner's exact grammar, never case-folded.
  static const String requiredApprovalDecision = 'delay';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The marker an entry declares when no committed witness names a reference
  /// state for its decision option. A record that uses it records an honest
  /// upstream gap rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The five canonical decision options declared by external canonical step
  /// 118.27, in canonical order.
  static const List<String> requiredDecisions = <String>[
    'EXPAND',
    'HOLD',
    'REDUCE',
    'DISABLE_CONNECTOR',
    'ROLLBACK',
  ];

  /// The canonical field set each entry must carry, so a decision cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'decision',
    'reference_state',
    'source',
    'detail',
    'limitations',
  ];

  /// The committed evidence file each canonical decision option is anchored to.
  static const List<String> canonicalSources = <String>[
    rolloutPlanManifestPath,
    approvalGateManifestPath,
    rolloutPlanManifestPath,
    connectorDisableManifestPath,
    rollbackDrillManifestPath,
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

  /// Whether a committed witness vocabulary grounds a reference-state token.
  ///
  /// A witness grounds a token when it names the token exactly (`exposure`,
  /// `artifact_rollback`), or when every underscore-separated part of a compound
  /// token is itself a witness-declared value (`per_connector_kill_switch` is
  /// grounded because the witnesses declare `per`, `connector`, and
  /// `kill_switch`... only when every part is present). The vocabulary is
  /// measured from the committed witnesses, so a reference state cannot be
  /// invented into the list without a witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed source for a canonical decision option, or `''` if unknown.
  static String sourceFor(String decision) {
    final index = requiredDecisions.indexOf(decision);
    return index < 0 ? '' : canonicalSources[index];
  }

  static const canonicalDecision = Sprint118RolloutProgressionDecision(
    releaseState: delayedReleaseState,
    selectedDecision: Sprint118RolloutDecision.hold,
    entries: <Sprint118RolloutProgressionEntry>[
      Sprint118RolloutProgressionEntry(
        decision: 'EXPAND',
        referenceState: 'exposure',
        source: rolloutPlanManifestPath,
        detail:
            'Expansion would raise the exposed connector subset and exposure '
            'percentage per the committed rollout plan, and is deferred until a '
            'release is authorized',
        limitations: <String>['live_expansion_deferred', 'synthetic_local'],
      ),
      Sprint118RolloutProgressionEntry(
        decision: 'HOLD',
        referenceState: 'stop_conditions',
        source: approvalGateManifestPath,
        detail:
            'The committed approval gate records a delay and blocked release, '
            'so the rollout is held at its declared state with nothing running',
        limitations: <String>['live_rollout_deferred', 'synthetic_local'],
      ),
      Sprint118RolloutProgressionEntry(
        decision: 'REDUCE',
        referenceState: 'connector_subset',
        source: rolloutPlanManifestPath,
        detail:
            'Reduction would shrink the exposed connector subset per the '
            'committed rollout plan, and is deferred while no rollout runs',
        limitations: <String>['live_reduction_deferred', 'synthetic_local'],
      ),
      Sprint118RolloutProgressionEntry(
        decision: 'DISABLE_CONNECTOR',
        referenceState: 'kill_switch',
        source: connectorDisableManifestPath,
        detail:
            'Disabling a connector uses the committed per-connector kill switch '
            'and safe-degradation path, and is deferred until a release',
        limitations: <String>[
          'live_connector_disable_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118RolloutProgressionEntry(
        decision: 'ROLLBACK',
        referenceState: 'artifact_rollback',
        source: rollbackDrillManifestPath,
        detail:
            'Rollback would restore the committed artifacts and connector state '
            'per the rollback drill, and is deferred because no rollout ran',
        limitations: <String>['live_rollback_deferred', 'synthetic_local'],
      ),
    ],
  );
}

/// Reads the committed witnesses for step 118.27. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118RolloutProgressionLoader {
  const Sprint118RolloutProgressionLoader();

  Sprint118RolloutProgressionAnchor? loadAnchor() {
    final baseline = _read(
      Sprint118RolloutProgressionContract.baselineManifestPath,
    );
    final charter = _read(
      Sprint118RolloutProgressionContract.charterManifestPath,
    );
    final regression = _read(
      Sprint118RolloutProgressionContract.regressionManifestPath,
    );
    final disable = _read(
      Sprint118RolloutProgressionContract.connectorDisableManifestPath,
    );
    final approval = _read(
      Sprint118RolloutProgressionContract.approvalGateManifestPath,
    );
    final rollout = _read(
      Sprint118RolloutProgressionContract.rolloutPlanManifestPath,
    );
    final drill = _read(
      Sprint118RolloutProgressionContract.rollbackDrillManifestPath,
    );
    if (baseline == null ||
        charter == null ||
        regression == null ||
        disable == null ||
        approval == null ||
        rollout == null ||
        drill == null) {
      return null;
    }

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);

    final approvalMap = approval['approval'];
    final approvalInner = approvalMap is Map<String, dynamic>
        ? approvalMap
        : const <String, dynamic>{};
    final blockerMap = approval['blocker_status'];
    final blockerInner = blockerMap is Map<String, dynamic>
        ? blockerMap
        : const <String, dynamic>{};

    final sources = <String>{
      Sprint118RolloutProgressionContract.baselineManifestPath,
      Sprint118RolloutProgressionContract.charterManifestPath,
      Sprint118RolloutProgressionContract.regressionManifestPath,
      Sprint118RolloutProgressionContract.connectorDisableManifestPath,
      Sprint118RolloutProgressionContract.approvalGateManifestPath,
      Sprint118RolloutProgressionContract.rolloutPlanManifestPath,
      Sprint118RolloutProgressionContract.rollbackDrillManifestPath,
    };

    return Sprint118RolloutProgressionAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: durationDays > 0 ? durationDays * 24 * 60 : 0,
      regressionState: _text(regression['state']),
      regressionVerdict: _text(regression['verdict']),
      disableState: _text(disable['state']),
      disableVerdict: _text(disable['verdict']),
      approvalDecision: _text(approvalInner['decision']),
      approvalState: _text(approvalInner['approval_state']),
      executionAuthorized: approvalInner['execution_authorized'] == true,
      releaseBlocked: blockerInner['release_blocked'] == true,
      liveRolloutExecuted: rollout['live_rollout_executed'] == true,
      rolloutFields: _strings(rollout['required_fields']),
      drillControls: _strings(drill['required_controls']),
      disableAcceptance: _strings(disable['required_acceptance']),
      regressionSuites: _strings(regression['required_suites']),
      baselineAreas: _strings(baseline['canonical_areas']),
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

/// The fail-closed rollout progression decision gate for step 118.27.
class Sprint118RolloutProgressionGate {
  const Sprint118RolloutProgressionGate();

  Sprint118RolloutProgressionReport evaluate() => evaluateWith(
    const Sprint118RolloutProgressionLoader().loadAnchor(),
    Sprint118RolloutProgressionContract.canonicalDecision,
  );

  Sprint118RolloutProgressionReport evaluateWith(
    Sprint118RolloutProgressionAnchor? anchor,
    Sprint118RolloutProgressionDecision decision,
  ) {
    if (anchor == null) {
      return Sprint118RolloutProgressionReport(
        state: Sprint118RolloutProgressionState.blocked,
        verdict: 'SPRINT_118_ROLLOUT_PROGRESSION_EVIDENCE_UNREADABLE',
        releaseState: decision.releaseState,
        blockers: const <String>[
          'committed_rollout_progression_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_rollout_progression_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    final vocabulary =
        Sprint118RolloutProgressionContract.stateVocabulary(<List<String>>[
          anchor.rolloutFields,
          anchor.drillControls,
          anchor.disableAcceptance,
          anchor.regressionSuites,
          anchor.baselineAreas,
        ]);

    // (1) The 118.4 baseline anchor must be a genuine frozen pass.
    if (anchor.baselineState !=
            Sprint118RolloutProgressionContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118RolloutProgressionContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint118RolloutProgressionContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118RolloutProgressionContract.requiredCharterVerdict ||
        anchor.charterWindowMinutes <= 0) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The 118.26 regression matrix must be a genuine pass. A progression
    // decision with no committed regression evidence is a guess.
    if (anchor.regressionState !=
            Sprint118RolloutProgressionContract.requiredRegressionState ||
        anchor.regressionVerdict !=
            Sprint118RolloutProgressionContract.requiredRegressionVerdict) {
      blockers.add(
        'regression_matrix_not_verified:${anchor.regressionVerdict}',
      );
    }

    // (4) The 118.25 connector-disable review must be a genuine pass.
    if (anchor.disableState !=
            Sprint118RolloutProgressionContract.requiredDisableState ||
        anchor.disableVerdict !=
            Sprint118RolloutProgressionContract.requiredDisableVerdict) {
      blockers.add('connector_disable_not_verified:${anchor.disableVerdict}');
    }

    // (5) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118RolloutProgressionContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (6) The release state must agree with the baseline anchor.
    if (anchor.releaseState != decision.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'decision=${decision.releaseState}',
      );
    }

    final delayed =
        decision.releaseState ==
        Sprint118RolloutProgressionContract.delayedReleaseState;

    // (7) On the delayed path a live rollout, an authorized release execution,
    // and an unblocked release are all behavior that never ran.
    if (delayed && anchor.liveRolloutExecuted) {
      violations.add('live_rollout_claimed_on_delayed_path');
    }
    if (delayed && anchor.executionAuthorized) {
      violations.add('release_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('release_not_blocked_on_delayed_path');
    }

    // (8) Every canonical decision option must be present exactly once, and each
    // entry must carry all five required fields non-blank, a reference state
    // drawn from a committed witness, a committed readable source, and at least
    // one limitation.
    final declared = <String, int>{};
    for (final entry in decision.entries) {
      declared[entry.decision] = (declared[entry.decision] ?? 0) + 1;
    }
    for (final entry in decision.entries) {
      final token = entry.decision;
      if (!Sprint118RolloutProgressionContract.requiredDecisions.contains(
        token,
      )) {
        violations.add('decision_unknown:$token');
      }
      for (final field in Sprint118RolloutProgressionContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$token');
        }
      }
      if (entry.referenceState.trim().isEmpty ||
          !Sprint118RolloutProgressionContract.grounds(
            vocabulary,
            entry.referenceState,
          )) {
        violations.add('reference_state_invalid:$token');
      }
      if (entry.referenceState ==
          Sprint118RolloutProgressionContract.noReferenceState) {
        openItems.add('upstream_state_vocabulary_gap:$token');
      }
      if (entry.source.trim().isEmpty ||
          !anchor.readableSources.contains(entry.source)) {
        violations.add('source_unreadable:$token');
      }
      // A rollout is never expanded without a release.
      if (entry.expansionClaimed) {
        violations.add('expansion_claimed_without_release:$token');
      }
      // Nothing rolled back a rollout that never ran.
      if (entry.rollbackClaimed) {
        violations.add('rollback_claimed_without_live_rollout:$token');
      }
      // A connector is never disabled without a release.
      if (entry.connectorDisableClaimed) {
        violations.add('connector_disable_claimed_without_release:$token');
      }
      // No live observation on the delayed path.
      if (entry.observed) {
        violations.add('live_observation_claimed:$token');
      }
    }
    for (final token in declared.keys) {
      if (declared[token]! > 1) {
        violations.add('decision_duplicate:$token');
      }
    }
    for (final token in Sprint118RolloutProgressionContract.requiredDecisions) {
      if (!declared.containsKey(token)) {
        violations.add('decision_missing:$token');
      }
    }

    // (9) A rollout progression decision is never made without a live rollout.
    // When no live rollout has executed, the only decision the evidence supports
    // is HOLD; any other selection describes an action that never ran.
    if (!anchor.liveRolloutExecuted &&
        decision.selectedDecision != Sprint118RolloutDecision.hold) {
      violations.add(
        'progression_decision_without_live_rollout:'
        '${decision.selectedDecision.wireName}',
      );
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118RolloutProgressionContract.canonicalSources.toSet()) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('required_source_unreadable:$source');
      }
    }

    final allItems = <String>[...violations, ...blockers, ...openItems];
    final decisions = decision.decisionItems;

    // An untrustworthy anchor short-circuits: if a committed witness is not a
    // genuine pass, the entry-level findings cannot be trusted either, so the
    // honest answer is `blocked`, not `fail`.
    if (blockers.isNotEmpty) {
      return Sprint118RolloutProgressionReport(
        state: Sprint118RolloutProgressionState.blocked,
        verdict: 'SPRINT_118_ROLLOUT_PROGRESSION_BLOCKED_UPSTREAM',
        releaseState: decision.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredDecisions: decisions,
        observedCount: decision.observedCount,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118RolloutProgressionReport(
        state: Sprint118RolloutProgressionState.fail,
        verdict: 'SPRINT_118_ROLLOUT_PROGRESSION_EVIDENCE_VIOLATION',
        releaseState: decision.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredDecisions: decisions,
        observedCount: decision.observedCount,
      );
    }
    return Sprint118RolloutProgressionReport(
      state: Sprint118RolloutProgressionState.pass,
      verdict: 'ROLLOUT_PROGRESSION_DECISION_VERIFIED_LOCAL',
      releaseState: decision.releaseState,
      selectedDecision: decision.selectedDecision.wireName,
      openItems: allItems,
      declaredDecisions: decisions,
      observedCount: decision.observedCount,
    );
  }
}
