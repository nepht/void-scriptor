import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_beta_exposure_flag_matrix.dart';

const String _artifact =
    'docs/planning/v1.3/sprint_117_beta_exposure_flag_matrix.json';

Sprint117ExposureFlagRecord _row({
  String providerId = 'openai',
  String connectorId = 'conn_openai',
  String flagKey = 'connector.openai.enabled',
  String flagId = 'flag_kill_openai',
  List<String> audience = const <String>[
    'stage_internal',
    'stage_alpha',
    'stage_waitlist',
  ],
  String defaultState = 'OFF',
  List<String> dependencies = const <String>[],
  String killSwitchId = 'kill_openai',
  String fallback = 'fail_closed_disabled',
}) => Sprint117ExposureFlagRecord(
  providerId: providerId,
  connectorId: connectorId,
  flagKey: flagKey,
  flagId: flagId,
  audience: audience,
  defaultState: defaultState,
  dependencies: dependencies,
  killSwitchId: killSwitchId,
  fallback: fallback,
);

Sprint117ExposureAnchor _anchor({
  String exposureVerdict = Sprint117ExposureContract.exposureVerdict,
  String cohortVerdict = Sprint117ExposureContract.cohortBlockedVerdict,
  List<String> surfaceProviderIds = const <String>['openai', 'gemini'],
  List<String> consentedProviderIds = const <String>[],
  List<String> committedWithoutParticipant = const <String>['openai'],
  String rolloutDefault = 'OFF',
  String masterFlagKey = 'beta.connectors.enabled',
  Map<String, String> providerFlagKey = const <String, String>{
    'openai': 'connector.openai.enabled',
    'gemini': 'connector.gemini.enabled',
  },
  Map<String, String> providerConnector = const <String, String>{
    'openai': 'conn_openai',
    'gemini': 'conn_gemini',
  },
  // Keyed by connector id, because that is how the rollout stages record
  // exposure: a stage row names the connectors it exposes.
  Map<String, List<String>> providerStages = const <String, List<String>>{
    'conn_openai': <String>['stage_internal', 'stage_alpha', 'stage_waitlist'],
    'conn_gemini': <String>['stage_alpha', 'stage_waitlist'],
  },
  Map<String, String> providerKill = const <String, String>{
    'openai': 'kill_openai',
    'gemini': 'kill_gemini',
  },
  Map<String, String> killFlagRef = const <String, String>{
    'kill_openai': 'flag_kill_openai',
    'kill_gemini': 'flag_kill_gemini',
  },
  List<String> undrilledKillIds = const <String>['kill_openai', 'kill_gemini'],
  String crossDependencies = 'none',
  List<String> carriedOpenItems = const <String>[
    'release_cut_pending: pubspec 1.2.0-rc.1 != v1.3.0-beta.1',
  ],
}) => Sprint117ExposureAnchor(
  exposureVerdict: exposureVerdict,
  cohortVerdict: cohortVerdict,
  surfaceProviderIds: surfaceProviderIds,
  consentedProviderIds: consentedProviderIds,
  committedWithoutParticipant: committedWithoutParticipant,
  rolloutDefault: rolloutDefault,
  masterFlagKey: masterFlagKey,
  providerFlagKey: providerFlagKey,
  providerConnector: providerConnector,
  providerStages: providerStages,
  providerKill: providerKill,
  killFlagRef: killFlagRef,
  undrilledKillIds: undrilledKillIds,
  crossDependencies: crossDependencies,
  carriedOpenItems: carriedOpenItems,
);

List<Sprint117ExposureFlagRecord> _determinedRows() =>
    <Sprint117ExposureFlagRecord>[
      _row(),
      _row(
        providerId: 'gemini',
        connectorId: 'conn_gemini',
        flagKey: 'connector.gemini.enabled',
        flagId: 'flag_kill_gemini',
        audience: <String>['stage_alpha', 'stage_waitlist'],
        killSwitchId: 'kill_gemini',
      ),
    ];

Sprint117ExposureInput _input({
  List<Sprint117ExposureFlagRecord>? rows,
  Sprint117ExposureAnchor? anchor,
}) => Sprint117ExposureInput(
  rows: rows ?? _determinedRows(),
  anchor: anchor ?? _anchor(),
);

void main() {
  group('117.5 contract basics', () {
    test('the live loader decides one row per exposed beta connector', () {
      final report = const Sprint117ExposureGate().evaluate();

      expect(report.state, Sprint117ExposureState.pass);
      expect(report.verdict, Sprint117ExposureContract.passVerdict);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.rows, hasLength(31));
    });

    test(
      'the seven required fields are exactly the canonical 117.5 fields',
      () {
        expect(Sprint117ExposureContract.requiredFields, <String>[
          'flag',
          'connector',
          'audience',
          'default',
          'dependencies',
          'kill_switch',
          'fallback',
        ]);
      },
    );

    test('the source manifest paths are pinned', () {
      expect(Sprint117ExposureContract.manifestPath, _artifact);
      expect(
        Sprint117ExposureContract.exposureManifestPath,
        'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json',
      );
      expect(
        Sprint117ExposureContract.cohortManifestPath,
        'docs/planning/v1.3/sprint_117_beta_cohort_consent_verification.json',
      );
      expect(
        Sprint117ExposureContract.rolloutManifestPath,
        'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json',
      );
      expect(
        Sprint117ExposureContract.dependencyManifestPath,
        'docs/planning/v1.2/sprint_113_feature_flag_dependency_validation.json',
      );
      expect(Sprint117ExposureContract.sourceManifests, hasLength(4));
    });

    test('the matrix never claims a live beta was run', () {
      final report = const Sprint117ExposureGate().evaluate();

      expect(report.liveBetaExecuted, isFalse);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
      expect(
        report.limitations.join(' '),
        contains('not live provider availability'),
      );
    });

    test('field coverage counts only the fields a row actually carries', () {
      final report = const Sprint117ExposureGate().evaluate();

      expect(
        report.fieldCoverage.keys,
        Sprint117ExposureContract.requiredFields,
      );

      // The default and the fallback are decided for every connector, because
      // both are single recorded values rather than per-connector rows.
      expect(report.fieldCoverage['default'], report.rows.length);
      expect(report.fieldCoverage['fallback'], report.rows.length);

      // The remaining four are per-connector, and only the two connectors the
      // rollout actually stages carry them. Reporting 31 here would be a lie
      // about a surface that has decided two connectors.
      for (final field in <String>[
        'flag',
        'connector',
        'audience',
        'kill_switch',
      ]) {
        expect(
          report.fieldCoverage[field],
          report.determinedExposed.length,
          reason: 'field $field is carried by the determined rows only',
        );
      }

      // 113.13 records no cross-flag dependency, so no row carries one and the
      // coverage is honestly zero rather than silently counted as complete.
      expect(report.fieldCoverage['dependencies'], 0);
    });
  });

  group('117.5 determined exposure', () {
    test('only a row with every gating field may be exposed', () {
      final report = const Sprint117ExposureGate().evaluateWith(_input());

      expect(report.determinedExposed, <String>['openai', 'gemini']);
      expect(report.undetermined, isEmpty);
    });

    test(
      'a connector with no recorded flag is undetermined, not a violation',
      () {
        final report = const Sprint117ExposureGate().evaluateWith(
          _input(
            anchor: _anchor(
              surfaceProviderIds: <String>['openai', 'kofi'],
              providerFlagKey: const <String, String>{
                'openai': 'connector.openai.enabled',
                'gemini': 'connector.gemini.enabled',
              },
            ),
            rows: <Sprint117ExposureFlagRecord>[
              _row(),
              _row(
                providerId: 'kofi',
                connectorId: '',
                flagKey: '',
                flagId: '',
                audience: const <String>[],
                killSwitchId: '',
              ),
            ],
          ),
        );

        expect(report.determinedExposed, <String>['openai']);
        expect(report.undetermined, <String>['kofi']);
        expect(report.violations, isEmpty);
        expect(report.state, Sprint117ExposureState.pass);
      },
    );

    test('the shipped surface determines two of thirty-one connectors', () {
      final report = const Sprint117ExposureGate().evaluate();

      expect(report.determinedExposed, <String>['openai', 'gemini']);
      expect(report.undetermined, hasLength(29));
      expect(report.determinedExposed, isNot(contains('kofi')));
    });

    test('a row with no flag may not claim exposure', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[_row(flagKey: '', flagId: '')],
        ),
      );

      expect(report.determinedExposed, isEmpty);
      expect(report.violations, contains('flag_blank:openai'));
    });

    test('a row with no kill switch may not claim exposure', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[_row(killSwitchId: '')],
        ),
      );

      expect(report.determinedExposed, isEmpty);
      expect(report.violations, contains('kill_switch_blank:openai'));
    });

    test('a row with no audience may not claim exposure', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[_row(audience: const <String>[])],
        ),
      );

      expect(report.determinedExposed, isEmpty);
      expect(report.violations, contains('audience_blank:openai'));
    });

    test('exposure is counted only when the row is coherent', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[_row(defaultState: 'ON')],
        ),
      );

      expect(report.determinedExposed, isEmpty);
      expect(report.violations, contains('default_on:openai'));
    });
  });

  group('117.5 flag rules', () {
    test('a flag that ships ON is a violation', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[_row(defaultState: 'ON')],
        ),
      );

      expect(report.violations, contains('default_on:openai'));
      expect(report.violations, contains('default_drift:openai:ON:OFF'));
    });

    test(
      'a default that is not the recorded rollout default is a violation',
      () {
        final report = const Sprint117ExposureGate().evaluateWith(
          _input(
            anchor: _anchor(surfaceProviderIds: const <String>['openai']),
            rows: <Sprint117ExposureFlagRecord>[_row(defaultState: 'MAYBE')],
          ),
        );

        expect(report.violations, contains('default_unknown:openai:MAYBE'));
      },
    );

    test('a flag key the rollout does not record is unsourced', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[
            _row(flagKey: 'connector.fabricated.enabled'),
          ],
        ),
      );

      expect(
        report.violations,
        contains(
          'flag_drift:openai:connector.fabricated.enabled:connector.openai.enabled',
        ),
      );
      expect(report.determinedExposed, isEmpty);
    });

    test('two rows may not share one flag key', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          rows: <Sprint117ExposureFlagRecord>[
            _row(),
            _row(providerId: 'gemini', connectorId: 'conn_gemini'),
          ],
        ),
      );

      expect(
        report.violations,
        contains('flag_duplicate:connector.openai.enabled'),
      );
    });

    test('two rows may not share one provider', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          rows: <Sprint117ExposureFlagRecord>[
            _row(),
            _row(
              flagKey: 'connector.gemini.enabled',
              flagId: 'flag_kill_gemini',
            ),
          ],
        ),
      );

      expect(report.violations, contains('provider_duplicate:openai'));
    });

    test('a row for a provider outside the exposed surface is a violation', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          rows: <Sprint117ExposureFlagRecord>[
            _row(),
            _row(
              providerId: 'saweria',
              connectorId: 'conn_saweria',
              flagKey: 'connector.saweria.enabled',
              flagId: 'flag_kill_saweria',
              killSwitchId: 'kill_saweria',
            ),
          ],
        ),
      );

      expect(report.violations, contains('provider_unlisted:saweria'));
    });
  });

  group('117.5 connector and audience rules', () {
    test('a connector the rollout does not record is unsourced', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[_row(connectorId: 'conn_fake')],
        ),
      );

      expect(
        report.violations,
        contains('connector_drift:openai:conn_fake:conn_openai'),
      );
      expect(report.determinedExposed, isEmpty);
    });

    test('an audience the rollout does not record is unknown', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[
            _row(audience: const <String>['stage_ghost']),
          ],
        ),
      );

      expect(
        report.violations,
        contains('audience_unknown:openai:stage_ghost'),
      );
      expect(report.determinedExposed, isEmpty);
    });

    test('a blank audience entry is not an audience', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[
            _row(audience: const <String>['', '  ']),
          ],
        ),
      );

      expect(report.violations, contains('audience_blank:openai'));
    });

    test('a row exposed to fewer stages than recorded is a drift', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[
            _row(audience: const <String>['stage_alpha']),
          ],
        ),
      );

      expect(report.violations, contains('audience_drift:openai'));
      expect(report.determinedExposed, isEmpty);
    });
  });

  group('117.5 kill switch rules', () {
    test('a kill switch the rollout does not record is unsourced', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[_row(killSwitchId: 'kill_ghost')],
        ),
      );

      expect(
        report.violations,
        contains('kill_switch_unsourced:openai:kill_ghost'),
      );
    });

    test('a kill switch pointing at another provider flag is a mismatch', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[_row(flagId: 'flag_kill_gemini')],
        ),
      );

      expect(
        report.violations,
        contains('kill_flag_mismatch:openai:flag_kill_gemini:flag_kill_openai'),
      );
      expect(report.determinedExposed, isEmpty);
    });

    test('an undrilled kill switch is surfaced as an open item', () {
      final report = const Sprint117ExposureGate().evaluate();

      expect(report.openItems, contains('kill_switch_not_drilled:kill_openai'));
      expect(report.openItems, contains('kill_switch_not_drilled:kill_gemini'));
    });

    test('a fully drilled kill switch raises no open item', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(anchor: _anchor(undrilledKillIds: const <String>[])),
      );

      expect(
        report.openItems.where(
          (item) => item.startsWith('kill_switch_not_drilled:'),
        ),
        isEmpty,
      );
    });
  });

  group('117.5 dependency and fallback rules', () {
    test('a dependency the repository does not record is unsourced', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[
            _row(dependencies: <String>['beta.connectors.enabled']),
          ],
        ),
      );

      expect(
        report.violations,
        contains('dependency_unsourced:openai:beta.connectors.enabled'),
      );
    });

    test(
      'an empty dependency list is accepted when the source records none',
      () {
        final report = const Sprint117ExposureGate().evaluateWith(_input());

        expect(report.violations, isEmpty);
      },
    );

    test('a blank fallback is a violation', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[_row(fallback: '  ')],
        ),
      );

      expect(report.violations, contains('fallback_blank:openai'));
      expect(report.determinedExposed, isEmpty);
    });

    test('a fallback that does not fail closed is a violation', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(surfaceProviderIds: const <String>['openai']),
          rows: <Sprint117ExposureFlagRecord>[_row(fallback: 'fail_open')],
        ),
      );

      expect(
        report.violations,
        contains('fallback_not_fail_closed:openai:fail_open'),
      );
    });
  });

  group('117.5 consent gate', () {
    test('an unverified cohort enables nobody', () {
      final report = const Sprint117ExposureGate().evaluate();

      expect(report.enabledSubset, isEmpty);
      expect(report.consentGateVerified, isFalse);
      expect(report.openItems, contains('cohort_not_verified'));
    });

    test('a committed consent with no participant is not consent', () {
      final report = const Sprint117ExposureGate().evaluate();

      expect(report.consentedProviderIds, isEmpty);
      expect(report.openItems, contains('consent_without_participant:openai'));
    });

    test('a verified cohort exposes only the consented connectors', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(
            cohortVerdict: Sprint117ExposureContract.cohortVerifiedVerdict,
            consentedProviderIds: <String>['openai'],
            committedWithoutParticipant: const <String>[],
          ),
        ),
      );

      expect(report.consentGateVerified, isTrue);
      expect(report.enabledSubset, <String>['openai']);
      expect(report.determinedExposed, <String>['openai', 'gemini']);
    });

    test('a partially consenting cohort enables only what it covers', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(
            cohortVerdict: Sprint117ExposureContract.cohortVerifiedVerdict,
            consentedProviderIds: const <String>['gemini'],
            committedWithoutParticipant: const <String>[],
          ),
        ),
      );

      expect(report.violations, isEmpty);
      expect(report.determinedExposed, <String>['openai', 'gemini']);
      expect(report.enabledSubset, <String>['gemini']);
    });

    test('the shipped matrix enables nobody because consent is unverified', () {
      final report = const Sprint117ExposureGate().evaluate();

      expect(report.determinedExposed, hasLength(2));
      expect(report.enabledSubset, isEmpty);
      expect(report.violations, isEmpty);
    });
  });

  group('117.5 surface coherence', () {
    test('a drifted exposure surface is a violation', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(
            exposureVerdict: 'CERTIFICATION_SNAPSHOT_INCONSISTENT',
          ),
        ),
      );

      expect(report.violations, contains('exposure_anchor_drift'));
    });

    test('a missing anchor blocks rather than passes', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        const Sprint117ExposureInput(),
      );

      expect(report.state, Sprint117ExposureState.blocked);
      expect(report.verdict, Sprint117ExposureContract.blockedVerdict);
      expect(report.missingFields, contains('exposure_anchor'));
    });

    test('a missing master flag blocks the matrix', () {
      final report = const Sprint117ExposureGate().evaluateWith(
        _input(
          anchor: _anchor(
            surfaceProviderIds: const <String>['openai'],
            masterFlagKey: '',
          ),
          rows: <Sprint117ExposureFlagRecord>[_row()],
        ),
      );

      expect(report.violations, isEmpty);
      expect(report.state, Sprint117ExposureState.blocked);
      expect(report.verdict, Sprint117ExposureContract.blockedVerdict);
      expect(report.missingFields, contains('master_flag'));
    });

    test('the undetermined surface is reported, never silently dropped', () {
      final report = const Sprint117ExposureGate().evaluate();

      expect(
        report.undetermined.length + report.determinedExposed.length,
        report.rows.length,
      );
      expect(report.openItems, contains('exposure_undetermined:29'));
    });
  });

  group('117.5 committed manifest', () {
    test(
      'the committed manifest records the same verdict as the live gate',
      () {
        final live = const Sprint117ExposureGate().evaluate();
        final file = File(Sprint117ExposureContract.manifestPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'the generated exposure matrix manifest must be committed',
        );
        final decoded = jsonDecode(file.readAsStringSync());
        expect(decoded, isA<Map<String, dynamic>>());
        final manifest = decoded as Map<String, dynamic>;

        expect(manifest['state'], live.state.name);
        expect(manifest['verdict'], live.verdict);
        expect(
          List<String>.from(manifest['missing_fields'] as List<dynamic>),
          live.missingFields,
        );
        expect(
          List<String>.from(manifest['violations'] as List<dynamic>),
          live.violations,
        );
        expect(manifest['row_count'], live.rows.length);
        expect(
          List<String>.from(manifest['determined_exposed'] as List<dynamic>),
          live.determinedExposed,
        );
        expect(
          List<String>.from(manifest['enabled_subset'] as List<dynamic>),
          live.enabledSubset,
        );
      },
    );

    test('the manifest pins the seven canonical fields and its sources', () {
      final file = File(Sprint117ExposureContract.manifestPath);
      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(manifest['canonical_step'], '117.5');
      expect(manifest['live_beta_executed'], isFalse);
      expect(
        List<String>.from(manifest['required_fields'] as List<dynamic>),
        Sprint117ExposureContract.requiredFields,
      );
      expect(
        List<String>.from(manifest['source_manifests'] as List<dynamic>),
        Sprint117ExposureContract.sourceManifests,
      );
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
    });

    test('the manifest records the master flag and the recorded default', () {
      final file = File(Sprint117ExposureContract.manifestPath);
      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(manifest['master_flag'], 'beta.connectors.enabled');
      expect(manifest['recorded_default'], 'OFF');
      expect(manifest['consented_provider_ids'], isEmpty);
      expect(manifest['consent_gate_verified'], isFalse);
    });

    test('the manifest row count matches the exposed surface it inherits', () {
      final exposure =
          jsonDecode(
                File(
                  Sprint117ExposureContract.exposureManifestPath,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final file = File(Sprint117ExposureContract.manifestPath);
      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(
        manifest['row_count'],
        List<String>.from(exposure['exposed_subset'] as List<dynamic>).length,
      );
    });
  });
}
