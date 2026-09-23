/// Local feedback/adoption evidence contract for Sprint 114.6.
///
/// This dependency-free model records outcome metadata only. Creative content,
/// prompts, manuscripts, and secrets are outside the intake scope.
class AdoptionEvidence {
  const AdoptionEvidence({
    required this.evidenceId,
    required this.source,
    required this.consent,
    required this.workflow,
    required this.outcome,
    required this.friction,
    required this.limitations,
    required this.confidence,
  });

  final String evidenceId;
  final String source;
  final String consent;
  final String workflow;
  final String outcome;
  final String friction;
  final List<String> limitations;
  final String confidence;
}

enum FeedbackAdoptionState { pass, fail, blocked }

class FeedbackAdoptionDecision {
  const FeedbackAdoptionDecision({
    required this.state,
    required this.evidenceCount,
    required this.missingFields,
    required this.notes,
  });

  final FeedbackAdoptionState state;
  final int evidenceCount;
  final List<String> missingFields;
  final List<String> notes;
}

class FeedbackAdoptionIntake {
  final List<AdoptionEvidence> _records = <AdoptionEvidence>[];

  List<AdoptionEvidence> get records =>
      List<AdoptionEvidence>.unmodifiable(_records);

  void add(AdoptionEvidence evidence) => _records.add(evidence);

  FeedbackAdoptionDecision evaluate() {
    if (_records.isEmpty) {
      return const FeedbackAdoptionDecision(
        state: FeedbackAdoptionState.blocked,
        evidenceCount: 0,
        missingFields: <String>[],
        notes: <String>[
          'Belum ada evidence adopsi nyata; external adoption '
              'DEFERRED-EXTERNAL.',
        ],
      );
    }

    final missing = <String>[];
    for (final evidence in _records) {
      if (evidence.evidenceId.trim().isEmpty) missing.add('evidence_id');
      if (evidence.source.trim().isEmpty) missing.add('source');
      if (evidence.consent.trim().isEmpty) missing.add('consent');
      if (evidence.workflow.trim().isEmpty) missing.add('workflow');
      if (evidence.outcome.trim().isEmpty) missing.add('outcome');
      if (evidence.friction.trim().isEmpty) missing.add('friction');
      if (evidence.limitations.isEmpty) missing.add('limitations');
      if (evidence.confidence.trim().isEmpty) missing.add('confidence');
    }

    return FeedbackAdoptionDecision(
      state: missing.isEmpty
          ? FeedbackAdoptionState.pass
          : FeedbackAdoptionState.fail,
      evidenceCount: _records.length,
      missingFields: List<String>.unmodifiable(missing),
      notes: const <String>[
        'Intake menyimpan metadata workflow dan outcome saja; '
            'creative content dan secret tidak dikumpulkan.',
      ],
    );
  }
}
