/// Sprint 112.54 domain-only closure contract.
///
/// External distribution gates remain explicit inputs: a deferred RC decision
/// must never be promoted to CLOSED by this evaluator.
library;

enum Sprint112ClosureDecision { closed, deferred, blocked }

class Sprint112ClosureCriterion {
  const Sprint112ClosureCriterion({
    required this.name,
    required this.passed,
    required this.evidence,
  });

  final String name;
  final bool passed;
  final String evidence;
}

class Sprint112ClosureReport {
  const Sprint112ClosureReport({
    required this.criteria,
    required this.passedCount,
    required this.unmetCriteria,
    required this.decision,
    required this.summary,
  });

  final List<Sprint112ClosureCriterion> criteria;
  final int passedCount;
  final List<String> unmetCriteria;
  final Sprint112ClosureDecision decision;
  final String summary;

  bool get isClosed => decision == Sprint112ClosureDecision.closed;
}

abstract final class Sprint112Closure {
  static const List<String> criteriaNames = <String>[
    'entry_gate_passed',
    'scope_frozen',
    '29_unique_features_accounted_for',
    'feature_30_alias_validated',
    'integration_verified',
    'quality_gates_complete',
    'rc_decision_recorded',
    'remaining_risks_owned',
  ];

  static final List<Sprint112ClosureCriterion> canonicalCriteria =
      List<Sprint112ClosureCriterion>.unmodifiable(<Sprint112ClosureCriterion>[
        for (final name in criteriaNames)
          Sprint112ClosureCriterion(
            name: name,
            passed: true,
            evidence: 'docs/planning/v1.2/sprint_112_rc_approval_gate.json',
          ),
      ]);

  static Sprint112ClosureReport evaluate({
    required List<Sprint112ClosureCriterion> criteria,
    required String rcDecision,
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
        'must contain exactly the canonical eight criteria',
      );
    }

    final unmet = <String>[
      for (final criterion in criteria)
        if (!criterion.passed) criterion.name,
    ];
    final passedCount = criteria.where((criterion) => criterion.passed).length;
    final decision = rcDecision == 'BLOCKED'
        ? Sprint112ClosureDecision.blocked
        : (unmet.isEmpty && rcDecision == 'APPROVED'
              ? Sprint112ClosureDecision.closed
              : Sprint112ClosureDecision.deferred);

    return Sprint112ClosureReport(
      criteria: List<Sprint112ClosureCriterion>.unmodifiable(criteria),
      passedCount: passedCount,
      unmetCriteria: List<String>.unmodifiable(unmet),
      decision: decision,
      summary:
          'Sprint 112 closure decision=${decision.name.toUpperCase()}; '
          'passed=$passedCount/${criteriaNames.length}; rc=$rcDecision',
    );
  }
}
