/// Execution gate for roadmap step 117.46 -- General Availability Release.
///
/// Objective (external canonical JSON): run the staged release only for the
/// certified/limited connector subset, and only after the GA approval gate
/// passes. The seven canonical requirements are `approval_recorded`,
/// `artifact_published`, `connector_subset_enforced`, `uncertified_hidden`,
/// `monitoring_active`, `support_ready`, `rollback_available`.
///
/// The seven requirements are not a checklist. "Artifact published" and
/// "monitoring active" are claims about the outside world, so a release gate
/// that accepts them from a caller-supplied record is a gate that can be made
/// to say `pass` by the very code it is supposed to police. That is exactly
/// how a sprint reports a release that never happened.
///
/// Four rules carry the weight:
///
/// * The gate reads the committed execution manifest. A `verified` output is
///   only accepted when the evidence path it cites exists on disk, and a
///   blocking release decision forbids `pass` however the output records
///   read. A record that claims `verified` while the committed manifest
///   records `UNVERIFIABLE` is an overclaim and fails the gate, not passes it.
/// * The committed approval gate (117.45) is read through all six of its
///   witnesses: the boolean `execution_authorized`, the decision word,
///   `blocker_status.release_blocked`, `approval.approval_state`,
///   `rollback_readiness.ready`, and its `required_evidence` completeness.
///   Consulting only the flag lets a source that records a blocking decision
///   (delay/rollback) still authorize execution through a contradictory
///   boolean, so the decision word is gated too, matched against the owner
///   gate's own wire vocabulary (derived from its enum, not hand-copied).
///   An unrecognised decision word is drift, and a source that records no
///   decision word at all has not corroborated its flag, so silence fails
///   rather than permits. The
///   blocker witness is read the same way: the source's own gate treats an
///   active blocker as a hard veto, so a consumer that never reads it can
///   pass a record that gate fails, and a source silent about its blocker
///   status has not corroborated that none is active. The last two witnesses
///   are the ones the source's own gate fails a `release` on: an approver
///   state other than APPROVED, and rollback readiness that is not confirmed.
///   A consumer that never reads them can pass a record the source's own gate
///   fails, so both are gated here too. The sixth witness is the source's own
///   FIRST check: the completeness of its eight `required_evidence` groups. A
///   source whose evidence is incomplete fails its own gate before it ever
///   reads the decision, so a consumer that reads the five authorization
///   witnesses but not the evidence groups can pass a record the source
///   fails; silence about the groups is undetermined, never complete.
/// * Presence is not relevance. A `verified` output is only accepted when
///   the evidence it cites is topically about that output; a path that exists
///   but never speaks about the claim backs nothing, so it fails rather than
///   passes. The committed execution manifest is topically about all seven.
/// * Absent evidence is undetermined, never permission. A missing or
///   malformed manifest, an unknown status word, or an unknown release
///   decision keeps the gate closed (`blocked`/`fail`), never `pass`.
///
/// Nothing here publishes anything: `execution_authorized` is read from the
/// committed approval gate, which records DELAY with
/// `execution_authorized: false`. This gate therefore evaluates to `blocked`
/// on committed evidence, and that is the honest answer.
library;

import 'dart:convert';
import 'dart:io';

import 'sprint_117_ga_approval_gate.dart';

const List<String> _requiredOutputs = <String>[
  'approval_recorded',
  'artifact_published',
  'connector_subset_enforced',
  'uncertified_hidden',
  'monitoring_active',
  'support_ready',
  'rollback_available',
];

enum Sprint117GaOutputStatus { verified, unverifiable, partial, blocked }

enum Sprint117GaReleaseExecutionState { blocked, fail, pass }

/// The fixed vocabulary of step 117.46, kept in one place so the loader and
/// the gate cannot drift apart about what the step is made of.
abstract final class Sprint117GaReleaseContract {
  const Sprint117GaReleaseContract._();

  static const String canonicalStep = '117.46';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_ga_release_execution.json';

  /// The committed source that decides whether execution is authorized.
  static const String approvalManifestPath =
      'docs/planning/v1.3/sprint_117_ga_approval_gate.json';

  static const List<String> requiredOutputs = _requiredOutputs;

  /// Release decisions that forbid a `pass`, whatever the output records say.
  /// A release decision recorded as blocked is a decision *not* to execute.
  static const Set<String> blockingDecisions = <String>{
    'BLOCKED_EXTERNAL_GATES',
    'DELAY',
    'DELAYED',
    'ROLLED_BACK',
  };

  /// Every decision word this gate understands. An unlisted word is treated
  /// as unknown and fails the gate instead of being read optimistically.
  static const Set<String> decisionVocabulary = <String>{
    'BLOCKED_EXTERNAL_GATES',
    'DELAY',
    'DELAYED',
    'ROLLED_BACK',
    'AUTHORIZED',
    'AUTHORIZED_FOR_EXECUTION',
    'RELEASED',
  };

  /// Approval-source decision words, matched case-insensitively. This is the
  /// 117.45 owner gate's OWN wire vocabulary, derived from its enum rather
  /// than hand-copied: a hand-copied list drifts, and a consumer that speaks a
  /// different vocabulary than the source's own gate both rejects the owner's
  /// genuine words and accepts words the owner rejects.
  static final Set<String> approvalDecisionVocabulary = <String>{
    for (final decision in Sprint117GaDecision.values)
      decision.wireName.toUpperCase(),
  };

  /// Approval-source decisions that forbid a `pass`: the owner gate's
  /// decisions that decide *not* to execute. `release` and `subset_reduction`
  /// both mean "proceed" (full release or certified subset); `delay` and
  /// `rollback` mean "do not". A source recording one of these has decided
  /// not to authorize execution, whatever its boolean flag happens to read.
  static const Set<String> blockingApprovalDecisions = <String>{
    'DELAY',
    'ROLLBACK',
  };

  /// Every approval-state word this gate understands, derived from the 117.45
  /// owner gate's own enum rather than hand-copied so the two cannot drift.
  /// An unlisted word is unknown and fails the gate instead of being read
  /// optimistically.
  static final Set<String> approvalStateVocabulary = <String>{
    for (final state in Sprint117GaApprovalState.values) state.wireName,
  };

  /// The only approval state that authorizes a release. The 117.45 owner gate
  /// fails a `release` unless the approver's state is exactly this.
  static const String authorizingApprovalState = 'APPROVED';

  /// The approval source's eight required evidence groups, in canonical order.
  /// This is the FIRST check the 117.45 owner gate runs: it fails when any
  /// group is absent or lacks sources. Taken directly from the owner's own
  /// contract rather than hand-copied, so the two cannot drift apart.
  static const List<String> approvalEvidenceKeys =
      Sprint117GaApprovalGate.requiredEvidenceKeys;

  /// The topical witness of each output: the word its evidence must actually
  /// mention. A verified output whose cited files exist but never speak about
  /// the output is not evidence for it. Presence is not relevance, so the
  /// gate measures the topic instead of trusting the path.
  static const Map<String, String> outputTopics = <String, String>{
    'approval_recorded': 'approval',
    'artifact_published': 'artifact',
    'connector_subset_enforced': 'subset',
    'uncertified_hidden': 'hidden',
    'monitoring_active': 'telemetry',
    'support_ready': 'support',
    'rollback_available': 'rollback',
  };

  /// Map a manifest status word to the enum, tolerating case.
  ///
  /// An unrecognised word is *not* silently promoted to `verified`; it maps
  /// to `blocked` and the caller records the drift by name.
  static Sprint117GaOutputStatus statusFromText(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'VERIFIED':
        return Sprint117GaOutputStatus.verified;
      case 'UNVERIFIABLE':
        return Sprint117GaOutputStatus.unverifiable;
      case 'PARTIAL':
        return Sprint117GaOutputStatus.partial;
      case 'BLOCKED':
        return Sprint117GaOutputStatus.blocked;
      default:
        return Sprint117GaOutputStatus.blocked;
    }
  }

  static bool isKnownStatus(String raw) => const <String>{
    'VERIFIED',
    'UNVERIFIABLE',
    'PARTIAL',
    'BLOCKED',
  }.contains(raw.trim().toUpperCase());
}

class Sprint117GaOutputRecord {
  const Sprint117GaOutputRecord({
    required this.status,
    required this.evidence,
    required this.note,
  });

  final Sprint117GaOutputStatus status;
  final List<String> evidence;
  final String note;

  bool get verified =>
      status == Sprint117GaOutputStatus.verified &&
      evidence.isNotEmpty &&
      evidence.every((item) => item.trim().isNotEmpty) &&
      note.trim().isNotEmpty;
}

class Sprint117GaReleaseExecution {
  const Sprint117GaReleaseExecution({
    required this.approvalAuthorized,
    required this.outputs,
  });

  static const String canonicalStep = '117.46';
  static const List<String> requiredOutputs = _requiredOutputs;

  final bool approvalAuthorized;
  final Map<String, Sprint117GaOutputRecord> outputs;

  static Sprint117GaReleaseEvaluation evaluate(
    Sprint117GaReleaseExecution? execution,
  ) {
    if (execution == null || execution.outputs.isEmpty) {
      return const Sprint117GaReleaseEvaluation(
        state: Sprint117GaReleaseExecutionState.blocked,
        missing: _requiredOutputs,
        notes: <String>['no GA execution record'],
      );
    }

    final missing = <String>[];
    for (final name in _requiredOutputs) {
      final output = execution.outputs[name];
      if (output == null || !output.verified) missing.add(name);
    }
    if (missing.isNotEmpty) {
      return Sprint117GaReleaseEvaluation(
        state: Sprint117GaReleaseExecutionState.blocked,
        missing: missing,
        notes: <String>[
          'external execution evidence missing or unverified: ${missing.join(', ')}',
        ],
      );
    }
    if (!execution.approvalAuthorized) {
      return const Sprint117GaReleaseEvaluation(
        state: Sprint117GaReleaseExecutionState.fail,
        notes: <String>['execution authorization is required'],
      );
    }
    return const Sprint117GaReleaseEvaluation(
      state: Sprint117GaReleaseExecutionState.pass,
      missing: <String>[],
      notes: <String>['all seven GA execution outputs verified'],
    );
  }
}

class Sprint117GaReleaseEvaluation {
  const Sprint117GaReleaseEvaluation({
    required this.state,
    this.missing = const <String>[],
    this.notes = const <String>[],
  });

  final Sprint117GaReleaseExecutionState state;
  final List<String> missing;
  final List<String> notes;
}

/// What the committed execution manifest actually says.
class Sprint117GaReleaseEvidence {
  const Sprint117GaReleaseEvidence({
    required this.execution,
    required this.recordedDecision,
    required this.recordedAuthorized,
    required this.unrecognisedStatuses,
    this.approvalSourceAuthorized,
    this.approvalSourceDecision,
    this.approvalSourceReleaseBlocked,
    this.approvalSourceApprovalState,
    this.approvalSourceRollbackReady,
    this.approvalSourceMissingEvidence,
  });

  final Sprint117GaReleaseExecution execution;
  final String recordedDecision;
  final bool recordedAuthorized;

  /// `output -> raw status word` for every status the contract does not know.
  /// Carried so the gate can name the drift instead of hiding it.
  final Map<String, String> unrecognisedStatuses;

  /// What the committed approval gate (117.45) says about authorization.
  /// `null` when the approval source could not be read: undetermined, so the
  /// gate must not treat the execution manifest's own claim as sufficient.
  final bool? approvalSourceAuthorized;
  final String? approvalSourceDecision;

  /// The approval source's own blocker witness (`blocker_status.release_blocked`).
  /// `null` when the source does not record one: undetermined, so the gate must
  /// not read silence as "no blocker". The 117.45 gate treats `true` as a hard
  /// veto, so a consumer that never reads this witness can pass a record the
  /// source's own gate fails.
  final bool? approvalSourceReleaseBlocked;

  /// The approval source's own approval-state witness (`approval.approval_state`).
  /// `null` when the source does not record one: undetermined, so the gate must
  /// not read silence as "approved". The 117.45 owner gate fails a `release`
  /// unless the state is `APPROVED`, so a consumer that never reads it can pass
  /// a record the owner fails.
  final String? approvalSourceApprovalState;

  /// The approval source's own rollback-readiness witness
  /// (`rollback_readiness.ready`). `null` when the source does not record one:
  /// undetermined. The 117.45 owner gate fails a `release` unless readiness is
  /// `true`, so a consumer that never reads it can pass a record the owner
  /// fails.
  final bool? approvalSourceRollbackReady;

  /// The approval source's own evidence-completeness witness: the eight
  /// `required_evidence` groups its own gate (117.45) fails on when any is
  /// absent or lacks sources. `null` when the source records no
  /// `required_evidence` block at all: undetermined, so the gate must not read
  /// silence as "all groups present". An empty list means all eight groups are
  /// recorded complete.
  final List<String>? approvalSourceMissingEvidence;
}

/// Reads the committed manifest. Never invents: an unreadable manifest yields
/// `null`, which the gate reports as undetermined.
class Sprint117GaReleaseLoader {
  const Sprint117GaReleaseLoader();

  Sprint117GaReleaseEvidence? load() => loadFrom(
    manifestPath: Sprint117GaReleaseContract.manifestPath,
    approvalPath: Sprint117GaReleaseContract.approvalManifestPath,
  );

  /// Like [load], but reads the execution and approval manifests from the
  /// given paths. The authorization witnesses are read from exactly the
  /// locations the 117.45 owner gate reads, so the consumer cannot be shown
  /// authorization the owner gate never saw.
  Sprint117GaReleaseEvidence? loadFrom({
    required String manifestPath,
    required String approvalPath,
  }) {
    final manifest = _readJsonObject(manifestPath);
    if (manifest == null) return null;

    final rawOutputs = manifest['outputs'];
    if (rawOutputs is! Map) return null;

    final records = <String, Sprint117GaOutputRecord>{};
    final unrecognised = <String, String>{};
    for (final name in Sprint117GaReleaseContract.requiredOutputs) {
      final raw = rawOutputs[name];
      if (raw is! Map) return null;
      final statusText = _text(raw['status']);
      if (!Sprint117GaReleaseContract.isKnownStatus(statusText)) {
        unrecognised[name] = statusText;
      }
      records[name] = Sprint117GaOutputRecord(
        status: Sprint117GaReleaseContract.statusFromText(statusText),
        evidence: _stringList(raw['evidence']),
        note: _text(raw['note']),
      );
    }

    return Sprint117GaReleaseEvidence(
      execution: Sprint117GaReleaseExecution(
        approvalAuthorized: manifest['execution_authorized'] == true,
        outputs: records,
      ),
      recordedDecision: _text(manifest['decision']),
      recordedAuthorized: manifest['execution_authorized'] == true,
      unrecognisedStatuses: unrecognised,
      approvalSourceAuthorized: _approvalAuthorized(approvalPath),
      approvalSourceDecision: _approvalDecision(approvalPath),
      approvalSourceReleaseBlocked: _approvalReleaseBlocked(approvalPath),
      approvalSourceApprovalState: _approvalState(approvalPath),
      approvalSourceRollbackReady: _approvalRollbackReady(approvalPath),
      approvalSourceMissingEvidence: _approvalMissingEvidence(approvalPath),
    );
  }

  /// Read the committed approval gate (117.45). A missing or malformed file
  /// yields `null`, which the gate treats as undetermined.
  ///
  /// The witness is read from exactly the location the 117.45 owner gate reads
  /// it: the nested `approval` block. A top-level fallback would let a source
  /// carry its authorization claims where the owner gate never looks, so the
  /// consumer would pass a record the owner fails.
  static bool? _approvalAuthorized(String path) {
    final approval = _readJsonObject(path);
    if (approval == null) return null;
    final block = approval['approval'];
    if (block is Map && block['execution_authorized'] is bool) {
      return block['execution_authorized'] as bool;
    }
    return null;
  }

  /// Read the approval source's own blocker witness
  /// (`blocker_status.release_blocked`). `null` when the source records none:
  /// undetermined, so the gate must not read silence as "no blocker".
  static bool? _approvalReleaseBlocked(String path) {
    final approval = _readJsonObject(path);
    if (approval == null) return null;
    final blockers = approval['blocker_status'];
    if (blockers is Map && blockers['release_blocked'] is bool) {
      return blockers['release_blocked'] as bool;
    }
    return null;
  }

  /// Read the decision word from exactly the location the 117.45 owner gate
  /// reads it: the nested `approval` block. A top-level fallback would read a
  /// word the owner never sees, so the consumer could pass a source the owner
  /// fails.
  static String? _approvalDecision(String path) {
    final approval = _readJsonObject(path);
    if (approval == null) return null;
    final block = approval['approval'];
    if (block is Map && block['decision'] is String) {
      return _text(block['decision']);
    }
    return null;
  }

  /// Read the approval source's own approval-state witness
  /// (`approval.approval_state`). `null` when the source records none:
  /// undetermined, so the gate must not read silence as "approved".
  /// Read the approver state from exactly the location the 117.45 owner gate
  /// reads it: the nested `approval` block. A top-level fallback would read a
  /// state the owner never sees, so the consumer could pass a source the owner
  /// fails.
  static String? _approvalState(String path) {
    final approval = _readJsonObject(path);
    if (approval == null) return null;
    final block = approval['approval'];
    if (block is Map && block['approval_state'] is String) {
      return _text(block['approval_state']);
    }
    return null;
  }

  /// Read the approval source's own rollback-readiness witness
  /// (`rollback_readiness.ready`). `null` when the source records none:
  /// undetermined, so the gate must not read silence as "ready".
  static bool? _approvalRollbackReady(String path) {
    final approval = _readJsonObject(path);
    if (approval == null) return null;
    final rollback = approval['rollback_readiness'];
    if (rollback is Map && rollback['ready'] is bool) {
      return rollback['ready'] as bool;
    }
    return null;
  }

  /// Read the approval source's own evidence-completeness witness: the eight
  /// `required_evidence` groups its gate (117.45) requires. Returns the names
  /// of groups that are absent or lack non-empty sources; an empty list means
  /// all eight are recorded complete. `null` when the source records no
  /// `required_evidence` block at all: undetermined, so silence is not
  /// "complete".
  static List<String>? _approvalMissingEvidence(String path) {
    final approval = _readJsonObject(path);
    if (approval == null) return null;
    final raw = approval['required_evidence'];
    if (raw is! Map) return null;
    final missing = <String>[];
    for (final name in Sprint117GaReleaseContract.approvalEvidenceKeys) {
      final entry = raw[name];
      if (entry is! Map) {
        missing.add(name);
        continue;
      }
      final sources = entry['sources'];
      final complete =
          entry['present'] == true &&
          sources is List &&
          sources.isNotEmpty &&
          sources.every((s) => s is String && s.trim().isNotEmpty);
      if (!complete) missing.add(name);
    }
    return missing;
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

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

/// Read an evidence file's text for topicality. A file that cannot be read
/// yields the empty string, so an unreadable path is never topical: absent or
/// broken evidence is undetermined, never permission.
String _readEvidenceText(String path) {
  try {
    return File(path).readAsStringSync();
  } on FileSystemException {
    return '';
  }
}

class Sprint117GaReleaseReport {
  const Sprint117GaReleaseReport({
    required this.state,
    required this.verdict,
    this.missingOutputs = const <String>[],
    this.violations = const <String>[],
    this.openItems = const <String>[],
  });

  final Sprint117GaReleaseExecutionState state;
  final String verdict;
  final List<String> missingOutputs;
  final List<String> violations;
  final List<String> openItems;
}

class Sprint117GaReleaseGate {
  const Sprint117GaReleaseGate();

  /// Evaluate against committed evidence. This is the entry point that makes
  /// the answer trustworthy: the verdict is bound to the manifest on disk.
  Sprint117GaReleaseReport evaluate() =>
      evaluateWith(const Sprint117GaReleaseLoader().load());

  Sprint117GaReleaseReport evaluateWith(Sprint117GaReleaseEvidence? evidence) {
    if (evidence == null) {
      return Sprint117GaReleaseReport(
        state: Sprint117GaReleaseExecutionState.blocked,
        verdict: 'GA_RELEASE_EXECUTION_MANIFEST_UNREADABLE',
        missingOutputs: List<String>.from(
          Sprint117GaReleaseContract.requiredOutputs,
        ),
        violations: const <String>['execution_manifest_unreadable'],
        openItems: const <String>['execution_manifest_unreadable'],
      );
    }

    final violations = <String>[];
    final missing = <String>[];
    final openItems = <String>[];

    // An unrecognised status word is drift, not a pass. Fail rather than
    // read it optimistically.
    for (final entry in evidence.unrecognisedStatuses.entries) {
      violations.add('unknown_output_status:${entry.key}:${entry.value}');
    }

    // A missing or unknown release decision is drift too: the gate cannot
    // tell whether the step was authorized, so it must not claim it was.
    final decision = evidence.recordedDecision;
    final decisionKnown = Sprint117GaReleaseContract.decisionVocabulary
        .contains(decision);
    if (decision.isEmpty) {
      violations.add('release_decision_missing');
    } else if (!decisionKnown) {
      violations.add('unknown_release_decision:$decision');
    }

    final outputs = evidence.execution.outputs;
    for (final name in Sprint117GaReleaseContract.requiredOutputs) {
      final record = outputs[name];
      if (record == null || !record.verified) {
        missing.add(name);
        continue;
      }
      // A `verified` output has to be backed by evidence that is actually
      // present. Otherwise the word "verified" is doing no work.
      final absent = <String>[
        for (final path in record.evidence)
          if (!File(path).existsSync()) path,
      ];
      if (absent.isNotEmpty) {
        violations.add('verified_without_evidence:$name:${absent.join('|')}');
      }

      // Presence is not relevance. A `verified` output whose cited files all
      // exist but never speak about the output is not evidence for it: the
      // path would be doing the work the claim is supposed to do. Measure the
      // topic, not just the path.
      final topic = Sprint117GaReleaseContract.outputTopics[name];
      if (topic != null) {
        final present = <String>[
          for (final path in record.evidence)
            if (File(path).existsSync()) path,
        ];
        if (present.isNotEmpty) {
          final body = StringBuffer();
          for (final path in present) {
            body.write(_readEvidenceText(path).toLowerCase());
            body.write(' ');
          }
          if (!body.toString().contains(topic)) {
            violations.add('verified_without_topical_evidence:$name');
          }
        }
      }
    }

    // The execution manifest is not allowed to be the only witness to its own
    // authorization. If it claims authorization while the committed approval
    // gate says otherwise (or cannot be read), that disagreement fails the
    // gate: a release authorized by the record it is supposed to obey is not
    // authorized at all.
    if (evidence.execution.approvalAuthorized) {
      final source = evidence.approvalSourceAuthorized;
      if (source == null) {
        violations.add('authorization_source_unreadable');
      } else if (!source) {
        violations.add(
          'authorization_disagrees_with_approval_gate:'
          '${evidence.approvalSourceDecision ?? 'unknown'}',
        );
      }
      // The approval source records its decision as a word, not only as a
      // boolean. The word is a second witness in the same source: even when
      // the boolean reads authorized, a recorded blocking decision (delay or
      // rollback) forbids pass, and an unrecognised decision word is drift,
      // not permission. Consulting only the flag lets the two readers of one
      // question disagree unnoticed.
      final approvalDecision = evidence.approvalSourceDecision;
      // The approval source authorized execution by its flag but recorded no
      // decision word. The word is a second witness in the same source: a
      // source that is silent about its decision has not corroborated the
      // flag, and absent evidence is undetermined, never permission.
      if (approvalDecision == null || approvalDecision.trim().isEmpty) {
        violations.add('authorization_source_decision_missing');
      }
      if (approvalDecision != null && approvalDecision.trim().isNotEmpty) {
        final normalized = approvalDecision.trim().toUpperCase();
        if (!Sprint117GaReleaseContract.approvalDecisionVocabulary.contains(
          normalized,
        )) {
          violations.add('unknown_approval_source_decision:$approvalDecision');
        } else if (Sprint117GaReleaseContract.blockingApprovalDecisions
            .contains(normalized)) {
          violations.add(
            'authorization_source_decision_blocks_execution:'
            '$approvalDecision',
          );
        }
      }
      // The approval source carries a third witness beside the flag and the
      // decision word: `blocker_status.release_blocked`, which its own gate
      // (117.45) treats as a hard veto. Consulting only two of the three
      // witnesses lets a source that records an active release blocker still
      // authorize execution through the two it happens to agree with.
      final releaseBlocked = evidence.approvalSourceReleaseBlocked;
      if (releaseBlocked == null) {
        violations.add('authorization_source_blocker_status_missing');
      } else if (releaseBlocked) {
        violations.add('authorization_source_release_blocked');
      }
      // The approval source carries two more witnesses its own gate (117.45)
      // consults: the approver state and the rollback readiness. A `release`
      // requires an APPROVED approver and confirmed readiness there, so a
      // consumer that never reads them can pass a record the source's own gate
      // fails. Silence is undetermined, never permission: an absent state or
      // readiness has not corroborated the flag, and an unknown state word is
      // drift, not an approval.
      final approvalState = evidence.approvalSourceApprovalState;
      if (approvalState == null || approvalState.trim().isEmpty) {
        violations.add('authorization_source_approval_state_missing');
      } else {
        final normalizedState = approvalState.trim().toUpperCase();
        if (!Sprint117GaReleaseContract.approvalStateVocabulary.contains(
          normalizedState,
        )) {
          violations.add('unknown_approval_source_state:$approvalState');
        } else if (normalizedState !=
            Sprint117GaReleaseContract.authorizingApprovalState) {
          violations.add(
            'authorization_source_approval_state_not_approved:'
            '$approvalState',
          );
        }
      }
      final rollbackReady = evidence.approvalSourceRollbackReady;
      if (rollbackReady == null) {
        violations.add('authorization_source_rollback_readiness_missing');
      } else if (!rollbackReady) {
        violations.add('authorization_source_rollback_readiness_not_confirmed');
      }
      // The approval source's own FIRST gate is evidence completeness: 117.45
      // fails when any of its eight `required_evidence` groups is absent or
      // lacks sources, before it ever looks at the decision. A consumer that
      // reads the five authorization witnesses but never the evidence groups
      // can pass a record the source's own gate fails. Silence is
      // undetermined, never permission: a source that records no
      // `required_evidence` block has not corroborated that its evidence is
      // complete.
      final missingEvidence = evidence.approvalSourceMissingEvidence;
      if (missingEvidence == null) {
        violations.add('authorization_source_evidence_missing');
      } else if (missingEvidence.isNotEmpty) {
        violations.add(
          'authorization_source_evidence_incomplete:'
          '${missingEvidence.join('|')}',
        );
      }
    }

    if (violations.isNotEmpty) {
      return Sprint117GaReleaseReport(
        state: Sprint117GaReleaseExecutionState.fail,
        verdict: 'GA_RELEASE_EXECUTION_EVIDENCE_VIOLATION',
        missingOutputs: missing,
        violations: violations,
        openItems: openItems,
      );
    }

    if (missing.isNotEmpty) {
      return Sprint117GaReleaseReport(
        state: Sprint117GaReleaseExecutionState.blocked,
        verdict: 'GA_RELEASE_EXECUTION_BLOCKED_EXTERNAL',
        missingOutputs: missing,
        violations: const <String>[],
        openItems: <String>[
          for (final name in missing) 'unverified_output:$name',
          if (decision.isNotEmpty) 'release_decision:$decision',
        ],
      );
    }

    // A blocking release decision forbids `pass` even if every output record
    // claims to be verified: the decision is not to execute.
    if (Sprint117GaReleaseContract.blockingDecisions.contains(decision)) {
      return Sprint117GaReleaseReport(
        state: Sprint117GaReleaseExecutionState.fail,
        verdict: 'GA_RELEASE_EXECUTION_DECISION_BLOCKS_RELEASE',
        missingOutputs: const <String>[],
        violations: <String>['release_decision_blocks_execution:$decision'],
        openItems: <String>['release_decision:$decision'],
      );
    }

    if (!evidence.execution.approvalAuthorized) {
      return Sprint117GaReleaseReport(
        state: Sprint117GaReleaseExecutionState.fail,
        verdict: 'GA_RELEASE_EXECUTION_NOT_AUTHORIZED',
        missingOutputs: const <String>[],
        violations: const <String>['execution_authorization_required'],
        openItems: const <String>['execution_not_authorized'],
      );
    }

    return Sprint117GaReleaseReport(
      state: Sprint117GaReleaseExecutionState.pass,
      verdict: 'GA_RELEASE_EXECUTION_VERIFIED',
      missingOutputs: const <String>[],
      violations: const <String>[],
      openItems: const <String>[],
    );
  }
}
