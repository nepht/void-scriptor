/// Fail-closed local closure contract for Sprint 116.52.
///
/// Sprint 116 closes locally after the beta acceptance decision is recorded.
/// Live beta execution, provider handshake, credentials, quota, hosted CI,
/// billing settlement, hardware, and publication remain deferred.
library;

enum Sprint116ClosureDecision { closedLocalDeferredExternal, blocked }

class Sprint116ClosureCriterion {
  const Sprint116ClosureCriterion({
    required this.name,
    required this.passed,
    required this.evidence,
  });

  final String name;
  final bool passed;
  final String evidence;
}

class Sprint116ClosureReport {
  const Sprint116ClosureReport({
    required this.criteria,
    required this.passedCount,
    required this.unmetCriteria,
    required this.decision,
    required this.summary,
  });

  final List<Sprint116ClosureCriterion> criteria;
  final int passedCount;
  final List<String> unmetCriteria;
  final Sprint116ClosureDecision decision;
  final String summary;

  bool get isClosed =>
      decision == Sprint116ClosureDecision.closedLocalDeferredExternal;
}

abstract final class Sprint116Closure {
  static const String canonicalStep = '116.52';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_sprint_closure.json';

  static const List<String> criteriaNames = <String>[
    '32_providers_accounted_for',
    'no_bulk_fake_certification',
    'icons_reviewed',
    'quality_gates_complete',
    'uncertified_hidden_or_labeled',
    'beta_decision_recorded',
    'remaining_risks_owned',
  ];

  static const String betaDecisionLocalScope = 'BETA_ACCEPTANCE_LOCAL_READY';

  static Sprint116ClosureReport evaluate({
    required List<Sprint116ClosureCriterion> criteria,
    required String betaDecision,
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
    if (betaDecision != betaDecisionLocalScope) {
      throw ArgumentError.value(
        betaDecision,
        'betaDecision',
        'only $betaDecisionLocalScope is permitted by the local closure contract',
      );
    }
    for (final criterion in criteria) {
      if (criterion.evidence.trim().isEmpty) {
        throw ArgumentError.value(
          criterion,
          'criteria',
          '${criterion.name} requires non-empty evidence',
        );
      }
    }

    final unmet = <String>[
      for (final criterion in criteria)
        if (!criterion.passed) criterion.name,
    ];
    final passedCount = criteria.where((criterion) => criterion.passed).length;
    final decision = unmet.isEmpty
        ? Sprint116ClosureDecision.closedLocalDeferredExternal
        : Sprint116ClosureDecision.blocked;

    return Sprint116ClosureReport(
      criteria: List<Sprint116ClosureCriterion>.unmodifiable(criteria),
      passedCount: passedCount,
      unmetCriteria: List<String>.unmodifiable(unmet),
      decision: decision,
      summary:
          'Sprint 116 local closure decision=${decision.name}; '
          'passed=$passedCount/${criteriaNames.length}; '
          'beta=$betaDecision',
    );
  }
}
