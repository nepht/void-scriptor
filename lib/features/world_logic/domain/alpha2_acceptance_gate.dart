// Sprint 110.49 - Alpha 2 Acceptance Gate (domain aggregator).
//
// Wave-2 (Sprint 110) ships ten feature capabilities across steps 110.3
// through 110.48. The Alpha 2 acceptance gate collects the canonical eight
// evidence items required by `sprint_110.json` step 110.49:
//
//   1. feature_acceptance       - every Wave-2 step has its verified contract.
//   2. determinism_results      - replay/seed determinism is green (110.43).
//   3. test_results             - domain suites (110.44) are green.
//   4. migration_results       - D-SCHEMA-01 is OPEN; the gate records the
//                                additive-only contract for migrations.
//   5. performance_results      - bench report from 110.45 stays within budget.
//   6. security_review         - 110.46 reports no actionRequired threats.
//   7. accessibility_review     - 110.47 reports clean/acceptable status.
//   8. rollback_readiness      - 110.6 / 110.42 recovery path is recorded.
//
// Domain-only, deterministic, no persistence, no UI, no wall clock,
// no locale, no random, no network.

library;

enum Alpha2EvidenceKind {
  featureAcceptance,
  determinismResults,
  testResults,
  migrationResults,
  performanceResults,
  securityReview,
  accessibilityReview,
  rollbackReadiness;

  String get slug {
    switch (this) {
      case Alpha2EvidenceKind.featureAcceptance:
        return 'feature_acceptance';
      case Alpha2EvidenceKind.determinismResults:
        return 'determinism_results';
      case Alpha2EvidenceKind.testResults:
        return 'test_results';
      case Alpha2EvidenceKind.migrationResults:
        return 'migration_results';
      case Alpha2EvidenceKind.performanceResults:
        return 'performance_results';
      case Alpha2EvidenceKind.securityReview:
        return 'security_review';
      case Alpha2EvidenceKind.accessibilityReview:
        return 'accessibility_review';
      case Alpha2EvidenceKind.rollbackReadiness:
        return 'rollback_readiness';
    }
  }
}

enum Alpha2EvidenceStatus { pass, passLocal, recorded, blocked }

class Alpha2FeatureScope {
  const Alpha2FeatureScope({
    required this.totalSteps,
    required this.verifiedSteps,
    required this.capabilities,
  });

  final int totalSteps;
  final int verifiedSteps;
  final List<String> capabilities;

  bool get allStepsVerified => verifiedSteps >= totalSteps;
}

class Alpha2Evidence {
  const Alpha2Evidence({
    required this.kind,
    required this.status,
    required this.sourceRevision,
    required this.notes,
  });

  final Alpha2EvidenceKind kind;
  final Alpha2EvidenceStatus status;
  final String sourceRevision;
  final String notes;

  bool get isCovered =>
      status == Alpha2EvidenceStatus.pass ||
      status == Alpha2EvidenceStatus.passLocal ||
      status == Alpha2EvidenceStatus.recorded;
}

class Alpha2AcceptanceReport {
  const Alpha2AcceptanceReport._({
    required this.scope,
    required this.evidences,
    required this.summary,
  });

  final Alpha2FeatureScope scope;
  final List<Alpha2Evidence> evidences;

  final String summary;

  factory Alpha2AcceptanceReport.from({
    required Alpha2FeatureScope scope,
    required List<Alpha2Evidence> evidences,
  }) {
    final blocked = evidences.where(
      (e) => e.status == Alpha2EvidenceStatus.blocked,
    );
    final uncovered = evidences.where((e) => !e.isCovered).toList();
    String decision;
    if (blocked.isNotEmpty) {
      decision = 'NO-GO';
    } else if (!scope.allStepsVerified || uncovered.isNotEmpty) {
      decision = 'GO_WITH_DOCUMENTED_RISK';
    } else {
      decision = 'GO';
    }
    final summary = StringBuffer('v1.2.0-alpha.2 decision=')
      ..write(decision)
      ..write('; evidence_count=')
      ..write(evidences.length)
      ..write('/')
      ..write(Alpha2EvidenceKind.values.length)
      ..write('; steps=')
      ..write(scope.verifiedSteps)
      ..write('/')
      ..write(scope.totalSteps);
    return Alpha2AcceptanceReport._(
      scope: scope,
      evidences: List<Alpha2Evidence>.unmodifiable(evidences),
      summary: summary.toString(),
    );
  }

  bool get isBlocked =>
      evidences.any((e) => e.status == Alpha2EvidenceStatus.blocked);

  bool get allEvidenceCovered => evidences.every((e) => e.isCovered);

  Alpha2Evidence evidenceFor(Alpha2EvidenceKind kind) =>
      evidences.firstWhere((e) => e.kind == kind);
}

class Alpha2AcceptanceGate {
  static List<Alpha2Evidence> buildCanonicalEvidence({
    required int verifiedSteps,
    int totalSteps = 10,
    required bool determinismGreen,
    required bool testResultsGreen,
    required bool benchReportWithinBudget,
    required String threatReviewFixStatus,
    required String a11yFixStatus,
    required bool rollbackRecorded,
  }) {
    assert(totalSteps > 0, 'totalSteps must be positive');
    assert(
      verifiedSteps >= 0 && verifiedSteps <= totalSteps,
      'verifiedSteps must be in [0, totalSteps]',
    );

    return <Alpha2Evidence>[
      Alpha2Evidence(
        kind: Alpha2EvidenceKind.featureAcceptance,
        status: verifiedSteps >= totalSteps
            ? Alpha2EvidenceStatus.pass
            : Alpha2EvidenceStatus.passLocal,
        sourceRevision: 'sprint_110.json:110.3-110.42',
        notes:
            '$verifiedSteps/$totalSteps Wave-2 capability contracts verified',
      ),
      Alpha2Evidence(
        kind: Alpha2EvidenceKind.determinismResults,
        status: determinismGreen
            ? Alpha2EvidenceStatus.pass
            : Alpha2EvidenceStatus.blocked,
        sourceRevision: 'sprint_110.json:110.43',
        notes: determinismGreen
            ? 'replay/seed suites green for Wave-2 modules'
            : 'replay/seed suite reported a failure',
      ),
      Alpha2Evidence(
        kind: Alpha2EvidenceKind.testResults,
        status: testResultsGreen
            ? Alpha2EvidenceStatus.pass
            : Alpha2EvidenceStatus.blocked,
        sourceRevision: 'sprint_110.json:110.44',
        notes: testResultsGreen
            ? 'unit + property + integration + contract + regression suites green'
            : 'one of the required test suites reported a failure',
      ),
      const Alpha2Evidence(
        kind: Alpha2EvidenceKind.migrationResults,
        status: Alpha2EvidenceStatus.recorded,
        sourceRevision: 'sprint_110.json:110.6',
        notes:
            'D-SCHEMA-01 OPEN; Wave-2 is additive-only with documented rollback',
      ),
      Alpha2Evidence(
        kind: Alpha2EvidenceKind.performanceResults,
        status: benchReportWithinBudget
            ? Alpha2EvidenceStatus.passLocal
            : Alpha2EvidenceStatus.blocked,
        sourceRevision: 'sprint_110.json:110.45',
        notes: benchReportWithinBudget
            ? 'bench report stays within budget across all six datasets'
            : 'one dataset missed its budget',
      ),
      Alpha2Evidence(
        kind: Alpha2EvidenceKind.securityReview,
        status: threatReviewFixStatus == 'actionRequired'
            ? Alpha2EvidenceStatus.blocked
            : (threatReviewFixStatus == 'clean'
                  ? Alpha2EvidenceStatus.pass
                  : Alpha2EvidenceStatus.passLocal),
        sourceRevision: 'sprint_110.json:110.46',
        notes: 'threat review fix status=$threatReviewFixStatus',
      ),
      Alpha2Evidence(
        kind: Alpha2EvidenceKind.accessibilityReview,
        status: a11yFixStatus == 'actionRequired'
            ? Alpha2EvidenceStatus.blocked
            : (a11yFixStatus == 'clean'
                  ? Alpha2EvidenceStatus.pass
                  : Alpha2EvidenceStatus.passLocal),
        sourceRevision: 'sprint_110.json:110.47',
        notes: 'a11y locale fix status=$a11yFixStatus',
      ),
      Alpha2Evidence(
        kind: Alpha2EvidenceKind.rollbackReadiness,
        status: rollbackRecorded
            ? Alpha2EvidenceStatus.passLocal
            : Alpha2EvidenceStatus.blocked,
        sourceRevision: 'sprint_110.json:110.6,110.42',
        notes: rollbackRecorded
            ? 'recovery path published via Wave-2 transparency catalog'
            : 'recovery path missing from the transparency catalog',
      ),
    ];
  }

  static const List<String> canonicalCapabilities = <String>[
    'world_time_state_authority',
    'route_network',
    'travel_mode_profiles',
    'calendar_system',
    'genealogy_model',
    'temporal_map_state',
    'faction_relationships',
    'power_system',
    'economy_model',
    'communication_rumor',
  ];
}
