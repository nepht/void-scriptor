/// Canonical step 117.48 -- Sprint Closure.
///
/// Objective (external canonical JSON): close Sprint 117 after the GA/delay
/// decision and the observation handoff are recorded.
///
/// The seven canonical definition-of-done items are not a checklist to tick.
/// Each one is a claim about what the sprint actually established, so each one
/// has to be *read out of committed evidence* rather than typed into the
/// closure record. A closure that reports a completed beta window nobody ran,
/// or visible connectors that were never certified, is the exact way a sprint
/// closes on paper while nothing was released.
///
/// Three rules carry the weight:
///
/// * A criterion is `satisfied` only when a committed manifest says so. It is
///   `deferredExternal` when the criterion names something this repository
///   cannot establish locally (a live beta window, live connector visibility),
///   and `unmet` when the evidence contradicts the claim. Nothing is ever
///   promoted from deferred to satisfied by the passage of time.
/// * The closure is a *record of a delay decision*, never a claim of release.
///   117.45 records `DELAY` with `execution_authorized: false`, 117.41 records
///   zero CERTIFIED connectors, and 117.3 records zero verified participants.
///   `liveReleaseExecuted` is therefore structurally false.
/// * Two committed manifests that describe the same registry are recorded side
///   by side, never averaged. 117.4 froze a local certification chain
///   (`status_scope: local_certification_freeze_only`) while 117.41 reconciled
///   the shipped registry; where they disagree the disagreement is a named
///   open item for the operator, not a number this gate is allowed to pick.
///
/// Nothing here releases, publishes, tags, or pushes: those remain
/// [Sprint117ClosureContract.externalGates].
library;

import 'dart:convert';
import 'dart:io';

enum Sprint117ClosureState { pass, blocked, fail }

enum Sprint117ClosureDecision { closedLocalDeferredExternal, blocked }

/// How a canonical definition-of-done item stands against committed evidence.
enum Sprint117ClosureCriterionStatus { satisfied, deferredExternal, unmet }

/// One canonical definition-of-done item, with the evidence it was read from.
class Sprint117ClosureCriterion {
  const Sprint117ClosureCriterion({
    required this.name,
    required this.status,
    required this.evidence,
    required this.detail,
  });

  final String name;
  final Sprint117ClosureCriterionStatus status;

  /// Committed paths this criterion was read from. Empty evidence means the
  /// criterion was asserted, not measured, which the gate refuses.
  final List<String> evidence;
  final String detail;

  bool get satisfied => status == Sprint117ClosureCriterionStatus.satisfied;

  bool get deferred =>
      status == Sprint117ClosureCriterionStatus.deferredExternal;

  bool get unmet => status == Sprint117ClosureCriterionStatus.unmet;

  /// A criterion that is not `unmet` does not block a local closure; it is
  /// either established locally or explicitly owned by an external gate.
  bool get resolved => status != Sprint117ClosureCriterionStatus.unmet;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'status': status.name,
    'evidence': List<String>.from(evidence),
    'detail': detail,
  };
}

/// The committed evidence the closure is allowed to read from.
///
/// Every field is derived from a committed manifest by
/// [Sprint117ClosureLoader]; none of it is passed in by a caller.
class Sprint117ClosureEvidenceAnchor {
  Sprint117ClosureEvidenceAnchor({
    required this.entryState,
    required this.entryVerdict,
    required this.canonicalEntryReadiness,
    required this.canonicalEntryBlockResolved,
    required this.entryLiveBetaExecuted,
    required this.entryRegistryProviderCount,
    required this.charterState,
    required this.charterVerdict,
    required this.betaWindowStartMs,
    required this.betaWindowEndMs,
    required this.betaWindowDays,
    required this.betaWindowPhaseCount,
    required this.cohortState,
    required this.cohortVerdict,
    required this.verifiedCohortSize,
    required this.cohortLiveBetaExecuted,
    required this.certificationVerdict,
    required this.certificationScope,
    required this.lockedProviderCount,
    required this.lockedCertifiedCount,
    required this.lockedLimitedCount,
    required this.lockedBlockedCount,
    required this.matrixVerdict,
    required this.masterFlag,
    required this.matrixDefault,
    required this.matrixRowCount,
    required this.consentGateVerified,
    required List<String> enabledSubset,
    required List<String> determinedExposed,
    required this.registryVerdict,
    required this.registryProviderCount,
    required this.registryCertifiedCount,
    required this.registryUnverifiedCount,
    required this.registryWithheldCount,
    required this.registryExposedCount,
    required this.rolloutState,
    required this.rolloutVerdict,
    required this.rolloutStageCount,
    required this.rolloutDefault,
    required List<String> rolloutEnabledSubset,
    required this.rolloutKillSwitchCount,
    required this.rolloutKillSwitchDrilledCount,
    required this.rolloutRollbackCount,
    required this.rolloutRollbackVerifiedCount,
    required this.gaStatus,
    required this.gaDecision,
    required this.gaApprovalState,
    required this.gaExecutionAuthorized,
    required this.gaReleaseBlocked,
    required this.gaQualityGatesPresent,
    required List<String> gaQualityGateSources,
    required List<String> gaOpenItems,
    required this.handoffState,
    required this.handoffVerdict,
    required this.handoffResolvedOutputs,
    required this.handoffRequiredOutputs,
    required this.handoffViolationCount,
    required this.handoffLiveReleaseObserved,
    required this.ledgerPath,
  }) : enabledSubset = List<String>.unmodifiable(enabledSubset),
       determinedExposed = List<String>.unmodifiable(determinedExposed),
       rolloutEnabledSubset = List<String>.unmodifiable(rolloutEnabledSubset),
       gaQualityGateSources = List<String>.unmodifiable(gaQualityGateSources),
       gaOpenItems = List<String>.unmodifiable(gaOpenItems);

  // --- 117.1 beta entry gate ------------------------------------------------
  final String entryState;
  final String entryVerdict;

  /// The block the canonical document still carries; reported, never edited.
  final String canonicalEntryReadiness;
  final bool canonicalEntryBlockResolved;
  final bool entryLiveBetaExecuted;
  final int entryRegistryProviderCount;

  // --- 117.2 beta validation charter ---------------------------------------
  final String charterState;
  final String charterVerdict;
  final int betaWindowStartMs;
  final int betaWindowEndMs;
  final int betaWindowDays;
  final int betaWindowPhaseCount;

  // --- 117.3 beta cohort & consent -----------------------------------------
  final String cohortState;
  final String cohortVerdict;
  final int verifiedCohortSize;
  final bool cohortLiveBetaExecuted;

  // --- 117.4 certification snapshot lock -----------------------------------
  final String certificationVerdict;
  final String certificationScope;
  final int lockedProviderCount;
  final int lockedCertifiedCount;
  final int lockedLimitedCount;
  final int lockedBlockedCount;

  // --- 117.5 beta exposure & feature flag matrix ---------------------------
  final String matrixVerdict;
  final String masterFlag;
  final String matrixDefault;
  final int matrixRowCount;
  final bool consentGateVerified;
  final List<String> enabledSubset;
  final List<String> determinedExposed;

  // --- 117.41 final connector registry reconciliation ----------------------
  final String registryVerdict;
  final int registryProviderCount;
  final int registryCertifiedCount;
  final int registryUnverifiedCount;
  final int registryWithheldCount;
  final int registryExposedCount;

  // --- 117.44 staged GA rollout plan ---------------------------------------
  final String rolloutState;
  final String rolloutVerdict;
  final int rolloutStageCount;
  final String rolloutDefault;
  final List<String> rolloutEnabledSubset;
  final int rolloutKillSwitchCount;
  final int rolloutKillSwitchDrilledCount;
  final int rolloutRollbackCount;
  final int rolloutRollbackVerifiedCount;

  // --- 117.45 GA approval gate ---------------------------------------------
  final String gaStatus;
  final String gaDecision;
  final String gaApprovalState;
  final bool gaExecutionAuthorized;
  final bool gaReleaseBlocked;
  final bool gaQualityGatesPresent;
  final List<String> gaQualityGateSources;
  final List<String> gaOpenItems;

  // --- 117.47 post-release observation handoff -----------------------------
  final String handoffState;
  final String handoffVerdict;
  final int handoffResolvedOutputs;
  final int handoffRequiredOutputs;
  final int handoffViolationCount;
  final bool handoffLiveReleaseObserved;

  // --- ledger ---------------------------------------------------------------
  final String ledgerPath;

  /// A local closure never observes a live release.
  bool get liveReleaseExecuted => false;

  /// True when any committed source claims a live beta or a live release.
  bool get liveClaimRecorded =>
      entryLiveBetaExecuted ||
      cohortLiveBetaExecuted ||
      handoffLiveReleaseObserved;

  /// The providers any release would actually show: the enabled subset the
  /// exposure matrix and the rollout plan agree on. Empty means nothing is
  /// visible, which is a deferred external question, not a passed check.
  List<String> get visibleProviders => <String>[
    ...<String>{...enabledSubset, ...rolloutEnabledSubset},
  ];

  /// True when the two committed certification sources disagree on how many
  /// providers are certified. Both are legitimate and scope-limited; the
  /// disagreement is recorded, never resolved by this gate.
  bool get certificationSourcesDisagree =>
      lockedCertifiedCount != registryCertifiedCount;
}

class Sprint117ClosureInput {
  const Sprint117ClosureInput({this.anchor});

  final Sprint117ClosureEvidenceAnchor? anchor;
}

class Sprint117ClosureReport {
  Sprint117ClosureReport({
    required this.state,
    required this.decision,
    required this.verdict,
    required List<Sprint117ClosureCriterion> criteria,
    required List<String> missingEvidence,
    required List<String> violations,
    required List<String> openItems,
    required List<String> limitations,
    required this.releaseDecision,
    required this.releaseDecisionOwner,
    required this.summary,
    required this.anchor,
  }) : criteria = List<Sprint117ClosureCriterion>.unmodifiable(criteria),
       missingEvidence = List<String>.unmodifiable(missingEvidence),
       violations = List<String>.unmodifiable(violations),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations);

  final Sprint117ClosureState state;
  final Sprint117ClosureDecision decision;
  final String verdict;
  final List<Sprint117ClosureCriterion> criteria;
  final List<String> missingEvidence;
  final List<String> violations;
  final List<String> openItems;
  final List<String> limitations;
  final String releaseDecision;
  final String releaseDecisionOwner;
  final String summary;
  final Sprint117ClosureEvidenceAnchor? anchor;

  int get satisfiedCount =>
      criteria.where((criterion) => criterion.satisfied).length;

  int get deferredCount =>
      criteria.where((criterion) => criterion.deferred).length;

  List<String> get unmetCriteria => <String>[
    for (final criterion in criteria)
      if (criterion.unmet) criterion.name,
  ];

  List<String> get deferredCriteria => <String>[
    for (final criterion in criteria)
      if (criterion.deferred) criterion.name,
  ];

  bool get isClosed =>
      decision == Sprint117ClosureDecision.closedLocalDeferredExternal;

  String get externalGates => Sprint117ClosureContract.externalGates;

  /// A closure is never a live release, whatever the evidence says.
  bool get liveReleaseExecuted => false;

  Map<String, Object?> toJson() => <String, Object?>{
    'state': state.name,
    'decision': decision.name,
    'verdict': verdict,
    'release_decision': releaseDecision,
    'release_decision_owner': releaseDecisionOwner,
    'live_release_executed': liveReleaseExecuted,
    'criteria': <Map<String, Object?>>[
      for (final criterion in criteria) criterion.toJson(),
    ],
    'satisfied_count': satisfiedCount,
    'deferred_count': deferredCount,
    'unmet_criteria': List<String>.from(unmetCriteria),
    'deferred_criteria': List<String>.from(deferredCriteria),
    'missing_evidence': List<String>.from(missingEvidence),
    'violations': List<String>.from(violations),
    'external_gates': externalGates,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
    'summary': summary,
  };
}

abstract final class Sprint117ClosureContract {
  static const String canonicalStep = '117.48';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_sprint_closure.json';

  /// 117.1 supplies the entry gate state and the canonical block text.
  static const String entryGatePath =
      'docs/planning/v1.3/sprint_117_beta_entry_gate.json';

  /// 117.2 supplies the beta window.
  static const String charterPath =
      'docs/planning/v1.3/sprint_117_beta_validation_charter.json';

  /// 117.3 supplies the cohort verdict and the verified participant count.
  static const String cohortPath =
      'docs/planning/v1.3/sprint_117_beta_cohort_consent_verification.json';

  /// 117.4 supplies the frozen local certification chain.
  static const String certificationPath =
      'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json';

  /// 117.5 supplies the enabled subset and the exposure default.
  static const String matrixPath =
      'docs/planning/v1.3/sprint_117_beta_exposure_flag_matrix.json';

  /// 117.41 supplies the reconciled shipped registry.
  static const String registryPath =
      'docs/evidence/sprint-117-41-manifest-20261002.json';

  /// 117.44 supplies the staged rollout plan and its control state.
  static const String rolloutPath =
      'docs/planning/v1.3/sprint_117_staged_ga_rollout_plan.json';

  /// 117.45 supplies the recorded GA decision.
  static const String gaApprovalPath =
      'docs/planning/v1.3/sprint_117_ga_approval_gate.json';

  /// 117.47 supplies the observation handoff.
  static const String handoffPath =
      'docs/planning/v1.3/sprint_117_post_release_observation_handoff.json';

  /// The repository ledger: the human-readable record this closure cites.
  static const String ledgerPath = 'docs/sprints/sprint-117-beta-validation.md';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The seven definition-of-done items canonical step 117.48 names, in
  /// canonical order.
  static const List<String> criteriaNames = <String>[
    'entry_gate_passed',
    'beta_window_complete',
    'visible_connectors_certified_or_limited',
    'quality_gates_passed',
    'ga_decision_recorded',
    'staged_rollout_controlled',
    'observation_handoff_complete',
  ];

  static const String closedDecision = 'CLOSED_LOCAL_DEFERRED_EXTERNAL';
  static const String blockedDecision =
      'CLOSURE_BLOCKED_UNMET_DEFINITION_OF_DONE';

  static const String passVerdict = 'SPRINT_117_CLOSED_LOCAL_DEFERRED_EXTERNAL';
  static const String blockedVerdict =
      'SPRINT_117_CLOSURE_BLOCKED_UNMET_DEFINITION_OF_DONE';
  static const String failVerdict = 'SPRINT_117_CLOSURE_INCONSISTENT';

  /// The only release decision a local closure can record: the sprint closes
  /// after a delay, never after a release.
  static const String delayDecision = 'DELAY';

  static const List<String> knownReleaseDecisions = <String>[
    'DELAY',
    'RELEASE',
    'SUBSET_REDUCTION',
    'ROLLBACK',
  ];

  /// The manifests the loader must read before any criterion can be judged.
  static const List<String> sourceManifests = <String>[
    entryGatePath,
    charterPath,
    cohortPath,
    certificationPath,
    matrixPath,
    registryPath,
    rolloutPath,
    gaApprovalPath,
    handoffPath,
  ];
}

class Sprint117ClosureLoader {
  const Sprint117ClosureLoader();

  /// Read every source, or return `null`.
  ///
  /// A closure that cannot read one of its sources is not a closure with a
  /// missing footnote: it is a closure with an undetermined criterion. The
  /// gate turns `null` into `blocked`, never into `pass`.
  Sprint117ClosureEvidenceAnchor? load() {
    final entry = _readJsonObject(Sprint117ClosureContract.entryGatePath);
    final charter = _readJsonObject(Sprint117ClosureContract.charterPath);
    final cohort = _readJsonObject(Sprint117ClosureContract.cohortPath);
    final certification = _readJsonObject(
      Sprint117ClosureContract.certificationPath,
    );
    final matrix = _readJsonObject(Sprint117ClosureContract.matrixPath);
    final registry = _readJsonObject(Sprint117ClosureContract.registryPath);
    final rollout = _readJsonObject(Sprint117ClosureContract.rolloutPath);
    final ga = _readJsonObject(Sprint117ClosureContract.gaApprovalPath);
    final handoff = _readJsonObject(Sprint117ClosureContract.handoffPath);
    if (entry == null ||
        charter == null ||
        cohort == null ||
        certification == null ||
        matrix == null ||
        registry == null ||
        rollout == null ||
        ga == null ||
        handoff == null) {
      return null;
    }

    // 117.4 freezes the certification chain as a per-provider snapshot, so the
    // counts come from the rows themselves, never from `exposed_subset` --
    // that list is the set of providers the lock snapshotted, not a set of
    // certifications.
    var lockedCertified = 0;
    var lockedLimited = 0;
    var lockedBlocked = 0;
    final snapshot = certification['snapshot'];
    if (snapshot is List) {
      for (final raw in snapshot) {
        if (raw is! Map) continue;
        switch (_text(raw['status'])) {
          case 'CERTIFIED':
            lockedCertified++;
          case 'LIMITED':
            lockedLimited++;
          case 'BLOCKED':
            lockedBlocked++;
        }
      }
    }

    // 117.41 records aggregate status counts. A count that is absent stays 0
    // and is reported as 0, never inferred from a neighbouring key.
    final registryCounts = _intMap(registry['status_counts']);
    final registryVisibility = _intMap(registry['visibility_counts']);

    final gaApproval = ga['approval'] is Map
        ? Map<String, dynamic>.from(ga['approval'] as Map)
        : const <String, dynamic>{};
    final gaEvidence = ga['required_evidence'] is Map
        ? Map<String, dynamic>.from(ga['required_evidence'] as Map)
        : const <String, dynamic>{};
    final qualityGates = gaEvidence['quality_gates'] is Map
        ? Map<String, dynamic>.from(gaEvidence['quality_gates'] as Map)
        : const <String, dynamic>{};
    final blockerStatus = ga['blocker_status'] is Map
        ? Map<String, dynamic>.from(ga['blocker_status'] as Map)
        : const <String, dynamic>{};

    final window = charter['window'] is Map
        ? Map<String, dynamic>.from(charter['window'] as Map)
        : const <String, dynamic>{};
    final phases = window['phases'];

    var killSwitches = 0;
    var killSwitchesDrilled = 0;
    final rawKillSwitches = rollout['kill_switches'];
    if (rawKillSwitches is List) {
      for (final raw in rawKillSwitches) {
        if (raw is! Map) continue;
        killSwitches++;
        if (raw['drilled'] == true) killSwitchesDrilled++;
      }
    }

    var rollbackCount = 0;
    var rollbackVerified = 0;
    final rawRollback = rollout['rollback'];
    if (rawRollback is List) {
      for (final raw in rawRollback) {
        if (raw is! Map) continue;
        rollbackCount++;
        if (raw['verified'] == true) rollbackVerified++;
      }
    }

    return Sprint117ClosureEvidenceAnchor(
      entryState: _text(entry['state']),
      entryVerdict: _text(entry['verdict']),
      canonicalEntryReadiness: _text(entry['canonical_entry_readiness']),
      canonicalEntryBlockResolved:
          entry['canonical_entry_block_resolved'] == true,
      entryLiveBetaExecuted: entry['live_beta_executed'] == true,
      entryRegistryProviderCount: _int(entry['registry_provider_count']) ?? 0,
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      betaWindowStartMs: _int(window['start_epoch_ms']) ?? 0,
      betaWindowEndMs: _int(window['end_epoch_ms']) ?? 0,
      betaWindowDays: _int(window['duration_days']) ?? 0,
      betaWindowPhaseCount: phases is List ? phases.length : 0,
      cohortState: _text(cohort['state']),
      cohortVerdict: _text(cohort['verdict']),
      verifiedCohortSize: _int(cohort['verified_participant_count']) ?? 0,
      cohortLiveBetaExecuted: cohort['live_beta_executed'] == true,
      certificationVerdict: _text(certification['verdict']),
      certificationScope: _text(certification['status_scope']),
      lockedProviderCount: _int(certification['locked_provider_count']) ?? 0,
      lockedCertifiedCount: lockedCertified,
      lockedLimitedCount: lockedLimited,
      lockedBlockedCount: lockedBlocked,
      matrixVerdict: _text(matrix['verdict']),
      masterFlag: _text(matrix['master_flag']),
      matrixDefault: _text(matrix['recorded_default']),
      matrixRowCount: _int(matrix['row_count']) ?? 0,
      consentGateVerified: matrix['consent_gate_verified'] == true,
      enabledSubset: _stringList(matrix['enabled_subset']),
      determinedExposed: _stringList(matrix['determined_exposed']),
      registryVerdict: _text(registry['verdict']),
      registryProviderCount: _int(registry['provider_count']) ?? 0,
      registryCertifiedCount: registryCounts['CERTIFIED'] ?? 0,
      registryUnverifiedCount: registryCounts['UNVERIFIED'] ?? 0,
      registryWithheldCount: registryVisibility['WITHHELD'] ?? 0,
      registryExposedCount: registryVisibility['EXPOSED'] ?? 0,
      rolloutState: _text(rollout['state']),
      rolloutVerdict: _text(rollout['verdict']),
      rolloutStageCount: _int(rollout['stage_count']) ?? 0,
      rolloutDefault: _text(rollout['recorded_default']),
      rolloutEnabledSubset: _stringList(rollout['enabled_subset']),
      rolloutKillSwitchCount: killSwitches,
      rolloutKillSwitchDrilledCount: killSwitchesDrilled,
      rolloutRollbackCount: rollbackCount,
      rolloutRollbackVerifiedCount: rollbackVerified,
      gaStatus: _text(ga['status']),
      gaDecision: _text(ga['decision']),
      gaApprovalState: _text(gaApproval['approval_state']),
      gaExecutionAuthorized: gaApproval['execution_authorized'] == true,
      gaReleaseBlocked: blockerStatus['release_blocked'] == true,
      gaQualityGatesPresent: qualityGates['present'] == true,
      gaQualityGateSources: _stringList(qualityGates['sources']),
      gaOpenItems: _stringList(blockerStatus['open_items']),
      handoffState: _text(handoff['state']),
      handoffVerdict: _text(handoff['verdict']),
      handoffResolvedOutputs: _int(handoff['resolved_outputs']) ?? 0,
      handoffRequiredOutputs: handoff['required_outputs'] is List
          ? (handoff['required_outputs'] as List).length
          : 0,
      handoffViolationCount: handoff['violations'] is List
          ? (handoff['violations'] as List).length
          : 0,
      handoffLiveReleaseObserved: handoff['live_release_observed'] == true,
      ledgerPath: Sprint117ClosureContract.ledgerPath,
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

  /// Read a value as trimmed text, treating absent and null alike.
  ///
  /// An empty string means "the manifest did not say", which is not the same
  /// as "the manifest said empty". Both keep the gate closed.
  static String _text(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static int? _int(Object? value) => value is num ? value.toInt() : null;

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) return const <String, int>{};
    final out = <String, int>{};
    for (final entry in value.entries) {
      final raw = entry.value;
      if (raw is num) out[entry.key.toString()] = raw.toInt();
    }
    return out;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

abstract final class Sprint117SprintClosure {
  /// Derive the seven criteria from committed evidence.
  ///
  /// This is the whole decision: nothing below consults a caller-supplied
  /// pass/fail flag, and no criterion can be satisfied by an absent source.
  static List<Sprint117ClosureCriterion> deriveCriteria(
    Sprint117ClosureEvidenceAnchor anchor,
  ) {
    return <Sprint117ClosureCriterion>[
      _entryGatePassed(anchor),
      _betaWindowComplete(anchor),
      _visibleConnectorsCertifiedOrLimited(anchor),
      _qualityGatesPassed(anchor),
      _gaDecisionRecorded(anchor),
      _stagedRolloutControlled(anchor),
      _observationHandoffComplete(anchor),
    ];
  }

  static Sprint117ClosureCriterion _entryGatePassed(
    Sprint117ClosureEvidenceAnchor anchor,
  ) {
    final satisfied =
        anchor.entryState == 'pass' &&
        anchor.entryVerdict == 'BETA_ENTRY_LOCAL_READY';
    return Sprint117ClosureCriterion(
      name: Sprint117ClosureContract.criteriaNames[0],
      status: satisfied
          ? Sprint117ClosureCriterionStatus.satisfied
          : Sprint117ClosureCriterionStatus.unmet,
      evidence: const <String>[Sprint117ClosureContract.entryGatePath],
      detail:
          'state=${anchor.entryState} verdict=${anchor.entryVerdict} '
          'canonical_entry_readiness=${anchor.canonicalEntryReadiness.isEmpty ? '(absent)' : anchor.canonicalEntryReadiness} '
          'canonical_entry_block_resolved=${anchor.canonicalEntryBlockResolved} '
          'live_beta_executed=${anchor.entryLiveBetaExecuted}',
    );
  }

  static Sprint117ClosureCriterion _betaWindowComplete(
    Sprint117ClosureEvidenceAnchor anchor,
  ) {
    final liveExecuted =
        anchor.entryLiveBetaExecuted || anchor.cohortLiveBetaExecuted;
    final Sprint117ClosureCriterionStatus status;
    if (!liveExecuted) {
      // No live beta ran, so the window never opened. That is an external
      // gate (real participants and consent), not a failure of this sprint --
      // and it is emphatically not a completed window.
      status = Sprint117ClosureCriterionStatus.deferredExternal;
    } else if (anchor.betaWindowEndMs > anchor.betaWindowStartMs &&
        anchor.verifiedCohortSize > 0) {
      status = Sprint117ClosureCriterionStatus.satisfied;
    } else {
      status = Sprint117ClosureCriterionStatus.unmet;
    }
    return Sprint117ClosureCriterion(
      name: Sprint117ClosureContract.criteriaNames[1],
      status: status,
      evidence: const <String>[
        Sprint117ClosureContract.charterPath,
        Sprint117ClosureContract.entryGatePath,
        Sprint117ClosureContract.cohortPath,
      ],
      detail:
          'window=${anchor.betaWindowStartMs}..${anchor.betaWindowEndMs} '
          'days=${anchor.betaWindowDays} phases=${anchor.betaWindowPhaseCount} '
          'live_beta_executed=$liveExecuted '
          'verified_participants=${anchor.verifiedCohortSize} '
          'cohort=${anchor.cohortVerdict.isEmpty ? '(absent)' : anchor.cohortVerdict}',
    );
  }

  static Sprint117ClosureCriterion _visibleConnectorsCertifiedOrLimited(
    Sprint117ClosureEvidenceAnchor anchor,
  ) {
    final visible = anchor.visibleProviders;
    final Sprint117ClosureCriterionStatus status;
    if (visible.isEmpty) {
      // Nothing is visible: the master flag defaults OFF and no stage has
      // advanced. The claim "visible connectors are certified or limited" has
      // no witness, so it is deferred to the release gate, never passed on
      // the strength of an empty set.
      status = Sprint117ClosureCriterionStatus.deferredExternal;
    } else if (anchor.lockedCertifiedCount > 0 ||
        anchor.lockedLimitedCount > 0 ||
        anchor.registryCertifiedCount > 0) {
      status = Sprint117ClosureCriterionStatus.satisfied;
    } else {
      status = Sprint117ClosureCriterionStatus.unmet;
    }
    return Sprint117ClosureCriterion(
      name: Sprint117ClosureContract.criteriaNames[2],
      status: status,
      evidence: const <String>[
        Sprint117ClosureContract.certificationPath,
        Sprint117ClosureContract.matrixPath,
        Sprint117ClosureContract.registryPath,
      ],
      // Both certification sources are named side by side. 117.4 froze the
      // local certification chain; 117.41 reconciled the shipped registry.
      // Averaging them would invent a number neither document records.
      detail:
          'visible=${visible.length} '
          'determined_exposed=${anchor.determinedExposed.length} '
          'consent_gate_verified=${anchor.consentGateVerified} '
          '117.4[scope=${anchor.certificationScope.isEmpty ? '(absent)' : anchor.certificationScope} '
          'certified=${anchor.lockedCertifiedCount} '
          'limited=${anchor.lockedLimitedCount} '
          'blocked=${anchor.lockedBlockedCount}] '
          '117.41[certified=${anchor.registryCertifiedCount} '
          'unverified=${anchor.registryUnverifiedCount} '
          'withheld=${anchor.registryWithheldCount}]',
    );
  }

  static Sprint117ClosureCriterion _qualityGatesPassed(
    Sprint117ClosureEvidenceAnchor anchor,
  ) {
    final satisfied =
        anchor.gaQualityGatesPresent && anchor.gaQualityGateSources.isNotEmpty;
    return Sprint117ClosureCriterion(
      name: Sprint117ClosureContract.criteriaNames[3],
      status: satisfied
          ? Sprint117ClosureCriterionStatus.satisfied
          : Sprint117ClosureCriterionStatus.unmet,
      // The sources come from the decision record that measured them, so this
      // criterion cites whatever 117.45 actually read rather than a path this
      // gate typed.
      evidence: anchor.gaQualityGateSources.isEmpty
          ? const <String>[Sprint117ClosureContract.gaApprovalPath]
          : anchor.gaQualityGateSources,
      detail:
          'quality_gate_evidence_present=${anchor.gaQualityGatesPresent} '
          'sources=${anchor.gaQualityGateSources.length}; '
          'the local gate suite is green, which is necessary but not '
          'sufficient for GA',
    );
  }

  static Sprint117ClosureCriterion _gaDecisionRecorded(
    Sprint117ClosureEvidenceAnchor anchor,
  ) {
    final satisfied = anchor.gaDecision.isNotEmpty;
    return Sprint117ClosureCriterion(
      name: Sprint117ClosureContract.criteriaNames[4],
      status: satisfied
          ? Sprint117ClosureCriterionStatus.satisfied
          : Sprint117ClosureCriterionStatus.unmet,
      evidence: const <String>[Sprint117ClosureContract.gaApprovalPath],
      detail:
          'decision=${anchor.gaDecision.isEmpty ? '(absent)' : anchor.gaDecision} '
          'approval_state=${anchor.gaApprovalState.isEmpty ? '(absent)' : anchor.gaApprovalState} '
          'execution_authorized=${anchor.gaExecutionAuthorized} '
          'release_blocked=${anchor.gaReleaseBlocked}',
    );
  }

  static Sprint117ClosureCriterion _stagedRolloutControlled(
    Sprint117ClosureEvidenceAnchor anchor,
  ) {
    // "Controlled" is measurable: stages are defined and nothing is exposed.
    // An empty stage list would make the criterion vacuous, so it fails.
    final satisfied =
        anchor.rolloutStageCount > 0 &&
        anchor.rolloutDefault == 'OFF' &&
        anchor.rolloutEnabledSubset.isEmpty;
    return Sprint117ClosureCriterion(
      name: Sprint117ClosureContract.criteriaNames[5],
      status: satisfied
          ? Sprint117ClosureCriterionStatus.satisfied
          : Sprint117ClosureCriterionStatus.unmet,
      evidence: const <String>[
        Sprint117ClosureContract.rolloutPath,
        Sprint117ClosureContract.matrixPath,
      ],
      detail:
          'stages=${anchor.rolloutStageCount} '
          'default=${anchor.rolloutDefault.isEmpty ? '(absent)' : anchor.rolloutDefault} '
          'enabled=${anchor.rolloutEnabledSubset.length} '
          'kill_switches=${anchor.rolloutKillSwitchCount} '
          'drilled=${anchor.rolloutKillSwitchDrilledCount} '
          'rollback=${anchor.rolloutRollbackCount} '
          'verified=${anchor.rolloutRollbackVerifiedCount}',
    );
  }

  static Sprint117ClosureCriterion _observationHandoffComplete(
    Sprint117ClosureEvidenceAnchor anchor,
  ) {
    final satisfied =
        anchor.handoffState == 'pass' &&
        anchor.handoffRequiredOutputs > 0 &&
        anchor.handoffResolvedOutputs == anchor.handoffRequiredOutputs &&
        anchor.handoffViolationCount == 0;
    return Sprint117ClosureCriterion(
      name: Sprint117ClosureContract.criteriaNames[6],
      status: satisfied
          ? Sprint117ClosureCriterionStatus.satisfied
          : Sprint117ClosureCriterionStatus.unmet,
      evidence: const <String>[Sprint117ClosureContract.handoffPath],
      detail:
          'state=${anchor.handoffState} '
          'verdict=${anchor.handoffVerdict.isEmpty ? '(absent)' : anchor.handoffVerdict} '
          'resolved=${anchor.handoffResolvedOutputs}/${anchor.handoffRequiredOutputs} '
          'violations=${anchor.handoffViolationCount} '
          'live_release_observed=${anchor.handoffLiveReleaseObserved}',
    );
  }

  /// Judge a criterion set.
  ///
  /// The guards are the fail-closed part: a set that is not exactly the seven
  /// canonical criteria, a criterion with no evidence, or a release decision
  /// outside the known vocabulary all throw rather than close.
  static Sprint117ClosureReport evaluate({
    required List<Sprint117ClosureCriterion> criteria,
    required String releaseDecision,
    required String releaseDecisionOwner,
    Sprint117ClosureEvidenceAnchor? anchor,
    List<String> openItems = const <String>[],
  }) {
    final names = criteria.map((criterion) => criterion.name).toSet();
    if (criteria.length != Sprint117ClosureContract.criteriaNames.length ||
        names.length != Sprint117ClosureContract.criteriaNames.length ||
        !Sprint117ClosureContract.criteriaNames.every(names.contains)) {
      throw ArgumentError.value(
        criteria,
        'criteria',
        'must contain exactly the canonical seven definition-of-done items',
      );
    }
    if (!Sprint117ClosureContract.knownReleaseDecisions.contains(
      releaseDecision,
    )) {
      throw ArgumentError.value(
        releaseDecision,
        'releaseDecision',
        'must be one of '
            '${Sprint117ClosureContract.knownReleaseDecisions.join(', ')}',
      );
    }
    for (final criterion in criteria) {
      if (criterion.evidence.isEmpty) {
        throw ArgumentError.value(
          criterion,
          'criteria',
          '${criterion.name} requires at least one committed evidence path',
        );
      }
      if (criterion.detail.trim().isEmpty) {
        throw ArgumentError.value(
          criterion,
          'criteria',
          '${criterion.name} requires a non-empty detail',
        );
      }
    }

    final violations = <String>[
      // A closure that records a live release or a live beta contradicts every
      // committed source: 117.1/117.3 record live_beta_executed false and
      // 117.45 records execution_authorized false.
      if (anchor != null && anchor.liveClaimRecorded)
        'live_release_claimed_without_beta',
      // A visible connector with nothing certified anywhere is an uncertified
      // connector exposed to users: the one thing the release rules forbid.
      if (anchor != null &&
          anchor.visibleProviders.isNotEmpty &&
          anchor.lockedCertifiedCount == 0 &&
          anchor.lockedLimitedCount == 0 &&
          anchor.registryCertifiedCount == 0)
        'visible_connector_uncertified:${anchor.visibleProviders.join(',')}',
      // A recorded release decision without the release step is incoherent:
      // 117.46 records execution_authorized false and PARTIAL-LOCAL.
      if (releaseDecision == 'RELEASE' &&
          anchor != null &&
          !anchor.gaExecutionAuthorized)
        'release_decision_without_authorization',
    ];

    final missing = <String>[
      for (final criterion in criteria)
        if (criterion.unmet) criterion.name,
    ];

    final deferred = <String>[
      for (final criterion in criteria)
        if (criterion.deferred) criterion.name,
    ];

    final state = violations.isNotEmpty
        ? Sprint117ClosureState.fail
        : missing.isNotEmpty
        ? Sprint117ClosureState.blocked
        : Sprint117ClosureState.pass;
    final decision = state == Sprint117ClosureState.pass
        ? Sprint117ClosureDecision.closedLocalDeferredExternal
        : Sprint117ClosureDecision.blocked;
    final verdict = switch (state) {
      Sprint117ClosureState.pass => Sprint117ClosureContract.passVerdict,
      Sprint117ClosureState.blocked => Sprint117ClosureContract.blockedVerdict,
      Sprint117ClosureState.fail => Sprint117ClosureContract.failVerdict,
    };

    final satisfiedCount = criteria.where((c) => c.satisfied).length;
    final summary =
        'Sprint 117 local closure decision=${decision.name}; '
        'satisfied=$satisfiedCount/${Sprint117ClosureContract.criteriaNames.length}; '
        'deferred=${deferred.length}; '
        'release=$releaseDecision';

    return Sprint117ClosureReport(
      state: state,
      decision: decision,
      verdict: verdict,
      criteria: criteria,
      missingEvidence: missing,
      violations: violations,
      openItems: openItems,
      limitations: _limitations(anchor, releaseDecision, releaseDecisionOwner),
      releaseDecision: releaseDecision,
      releaseDecisionOwner: releaseDecisionOwner,
      summary: summary,
      anchor: anchor,
    );
  }

  static List<String> _limitations(
    Sprint117ClosureEvidenceAnchor? anchor,
    String releaseDecision,
    String owner,
  ) => <String>[
    'This closes Sprint 117 locally. It records a $releaseDecision decision whose owner is $owner; it releases nothing, publishes nothing, tags nothing, and pushes nothing.',
    'No live beta ran and no release was executed: 117.1 and 117.3 record live_beta_executed false, and 117.45 records execution_authorized false. The beta window is carried as an external gate, never as a completed window.',
    'Certification is reported from two committed sources side by side: 117.4 froze the local certification chain while 117.41 reconciled the shipped registry. The gate records their disagreement and never averages it.',
    'Connector visibility, kill-switch drills, and rollback verification remain unexecuted; they stay ${Sprint117ClosureContract.externalGates} with hosted CI, public-trust signing, and publication.',
  ];
}

class Sprint117SprintClosureGate {
  const Sprint117SprintClosureGate();

  Sprint117ClosureReport evaluate() => evaluateWith(
    Sprint117ClosureInput(anchor: const Sprint117ClosureLoader().load()),
  );

  Sprint117ClosureReport evaluateWith(Sprint117ClosureInput input) {
    final anchor = input.anchor;
    if (anchor == null) {
      // Not one source could be read: every criterion is undetermined, which
      // is `blocked`, never a closure.
      return Sprint117ClosureReport(
        state: Sprint117ClosureState.blocked,
        decision: Sprint117ClosureDecision.blocked,
        verdict: Sprint117ClosureContract.blockedVerdict,
        criteria: const <Sprint117ClosureCriterion>[],
        missingEvidence: const <String>[
          'closure_anchor',
          ...Sprint117ClosureContract.criteriaNames,
        ],
        violations: const <String>[],
        openItems: const <String>['closure_evidence_unreadable'],
        limitations: const <String>[
          'Not one committed source of the closure contract could be read, so no definition-of-done item is judged.',
        ],
        releaseDecision: '',
        releaseDecisionOwner: '',
        summary:
            'Sprint 117 local closure decision=blocked; satisfied=0/'
            '${Sprint117ClosureContract.criteriaNames.length}; '
            'deferred=0; release=(unreadable)',
        anchor: null,
      );
    }

    final criteria = Sprint117SprintClosure.deriveCriteria(anchor);
    final openItems = <String>[
      ...anchor.gaOpenItems,
      // 117.1 carries a block text while also declaring the block resolved.
      // Both are committed; the gate names the contradiction rather than
      // picking the field that would let it close quietly.
      if (anchor.canonicalEntryBlockResolved &&
          anchor.canonicalEntryReadiness.startsWith('BLOCKED'))
        'entry_gate_readiness_contradiction:'
            'canonical_entry_block_resolved=true:'
            'canonical_entry_readiness=${anchor.canonicalEntryReadiness}',
      // 117.3 failed cohort consent verification: no verified participants, so
      // the beta window is an external gate, never a completed window.
      if (anchor.cohortState == 'fail')
        'cohort_verification_failed:${anchor.cohortVerdict.isEmpty ? '117.3' : anchor.cohortVerdict}',
      // The disagreement is surfaced by name, with both numbers, so the
      // operator decides which certification semantics the closure carries.
      if (anchor.certificationSourcesDisagree)
        'certification_source_disagreement:'
            '117.4=${anchor.lockedCertifiedCount}:'
            '117.41=${anchor.registryCertifiedCount}',
      if (anchor.rolloutKillSwitchDrilledCount < anchor.rolloutKillSwitchCount)
        'kill_switch_not_drilled:'
            '${anchor.rolloutKillSwitchCount - anchor.rolloutKillSwitchDrilledCount}',
      if (anchor.rolloutRollbackVerifiedCount < anchor.rolloutRollbackCount)
        'rollback_not_verified:'
            '${anchor.rolloutRollbackCount - anchor.rolloutRollbackVerifiedCount}',
      if (anchor.registryExposedCount == 0) 'no_connector_exposed',
      if (anchor.verifiedCohortSize == 0) 'verified_cohort_size_zero',
      'live_release_not_executed',
    ];

    return Sprint117SprintClosure.evaluate(
      criteria: criteria,
      releaseDecision: anchor.gaDecision.isEmpty
          ? Sprint117ClosureContract.delayDecision
          : anchor.gaDecision,
      releaseDecisionOwner: anchor.gaApprovalState.isEmpty
          ? 'operator'
          : anchor.gaApprovalState,
      anchor: anchor,
      openItems: openItems,
    );
  }
}
