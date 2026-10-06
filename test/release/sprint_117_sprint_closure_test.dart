import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_sprint_closure.dart';

void main() {
  /// A synthetic anchor used to exercise the judgement logic in isolation.
  ///
  /// It deliberately mirrors what the committed manifests currently say, so a
  /// test that flips one field is proving that field -- and only that field --
  /// decides the criterion.
  Sprint117ClosureEvidenceAnchor anchorWith({
    String entryState = 'pass',
    String entryVerdict = 'BETA_ENTRY_LOCAL_READY',
    String canonicalEntryReadiness =
        'BLOCKED_NO_CERTIFIED_CONNECTOR_CURRENTLY_RECORDED',
    bool canonicalEntryBlockResolved = true,
    bool entryLiveBetaExecuted = false,
    int entryRegistryProviderCount = 32,
    String charterState = 'pass',
    String charterVerdict = 'CHARTER_COMPLETE_LOCAL',
    int betaWindowStartMs = 1791158400000,
    int betaWindowEndMs = 1794787200000,
    int betaWindowDays = 42,
    int betaWindowPhaseCount = 3,
    String cohortState = 'fail',
    String cohortVerdict = 'COHORT_CONSENT_VERIFICATION_FAILED',
    int verifiedCohortSize = 0,
    bool cohortLiveBetaExecuted = false,
    String certificationVerdict = 'CERTIFICATION_SNAPSHOT_LOCKED_LOCAL',
    String certificationScope = 'local_certification_freeze_only',
    int lockedProviderCount = 32,
    int lockedCertifiedCount = 30,
    int lockedLimitedCount = 1,
    int lockedBlockedCount = 1,
    String matrixVerdict = 'BETA_EXPOSURE_MATRIX_DETERMINED_LOCAL',
    String masterFlag = 'beta.connectors.enabled',
    String matrixDefault = 'OFF',
    int matrixRowCount = 31,
    bool consentGateVerified = false,
    List<String> enabledSubset = const <String>[],
    List<String> determinedExposed = const <String>['openai', 'gemini'],
    String registryVerdict = 'FINAL_CONNECTOR_REGISTRY_RECONCILED_LOCAL',
    int registryProviderCount = 32,
    int registryCertifiedCount = 0,
    int registryUnverifiedCount = 32,
    int registryWithheldCount = 32,
    int registryExposedCount = 0,
    String rolloutState = 'pass',
    String rolloutVerdict = 'STAGED_GA_ROLLOUT_PLAN_DEFINED_LOCAL',
    int rolloutStageCount = 3,
    String rolloutDefault = 'OFF',
    List<String> rolloutEnabledSubset = const <String>[],
    int rolloutKillSwitchCount = 2,
    int rolloutKillSwitchDrilledCount = 0,
    int rolloutRollbackCount = 3,
    int rolloutRollbackVerifiedCount = 0,
    String gaStatus = 'VERIFIED-LOCAL',
    String gaDecision = 'DELAY',
    String gaApprovalState = 'PENDING_CHOIRUDIN',
    bool gaExecutionAuthorized = false,
    bool gaReleaseBlocked = true,
    bool gaQualityGatesPresent = true,
    List<String> gaQualityGateSources = const <String>[
      'docs/sprints/sprint-117-beta-validation.md',
      'docs/evidence/sprint-117-35-manifest-20261002.json',
      'docs/evidence/sprint-117-36-manifest-20261002.json',
    ],
    List<String> gaOpenItems = const <String>[
      '117.41: zero CERTIFIED connectors',
    ],
    String handoffState = 'pass',
    String handoffVerdict = 'POST_RELEASE_OBSERVATION_HANDOFF_DEFINED_LOCAL',
    int handoffResolvedOutputs = 8,
    int handoffRequiredOutputs = 8,
    int handoffViolationCount = 0,
    bool handoffLiveReleaseObserved = false,
    String ledgerPath = Sprint117ClosureContract.ledgerPath,
  }) => Sprint117ClosureEvidenceAnchor(
    entryState: entryState,
    entryVerdict: entryVerdict,
    canonicalEntryReadiness: canonicalEntryReadiness,
    canonicalEntryBlockResolved: canonicalEntryBlockResolved,
    entryLiveBetaExecuted: entryLiveBetaExecuted,
    entryRegistryProviderCount: entryRegistryProviderCount,
    charterState: charterState,
    charterVerdict: charterVerdict,
    betaWindowStartMs: betaWindowStartMs,
    betaWindowEndMs: betaWindowEndMs,
    betaWindowDays: betaWindowDays,
    betaWindowPhaseCount: betaWindowPhaseCount,
    cohortState: cohortState,
    cohortVerdict: cohortVerdict,
    verifiedCohortSize: verifiedCohortSize,
    cohortLiveBetaExecuted: cohortLiveBetaExecuted,
    certificationVerdict: certificationVerdict,
    certificationScope: certificationScope,
    lockedProviderCount: lockedProviderCount,
    lockedCertifiedCount: lockedCertifiedCount,
    lockedLimitedCount: lockedLimitedCount,
    lockedBlockedCount: lockedBlockedCount,
    matrixVerdict: matrixVerdict,
    masterFlag: masterFlag,
    matrixDefault: matrixDefault,
    matrixRowCount: matrixRowCount,
    consentGateVerified: consentGateVerified,
    enabledSubset: enabledSubset,
    determinedExposed: determinedExposed,
    registryVerdict: registryVerdict,
    registryProviderCount: registryProviderCount,
    registryCertifiedCount: registryCertifiedCount,
    registryUnverifiedCount: registryUnverifiedCount,
    registryWithheldCount: registryWithheldCount,
    registryExposedCount: registryExposedCount,
    rolloutState: rolloutState,
    rolloutVerdict: rolloutVerdict,
    rolloutStageCount: rolloutStageCount,
    rolloutDefault: rolloutDefault,
    rolloutEnabledSubset: rolloutEnabledSubset,
    rolloutKillSwitchCount: rolloutKillSwitchCount,
    rolloutKillSwitchDrilledCount: rolloutKillSwitchDrilledCount,
    rolloutRollbackCount: rolloutRollbackCount,
    rolloutRollbackVerifiedCount: rolloutRollbackVerifiedCount,
    gaStatus: gaStatus,
    gaDecision: gaDecision,
    gaApprovalState: gaApprovalState,
    gaExecutionAuthorized: gaExecutionAuthorized,
    gaReleaseBlocked: gaReleaseBlocked,
    gaQualityGatesPresent: gaQualityGatesPresent,
    gaQualityGateSources: gaQualityGateSources,
    gaOpenItems: gaOpenItems,
    handoffState: handoffState,
    handoffVerdict: handoffVerdict,
    handoffResolvedOutputs: handoffResolvedOutputs,
    handoffRequiredOutputs: handoffRequiredOutputs,
    handoffViolationCount: handoffViolationCount,
    handoffLiveReleaseObserved: handoffLiveReleaseObserved,
    ledgerPath: ledgerPath,
  );

  Sprint117ClosureReport reportWith({
    Sprint117ClosureEvidenceAnchor? anchor,
    String releaseDecision = 'DELAY',
    String releaseDecisionOwner = 'PENDING_CHOIRUDIN',
  }) {
    final resolved = anchor ?? anchorWith();
    return Sprint117SprintClosure.evaluate(
      criteria: Sprint117SprintClosure.deriveCriteria(resolved),
      releaseDecision: releaseDecision,
      releaseDecisionOwner: releaseDecisionOwner,
      anchor: resolved,
    );
  }

  group('117.48 canonical contract', () {
    test('declares the seven canonical definition-of-done items in order', () {
      expect(Sprint117ClosureContract.canonicalStep, '117.48');
      expect(Sprint117ClosureContract.criteriaNames, <String>[
        'entry_gate_passed',
        'beta_window_complete',
        'visible_connectors_certified_or_limited',
        'quality_gates_passed',
        'ga_decision_recorded',
        'staged_rollout_controlled',
        'observation_handoff_complete',
      ]);
      expect(Sprint117ClosureContract.criteriaNames.length, 7);
    });

    test('every external gate is deferred, never satisfied', () {
      expect(Sprint117ClosureContract.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('names every source manifest the closure reads', () {
      expect(Sprint117ClosureContract.sourceManifests, <String>[
        Sprint117ClosureContract.entryGatePath,
        Sprint117ClosureContract.charterPath,
        Sprint117ClosureContract.cohortPath,
        Sprint117ClosureContract.certificationPath,
        Sprint117ClosureContract.matrixPath,
        Sprint117ClosureContract.registryPath,
        Sprint117ClosureContract.rolloutPath,
        Sprint117ClosureContract.gaApprovalPath,
        Sprint117ClosureContract.handoffPath,
      ]);
      for (final path in Sprint117ClosureContract.sourceManifests) {
        expect(path, startsWith('docs/'));
      }
    });

    test('a local closure can only record a delay, never a release', () {
      expect(Sprint117ClosureContract.delayDecision, 'DELAY');
      expect(
        Sprint117ClosureContract.closedDecision,
        'CLOSED_LOCAL_DEFERRED_EXTERNAL',
      );
    });
  });

  group('117.48 gate — committed evidence', () {
    test('reads committed manifests and derives all seven criteria', () {
      final report = const Sprint117SprintClosureGate().evaluate();

      expect(
        report.anchor,
        isNotNull,
        reason: 'every source manifest must be committed and readable',
      );
      expect(
        report.criteria.length,
        Sprint117ClosureContract.criteriaNames.length,
        reason: 'all seven criteria must be derived, none skipped',
      );
      expect(<String>[
        for (final c in report.criteria) c.name,
      ], Sprint117ClosureContract.criteriaNames);
    });

    test('cites committed evidence for every criterion, none unmeasured', () {
      final report = const Sprint117SprintClosureGate().evaluate();
      for (final criterion in report.criteria) {
        expect(
          criterion.evidence,
          isNotEmpty,
          reason: '${criterion.name} has no evidence path',
        );
        for (final path in criterion.evidence) {
          expect(
            path,
            startsWith('docs/'),
            reason: '${criterion.name} cites a non-repository path: $path',
          );
        }
        expect(
          criterion.detail.trim(),
          isNotEmpty,
          reason: '${criterion.name} carries no measured detail',
        );
      }
    });

    test('reports the real registry: 0 CERTIFIED of 32', () {
      final anchor = const Sprint117SprintClosureGate().evaluate().anchor!;
      expect(anchor.registryCertifiedCount, 0);
      expect(anchor.registryUnverifiedCount, 32);
      expect(anchor.registryWithheldCount, 32);
      expect(anchor.registryProviderCount, 32);
    });

    test('reports the frozen certification chain as 30 CERTIFIED', () {
      final anchor = const Sprint117SprintClosureGate().evaluate().anchor!;
      expect(anchor.lockedProviderCount, 32);
      expect(anchor.lockedCertifiedCount, 30);
      expect(anchor.lockedLimitedCount, 1);
      expect(anchor.lockedBlockedCount, 1);
      expect(anchor.certificationScope, 'local_certification_freeze_only');
    });

    test('records the GA decision as DELAY with no authorization', () {
      final anchor = const Sprint117SprintClosureGate().evaluate().anchor!;
      expect(anchor.gaDecision, 'DELAY');
      expect(anchor.gaExecutionAuthorized, isFalse);
      expect(anchor.gaReleaseBlocked, isTrue);
    });

    test('never claims a live release was executed or observed', () {
      final report = const Sprint117SprintClosureGate().evaluate();
      expect(report.liveReleaseExecuted, isFalse);
      expect(report.anchor!.liveReleaseExecuted, isFalse);
      expect(report.anchor!.handoffLiveReleaseObserved, isFalse);
      expect(report.anchor!.entryLiveBetaExecuted, isFalse);
      expect(report.anchor!.cohortLiveBetaExecuted, isFalse);
      expect(report.anchor!.liveClaimRecorded, isFalse);
    });
  });

  group('117.48 criterion judgement', () {
    test(
      'entry gate is satisfied only when state=pass and verdict matches',
      () {
        final satisfied = Sprint117SprintClosure.deriveCriteria(
          anchorWith(),
        ).firstWhere((c) => c.name == 'entry_gate_passed');
        expect(satisfied.status, Sprint117ClosureCriterionStatus.satisfied);

        final notReady = Sprint117SprintClosure.deriveCriteria(
          anchorWith(entryVerdict: 'BETA_ENTRY_BLOCKED'),
        ).firstWhere((c) => c.name == 'entry_gate_passed');
        expect(notReady.status, Sprint117ClosureCriterionStatus.unmet);
      },
    );

    test('beta window is deferred while no live beta executed', () {
      final criterion = Sprint117SprintClosure.deriveCriteria(
        anchorWith(),
      ).firstWhere((c) => c.name == 'beta_window_complete');
      expect(
        criterion.status,
        Sprint117ClosureCriterionStatus.deferredExternal,
      );
      expect(criterion.deferred, isTrue);
      expect(criterion.resolved, isTrue);
      expect(criterion.detail, contains('live_beta_executed=false'));
      expect(criterion.detail, contains('verified_participants=0'));
    });

    test('a completed window needs a live beta and a verified cohort', () {
      final complete = Sprint117SprintClosure.deriveCriteria(
        anchorWith(
          cohortState: 'pass',
          cohortLiveBetaExecuted: true,
          verifiedCohortSize: 25,
        ),
      ).firstWhere((c) => c.name == 'beta_window_complete');
      expect(complete.status, Sprint117ClosureCriterionStatus.satisfied);

      final noCohort = Sprint117SprintClosure.deriveCriteria(
        anchorWith(cohortLiveBetaExecuted: true, verifiedCohortSize: 0),
      ).firstWhere((c) => c.name == 'beta_window_complete');
      expect(noCohort.status, Sprint117ClosureCriterionStatus.unmet);
    });

    test('visible connectors are deferred when nothing is visible', () {
      final criterion = Sprint117SprintClosure.deriveCriteria(
        anchorWith(),
      ).firstWhere((c) => c.name == 'visible_connectors_certified_or_limited');
      expect(
        criterion.status,
        Sprint117ClosureCriterionStatus.deferredExternal,
      );
      expect(criterion.detail, contains('visible=0'));
      // Both certification sources are named side by side, never averaged.
      expect(criterion.detail, contains('117.4['));
      expect(criterion.detail, contains('117.41['));
      expect(criterion.detail, contains('certified=30'));
      expect(criterion.detail, contains('certified=0'));
    });

    test('a visible connector with no certification is unmet', () {
      final criterion = Sprint117SprintClosure.deriveCriteria(
        anchorWith(
          enabledSubset: const <String>['openai'],
          rolloutEnabledSubset: const <String>['openai'],
          lockedCertifiedCount: 0,
          lockedLimitedCount: 0,
          registryCertifiedCount: 0,
        ),
      ).firstWhere((c) => c.name == 'visible_connectors_certified_or_limited');
      expect(criterion.status, Sprint117ClosureCriterionStatus.unmet);
    });

    test('a visible connector with certification is satisfied', () {
      final criterion = Sprint117SprintClosure.deriveCriteria(
        anchorWith(enabledSubset: const <String>['openai']),
      ).firstWhere((c) => c.name == 'visible_connectors_certified_or_limited');
      expect(criterion.status, Sprint117ClosureCriterionStatus.satisfied);
    });

    test('quality gates cite the sources 117.45 actually measured', () {
      final criterion = Sprint117SprintClosure.deriveCriteria(
        anchorWith(),
      ).firstWhere((c) => c.name == 'quality_gates_passed');
      expect(criterion.status, Sprint117ClosureCriterionStatus.satisfied);
      expect(
        criterion.evidence,
        contains('docs/evidence/sprint-117-35-manifest-20261002.json'),
      );

      final absent = Sprint117SprintClosure.deriveCriteria(
        anchorWith(gaQualityGatesPresent: false),
      ).firstWhere((c) => c.name == 'quality_gates_passed');
      expect(absent.status, Sprint117ClosureCriterionStatus.unmet);
    });

    test('ga decision recorded needs a non-empty decision', () {
      expect(
        Sprint117SprintClosure.deriveCriteria(
          anchorWith(),
        ).firstWhere((c) => c.name == 'ga_decision_recorded').status,
        Sprint117ClosureCriterionStatus.satisfied,
      );
      expect(
        Sprint117SprintClosure.deriveCriteria(
          anchorWith(gaDecision: ''),
        ).firstWhere((c) => c.name == 'ga_decision_recorded').status,
        Sprint117ClosureCriterionStatus.unmet,
      );
    });

    test('staged rollout controlled needs stages, default OFF, nothing on', () {
      expect(
        Sprint117SprintClosure.deriveCriteria(
          anchorWith(),
        ).firstWhere((c) => c.name == 'staged_rollout_controlled').status,
        Sprint117ClosureCriterionStatus.satisfied,
      );
      expect(
        Sprint117SprintClosure.deriveCriteria(
          anchorWith(rolloutStageCount: 0),
        ).firstWhere((c) => c.name == 'staged_rollout_controlled').status,
        Sprint117ClosureCriterionStatus.unmet,
      );
      expect(
        Sprint117SprintClosure.deriveCriteria(
          anchorWith(rolloutEnabledSubset: const <String>['openai']),
        ).firstWhere((c) => c.name == 'staged_rollout_controlled').status,
        Sprint117ClosureCriterionStatus.unmet,
      );
    });

    test(
      'observation handoff needs every output resolved and no violation',
      () {
        expect(
          Sprint117SprintClosure.deriveCriteria(
            anchorWith(),
          ).firstWhere((c) => c.name == 'observation_handoff_complete').status,
          Sprint117ClosureCriterionStatus.satisfied,
        );
        expect(
          Sprint117SprintClosure.deriveCriteria(
            anchorWith(handoffResolvedOutputs: 7),
          ).firstWhere((c) => c.name == 'observation_handoff_complete').status,
          Sprint117ClosureCriterionStatus.unmet,
        );
        expect(
          Sprint117SprintClosure.deriveCriteria(
            anchorWith(handoffViolationCount: 1),
          ).firstWhere((c) => c.name == 'observation_handoff_complete').status,
          Sprint117ClosureCriterionStatus.unmet,
        );
      },
    );
  });

  group('117.48 closure decision', () {
    test('a closure with no unmet criterion closes locally', () {
      final report = reportWith();
      expect(
        report.unmetCriteria,
        isEmpty,
        reason: 'no criterion should be unmet in the committed state',
      );
      expect(report.state, Sprint117ClosureState.pass);
      expect(
        report.decision,
        Sprint117ClosureDecision.closedLocalDeferredExternal,
      );
      expect(report.isClosed, isTrue);
      expect(report.verdict, Sprint117ClosureContract.passVerdict);
      expect(report.missingEvidence, isEmpty);
    });

    test('deferred criteria are carried, never promoted to satisfied', () {
      final report = reportWith();
      expect(report.deferredCriteria, contains('beta_window_complete'));
      expect(
        report.deferredCriteria,
        contains('visible_connectors_certified_or_limited'),
      );
      expect(report.deferredCount, 2);
      // Deferred is not satisfied: only five of seven are established locally.
      expect(report.satisfiedCount, 5);
    });

    test('an unmet criterion blocks the closure', () {
      final report = reportWith(anchor: anchorWith(entryVerdict: 'BLOCKED'));
      expect(report.state, Sprint117ClosureState.blocked);
      expect(report.decision, Sprint117ClosureDecision.blocked);
      expect(report.isClosed, isFalse);
      expect(report.verdict, Sprint117ClosureContract.blockedVerdict);
      expect(report.missingEvidence, contains('entry_gate_passed'));
    });

    test(
      'a recorded release decision without authorization is a violation',
      () {
        final report = reportWith(releaseDecision: 'RELEASE');
        expect(report.state, Sprint117ClosureState.fail);
        expect(report.verdict, Sprint117ClosureContract.failVerdict);
        expect(
          report.violations,
          contains('release_decision_without_authorization'),
        );
      },
    );

    test('an authorized release decision is not a violation', () {
      final report = reportWith(
        anchor: anchorWith(gaExecutionAuthorized: true),
        releaseDecision: 'RELEASE',
      );
      expect(
        report.violations,
        isNot(contains('release_decision_without_authorization')),
      );
    });

    test('a visible uncertified connector is a violation, never a closure', () {
      final report = reportWith(
        anchor: anchorWith(
          enabledSubset: const <String>['openai'],
          lockedCertifiedCount: 0,
          lockedLimitedCount: 0,
          registryCertifiedCount: 0,
        ),
      );
      expect(report.state, Sprint117ClosureState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('visible_connector_uncertified'),
        ),
        isTrue,
      );
    });

    test('a live claim contradicts the committed sources', () {
      final report = reportWith(
        anchor: anchorWith(entryLiveBetaExecuted: true),
      );
      expect(report.state, Sprint117ClosureState.fail);
      expect(report.violations, contains('live_release_claimed_without_beta'));
    });

    test('refuses a criterion set that is not the canonical seven', () {
      expect(
        () => Sprint117SprintClosure.evaluate(
          criteria: const <Sprint117ClosureCriterion>[],
          releaseDecision: 'DELAY',
          releaseDecisionOwner: 'operator',
        ),
        throwsArgumentError,
      );
    });

    test('refuses an unknown release decision', () {
      expect(() => reportWith(releaseDecision: 'SHIP_IT'), throwsArgumentError);
    });

    test('refuses a criterion with no evidence', () {
      expect(
        () => Sprint117SprintClosure.evaluate(
          criteria: <Sprint117ClosureCriterion>[
            for (final name in Sprint117ClosureContract.criteriaNames)
              Sprint117ClosureCriterion(
                name: name,
                status: Sprint117ClosureCriterionStatus.satisfied,
                evidence: name == 'entry_gate_passed'
                    ? const <String>[]
                    : const <String>['docs/planning/v1.3/x.json'],
                detail: 'recorded',
              ),
          ],
          releaseDecision: 'DELAY',
          releaseDecisionOwner: 'operator',
        ),
        throwsArgumentError,
      );
    });

    test('an unreadable anchor blocks, it never closes', () {
      final report = const Sprint117SprintClosureGate().evaluateWith(
        const Sprint117ClosureInput(),
      );
      expect(report.state, Sprint117ClosureState.blocked);
      expect(report.anchor, isNull);
      expect(report.criteria, isEmpty);
      expect(report.missingEvidence, contains('closure_anchor'));
      expect(report.missingEvidence, contains('entry_gate_passed'));
      expect(report.liveReleaseExecuted, isFalse);
    });

    test('the closure carries limitations that name the deferral', () {
      final report = reportWith();
      expect(report.limitations, isNotEmpty);
      expect(
        report.limitations.join(' '),
        contains(Sprint117ClosureContract.externalGates),
      );
      expect(report.limitations.join(' '), contains('releases nothing'));
    });
  });

  group('117.48 open items', () {
    test('surfaces the two certification sources by name, never averaged', () {
      final report = const Sprint117SprintClosureGate().evaluate();
      expect(report.anchor!.certificationSourcesDisagree, isTrue);
      expect(
        report.openItems,
        contains('certification_source_disagreement:117.4=30:117.41=0'),
      );
    });

    test('surfaces the 117.1 readiness contradiction without editing it', () {
      final report = const Sprint117SprintClosureGate().evaluate();
      expect(
        report.openItems.any(
          (item) => item.startsWith('entry_gate_readiness_contradiction:'),
        ),
        isTrue,
      );
      expect(
        report.anchor!.canonicalEntryReadiness,
        'BLOCKED_NO_CERTIFIED_CONNECTOR_CURRENTLY_RECORDED',
      );
    });

    test('surfaces the failed cohort and the unexecuted controls', () {
      final report = const Sprint117SprintClosureGate().evaluate();
      expect(
        report.openItems.any(
          (item) => item.startsWith('cohort_verification_failed:'),
        ),
        isTrue,
      );
      expect(report.openItems, contains('kill_switch_not_drilled:2'));
      expect(report.openItems, contains('rollback_not_verified:3'));
      expect(report.openItems, contains('no_connector_exposed'));
      expect(report.openItems, contains('live_release_not_executed'));
    });

    test('carries the GA blocker open items forward', () {
      final report = const Sprint117SprintClosureGate().evaluate();
      expect(
        report.openItems.any(
          (item) => item.startsWith('117.41: zero CERTIFIED connectors'),
        ),
        isTrue,
        reason: 'the GA blocker list must be carried, not summarised away',
      );
      expect(
        report.openItems.length,
        greaterThanOrEqualTo(report.anchor!.gaOpenItems.length),
      );
    });
  });
}
