/// Sprint 113.46 local closure contract.
///
/// DEFERRED_RELEASE is terminal for local closure: it records that external
/// release gates are stopped, without claiming publication or observation.
library;

enum Sprint113ClosureDecision { closedLocalDeferredRelease, blocked }

class Sprint113ClosureCriterion {
  const Sprint113ClosureCriterion({
    required this.name,
    required this.passed,
    required this.evidence,
  });

  final String name;
  final bool passed;
  final String evidence;
}

class Sprint113ClosureReport {
  const Sprint113ClosureReport({
    required this.criteria,
    required this.passedCount,
    required this.unmetCriteria,
    required this.decision,
    required this.summary,
  });

  final List<Sprint113ClosureCriterion> criteria;
  final int passedCount;
  final List<String> unmetCriteria;
  final Sprint113ClosureDecision decision;
  final String summary;

  bool get isClosed =>
      decision == Sprint113ClosureDecision.closedLocalDeferredRelease;
}

abstract final class Sprint113Closure {
  static const List<String> criteriaNames = <String>[
    'entry_gate_passed',
    'validation_window_completed',
    'release_blockers_resolved_or_release_stopped',
    'quality_gates_passed',
    'ga_decision_recorded',
    'staged_rollout_controlled',
    'observation_handoff_complete',
  ];

  static final List<Sprint113ClosureCriterion>
  canonicalCriteria = List<Sprint113ClosureCriterion>.unmodifiable(<
    Sprint113ClosureCriterion
  >[
    for (final name in criteriaNames)
      Sprint113ClosureCriterion(
        name: name,
        passed: true,
        evidence:
            'docs/planning/v1.2/sprint_113_post_release_observation_handoff.json',
      ),
  ]);

  static Sprint113ClosureReport evaluate({
    required List<Sprint113ClosureCriterion> criteria,
    required String gaDecision,
  }) {
    if (criteria.length != criteriaNames.length ||
        criteria.map((criterion) => criterion.name).toSet().length !=
            criteriaNames.length ||
        !criteriaNames.every(
          (name) => criteria.any((criterion) => criterion.name == name),
        )) {
      throw ArgumentError.value(
        criteria,
        'criteria',
        'must contain exactly the canonical seven criteria',
      );
    }
    if (gaDecision != 'DEFERRED_RELEASE') {
      throw ArgumentError.value(
        gaDecision,
        'gaDecision',
        'only DEFERRED_RELEASE is permitted by the local closure contract',
      );
    }

    final unmet = <String>[
      for (final criterion in criteria)
        if (!criterion.passed) criterion.name,
    ];
    final passedCount = criteria.where((criterion) => criterion.passed).length;
    final decision = unmet.isEmpty
        ? Sprint113ClosureDecision.closedLocalDeferredRelease
        : Sprint113ClosureDecision.blocked;

    return Sprint113ClosureReport(
      criteria: List<Sprint113ClosureCriterion>.unmodifiable(criteria),
      passedCount: passedCount,
      unmetCriteria: List<String>.unmodifiable(unmet),
      decision: decision,
      summary:
          'Sprint 113 local closure decision=${decision.name}; '
          'passed=$passedCount/${criteriaNames.length}; ga=$gaDecision',
    );
  }
}
