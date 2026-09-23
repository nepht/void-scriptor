/// GA Approval Gate (Step 113.43).
///
/// Decides release, defer, or cancel from the eight canonical evidence
/// groups of the GA approval gate plus rollback readiness. The gate is a
/// decision record, not an approval machine: a `release` outcome
/// additionally requires Choirudin's explicit approval, no active
/// release blocker, and confirmed rollback readiness — writing the
/// manifest never authorizes execution on its own.
library;

/// Canonical step identifier.
const String kGaApprovalGateStep = '113.43';

/// The eight required evidence groups, in roadmap order.
const List<String> kGaApprovalEvidenceKeys = <String>[
  'validation_results',
  'blocker_status',
  'quality_gate_rerun',
  'feature_reconciliation',
  'known_issues',
  'signed_artifacts',
  'staged_rollout_plan',
  'rollback_readiness',
];

/// Outcome of evaluating the gate record.
enum GaGateState {
  /// Nothing recorded — nothing to decide.
  blocked,

  /// Evidence missing/incomplete, or a release was requested without
  /// approval, without rollback readiness, or while blocked.
  fail,

  /// The record is complete and internally consistent with its decision.
  pass,
}

/// The decision the gate record asks for.
enum GaDecision {
  /// Proceed toward GA release (strictest requirements).
  release,

  /// Hold until the approver rules (the default honest outcome).
  defer,

  /// Abandon this release candidate.
  cancel,
}

/// Approval state of the designated approver.
enum GaApprovalState {
  /// Explicit approval given.
  approved,

  /// Awaiting Choirudin's explicit decision.
  pendingChoirudin,

  /// Explicitly refused.
  rejected,
}

/// Wire-name helpers for manifest round-trips.
extension GaDecisionWire on GaDecision {
  String get wireName => switch (this) {
    GaDecision.release => 'release',
    GaDecision.defer => 'defer',
    GaDecision.cancel => 'cancel',
  };
}

extension GaApprovalStateWire on GaApprovalState {
  String get wireName => switch (this) {
    GaApprovalState.approved => 'APPROVED',
    GaApprovalState.pendingChoirudin => 'PENDING_CHOIRUDIN',
    GaApprovalState.rejected => 'REJECTED',
  };
}

/// One evidence group of the approval record.
class GaEvidenceRecord {
  const GaEvidenceRecord({required this.present, required this.sources});

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
class GaApprovalGate {
  const GaApprovalGate({
    this.evidence,
    this.decision,
    this.approval,
    this.rollbackReady,
    this.releaseBlocked,
  });

  /// Canonical step this gate belongs to.
  static const String canonicalStep = kGaApprovalGateStep;

  /// Canonical evidence keys, in roadmap order.
  static const List<String> requiredEvidenceKeys = kGaApprovalEvidenceKeys;

  /// Evidence groups by canonical name.
  final Map<String, GaEvidenceRecord>? evidence;

  /// Requested decision.
  final GaDecision? decision;

  /// Approver state.
  final GaApprovalState? approval;

  /// Whether rollback capability is confirmed.
  final bool? rollbackReady;

  /// Whether an active release blocker stops the release.
  final bool? releaseBlocked;

  /// Canonical names of evidence groups that are absent, not marked
  /// present, or lack non-empty sources. Returns every canonical key for
  /// a null/empty record.
  static List<String> missingEvidence(GaApprovalGate? gate) {
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

  /// Evaluates the gate record: null/empty is [GaGateState.blocked];
  /// missing evidence or missing structural fields fail naming them (in
  /// canonical order); a `release` decision fails while approval is not
  /// explicit, while a release blocker is active, or without rollback
  /// readiness; a consistent `release`/`defer`/`cancel` passes with
  /// evidence count, decision, and approval state in the notes.
  static GaEvaluation evaluate(GaApprovalGate? gate) {
    if (gate == null || gate.evidence == null || gate.evidence!.isEmpty) {
      return const GaEvaluation(
        state: GaGateState.blocked,
        notes: <String>['no GA approval record written'],
      );
    }

    final missing = missingEvidence(gate);
    if (missing.isNotEmpty) {
      return GaEvaluation(
        state: GaGateState.fail,
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
      return GaEvaluation(
        state: GaGateState.fail,
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

    if (decision == GaDecision.release) {
      if (approval != GaApprovalState.approved) {
        return GaEvaluation(
          state: GaGateState.fail,
          notes: <String>[
            'release requires explicit approval: approval is '
                '${approval.wireName}',
          ],
        );
      }
      if (gate.releaseBlocked == true) {
        return const GaEvaluation(
          state: GaGateState.fail,
          notes: <String>['release blocked: active release blocker'],
        );
      }
      if (gate.rollbackReady != true) {
        return const GaEvaluation(
          state: GaGateState.fail,
          notes: <String>['release requires confirmed rollback readiness'],
        );
      }
    }

    return GaEvaluation(state: GaGateState.pass, notes: notes);
  }

  /// Rebuilds a gate from the 113.43 planning manifest. Unknown wire
  /// values stay null so [evaluate] reports them as incomplete rather
  /// than guessing.
  factory GaApprovalGate.fromManifest(Map<String, dynamic> manifest) {
    final rawEvidence = manifest['required_evidence'] as Map<String, dynamic>?;
    final evidence = <String, GaEvidenceRecord>{};
    if (rawEvidence != null) {
      for (final name in rawEvidence.keys) {
        final entry = rawEvidence[name];
        if (entry is! Map<String, dynamic>) continue;
        final sources = entry['sources'];
        evidence[name] = GaEvidenceRecord(
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

    return GaApprovalGate(
      evidence: evidence.isEmpty ? null : evidence,
      decision: switch (decisionWire) {
        'release' => GaDecision.release,
        'defer' => GaDecision.defer,
        'cancel' => GaDecision.cancel,
        _ => null,
      },
      approval: switch (stateWire) {
        'APPROVED' => GaApprovalState.approved,
        'PENDING_CHOIRUDIN' => GaApprovalState.pendingChoirudin,
        'REJECTED' => GaApprovalState.rejected,
        _ => null,
      },
      rollbackReady: rollbackMap['ready'] as bool?,
      releaseBlocked: blockerMap['release_blocked'] as bool?,
    );
  }
}

/// Result of evaluating a [GaApprovalGate].
class GaEvaluation {
  const GaEvaluation({required this.state, required this.notes});

  final GaGateState state;
  final List<String> notes;
}
