/// GA Approval Gate (Step 117.45).
///
/// Decides release, delay, subset reduction, or rollback from the eight
/// canonical beta-evidence groups of sprint 117. The gate is a decision
/// record, not an approval machine: a `release` outcome additionally
/// requires Choirudin's explicit approval, no active release blocker, and
/// confirmed rollback readiness — writing the manifest never authorizes
/// execution on its own.
///
/// 117.45 is the sprint's governance gate, so the outcome is decided by
/// evidence, never by preference. Sprint 117's own committed evidence forces
/// [Sprint117GaDecision.delay]: 117.1 records
/// `BLOCKED_NO_CERTIFIED_CONNECTOR_CURRENTLY_RECORDED`, 117.4 locked the
/// certification snapshot with zero CERTIFIED connectors (32 UNVERIFIED),
/// the beta cohort consent verification failed, and no beta was ever
/// executed. A `release` recorded against that evidence would claim a beta
/// that never ran, so the gate is where that rule is enforced rather than
/// asserted.
///
/// Nothing here is a live release: no connector is enabled, no stage is
/// advanced, and no rollback is executed. Those remain external gates.
library;

/// Canonical step identifier.
const String kSprint117GaApprovalStep = '117.45';

/// The eight required beta-evidence groups, in canonical contract order.
const List<String> kSprint117GaApprovalEvidenceKeys = <String>[
  'beta_results',
  'connector_registry',
  'blocker_status',
  'quality_gates',
  'known_limits',
  'signed_artifacts',
  'rollout_plan',
  'rollback_readiness',
];

/// Outcome of evaluating the gate record.
enum Sprint117GaGateState {
  /// Nothing recorded — nothing to decide.
  blocked,

  /// Evidence missing/incomplete, or a release was requested without
  /// approval, without rollback readiness, or while blocked.
  fail,

  /// The record is complete and internally consistent with its decision.
  pass,
}

/// The decision the gate record asks for.
enum Sprint117GaDecision {
  /// Proceed toward GA release (strictest requirements).
  release,

  /// Hold the release until the blocking evidence is resolved (the honest
  /// outcome for sprint 117's current evidence).
  delay,

  /// Release only a certified subset of connectors.
  subsetReduction,

  /// Abandon this release candidate.
  rollback,
}

/// Approval state of the designated approver.
enum Sprint117GaApprovalState {
  /// Explicit approval given.
  approved,

  /// Awaiting Choirudin's explicit decision.
  pendingChoirudin,

  /// Explicitly refused.
  rejected,
}

/// Wire-name helpers for manifest round-trips.
extension Sprint117GaDecisionWire on Sprint117GaDecision {
  String get wireName => switch (this) {
    Sprint117GaDecision.release => 'release',
    Sprint117GaDecision.delay => 'delay',
    Sprint117GaDecision.subsetReduction => 'subset_reduction',
    Sprint117GaDecision.rollback => 'rollback',
  };
}

extension Sprint117GaApprovalStateWire on Sprint117GaApprovalState {
  String get wireName => switch (this) {
    Sprint117GaApprovalState.approved => 'APPROVED',
    Sprint117GaApprovalState.pendingChoirudin => 'PENDING_CHOIRUDIN',
    Sprint117GaApprovalState.rejected => 'REJECTED',
  };
}

/// One evidence group of the approval record.
class Sprint117GaEvidenceRecord {
  const Sprint117GaEvidenceRecord({
    required this.present,
    required this.sources,
  });

  /// Whether the group has been recorded for this gate.
  final bool? present;

  /// Repository paths backing the evidence (must be non-empty when
  /// [present] is true).
  final List<String>? sources;

  bool get isComplete =>
      present == true &&
      sources != null &&
      sources!.isNotEmpty &&
      sources!.every((s) => s.trim().isNotEmpty);
}

/// Immutable GA approval gate record.
class Sprint117GaApprovalGate {
  const Sprint117GaApprovalGate({
    this.evidence,
    this.decision,
    this.approval,
    this.rollbackReady,
    this.releaseBlocked,
  });

  /// Canonical step this gate belongs to.
  static const String canonicalStep = kSprint117GaApprovalStep;

  /// Canonical evidence keys, in contract order.
  static const List<String> requiredEvidenceKeys = kSprint117GaApprovalEvidenceKeys;

  /// Evidence groups by canonical name.
  final Map<String, Sprint117GaEvidenceRecord>? evidence;

  /// Requested decision.
  final Sprint117GaDecision? decision;

  /// Approver state.
  final Sprint117GaApprovalState? approval;

  /// Whether rollback capability is confirmed.
  final bool? rollbackReady;

  /// Whether an active release blocker stops the release.
  final bool? releaseBlocked;

  /// Canonical names of evidence groups that are absent, not marked
  /// present, or lack non-empty sources. Returns every canonical key for a
  /// null/empty record.
  static List<String> missingEvidence(Sprint117GaApprovalGate? gate) {
    final evidence = gate?.evidence;
    if (evidence == null || evidence.isEmpty) {
      return List<String>.unmodifiable(requiredEvidenceKeys);
    }
    final missing = <String>[];
    for (final name in requiredEvidenceKeys) {
      final record = evidence[name];
      if (record == null || !record.isComplete) missing.add(name);
    }
    return List<String>.unmodifiable(missing);
  }

  /// Evaluates the gate record: null/empty is
  /// [Sprint117GaGateState.blocked]; missing evidence or missing structural
  /// fields fail naming them (in canonical order); a `release` decision
  /// fails while approval is not explicit, while a release blocker is
  /// active, or without rollback readiness; a consistent
  /// `release`/`delay`/`subset_reduction`/`rollback` passes with evidence
  /// count, decision, and approval state in the notes.
  static Sprint117GaEvaluation evaluate(Sprint117GaApprovalGate? gate) {
    if (gate == null || gate.evidence == null || gate.evidence!.isEmpty) {
      return const Sprint117GaEvaluation(
        state: Sprint117GaGateState.blocked,
        notes: <String>['no GA approval record written'],
      );
    }

    final missing = missingEvidence(gate);
    if (missing.isNotEmpty) {
      return Sprint117GaEvaluation(
        state: Sprint117GaGateState.fail,
        notes: <String>[
          'approval evidence incomplete: missing ${missing.join(', ')}',
        ],
      );
    }

    final missingFields = <String>[
      if (gate.decision == null) 'decision',
      if (gate.approval == null) 'approval',
      if (gate.rollbackReady == null) 'rollback_readiness',
      if (gate.releaseBlocked == null) 'blocker_status',
    ];
    if (missingFields.isNotEmpty) {
      return Sprint117GaEvaluation(
        state: Sprint117GaGateState.fail,
        notes: <String>[
          'approval record incomplete: ${missingFields.join(', ')}',
        ],
      );
    }

    final decision = gate.decision!;
    final approval = gate.approval!;
    final notes = <String>[
      'evidence: ${requiredEvidenceKeys.length}/${requiredEvidenceKeys.length}',
      'decision: ${decision.wireName}',
      'approval: ${approval.wireName}',
    ];

    if (decision == Sprint117GaDecision.release) {
      if (approval != Sprint117GaApprovalState.approved) {
        return Sprint117GaEvaluation(
          state: Sprint117GaGateState.fail,
          notes: <String>[
            'release requires explicit approval: approval is '
                '${approval.wireName}',
          ],
        );
      }
      if (gate.releaseBlocked == true) {
        return const Sprint117GaEvaluation(
          state: Sprint117GaGateState.fail,
          notes: <String>['release blocked: active release blocker'],
        );
      }
      if (gate.rollbackReady != true) {
        return const Sprint117GaEvaluation(
          state: Sprint117GaGateState.fail,
          notes: <String>['release requires confirmed rollback readiness'],
        );
      }
    }

    return Sprint117GaEvaluation(
      state: Sprint117GaGateState.pass,
      notes: notes,
    );
  }

  /// Rebuilds a gate from the 117.45 planning manifest. Unknown wire values
  /// stay null so [evaluate] reports them as incomplete rather than
  /// guessing.
  factory Sprint117GaApprovalGate.fromManifest(Map<String, dynamic> manifest) {
    final rawEvidence = manifest['required_evidence'] as Map<String, dynamic>?;
    final evidence = <String, Sprint117GaEvidenceRecord>{};
    if (rawEvidence != null) {
      for (final name in rawEvidence.keys) {
        final entry = rawEvidence[name];
        if (entry is! Map<String, dynamic>) continue;
        final sources = entry['sources'];
        evidence[name] = Sprint117GaEvidenceRecord(
          present: entry['present'] as bool?,
          sources: sources is List
              ? sources.whereType<String>().toList(growable: false)
              : null,
        );
      }
    }

    final approvalBlock = manifest['approval'];
    final approvalMap = approvalBlock is Map<String, dynamic>
        ? approvalBlock
        : const <String, dynamic>{};
    final decisionWire = approvalMap['decision'] as String?;
    final stateWire = approvalMap['approval_state'] as String?;

    final blockers = manifest['blocker_status'];
    final blockerMap = blockers is Map<String, dynamic>
        ? blockers
        : const <String, dynamic>{};
    final rollback = manifest['rollback_readiness'];
    final rollbackMap = rollback is Map<String, dynamic>
        ? rollback
        : const <String, dynamic>{};

    return Sprint117GaApprovalGate(
      evidence: evidence.isEmpty ? null : evidence,
      decision: switch (decisionWire) {
        'release' => Sprint117GaDecision.release,
        'delay' => Sprint117GaDecision.delay,
        'subset_reduction' => Sprint117GaDecision.subsetReduction,
        'rollback' => Sprint117GaDecision.rollback,
        _ => null,
      },
      approval: switch (stateWire) {
        'APPROVED' => Sprint117GaApprovalState.approved,
        'PENDING_CHOIRUDIN' => Sprint117GaApprovalState.pendingChoirudin,
        'REJECTED' => Sprint117GaApprovalState.rejected,
        _ => null,
      },
      rollbackReady: rollbackMap['ready'] as bool?,
      releaseBlocked: blockerMap['release_blocked'] as bool?,
    );
  }
}

/// Result of evaluating a [Sprint117GaApprovalGate].
class Sprint117GaEvaluation {
  const Sprint117GaEvaluation({required this.state, required this.notes});

  final Sprint117GaGateState state;
  final List<String> notes;
}
