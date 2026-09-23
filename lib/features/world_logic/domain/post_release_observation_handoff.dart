/// Local/deferred handoff contract for roadmap step 113.45.
library;

const List<String> _requiredOutputs = <String>[
  'health_baseline',
  'monitoring_owners',
  'incident_queue',
  'feedback_queue',
  'risk_register',
  'rollback_criteria',
  'observation_window',
];

enum HandoffOutputStatus { verifiedLocal, deferred, blocked }

enum ObservationHandoffState { blocked, fail, pass }

class HandoffOutput {
  const HandoffOutput({
    required this.status,
    required this.evidence,
    required this.note,
  });

  final HandoffOutputStatus status;
  final List<String> evidence;
  final String note;

  bool get structurallyComplete =>
      evidence.isNotEmpty &&
      evidence.every((item) => item.trim().isNotEmpty) &&
      note.trim().isNotEmpty;
}

class PostReleaseObservationHandoff {
  const PostReleaseObservationHandoff({
    required this.deferredRelease,
    required this.outputs,
  });

  static const String canonicalStep = '113.45';
  static const List<String> requiredOutputs = _requiredOutputs;

  final bool deferredRelease;
  final Map<String, HandoffOutput> outputs;

  static ObservationHandoffEvaluation evaluate(
    PostReleaseObservationHandoff? handoff,
  ) {
    if (handoff == null || handoff.outputs.isEmpty) {
      return const ObservationHandoffEvaluation(
        state: ObservationHandoffState.blocked,
        missing: _requiredOutputs,
        notes: <String>['no observation handoff recorded'],
      );
    }

    final missing = <String>[];
    for (final name in _requiredOutputs) {
      final output = handoff.outputs[name];
      if (output == null || !output.structurallyComplete) missing.add(name);
    }
    if (missing.isNotEmpty) {
      return ObservationHandoffEvaluation(
        state: ObservationHandoffState.blocked,
        missing: missing,
        notes: <String>['handoff outputs incomplete: ${missing.join(', ')}'],
      );
    }

    if (!handoff.deferredRelease) {
      return const ObservationHandoffEvaluation(
        state: ObservationHandoffState.fail,
        notes: <String>[
          'post-release observation requires an active published release; '
              'deferred handoff must be explicitly selected',
        ],
      );
    }

    return const ObservationHandoffEvaluation(
      state: ObservationHandoffState.pass,
      missing: <String>[],
      notes: <String>[
        'deferred-release observation handoff is structurally complete',
      ],
    );
  }
}

class ObservationHandoffEvaluation {
  const ObservationHandoffEvaluation({
    required this.state,
    this.missing = const <String>[],
    this.notes = const <String>[],
  });

  final ObservationHandoffState state;
  final List<String> missing;
  final List<String> notes;
}
