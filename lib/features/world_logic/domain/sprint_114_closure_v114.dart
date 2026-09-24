/// Fail-closed local closure contract for Sprint 114.44.
///
/// DELAYED closes the local scope only. External release, telemetry,
/// signing, hosted CI, hardware, and publication remain deferred.
library;

enum Sprint114ClosureDecision { closedLocalDeferredExternal, blocked }

class Sprint114ClosureCriterion {
  Sprint114ClosureCriterion({
    required this.name,
    required this.passed,
    required this.evidence,
  });

  final String name;
  final bool passed;
  final String evidence;
}

class Sprint114ClosureReport {
  Sprint114ClosureReport({
    required this.criteria,
    required this.passedCount,
    required List<String> unmetCriteria,
    required List<String> violations,
    required this.decision,
    required this.summary,
  }) : unmetCriteria = List<String>.unmodifiable(unmetCriteria),
       violations = List<String>.unmodifiable(violations);

  final List<Sprint114ClosureCriterion> criteria;
  final int passedCount;
  final List<String> unmetCriteria;
  final List<String> violations;
  final Sprint114ClosureDecision decision;
  final String summary;

  String get externalGates => 'DEFERRED-EXTERNAL';

  bool get isClosed =>
      decision == Sprint114ClosureDecision.closedLocalDeferredExternal;
}

abstract final class Sprint114Closure {
  static const String canonicalStep = '114.44';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_114_sprint_closure.json';

  static const List<String> criteriaNames = <String>[
    'release_path_confirmed',
    'observation_completed_or_corrective_path_recorded',
    'critical_incidents_resolved_or_release_stopped',
    'stability_gate_decided',
    'patch_decision_recorded',
    'evidence_report_complete',
    'sprint_115_readiness_decided',
  ];

  static Sprint114ClosureReport evaluate({
    required List<Sprint114ClosureCriterion> criteria,
    required String releasePath,
  }) {
    final names = criteria.map((criterion) => criterion.name).toList();
    final canonical = criteriaNames.toSet();
    if (criteria.length != criteriaNames.length ||
        names.toSet().length != criteriaNames.length ||
        !names.every(canonical.contains)) {
      throw ArgumentError.value(
        criteria,
        'criteria',
        'must contain exactly the canonical seven criteria',
      );
    }

    final violations = <String>[];
    final normalizedPath = releasePath.trim();
    if (normalizedPath != 'DELAYED') {
      violations.add(
        normalizedPath == 'RELEASED' || normalizedPath == 'ROLLED_BACK'
            ? 'unsupported_local_closure_path_$normalizedPath'
            : 'unsupported_release_path',
      );
    }

    final unmet = <String>[];
    for (final criterion in criteria) {
      if (!criterion.passed) unmet.add(criterion.name);
      if (criterion.evidence.trim().isEmpty) {
        violations.add('${criterion.name}_missing_evidence');
      }
    }

    final passedCount = criteria.where((criterion) => criterion.passed).length;
    final decision = violations.isEmpty && unmet.isEmpty
        ? Sprint114ClosureDecision.closedLocalDeferredExternal
        : Sprint114ClosureDecision.blocked;

    return Sprint114ClosureReport(
      criteria: List<Sprint114ClosureCriterion>.unmodifiable(criteria),
      passedCount: passedCount,
      unmetCriteria: unmet,
      violations: violations,
      decision: decision,
      summary:
          'Sprint 114 local closure decision=${decision.name}; '
          'passed=$passedCount/${criteriaNames.length}; path=$normalizedPath',
    );
  }
}
