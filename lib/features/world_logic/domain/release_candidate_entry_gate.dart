import 'alpha2_acceptance_gate.dart';
import 'encyclopedia_wave3_beta_gate.dart';
import 'encyclopedia_wave3_closure.dart' as wave3;
import 'sprint_110_closure.dart';

enum RcEvidenceStatus {
  accepted,
  acceptedWithRisk,
  ready,
  readyWithLimits,
  blocked,
}

enum RcEntryDecision { ready, readyWithOwnedRisk, blocked }

class RcEntryEvidence {
  const RcEntryEvidence._({
    required this.id,
    required this.status,
    required this.source,
    required this.summary,
  });

  factory RcEntryEvidence.validated({
    required String id,
    required RcEvidenceStatus status,
    required String source,
    required String summary,
  }) {
    if (id.trim().isEmpty || source.trim().isEmpty || summary.trim().isEmpty) {
      throw ArgumentError('id/source/summary must be non-empty');
    }
    return RcEntryEvidence._(
      id: id.trim(),
      status: status,
      source: source.trim(),
      summary: summary.trim(),
    );
  }

  final String id;
  final RcEvidenceStatus status;
  final String source;
  final String summary;

  bool get isBlocked => status == RcEvidenceStatus.blocked;
  bool get carriesRisk =>
      status == RcEvidenceStatus.acceptedWithRisk ||
      status == RcEvidenceStatus.readyWithLimits;
}

class RcOpenRisk {
  const RcOpenRisk._({
    required this.id,
    required this.title,
    required this.owner,
    required this.mitigation,
  });

  factory RcOpenRisk.validated({
    required String id,
    required String title,
    required String owner,
    required String mitigation,
  }) {
    if (id.trim().isEmpty ||
        title.trim().isEmpty ||
        owner.trim().isEmpty ||
        mitigation.trim().isEmpty) {
      throw ArgumentError('id/title/owner/mitigation must be non-empty');
    }
    return RcOpenRisk._(
      id: id.trim(),
      title: title.trim(),
      owner: owner.trim(),
      mitigation: mitigation.trim(),
    );
  }

  final String id;
  final String title;
  final String owner;
  final String mitigation;
}

class RcEntryReport {
  const RcEntryReport._({
    required this.evidence,
    required this.openRisks,
    required this.decision,
  });

  static const requiredEvidenceIds = <String>[
    'sprint_109_acceptance',
    'sprint_110_acceptance',
    'sprint_111_acceptance',
    'open_risk_register',
    'migration_readiness',
  ];

  factory RcEntryReport.fromEvidence({
    required List<RcEntryEvidence> evidence,
    required List<RcOpenRisk> openRisks,
  }) {
    final byId = <String, RcEntryEvidence>{};
    for (final entry in evidence) {
      if (byId.containsKey(entry.id)) {
        throw StateError('duplicate evidence: ${entry.id}');
      }
      byId[entry.id] = entry;
    }
    for (final requiredId in requiredEvidenceIds) {
      if (!byId.containsKey(requiredId)) {
        throw StateError('missing required evidence: $requiredId');
      }
    }
    if (byId.length != requiredEvidenceIds.length) {
      throw StateError('unknown entry-gate evidence supplied');
    }

    final ordered = <RcEntryEvidence>[
      for (final id in requiredEvidenceIds) byId[id]!,
    ];
    final hasBlocked = ordered.any((entry) => entry.isBlocked);
    final hasOwnedRisk =
        ordered.any((entry) => entry.carriesRisk) || openRisks.isNotEmpty;
    final decision = hasBlocked
        ? RcEntryDecision.blocked
        : (hasOwnedRisk
              ? RcEntryDecision.readyWithOwnedRisk
              : RcEntryDecision.ready);
    return RcEntryReport._(
      evidence: List<RcEntryEvidence>.unmodifiable(ordered),
      openRisks: List<RcOpenRisk>.unmodifiable(openRisks),
      decision: decision,
    );
  }

  final List<RcEntryEvidence> evidence;
  final List<RcOpenRisk> openRisks;
  final RcEntryDecision decision;

  bool get isEntryAllowed => decision != RcEntryDecision.blocked;

  RcEntryEvidence evidenceFor(String id) =>
      evidence.firstWhere((entry) => entry.id == id);

  String describe() {
    final verdict = switch (decision) {
      RcEntryDecision.ready => 'READY',
      RcEntryDecision.readyWithOwnedRisk => 'READY_WITH_OWNED_RISK',
      RcEntryDecision.blocked => 'BLOCKED',
    };
    final buffer = StringBuffer('112.1 RC ENTRY $verdict');
    for (final entry in evidence) {
      buffer.write('\n- ${entry.id}: ${entry.status.name} — ${entry.summary}');
    }
    buffer.write('\nopen_risks=${openRisks.length}');
    return buffer.toString();
  }
}

abstract final class ReleaseCandidateEntryGate {
  static RcEntryReport evaluateCanonical() {
    final alpha2Evidence = Alpha2AcceptanceGate.buildCanonicalEvidence(
      verifiedSteps: 10,
      determinismGreen: true,
      testResultsGreen: true,
      benchReportWithinBudget: true,
      threatReviewFixStatus: 'clean',
      a11yFixStatus: 'acceptable',
      rollbackRecorded: true,
    );
    final alpha2 = Alpha2AcceptanceReport.from(
      scope: const Alpha2FeatureScope(
        totalSteps: 10,
        verifiedSteps: 10,
        capabilities: Alpha2AcceptanceGate.canonicalCapabilities,
      ),
      evidences: alpha2Evidence,
    );
    final sprint110 = Sprint110Closure.evaluate(
      dod: <ClosureDoD>[
        for (final key in Sprint110Closure.dodKeys)
          ClosureDoD.validated(
            key: key,
            passed: true,
            sourceRevision: 'sprint_110.json:110.50:$key',
          ),
      ],
      alpha2Report: alpha2,
    );

    final beta1 = Wave3BetaGateReport.evaluate();
    final sprint111 = wave3.SprintClosureReport.evaluate();
    final risks = <RcOpenRisk>[
      for (final risk in wave3.Wave3ClosureRisks.canonical)
        RcOpenRisk.validated(
          id: risk.riskId,
          title: risk.title,
          owner: risk.owner,
          mitigation: risk.plan,
        ),
      RcOpenRisk.validated(
        id: 'sprint-109-closure-pending',
        title:
            'Sprint 109 closure row remains pending after accepted Alpha 1 gate',
        owner: 'Sprint 112 risk burn-down',
        mitigation:
            'Preserve the accepted-with-risk decision and reconcile historical closure before RC approval.',
      ),
      RcOpenRisk.validated(
        id: 'hosted-ci-billing-gate',
        title:
            'GitHub Actions cannot execute while account billing gate is active',
        owner: 'Choirudin / GitHub account billing',
        mitigation:
            'Resolve Billing & plans, then rerun exact-SHA hosted checks before RC approval.',
      ),
    ];

    return RcEntryReport.fromEvidence(
      evidence: <RcEntryEvidence>[
        RcEntryEvidence.validated(
          id: 'sprint_109_acceptance',
          status: RcEvidenceStatus.acceptedWithRisk,
          source: 'docs/release/v1.2.0-alpha.1-acceptance-gate.md',
          summary:
              'Alpha 1 is GO_WITH_DOCUMENTED_RISK for local/offline evaluation; 109.52 remains pending.',
        ),
        RcEntryEvidence.validated(
          id: 'sprint_110_acceptance',
          status: sprint110.isClosed
              ? RcEvidenceStatus.accepted
              : RcEvidenceStatus.blocked,
          source: 'sprint_110.json:110.49-110.50',
          summary: sprint110.summary,
        ),
        RcEntryEvidence.validated(
          id: 'sprint_111_acceptance',
          status: beta1.isReadyForBeta && sprint111.isClosed
              ? RcEvidenceStatus.accepted
              : RcEvidenceStatus.blocked,
          source: 'sprint_111.json:111.45-111.46',
          summary: '${beta1.verdict}; ${sprint111.verdict}',
        ),
        RcEntryEvidence.validated(
          id: 'open_risk_register',
          status: risks.isEmpty
              ? RcEvidenceStatus.ready
              : RcEvidenceStatus.readyWithLimits,
          source: 'sprint_111.json:111.46 + live repository audit',
          summary: '${risks.length} open/deferred risks are explicitly owned.',
        ),
        RcEntryEvidence.validated(
          id: 'migration_readiness',
          status: RcEvidenceStatus.readyWithLimits,
          source: 'sprint_110.json:110.6,110.49; sprint_111.json:111.45-111.46',
          summary:
              'Backup/rollback contracts are recorded; D-SCHEMA-01 remains open for Sprint 112 integration.',
        ),
      ],
      openRisks: risks,
    );
  }
}
