/// Execution gate for roadmap step 117.46.
library;

const List<String> _requiredOutputs = <String>[
  'approval_recorded',
  'artifact_published',
  'connector_subset_enforced',
  'uncertified_hidden',
  'monitoring_active',
  'support_ready',
  'rollback_available',
];

enum Sprint117GaOutputStatus { verified, unverifiable, blocked }

enum Sprint117GaReleaseExecutionState { blocked, fail, pass }

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
