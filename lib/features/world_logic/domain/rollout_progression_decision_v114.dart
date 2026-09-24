/// Dependency-free rollout progression contract for Sprint 114.37.
///
/// The model validates a local health-evidence record and its proposed
/// progression decision. It does not execute or claim a live rollout.
library;

enum RolloutProgressionState { pass, fail, blocked }

enum RolloutProgressionHealthStatus { healthy, failed }

enum RolloutProgressionDecision {
  expand('EXPAND'),
  hold('HOLD'),
  reduce('REDUCE'),
  rollback('ROLLBACK');

  const RolloutProgressionDecision(this.wireName);

  final String wireName;
}

class RolloutProgressionHealthEvidence {
  const RolloutProgressionHealthEvidence({
    required this.name,
    required this.source,
    required this.status,
  });

  final String name;
  final String source;
  final RolloutProgressionHealthStatus status;
}

class RolloutProgressionRecord {
  const RolloutProgressionRecord({
    required this.healthEvidence,
    required this.decision,
    required this.rationale,
  });

  final List<RolloutProgressionHealthEvidence> healthEvidence;
  final RolloutProgressionDecision decision;
  final String rationale;
}

class RolloutProgressionDecisionReport {
  const RolloutProgressionDecisionReport({
    required this.state,
    required this.decision,
    required this.healthEvidence,
    required this.failedHealthEvidence,
    required this.violations,
    required this.notes,
  });

  final RolloutProgressionState state;
  final RolloutProgressionDecision? decision;
  final List<RolloutProgressionHealthEvidence> healthEvidence;
  final List<RolloutProgressionHealthEvidence> failedHealthEvidence;
  final List<String> violations;
  final List<String> notes;
}

class RolloutProgressionDecisionRegister {
  final List<RolloutProgressionRecord> _records = <RolloutProgressionRecord>[];

  void add(RolloutProgressionRecord record) => _records.add(record);

  void addRecords(Iterable<RolloutProgressionRecord> records) =>
      _records.addAll(records);

  RolloutProgressionDecisionReport evaluate() {
    if (_records.isEmpty) {
      return const RolloutProgressionDecisionReport(
        state: RolloutProgressionState.blocked,
        decision: null,
        healthEvidence: <RolloutProgressionHealthEvidence>[],
        failedHealthEvidence: <RolloutProgressionHealthEvidence>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada health evidence; keputusan rollout tidak diklaim; '
              'external rollout execution DEFERRED-EXTERNAL.',
        ],
      );
    }

    final violations = <String>[];
    final healthEvidence = <RolloutProgressionHealthEvidence>[];
    final failedHealthEvidence = <RolloutProgressionHealthEvidence>[];
    final decisions = <RolloutProgressionDecision>[];

    for (final record in _records) {
      decisions.add(record.decision);
      healthEvidence.addAll(record.healthEvidence);
      failedHealthEvidence.addAll(
        record.healthEvidence.where(
          (evidence) =>
              evidence.status == RolloutProgressionHealthStatus.failed,
        ),
      );

      if (record.healthEvidence.isEmpty) {
        violations.add('health_evidence missing');
      }
      for (final evidence in record.healthEvidence) {
        if (evidence.name.trim().isEmpty) {
          violations.add('health name missing');
        }
        if (evidence.source.trim().isEmpty) {
          violations.add('health source missing');
        }
      }
      if (record.rationale.trim().isEmpty) {
        violations.add('rationale missing');
      }
      if (failedHealthEvidence.isNotEmpty &&
          record.decision == RolloutProgressionDecision.expand) {
        violations.add('health_failure_ignored');
      }
    }

    final decision = decisions.length == 1 ? decisions.single : null;
    if (decisions.length > 1) {
      violations.add('multiple decisions');
    }
    if (decisions.toSet().length != decisions.length) {
      violations.add('duplicate decision');
    }

    return RolloutProgressionDecisionReport(
      state: violations.isEmpty
          ? RolloutProgressionState.pass
          : RolloutProgressionState.fail,
      decision: decision,
      healthEvidence: List<RolloutProgressionHealthEvidence>.unmodifiable(
        healthEvidence,
      ),
      failedHealthEvidence: List<RolloutProgressionHealthEvidence>.unmodifiable(
        failedHealthEvidence,
      ),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Kontrak lokal hanya merekam keputusan berdasarkan health evidence; '
            ' rollout execution, telemetry, dan publikasi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
