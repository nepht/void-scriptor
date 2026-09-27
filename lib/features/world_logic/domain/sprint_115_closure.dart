/// Fail-closed local closure contract for Sprint 115.56.
///
/// Sprint 115 closes locally after the alpha decision is recorded.
/// External release, connector certification, billing, hosted CI, telemetry,
/// hardware, and publication remain deferred.
library;

enum Sprint115ClosureDecision { closedLocalDeferredExternal, blocked }

class Sprint115ClosureCriterion {
  const Sprint115ClosureCriterion({
    required this.name,
    required this.passed,
    required this.evidence,
  });

  final String name;
  final bool passed;
  final String evidence;
}

class Sprint115ClosureReport {
  const Sprint115ClosureReport({
    required this.criteria,
    required this.passedCount,
    required this.unmetCriteria,
    required this.decision,
    required this.summary,
  });

  final List<Sprint115ClosureCriterion> criteria;
  final int passedCount;
  final List<String> unmetCriteria;
  final Sprint115ClosureDecision decision;
  final String summary;

  bool get isClosed =>
      decision == Sprint115ClosureDecision.closedLocalDeferredExternal;
}

abstract final class Sprint115Closure {
  static const String canonicalStep = '115.56';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_sprint_closure.json';

  static const List<String> criteriaNames = <String>[
    'entry_gate_passed',
    'global_scope_enforced',
    'reference_layout_implemented',
    'provider_icons_registry_complete',
    'mock_values_blocked_from_production',
    'security_privacy_verified',
    'responsive_accessible',
    'alpha_decision_recorded',
  ];

  static const String alphaDecisionLocalScope =
      'ALPHA_ACCEPTED_LOCAL_DEFERRED_EXTERNAL';

  static Sprint115ClosureReport evaluate({
    required List<Sprint115ClosureCriterion> criteria,
    required String alphaDecision,
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
    if (alphaDecision != alphaDecisionLocalScope) {
      throw ArgumentError.value(
        alphaDecision,
        'alphaDecision',
        'only $alphaDecisionLocalScope is permitted by the local closure contract',
      );
    }

    final unmet = <String>[
      for (final criterion in criteria)
        if (!criterion.passed) criterion.name,
    ];
    final passedCount = criteria.where((criterion) => criterion.passed).length;
    final decision = unmet.isEmpty
        ? Sprint115ClosureDecision.closedLocalDeferredExternal
        : Sprint115ClosureDecision.blocked;

    return Sprint115ClosureReport(
      criteria: List<Sprint115ClosureCriterion>.unmodifiable(criteria),
      passedCount: passedCount,
      unmetCriteria: List<String>.unmodifiable(unmet),
      decision: decision,
      summary:
          'Sprint 115 local closure decision=${decision.name}; '
          'passed=$passedCount/${criteriaNames.length}; '
          'alpha=$alphaDecision',
    );
  }
}
