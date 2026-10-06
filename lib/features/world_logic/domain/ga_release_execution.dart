/// Execution gate for roadmap step 117.46.
library;

const List<String> _requiredOutputs = <String>[
  'approval_recorded',
  'artifact_published',
  'release_notes_published',
  'support_notified',
  'monitoring_active',
  'rollback_available',
];

enum GaOutputStatus { verified, unverifiable, blocked }

enum GaReleaseExecutionState { blocked, fail, pass }

class GaOutputRecord {
  const GaOutputRecord({
    required this.status,
    required this.evidence,
    required this.note,
  });

  final GaOutputStatus status;
  final List<String> evidence;
  final String note;

  bool get verified =>
      status == GaOutputStatus.verified &&
      evidence.isNotEmpty &&
      evidence.every((item) => item.trim().isNotEmpty) &&
      note.trim().isNotEmpty;
}

class GaReleaseExecution {
  const GaReleaseExecution({
    required this.approvalAuthorized,
    required this.outputs,
  });

  static const String canonicalStep = '117.46';
  static const List<String> requiredOutputs = _requiredOutputs;

  final bool approvalAuthorized;
  final Map<String, GaOutputRecord> outputs;

  static GaReleaseEvaluation evaluate(GaReleaseExecution? execution) {
    if (execution == null || execution.outputs.isEmpty) {
      return const GaReleaseEvaluation(
        state: GaReleaseExecutionState.blocked,
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
      return GaReleaseEvaluation(
        state: GaReleaseExecutionState.blocked,
        missing: missing,
        notes: <String>[
          'external execution evidence missing or unverified: ${missing.join(', ')}',
        ],
      );
    }
    if (!execution.approvalAuthorized) {
      return const GaReleaseEvaluation(
        state: GaReleaseExecutionState.fail,
        notes: <String>['execution authorization is required'],
      );
    }
    return const GaReleaseEvaluation(
      state: GaReleaseExecutionState.pass,
      missing: <String>[],
      notes: <String>['all six GA execution outputs verified'],
    );
  }
}

class GaReleaseEvaluation {
  const GaReleaseEvaluation({
    required this.state,
    this.missing = const <String>[],
    this.notes = const <String>[],
  });

  final GaReleaseExecutionState state;
  final List<String> missing;
  final List<String> notes;
}
