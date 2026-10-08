import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_maintenance_regression_matrix.dart';

/// A single matrix entry. Each test flips exactly the one thing it is about, so
/// a test that flips nothing proves the pass path exists and every other test
/// proves one way the gate refuses to take it.
Sprint118MaintenanceRegressionEntry _entry({
  String suite = 'unit',
  String referenceState = 'unit',
  String source = Sprint118MaintenanceRegressionContract.testMatrixManifestPath,
  String detail =
      'The unit suite regresses the committed stability fixes without a live '
      'maintenance run',
  List<String>? limitations,
  bool maintenanceExecuted = false,
  bool connectorCertified = false,
  bool observed = false,
}) {
  return Sprint118MaintenanceRegressionEntry(
    suite: suite,
    referenceState: referenceState,
    source: source,
    detail: detail,
    limitations: limitations ?? const <String>['synthetic_local'],
    maintenanceExecuted: maintenanceExecuted,
    connectorCertified: connectorCertified,
    observed: observed,
  );
}

Sprint118MaintenanceRegressionMatrix _matrix({
  String releaseState =
      Sprint118MaintenanceRegressionContract.delayedReleaseState,
  List<Sprint118MaintenanceRegressionEntry>? entries,
}) {
  return Sprint118MaintenanceRegressionMatrix(
    releaseState: releaseState,
    entries:
        entries ??
        Sprint118MaintenanceRegressionContract.canonicalMatrix.entries,
  );
}

/// The canonical entries with exactly one suite replaced, so a test can flip a
/// single entry without rebuilding the whole matrix.
List<Sprint118MaintenanceRegressionEntry> _replacing(
  String suite,
  Sprint118MaintenanceRegressionEntry replacement,
) {
  return <Sprint118MaintenanceRegressionEntry>[
    for (final e
        in Sprint118MaintenanceRegressionContract.canonicalMatrix.entries)
      if (e.suite == suite) replacement else e,
  ];
}

Sprint118MaintenanceRegressionAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118MaintenanceRegressionContract.requiredBaselineVerdict,
  String releaseState =
      Sprint118MaintenanceRegressionContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118MaintenanceRegressionContract.requiredCharterVerdict,
  int charterWindowMinutes = 60480,
  String stabilityFixesState = 'pass',
  String stabilityFixesVerdict =
      Sprint118MaintenanceRegressionContract.requiredStabilityFixesVerdict,
  String intakeState = 'pass',
  String intakeVerdict =
      Sprint118MaintenanceRegressionContract.requiredIntakeVerdict,
  List<String>? testMatrixSuites,
  List<String>? fullMatrixSuites,
  List<String>? patchMatrixSuites,
  List<String>? connectorContractSuites,
  List<String>? intakeCategories,
  List<String>? fixesSuites,
  bool liveConnectorExecution = false,
  List<String>? readableSources,
}) {
  return Sprint118MaintenanceRegressionAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    stabilityFixesState: stabilityFixesState,
    stabilityFixesVerdict: stabilityFixesVerdict,
    intakeState: intakeState,
    intakeVerdict: intakeVerdict,
    testMatrixSuites:
        testMatrixSuites ??
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
    fullMatrixSuites:
        fullMatrixSuites ??
        const <String>[
          'unit',
          'property',
          'contract',
          'integration',
          'migration',
          'ui',
          'accessibility',
          'end_to_end',
          'security',
          'regression',
        ],
    patchMatrixSuites:
        patchMatrixSuites ??
        const <String>[
          'unit',
          'integration',
          'migration',
          'recovery',
          'security',
          'privacy',
          'accessibility',
          'ui',
          'end_to_end',
          'regression',
        ],
    connectorContractSuites:
        connectorContractSuites ??
        const <String>[
          'manifest',
          'auth',
          'capability',
          'usage',
          'error',
          'reauth',
          'disconnect',
          'cleanup',
          'regression',
        ],
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
    fixesSuites:
        fixesSuites ??
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
    liveConnectorExecution: liveConnectorExecution,
    readableSources:
        readableSources ??
        Sprint118MaintenanceRegressionContract.canonicalSources,
  );
}

Sprint118MaintenanceRegressionReport _run(
  Sprint118MaintenanceRegressionMatrix matrix, {
  Sprint118MaintenanceRegressionAnchor? anchor,
}) {
  return const Sprint118MaintenanceRegressionGate().evaluateWith(
    anchor ?? _anchor(),
    matrix,
  );
}

void main() {
  group('118.26 Maintenance Regression Matrix', () {
    test('declares the canonical step, title, suites, fields, and paths', () {
      expect(Sprint118MaintenanceRegressionContract.canonicalStep, '118.26');
      expect(
        Sprint118MaintenanceRegressionContract.title,
        'Maintenance Regression Matrix',
      );
      expect(
        Sprint118MaintenanceRegressionContract.manifestPath,
        'docs/planning/v1.3/sprint_118_maintenance_regression_matrix.json',
      );
      expect(Sprint118MaintenanceRegressionContract.requiredSuites, <String>[
        'unit',
        'connector_contract',
        'auth',
        'sync',
        'billing',
        'security',
        'privacy',
        'accessibility',
        'ui',
        'end_to_end',
      ]);
      expect(Sprint118MaintenanceRegressionContract.requiredFields, <String>[
        'suite',
        'reference_state',
        'source',
        'detail',
        'limitations',
      ]);
      expect(
        Sprint118MaintenanceRegressionContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118MaintenanceRegressionContract.requiredSuites.length, 10);
      expect(
        Sprint118MaintenanceRegressionContract.canonicalSources.length,
        10,
      );
      expect(
        Sprint118MaintenanceRegressionContract.canonicalMatrix.entries.length,
        10,
      );
      expect(Sprint118MaintenanceRegressionContract.requiredFields.length, 5);
    });

    test('derives the reference-state vocabulary from committed witnesses', () {
      final anchor = _anchor();
      final vocabulary =
          Sprint118MaintenanceRegressionContract.stateVocabulary(<List<String>>[
            anchor.testMatrixSuites,
            anchor.fullMatrixSuites,
            anchor.patchMatrixSuites,
            anchor.connectorContractSuites,
            anchor.intakeCategories,
            anchor.fixesSuites,
          ]);
      for (final suite
          in Sprint118MaintenanceRegressionContract.requiredSuites) {
        expect(
          Sprint118MaintenanceRegressionContract.grounds(vocabulary, suite),
          isTrue,
          reason: '$suite must be grounded in a witness vocabulary',
        );
      }
      expect(
        vocabulary,
        contains(Sprint118MaintenanceRegressionContract.noReferenceState),
      );
      expect(vocabulary, isNot(contains('telepathy')));
    });

    test('grounds suites by exact name or by every compound part', () {
      const vocabulary = <String>[
        'unit',
        'connector',
        'contract',
        'end_to_end',
      ];
      expect(
        Sprint118MaintenanceRegressionContract.grounds(vocabulary, 'unit'),
        isTrue,
      );
      expect(
        Sprint118MaintenanceRegressionContract.grounds(
          vocabulary,
          'connector_contract',
        ),
        isTrue,
      );
      expect(
        Sprint118MaintenanceRegressionContract.grounds(
          vocabulary,
          'end_to_end',
        ),
        isTrue,
      );
      expect(
        Sprint118MaintenanceRegressionContract.grounds(vocabulary, 'telepathy'),
        isFalse,
      );
      expect(
        Sprint118MaintenanceRegressionContract.grounds(
          vocabulary,
          'connector_telepathy',
        ),
        isFalse,
      );
    });

    test('canonical matrix covers the ten suites and claims no live run', () {
      final matrix = Sprint118MaintenanceRegressionContract.canonicalMatrix;
      expect(matrix.entries.length, 10);
      expect(matrix.suiteItems.toSet(), <String>{
        'unit',
        'connector_contract',
        'auth',
        'sync',
        'billing',
        'security',
        'privacy',
        'accessibility',
        'ui',
        'end_to_end',
      });
      for (final entry in matrix.entries) {
        expect(entry.maintenanceExecuted, isFalse);
        expect(entry.connectorCertified, isFalse);
        expect(entry.observed, isFalse);
        expect(entry.limitations, isNotEmpty);
        for (final field
            in Sprint118MaintenanceRegressionContract.requiredFields) {
          expect(
            (entry.requiredFields[field] ?? '').trim(),
            isNotEmpty,
            reason: '${entry.suite}.$field must not be blank',
          );
        }
      }
    });

    test('passes on the canonical matrix', () {
      final report = _run(_matrix());
      expect(report.state, Sprint118MaintenanceRegressionState.pass);
      expect(report.verdict, 'MAINTENANCE_REGRESSION_MATRIX_VERIFIED_LOCAL');
      expect(report.matrixVerified, isTrue);
      expect(report.declaredSuites.length, 10);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      // connector_contract has no committed witness naming a reference state, so
      // the canonical matrix records the honest upstream gap rather than
      // inventing one.
      expect(report.openItems, <String>[
        'upstream_state_vocabulary_gap:connector_contract',
      ]);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118MaintenanceRegressionGate().evaluateWith(
        null,
        _matrix(),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_MAINTENANCE_REGRESSION_EVIDENCE_UNREADABLE',
      );
      expect(report.matrixVerified, isFalse);
    });

    test('blocks when the baseline anchor is not a frozen pass', () {
      final report = _run(
        _matrix(),
        anchor: _anchor(
          baselineState: 'fail',
          baselineVerdict: 'POST_RELEASE_HEALTH_BASELINE_DRIFT',
        ),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.blocked);
      expect(
        report.blockers,
        contains('baseline_not_frozen:POST_RELEASE_HEALTH_BASELINE_DRIFT'),
      );
    });

    test('blocks when the charter anchor is incomplete', () {
      final report = _run(
        _matrix(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_INCOMPLETE_LOCAL'),
      );
    });

    test('blocks when the charter window is not positive', () {
      final report = _run(_matrix(), anchor: _anchor(charterWindowMinutes: 0));
      expect(report.state, Sprint118MaintenanceRegressionState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_COMPLETE_LOCAL'),
      );
    });

    test('blocks when the stability fixes register is not verified', () {
      final report = _run(
        _matrix(),
        anchor: _anchor(stabilityFixesVerdict: 'STABILITY_FIXES_PARTIAL_LOCAL'),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.blocked);
      expect(
        report.blockers,
        contains('stability_fixes_not_verified:STABILITY_FIXES_PARTIAL_LOCAL'),
      );
    });

    test('blocks when the incident support intake is not verified', () {
      final report = _run(
        _matrix(),
        anchor: _anchor(intakeVerdict: 'INCIDENT_SUPPORT_INTAKE_PARTIAL_LOCAL'),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.blocked);
      expect(
        report.blockers,
        contains('intake_not_verified:INCIDENT_SUPPORT_INTAKE_PARTIAL_LOCAL'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _matrix(releaseState: 'GA_RELEASED'),
        anchor: _anchor(),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.fail);
      expect(
        report.violations,
        contains('release_state_mismatch:anchor=GA_DELAYED:matrix=GA_RELEASED'),
      );
    });

    test(
      'fails when a live connector execution is claimed on the delayed path',
      () {
        final report = _run(
          _matrix(),
          anchor: _anchor(liveConnectorExecution: true),
        );
        expect(report.state, Sprint118MaintenanceRegressionState.fail);
        expect(
          report.violations,
          contains('live_connector_execution_claimed_on_delayed_path'),
        );
      },
    );

    test('opens an item when a canonical suite is not grounded in a witness', () {
      // 'sync' is grounded only by the intake category vocabulary, so removing it
      // there leaves the sync suite ungrounded while every other reference state
      // stays grounded by another witness. The sync entry honestly marks the
      // upstream gap with the no-reference marker.
      final report = _run(
        _matrix(
          entries: _replacing(
            'sync',
            _entry(
              suite: 'sync',
              referenceState:
                  Sprint118MaintenanceRegressionContract.noReferenceState,
            ),
          ),
        ),
        anchor: _anchor(intakeCategories: const <String>['support']),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.pass);
      expect(report.openItems, contains('suite_not_grounded_in_witness:sync'));
      expect(report.openItems, contains('upstream_state_vocabulary_gap:sync'));
    });

    test('fails when an entry names an unknown suite', () {
      final report = _run(
        _matrix(
          entries: <Sprint118MaintenanceRegressionEntry>[
            ...Sprint118MaintenanceRegressionContract.canonicalMatrix.entries,
            _entry(suite: 'telepathy', referenceState: 'unit'),
          ],
        ),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.fail);
      expect(report.violations, contains('suite_unknown:telepathy'));
    });

    test('fails when an entry drops a required field', () {
      final report = _run(
        _matrix(
          entries: _replacing(
            'unit',
            _entry(suite: 'unit', referenceState: 'unit', detail: ''),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.fail);
      expect(report.violations, contains('entry_blank_detail:unit'));
    });

    test(
      'fails when an entry names a reference state outside the vocabulary',
      () {
        final report = _run(
          _matrix(
            entries: _replacing(
              'unit',
              _entry(suite: 'unit', referenceState: 'telepathy'),
            ),
          ),
        );
        expect(report.state, Sprint118MaintenanceRegressionState.fail);
        expect(report.violations, contains('reference_state_invalid:unit'));
      },
    );

    test('opens an item when an entry honestly marks no reference state', () {
      final report = _run(
        _matrix(
          entries: _replacing(
            'unit',
            _entry(
              suite: 'unit',
              referenceState:
                  Sprint118MaintenanceRegressionContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.pass);
      expect(report.openItems, contains('upstream_state_vocabulary_gap:unit'));
    });

    test('fails when an entry names an unreadable source', () {
      final report = _run(
        _matrix(
          entries: _replacing(
            'unit',
            _entry(
              suite: 'unit',
              referenceState: 'unit',
              source: 'docs/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.fail);
      expect(report.violations, contains('source_unreadable:unit'));
    });

    test(
      'fails when an entry claims a live maintenance run without a release',
      () {
        final report = _run(
          _matrix(
            entries: _replacing(
              'unit',
              _entry(
                suite: 'unit',
                referenceState: 'unit',
                maintenanceExecuted: true,
              ),
            ),
          ),
        );
        expect(report.state, Sprint118MaintenanceRegressionState.fail);
        expect(
          report.violations,
          contains('maintenance_executed_without_release:unit'),
        );
      },
    );

    test('fails when an entry claims a connector certification', () {
      final report = _run(
        _matrix(
          entries: _replacing(
            'connector_contract',
            _entry(
              suite: 'connector_contract',
              referenceState:
                  Sprint118MaintenanceRegressionContract.noReferenceState,
              connectorCertified: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.fail);
      expect(
        report.violations,
        contains(
          'connector_certification_claimed_without_release:connector_contract',
        ),
      );
    });

    test('fails when an entry claims a live observation', () {
      final report = _run(
        _matrix(
          entries: _replacing(
            'unit',
            _entry(suite: 'unit', referenceState: 'unit', observed: true),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.fail);
      expect(report.violations, contains('live_observation_claimed:unit'));
    });

    test('fails when a canonical suite is duplicated', () {
      final report = _run(
        _matrix(
          entries: <Sprint118MaintenanceRegressionEntry>[
            ...Sprint118MaintenanceRegressionContract.canonicalMatrix.entries,
            _entry(suite: 'unit', referenceState: 'unit'),
          ],
        ),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.fail);
      expect(report.violations, contains('suite_duplicate:unit'));
    });

    test('fails when a canonical suite is missing', () {
      final report = _run(
        _matrix(
          entries: <Sprint118MaintenanceRegressionEntry>[
            for (final e
                in Sprint118MaintenanceRegressionContract
                    .canonicalMatrix
                    .entries)
              if (e.suite != 'end_to_end') e,
          ],
        ),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.fail);
      expect(report.violations, contains('suite_missing:end_to_end'));
    });

    test('fails when a required evidence source is unreadable', () {
      final report = _run(
        _matrix(),
        anchor: _anchor(
          readableSources: <String>[
            for (final s
                in Sprint118MaintenanceRegressionContract.canonicalSources)
              if (s != Sprint118MaintenanceRegressionContract.authManifestPath)
                s,
          ],
        ),
      );
      expect(report.state, Sprint118MaintenanceRegressionState.fail);
      expect(
        report.violations,
        contains(
          'required_source_unreadable:docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
        ),
      );
    });
  });
}
