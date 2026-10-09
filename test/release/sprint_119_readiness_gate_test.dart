import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_119_readiness_gate.dart';

/// A single Sprint 119 readiness dimension. Each test flips exactly the one
/// thing it is about, so a test that flips nothing proves the pass path exists
/// and every other test proves one way the gate refuses to take it.
Sprint119ReadinessDimension _dimension({
  String dimension = 'stability_gate',
  String referenceState = Sprint119ReadinessContract.stabilityGateToken,
  String summary = 'no live stability gate verified on the delayed path',
  List<String>? evidence,
  bool ready = false,
  bool admitted = false,
  bool passed = false,
  bool verified = false,
  bool complete = false,
  bool certified = false,
  bool released = false,
  bool selfServiceEnabled = false,
  bool ecosystemReady = false,
}) {
  return Sprint119ReadinessDimension(
    dimension: dimension,
    referenceState: referenceState,
    summary: summary,
    evidence:
        evidence ?? <String>[Sprint119ReadinessContract.sourceFor(dimension)],
    ready: ready,
    admitted: admitted,
    passed: passed,
    verified: verified,
    complete: complete,
    certified: certified,
    released: released,
    selfServiceEnabled: selfServiceEnabled,
    ecosystemReady: ecosystemReady,
  );
}

Sprint119ReadinessRecord _record({
  String releaseState = Sprint119ReadinessContract.delayedReleaseState,
  String readinessDecision = Sprint119ReadinessContract.requiredDecision,
  List<Sprint119ReadinessDimension>? dimensions,
}) {
  return Sprint119ReadinessRecord(
    releaseState: releaseState,
    readinessDecision: readinessDecision,
    dimensions:
        dimensions ?? Sprint119ReadinessContract.canonicalRecord.dimensions,
  );
}

/// The canonical dimensions with exactly one dimension replaced, so a test can
/// flip a single dimension without rebuilding the whole record.
List<Sprint119ReadinessDimension> _replacing(
  String dimension,
  Sprint119ReadinessDimension replacement,
) {
  return <Sprint119ReadinessDimension>[
    for (final e in Sprint119ReadinessContract.canonicalRecord.dimensions)
      if (e.dimension == dimension) replacement else e,
  ];
}

Sprint119ReadinessAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict = Sprint119ReadinessContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint119ReadinessContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict = Sprint119ReadinessContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered = Sprint119ReadinessContract.expectedProviderCount,
  String releaseState = Sprint119ReadinessContract.delayedReleaseState,
  int registryExpectedCount = Sprint119ReadinessContract.expectedProviderCount,
  int registryEvidenceProviderCount =
      Sprint119ReadinessContract.expectedProviderCount,
  int registryEvidenceExposed = 0,
  int registryEvidenceWithheld =
      Sprint119ReadinessContract.expectedProviderCount,
  int snapshotLockLockedCount =
      Sprint119ReadinessContract.expectedProviderCount,
  String approvalDecision = Sprint119ReadinessContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  List<String>? registeredProviders,
  List<String>? stabilityVocabulary,
  List<String>? expansionVocabulary,
  List<String>? registryVocabulary,
  List<String>? supportVocabulary,
  List<String>? securityPrivacyVocabulary,
  List<String>? technicalDebtVocabulary,
  List<String>? readableSources,
}) {
  return Sprint119ReadinessAnchor(
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterMaxNewCertified: charterMaxNewCertified,
    charterCurrentlyCertified: charterCurrentlyCertified,
    charterRegisteredProviders: charterRegisteredProviders,
    snapshotState: snapshotState,
    snapshotVerdict: snapshotVerdict,
    snapshotCertified: snapshotCertified,
    snapshotRegistered: snapshotRegistered,
    releaseState: releaseState,
    registryExpectedCount: registryExpectedCount,
    registryEvidenceProviderCount: registryEvidenceProviderCount,
    registryEvidenceExposed: registryEvidenceExposed,
    registryEvidenceWithheld: registryEvidenceWithheld,
    snapshotLockLockedCount: snapshotLockLockedCount,
    approvalDecision: approvalDecision,
    approvalState: approvalState,
    executionAuthorized: executionAuthorized,
    releaseBlocked: releaseBlocked,
    registeredProviders:
        registeredProviders ?? Sprint119ReadinessContract.canonicalProviders,
    stabilityVocabulary: stabilityVocabulary ?? const <String>['GA_DELAYED'],
    expansionVocabulary:
        expansionVocabulary ??
        const <String>[
          'UNVERIFIED',
          'CERTIFIED',
          'LIMITED',
          'BLOCKED',
          'EXPIRED',
        ],
    registryVocabulary:
        registryVocabulary ??
        const <String>[
          'CERTIFIED',
          'LIMITED',
          'UNVERIFIED',
          'PLANNED',
          'DEGRADED',
          'BLOCKED',
          'EXPOSED',
          'WITHHELD',
        ],
    supportVocabulary:
        supportVocabulary ??
        const <String>['P0', 'P1', 'P2', 'P3', 'Choirudin', 'nephthys'],
    securityPrivacyVocabulary:
        securityPrivacyVocabulary ??
        const <String>[
          'oauth_tests',
          'vault_tests',
          'redirect_tests',
          'session_tests',
          'permission_tests',
          'webhook_tests',
          'dependency_scan',
          'audit_tests',
          'data_flow',
          'consent',
          'minimization',
          'destinations',
          'retention',
          'deletion',
          'disconnect',
          'terms_limits',
        ],
    technicalDebtVocabulary:
        technicalDebtVocabulary ??
        const <String>[
          'item',
          'impact',
          'evidence',
          'reason_deferred',
          'owner',
          'target',
          'trigger',
          'live_production_telemetry',
          'public_incident_intake',
          'external_adoption_evidence',
          'public_release_signing',
          'hosted_ci_validation',
          'published_artifact_validation',
          'hardware_validation',
          'publication',
        ],
    readableSources:
        readableSources ??
        Sprint119ReadinessContract.witnessSources.toSet().toList(),
  );
}

Sprint119ReadinessReport _run(
  Sprint119ReadinessRecord record, {
  Sprint119ReadinessAnchor? anchor,
}) {
  return const Sprint119ReadinessGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.45 Sprint 119 Readiness Gate', () {
    test(
      'the canonical evidence dimensions are the six objective dimensions',
      () {
        expect(Sprint119ReadinessContract.requiredEvidence, <String>[
          'stability_gate',
          'expansion_gate',
          'provider_registry',
          'support_capacity',
          'security_privacy_constraints',
          'technical_debt',
        ]);
      },
    );

    test('the canonical outputs are the six objective dimensions', () {
      expect(
        Sprint119ReadinessContract.requiredOutputs,
        Sprint119ReadinessContract.requiredEvidence,
      );
      expect(
        Sprint119ReadinessContract.requiredOutputs.length,
        Sprint119ReadinessContract.expectedEvidenceCount,
      );
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint119ReadinessContract.stateVocabulary(
          <List<String>>[
            const <String>['GA_DELAYED'],
            const <String>['UNVERIFIED', 'CERTIFIED'],
            const <String>['P0', 'P1'],
          ],
        );
        expect(vocabulary, contains('GA_DELAYED'));
        expect(vocabulary, contains('UNVERIFIED'));
        expect(vocabulary, contains('P0'));
        expect(
          vocabulary,
          contains(Sprint119ReadinessContract.noReferenceState),
        );
        expect(
          Sprint119ReadinessContract.grounds(vocabulary, 'GA_DELAYED'),
          isTrue,
        );
        expect(
          Sprint119ReadinessContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
      },
    );

    test(
      'a compound reference state is grounded only when every part is a witness value',
      () {
        final vocabulary = <String>['live', 'provider', 'certification'];
        expect(
          Sprint119ReadinessContract.grounds(
            vocabulary,
            'live_provider_certification',
          ),
          isTrue,
        );
        expect(
          Sprint119ReadinessContract.grounds(
            vocabulary,
            'live_provider_telepathy',
          ),
          isFalse,
        );
      },
    );

    test('canonical record covers all six dimensions and claims nothing', () {
      final record = Sprint119ReadinessContract.canonicalRecord;
      expect(record.dimensions.length, 6);
      expect(
        record.dimensionNames.toSet(),
        Sprint119ReadinessContract.requiredEvidence.toSet(),
      );
      expect(
        record.releaseState,
        Sprint119ReadinessContract.delayedReleaseState,
      );
      expect(
        record.readinessDecision,
        Sprint119ReadinessContract.requiredDecision,
      );
      for (final dimension in record.dimensions) {
        expect(dimension.ready, isFalse);
        expect(dimension.admitted, isFalse);
        expect(dimension.passed, isFalse);
        expect(dimension.verified, isFalse);
        expect(dimension.complete, isFalse);
        expect(dimension.certified, isFalse);
        expect(dimension.released, isFalse);
        expect(dimension.selfServiceEnabled, isFalse);
        expect(dimension.ecosystemReady, isFalse);
        for (final field
            in Sprint119ReadinessContract.requiredFieldsForDimension) {
          expect(
            (dimension.requiredFields[field] ?? '').trim(),
            isNotEmpty,
            reason: '${dimension.dimension}.$field must not be blank',
          );
        }
      }
    });

    test('passes on the canonical record and claims no readiness', () {
      final report = _run(_record());
      expect(report.state, Sprint119ReadinessState.pass);
      expect(report.verdict, 'SPRINT_119_READINESS_GATE_VERIFIED_LOCAL');
      expect(report.readinessVerified, isTrue);
      expect(report.declaredDimensions.length, 6);
      expect(report.readyDimensions, isEmpty);
      expect(report.admittedDimensions, isEmpty);
      expect(report.passedDimensions, isEmpty);
      expect(report.verifiedDimensions, isEmpty);
      expect(report.completeDimensions, isEmpty);
      expect(report.certifiedDimensions, isEmpty);
      expect(report.releasedDimensions, isEmpty);
      expect(report.selfServiceEnabledDimensions, isEmpty);
      expect(report.ecosystemReadyDimensions, isEmpty);
      expect(report.readyCount, 0);
      expect(report.admittedCount, 0);
      expect(report.passedCount, 0);
      expect(report.verifiedCount, 0);
      expect(report.completeCount, 0);
      expect(report.certifiedCount, 0);
      expect(report.releasedCount, 0);
      expect(report.selfServiceEnabledCount, 0);
      expect(report.ecosystemReadyCount, 0);
      expect(report.expansionBudgetFrozen, isTrue);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint119ReadinessGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint119ReadinessState.blocked);
      expect(report.verdict, 'SPRINT_119_READINESS_EVIDENCE_UNREADABLE');
      expect(report.readinessVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_readiness_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint119ReadinessState.blocked);
      expect(report.verdict, 'SPRINT_119_READINESS_BLOCKED_UPSTREAM');
      expect(
        report.blockers.any((b) => b.startsWith('charter_not_complete:')),
        isTrue,
      );
    });

    test('blocks when the committed snapshot is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(snapshotVerdict: 'CERTIFIED_CONNECTOR_SNAPSHOT_DRIFT'),
      );
      expect(report.state, Sprint119ReadinessState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('snapshot_not_frozen:')),
        isTrue,
      );
    });

    test('blocks when the committed approval gate is not a delay', () {
      final report = _run(
        _record(),
        anchor: _anchor(approvalDecision: 'release'),
      );
      expect(report.state, Sprint119ReadinessState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('approval_gate_not_delay:')),
        isTrue,
      );
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint119ReadinessState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
    });

    test(
      'blocks when the registry evidence provider count does not reconcile',
      () {
        final report = _run(
          _record(),
          anchor: _anchor(registryEvidenceProviderCount: 31),
        );
        expect(report.state, Sprint119ReadinessState.blocked);
        expect(
          report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
          isTrue,
        );
      },
    );

    test('blocks when the snapshot lock count does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(snapshotLockLockedCount: 31),
      );
      expect(report.state, Sprint119ReadinessState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
    });

    test('blocks when the registry visibility does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryEvidenceWithheld: 31),
      );
      expect(report.state, Sprint119ReadinessState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('registry_visibility_not_reconciled:'),
        ),
        isTrue,
      );
    });

    test('blocks when the registry already exposes a connector', () {
      final report = _run(
        _record(),
        anchor: _anchor(
          registryEvidenceExposed: 1,
          registryEvidenceWithheld: 31,
        ),
      );
      expect(report.state, Sprint119ReadinessState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('registry_visibility_exposed_on_delayed_path:'),
        ),
        isTrue,
      );
    });

    test('fails when a dimension claims readiness', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'stability_gate',
            _dimension(dimension: 'stability_gate', ready: true),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_ready_claimed_on_delayed_path:stability_gate'),
      );
      expect(report.readyCount, 1);
    });

    test('fails when a dimension claims an admitted provider', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'provider_registry',
            _dimension(dimension: 'provider_registry', admitted: true),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains(
          'readiness_admitted_claimed_on_delayed_path:provider_registry',
        ),
      );
      expect(report.admittedCount, 1);
    });

    test('fails when a dimension claims it passed', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'expansion_gate',
            _dimension(dimension: 'expansion_gate', passed: true),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_passed_claimed_on_delayed_path:expansion_gate'),
      );
      expect(report.passedCount, 1);
    });

    test('fails when a dimension claims it was verified', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'support_capacity',
            _dimension(dimension: 'support_capacity', verified: true),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_verified_claimed_on_delayed_path:support_capacity'),
      );
      expect(report.verifiedCount, 1);
    });

    test('fails when a dimension claims it is complete', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'technical_debt',
            _dimension(dimension: 'technical_debt', complete: true),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_complete_claimed_on_delayed_path:technical_debt'),
      );
      expect(report.completeCount, 1);
    });

    test('fails when a dimension claims a certified connector', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'provider_registry',
            _dimension(dimension: 'provider_registry', certified: true),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains(
          'readiness_certified_claimed_on_delayed_path:provider_registry',
        ),
      );
      expect(report.certifiedCount, 1);
    });

    test('fails when a dimension claims a released connector', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'stability_gate',
            _dimension(dimension: 'stability_gate', released: true),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_released_claimed:stability_gate'),
      );
      expect(report.releasedCount, 1);
    });

    test('fails when a dimension claims self-service enablement', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'expansion_gate',
            _dimension(dimension: 'expansion_gate', selfServiceEnabled: true),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains(
          'readiness_self_service_enabled_claimed_on_delayed_path:expansion_gate',
        ),
      );
      expect(report.selfServiceEnabledCount, 1);
    });

    test('fails when a dimension claims an ecosystem-ready state', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'provider_registry',
            _dimension(dimension: 'provider_registry', ecosystemReady: true),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains(
          'readiness_ecosystem_ready_claimed_on_delayed_path:provider_registry',
        ),
      );
      expect(report.ecosystemReadyCount, 1);
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('readiness_expansion_budget_not_frozen:'),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when the snapshot certifies a connector', () {
      final report = _run(_record(), anchor: _anchor(snapshotCertified: 1));
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('readiness_snapshot_certified_nonzero:'),
        ),
        isTrue,
      );
    });

    test('fails when a required dimension is missing', () {
      final dimensions = <Sprint119ReadinessDimension>[
        for (final d in Sprint119ReadinessContract.canonicalRecord.dimensions)
          if (d.dimension != 'technical_debt') d,
      ];
      final report = _run(_record(dimensions: dimensions));
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_dimension_missing:technical_debt'),
      );
    });

    test('fails when an unknown dimension is invented', () {
      final dimensions = <Sprint119ReadinessDimension>[
        ...Sprint119ReadinessContract.canonicalRecord.dimensions,
        _dimension(dimension: 'telepathy'),
      ];
      final report = _run(_record(dimensions: dimensions));
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_dimension_unknown:telepathy'),
      );
    });

    test('fails when a dimension is duplicated', () {
      final dimensions = <Sprint119ReadinessDimension>[
        ...Sprint119ReadinessContract.canonicalRecord.dimensions,
        _dimension(dimension: 'stability_gate'),
      ];
      final report = _run(_record(dimensions: dimensions));
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_dimension_duplicate:stability_gate'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'stability_gate',
            _dimension(dimension: 'stability_gate', summary: '   '),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(report.violations, contains('entry_blank_summary:stability_gate'));
    });

    test('fails when a dimension evidence list is empty', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'stability_gate',
            _dimension(dimension: 'stability_gate', evidence: <String>[]),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_dimension_evidence_missing:stability_gate'),
      );
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'stability_gate',
            _dimension(
              dimension: 'stability_gate',
              referenceState: 'telepathy',
            ),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:stability_gate'),
      );
    });

    test('records an open item when a dimension has no reference state', () {
      final report = _run(
        _record(
          dimensions: _replacing(
            'support_capacity',
            _dimension(
              dimension: 'support_capacity',
              referenceState: Sprint119ReadinessContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint119ReadinessState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:support_capacity'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(_record(releaseState: 'GA_DRIFT'));
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when execution is authorized on the delayed path', () {
      final report = _run(
        _record(),
        anchor: _anchor(executionAuthorized: true),
      );
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a connector-ecosystem decision is claimed', () {
      final report = _run(_record(readinessDecision: 'CONNECTOR_ECOSYSTEM'));
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith(
            'connector_ecosystem_readiness_claimed_on_delayed_path:',
          ),
        ),
        isTrue,
      );
    });

    test('fails when a self-service-tooling decision is claimed', () {
      final report = _run(_record(readinessDecision: 'SELF_SERVICE_TOOLING'));
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith(
            'self_service_tooling_readiness_claimed_on_delayed_path:',
          ),
        ),
        isTrue,
      );
    });

    test('fails when the readiness decision is unknown', () {
      final report = _run(_record(readinessDecision: 'telepathy'));
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains('readiness_decision_unknown:telepathy'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final sources = Sprint119ReadinessContract.witnessSources.toSet().toList()
        ..remove('docs/planning/v1.2/sprint_116_privacy_compliance_gate.json');
      final report = _run(_record(), anchor: _anchor(readableSources: sources));
      expect(report.state, Sprint119ReadinessState.fail);
      expect(
        report.violations,
        contains(
          'required_source_unreadable:'
          'docs/planning/v1.2/sprint_116_privacy_compliance_gate.json',
        ),
      );
    });

    test('the canonical sources cover every dimension', () {
      expect(Sprint119ReadinessContract.canonicalSources.length, 6);
      for (final source in Sprint119ReadinessContract.canonicalSources) {
        expect(Sprint119ReadinessContract.witnessSources, contains(source));
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint119ReadinessLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.registeredProviders.length, 32);
      expect(anchor.charterMaxNewCertified, 0);
      expect(anchor.charterCurrentlyCertified, 0);
      expect(anchor.snapshotCertified, 0);
      expect(anchor.registryEvidenceExposed, 0);
      expect(anchor.registryEvidenceWithheld, 32);
      expect(anchor.approvalDecision, 'delay');
      expect(anchor.releaseState, 'GA_DELAYED');
      expect(anchor.stabilityVocabulary, contains('GA_DELAYED'));
      expect(anchor.expansionVocabulary, contains('UNVERIFIED'));
      expect(anchor.registryVocabulary, contains('WITHHELD'));
      expect(anchor.supportVocabulary, contains('P0'));
      expect(anchor.securityPrivacyVocabulary, contains('oauth_tests'));
      expect(anchor.technicalDebtVocabulary, contains('impact'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint119ReadinessGate().evaluate();
      expect(report.state, Sprint119ReadinessState.pass);
      expect(report.verdict, 'SPRINT_119_READINESS_GATE_VERIFIED_LOCAL');
      expect(report.readinessDecision, 'CORRECTIVE_STABILIZATION');
      expect(report.releaseState, 'GA_DELAYED');
      expect(report.declaredDimensions.length, 6);
      expect(report.readyCount, 0);
      expect(report.certifiedCount, 0);
      expect(report.releasedCount, 0);
      expect(report.expansionBudgetFrozen, isTrue);
    });
  });
}
