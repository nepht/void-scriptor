import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_stability_fixes.dart';

/// A single fix record. Each test flips exactly the one thing it is about, so a
/// test that flips nothing proves the pass path exists and every other test
/// proves one way the gate refuses to take it.
Sprint118StabilityFixEntry _entry({
  String fixArea = 'auth',
  String fixId = 'FIX-AUTH-REF',
  String reproduction = Sprint118StabilityFixContract.referenceReproduction,
  String minimalChange = Sprint118StabilityFixContract.referenceMinimalChange,
  String regressionTest = Sprint118StabilityFixContract.referenceRegressionTest,
  String review = Sprint118StabilityFixContract.referenceReview,
  String riskUpdate = Sprint118StabilityFixContract.referenceRiskUpdate,
  String releaseNote = Sprint118StabilityFixContract.referenceReleaseNote,
  String owner = Sprint118StabilityFixContract.fixOwner,
  String evidence =
      'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
  bool fixShipped = false,
  bool scopeExpanded = false,
}) {
  return Sprint118StabilityFixEntry(
    fixArea: fixArea,
    fixId: fixId,
    reproduction: reproduction,
    minimalChange: minimalChange,
    regressionTest: regressionTest,
    review: review,
    riskUpdate: riskUpdate,
    releaseNote: releaseNote,
    owner: owner,
    evidence: evidence,
    fixShipped: fixShipped,
    scopeExpanded: scopeExpanded,
  );
}

Sprint118StabilityFixRegister _register({
  String releaseState = Sprint118StabilityFixContract.delayedReleaseState,
  List<Sprint118StabilityFixEntry>? entries,
}) {
  return Sprint118StabilityFixRegister(
    releaseState: releaseState,
    entries: entries ?? Sprint118StabilityFixContract.canonicalRegister.entries,
  );
}

/// The canonical entries with exactly one area replaced, so a test can flip a
/// single field without rebuilding the whole register.
List<Sprint118StabilityFixEntry> _replacing(
  String fixArea,
  Sprint118StabilityFixEntry replacement,
) {
  return <Sprint118StabilityFixEntry>[
    for (final e in Sprint118StabilityFixContract.canonicalRegister.entries)
      if (e.fixArea == fixArea) replacement else e,
  ];
}

Sprint118StabilityFixAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118StabilityFixContract.requiredBaselineVerdict,
  String releaseState = Sprint118StabilityFixContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict = Sprint118StabilityFixContract.requiredCharterVerdict,
  String readinessState = 'pass',
  String readinessVerdict =
      Sprint118StabilityFixContract.requiredReadinessVerdict,
  bool liveIncidentExecuted = false,
  String intakeState = 'pass',
  String intakeVerdict = Sprint118StabilityFixContract.requiredIntakeVerdict,
  List<String>? owners,
  List<String>? intakeCategories,
  List<String>? testSuites,
  List<String>? rollbackEvidence,
  List<String>? p1Requirements,
  List<String>? readableSources,
}) {
  return Sprint118StabilityFixAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    readinessState: readinessState,
    readinessVerdict: readinessVerdict,
    liveIncidentExecuted: liveIncidentExecuted,
    intakeState: intakeState,
    intakeVerdict: intakeVerdict,
    owners: owners ?? const <String>['Choirudin', 'nephthys'],
    intakeCategories:
        intakeCategories ??
        const <String>[
          'support',
          'crash',
          'auth',
          'quota',
          'sync',
          'ai',
          'billing',
          'security',
          'privacy',
          'accessibility',
        ],
    testSuites:
        testSuites ??
        const <String>[
          'unit',
          'state_machine',
          'contract',
          'connector',
          'security',
          'billing',
          'ui',
          'accessibility',
          'end_to_end',
          'regression',
        ],
    rollbackEvidence:
        rollbackEvidence ??
        const <String>[
          'rollback_artifact',
          'kill_switch',
          'flag_matrix',
          'data_compatibility',
          'rollback_drill',
          'user_guidance',
        ],
    p1Requirements:
        p1Requirements ??
        const <String>[
          'reproduction',
          'minimal_change',
          'regression_test',
          'review',
          'risk_update',
          'release_note',
        ],
    readableSources:
        readableSources ?? Sprint118StabilityFixContract.canonicalSources,
  );
}

Sprint118StabilityFixReport _run(
  Sprint118StabilityFixRegister register, {
  Sprint118StabilityFixAnchor? anchor,
}) {
  return const Sprint118StabilityFixGate().evaluateWith(
    anchor ?? _anchor(),
    register,
  );
}

void main() {
  group('118.24 Stability Fixes', () {
    test('declares the canonical step, title, requirements, and paths', () {
      expect(Sprint118StabilityFixContract.canonicalStep, '118.24');
      expect(Sprint118StabilityFixContract.title, 'Stability Fixes');
      expect(
        Sprint118StabilityFixContract.manifestPath,
        'docs/planning/v1.3/sprint_118_stability_fixes.json',
      );
      expect(Sprint118StabilityFixContract.requiredRequirements, <String>[
        'reproduction',
        'minimal_change',
        'regression_test',
        'review',
        'risk_update',
        'release_note',
      ]);
      expect(Sprint118StabilityFixContract.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118StabilityFixContract.requiredRequirements.length, 6);
      expect(Sprint118StabilityFixContract.fixAreas.length, 8);
      expect(Sprint118StabilityFixContract.canonicalSources.length, 8);
      expect(Sprint118StabilityFixContract.canonicalRegister.entries.length, 8);
    });

    test(
      'grounds each approved area and requirement in a committed witness',
      () {
        const areaVocab = <String>[
          'support',
          'crash',
          'auth',
          'quota',
          'sync',
          'ai',
          'billing',
          'security',
          'privacy',
          'accessibility',
          'unit',
          'state_machine',
          'contract',
          'connector',
          'ui',
          'end_to_end',
          'regression',
          'rollback_artifact',
          'kill_switch',
          'flag_matrix',
          'data_compatibility',
          'rollback_drill',
          'user_guidance',
        ];
        const requirementVocab = <String>[
          'reproduction',
          'minimal_change',
          'regression_test',
          'review',
          'risk_update',
          'release_note',
        ];
        for (final area in Sprint118StabilityFixContract.fixAreas) {
          expect(
            Sprint118StabilityFixContract.grounds(areaVocab, area),
            isTrue,
            reason: '$area must be grounded in a witness vocabulary',
          );
        }
        for (final requirement
            in Sprint118StabilityFixContract.requiredRequirements) {
          expect(
            Sprint118StabilityFixContract.grounds(
              requirementVocab,
              requirement,
            ),
            isTrue,
            reason: '$requirement must be grounded in a witness vocabulary',
          );
        }
        expect(
          Sprint118StabilityFixContract.grounds(areaVocab, 'unknown'),
          isFalse,
        );
        expect(
          Sprint118StabilityFixContract.grounds(requirementVocab, 'unknown'),
          isFalse,
        );
      },
    );

    test(
      'canonical register covers the eight areas and claims no shipped fix',
      () {
        final register = Sprint118StabilityFixContract.canonicalRegister;
        expect(register.entries.length, 8);
        expect(register.fixAreas.toSet(), <String>{
          'auth',
          'quota',
          'sync',
          'ai',
          'billing',
          'ui',
          'accessibility',
          'compatibility',
        });
        for (final entry in register.entries) {
          expect(entry.fixShipped, isFalse);
          expect(entry.scopeExpanded, isFalse);
          for (final requirement
              in Sprint118StabilityFixContract.requiredRequirements) {
            expect(
              (entry.requiredFields[requirement] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.fixArea}.$requirement must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical register', () {
      final report = _run(_register());
      expect(report.state, Sprint118StabilityFixState.pass);
      expect(report.verdict, 'STABILITY_FIXES_VERIFIED_LOCAL');
      expect(report.registerVerified, isTrue);
      expect(report.declaredAreas.length, 8);
      expect(report.fixCount, 8);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118StabilityFixGate().evaluateWith(
        null,
        _register(),
      );
      expect(report.state, Sprint118StabilityFixState.blocked);
      expect(report.verdict, 'SPRINT_118_STABILITY_FIXES_EVIDENCE_UNREADABLE');
      expect(
        report.blockers,
        contains('committed_stability_fix_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _register(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118StabilityFixState.blocked);
      expect(
        report.blockers,
        contains('baseline_not_frozen:SPRINT_118_BASELINE_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 118.2 charter is not complete', () {
      final report = _run(
        _register(),
        anchor: _anchor(charterVerdict: 'CHARTER_EVIDENCE_VIOLATION'),
      );
      expect(report.state, Sprint118StabilityFixState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 117.6 readiness witness is not a pass', () {
      final report = _run(
        _register(),
        anchor: _anchor(
          readinessVerdict: 'SUPPORT_INCIDENT_READINESS_VIOLATION',
        ),
      );
      expect(report.state, Sprint118StabilityFixState.blocked);
      expect(
        report.blockers,
        contains('readiness_not_defined:SUPPORT_INCIDENT_READINESS_VIOLATION'),
      );
    });

    test('blocks when the 118.6 intake witness is not a pass', () {
      final report = _run(
        _register(),
        anchor: _anchor(intakeVerdict: 'INCIDENT_SUPPORT_INTAKE_VIOLATION'),
      );
      expect(report.state, Sprint118StabilityFixState.blocked);
      expect(
        report.blockers,
        contains('intake_not_verified:INCIDENT_SUPPORT_INTAKE_VIOLATION'),
      );
    });

    test('fails when the release state disagrees with the baseline', () {
      final report = _run(
        _register(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118StabilityFixState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a fix is claimed shipped on the delayed path', () {
      final report = _run(
        _register(),
        anchor: _anchor(liveIncidentExecuted: true),
      );
      expect(report.state, Sprint118StabilityFixState.fail);
      expect(
        report.violations,
        contains('fix_shipped_claimed_executed_without_release'),
      );
    });

    test('fails when a record claims a shipped fix', () {
      final report = _run(
        _register(
          entries: _replacing(
            'sync',
            _entry(
              fixArea: 'sync',
              fixId: 'FIX-SYNC-REF',
              evidence:
                  'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json',
              fixShipped: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityFixState.fail);
      expect(report.violations, contains('fix_shipped_without_release:sync'));
    });

    test('fails when a record widens scope beyond the approved change', () {
      final report = _run(
        _register(
          entries: _replacing(
            'billing',
            _entry(
              fixArea: 'billing',
              fixId: 'FIX-BILLING-REF',
              evidence:
                  'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
              scopeExpanded: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityFixState.fail);
      expect(
        report.violations,
        contains('scope_expanded_beyond_approval:billing'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _register(
          entries: _replacing(
            'quota',
            _entry(
              fixArea: 'quota',
              fixId: 'FIX-QUOTA-REF',
              evidence:
                  'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
              reproduction: '   ',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityFixState.fail);
      expect(report.violations, contains('entry_blank_reproduction:quota'));
    });

    test('fails when a record carries an unknown owner', () {
      final report = _run(
        _register(
          entries: _replacing(
            'ai',
            _entry(
              fixArea: 'ai',
              fixId: 'FIX-AI-REF',
              evidence:
                  'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json',
              owner: 'nobody',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityFixState.fail);
      expect(report.violations, contains('entry_unknown_owner:ai:nobody'));
    });

    test('fails when a record cites an unreadable evidence source', () {
      final report = _run(
        _register(
          entries: _replacing(
            'ui',
            _entry(
              fixArea: 'ui',
              fixId: 'FIX-UI-REF',
              evidence: 'docs/planning/v1.3/sprint_118_ui_missing.json',
            ),
          ),
        ),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
          ],
        ),
      );
      expect(report.state, Sprint118StabilityFixState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('entry_unreadable_evidence:ui:'),
        ),
        isTrue,
      );
    });

    test('fails on a duplicate fix area', () {
      final entries = <Sprint118StabilityFixEntry>[
        ...Sprint118StabilityFixContract.canonicalRegister.entries,
        _entry(fixArea: 'auth', fixId: 'FIX-AUTH-DUP'),
      ];
      final report = _run(_register(entries: entries));
      expect(report.state, Sprint118StabilityFixState.fail);
      expect(report.violations, contains('fix_area_duplicate:auth'));
    });

    test('fails when a canonical fix area is missing', () {
      final entries = <Sprint118StabilityFixEntry>[
        for (final e in Sprint118StabilityFixContract.canonicalRegister.entries)
          if (e.fixArea != 'compatibility') e,
      ];
      final report = _run(_register(entries: entries));
      expect(report.state, Sprint118StabilityFixState.fail);
      expect(report.violations, contains('fix_area_missing:compatibility'));
    });

    test('fails when a record names an unknown fix area', () {
      final report = _run(
        _register(
          entries: _replacing(
            'accessibility',
            _entry(fixArea: 'unknown_area', fixId: 'FIX-UNKNOWN-REF'),
          ),
        ),
      );
      expect(report.state, Sprint118StabilityFixState.fail);
      // The replacement also removes the real 'accessibility' record, so both
      // the unknown-area and the missing-area violations are expected.
      expect(report.violations, contains('fix_area_unknown:unknown_area'));
      expect(report.violations, contains('fix_area_missing:accessibility'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _register(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
          ],
        ),
      );
      expect(report.state, Sprint118StabilityFixState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('reports the missing upstream owner vocabulary honestly', () {
      final report = _run(
        _register(),
        anchor: _anchor(owners: const <String>[]),
      );
      expect(report.openItems, contains('upstream_owner_vocabulary_missing'));
    });

    test('reports the missing upstream area vocabulary honestly', () {
      final report = _run(
        _register(),
        anchor: _anchor(
          intakeCategories: const <String>[],
          testSuites: const <String>[],
          rollbackEvidence: const <String>[],
        ),
      );
      expect(report.openItems, contains('upstream_area_vocabulary_missing'));
    });

    test('reports the missing upstream requirement vocabulary honestly', () {
      final report = _run(
        _register(),
        anchor: _anchor(p1Requirements: const <String>[]),
      );
      expect(
        report.openItems,
        contains('upstream_requirement_vocabulary_missing'),
      );
    });

    test('reports a canonical area the witness does not ground', () {
      final report = _run(
        _register(),
        anchor: _anchor(
          intakeCategories: const <String>['auth'],
          testSuites: const <String>[],
          rollbackEvidence: const <String>[],
        ),
      );
      expect(
        report.openItems,
        contains('area_not_grounded_in_witness:compatibility'),
      );
    });

    test('reports a canonical requirement the witness does not ground', () {
      final report = _run(
        _register(),
        anchor: _anchor(p1Requirements: const <String>['reproduction']),
      );
      expect(
        report.openItems,
        contains('requirement_not_grounded_in_witness:release_note'),
      );
    });

    test('sourceFor maps each area to its committed evidence source', () {
      expect(
        Sprint118StabilityFixContract.sourceFor('auth'),
        'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
      );
      expect(
        Sprint118StabilityFixContract.sourceFor('compatibility'),
        'docs/planning/v1.2/sprint_112_platform_compatibility_gate.json',
      );
      expect(Sprint118StabilityFixContract.sourceFor('unknown'), '');
    });
  });
}
