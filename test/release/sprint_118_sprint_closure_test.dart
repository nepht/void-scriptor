import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_sprint_closure.dart';

void main() {
  Sprint118ClosureEvidenceAnchor anchorWith({
    String entryState = 'pass',
    bool entryExecutionAllowed = true,
    bool correctiveScopeApproved = true,
    String releaseState = 'GA_DELAYED',
    String charterState = 'pass',
    String snapshotState = 'pass',
    bool snapshotFrozen = true,
    int registeredProviderCount = 32,
    int certifiedProviderCount = 0,
    String incidentState = 'pass',
    bool liveIncidentExecuted = false,
    String disableState = 'pass',
    String fixesState = 'pass',
    String maintenanceState = 'pass',
    String maintenanceDecision = 'NO_PATCH',
    String certificationState = 'pass',
    String expansionAcceptanceState = 'pass',
    String reportState = 'pass',
    bool reportVerified = true,
    int reportDeclaredSectionCount = 9,
    int reportExpectedSectionCount = 9,
    String readinessState = 'pass',
    bool readinessVerified = true,
    String readinessDecision = 'CORRECTIVE_STABILIZATION',
    bool allLedgerStepsResolved = true,
    List<String> missingEvidence = const <String>[],
    List<String> sourceViolations = const <String>[],
  }) => Sprint118ClosureEvidenceAnchor(
    entryState: entryState,
    entryExecutionAllowed: entryExecutionAllowed,
    correctiveScopeApproved: correctiveScopeApproved,
    releaseState: releaseState,
    charterState: charterState,
    snapshotState: snapshotState,
    snapshotFrozen: snapshotFrozen,
    registeredProviderCount: registeredProviderCount,
    certifiedProviderCount: certifiedProviderCount,
    incidentState: incidentState,
    liveIncidentExecuted: liveIncidentExecuted,
    disableState: disableState,
    fixesState: fixesState,
    maintenanceState: maintenanceState,
    maintenanceDecision: maintenanceDecision,
    certificationState: certificationState,
    expansionAcceptanceState: expansionAcceptanceState,
    reportState: reportState,
    reportVerified: reportVerified,
    reportDeclaredSectionCount: reportDeclaredSectionCount,
    reportExpectedSectionCount: reportExpectedSectionCount,
    readinessState: readinessState,
    readinessVerified: readinessVerified,
    readinessDecision: readinessDecision,
    allLedgerStepsResolved: allLedgerStepsResolved,
    missingEvidence: missingEvidence,
    sourceViolations: sourceViolations,
    readableSourceCount: Sprint118ClosureContract.sourceManifests.length,
    ledgerPath: Sprint118ClosureContract.ledgerPath,
  );

  Sprint118ClosureReport reportWith({Sprint118ClosureEvidenceAnchor? anchor}) =>
      Sprint118SprintClosure.evaluate(anchor: anchor ?? anchorWith());

  group('118.46 canonical contract', () {
    test('declares the seven definition-of-done items in canonical order', () {
      expect(Sprint118ClosureContract.canonicalStep, '118.46');
      expect(Sprint118ClosureContract.criteriaNames, <String>[
        'entry_gate_passed',
        'release_state_confirmed',
        'critical_incidents_resolved_or_connectors_disabled',
        'maintenance_decision_recorded',
        'expansion_certification_evidence_recorded',
        'report_complete',
        'next_direction_decided',
      ]);
    });

    test('keeps live release and external certification deferred', () {
      expect(Sprint118ClosureContract.externalGates, 'DEFERRED-EXTERNAL');
      expect(
        Sprint118ClosureContract.closedDecision,
        'CLOSED_LOCAL_DEFERRED_EXTERNAL',
      );
    });
  });

  group('118.46 closure judgement', () {
    test('closes locally when every committed criterion is satisfied', () {
      final report = reportWith();

      expect(report.state, Sprint118ClosureState.pass);
      expect(
        report.decision,
        Sprint118ClosureDecision.closedLocalDeferredExternal,
      );
      expect(report.satisfiedCount, 7);
      expect(report.unmetCriteria, isEmpty);
      expect(report.liveReleaseExecuted, isFalse);
    });

    test('does not close when release state drifts', () {
      final report = reportWith(
        anchor: anchorWith(releaseState: 'GA_RELEASED'),
      );

      expect(report.state, Sprint118ClosureState.blocked);
      expect(report.unmetCriteria, contains('release_state_confirmed'));
    });

    test(
      'does not close when a source is missing or violates its contract',
      () {
        final report = reportWith(
          anchor: anchorWith(
            missingEvidence: const <String>['docs/planning/v1.3/missing.json'],
            sourceViolations: const <String>['118.24:violation'],
          ),
        );

        expect(report.state, Sprint118ClosureState.blocked);
        expect(report.missingEvidence, hasLength(1));
        expect(report.violations, hasLength(1));
      },
    );

    test('requires next direction and all prior ledger steps', () {
      final report = reportWith(
        anchor: anchorWith(
          readinessDecision: 'CONNECTOR_ECOSYSTEM',
          allLedgerStepsResolved: false,
        ),
      );

      expect(report.state, Sprint118ClosureState.blocked);
      expect(report.unmetCriteria, contains('next_direction_decided'));
      expect(report.violations, contains('prior_sprint_steps_unresolved'));
    });
  });

  group('118.46 committed evidence', () {
    test('loads the committed sources and derives all criteria', () {
      final report = const Sprint118SprintClosureGate().evaluate();

      expect(report.anchor, isNotNull);
      expect(report.criteria, hasLength(7));
      expect(
        report.criteria.map((criterion) => criterion.name),
        Sprint118ClosureContract.criteriaNames,
      );
      expect(report.state, Sprint118ClosureState.pass);
    });

    test('cites repository evidence for every criterion', () {
      final report = const Sprint118SprintClosureGate().evaluate();

      for (final criterion in report.criteria) {
        expect(criterion.evidence, isNotEmpty);
        expect(criterion.detail.trim(), isNotEmpty);
        for (final path in criterion.evidence) {
          expect(path, startsWith('docs/'));
        }
      }
    });

    test('records the delayed release and zero certified providers', () {
      final anchor = const Sprint118SprintClosureGate().evaluate().anchor!;

      expect(anchor.releaseState, 'GA_DELAYED');
      expect(anchor.registeredProviderCount, 32);
      expect(anchor.certifiedProviderCount, 0);
      expect(anchor.readinessDecision, 'CORRECTIVE_STABILIZATION');
    });
  });
}
