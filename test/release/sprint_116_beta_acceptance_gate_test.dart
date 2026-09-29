import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_icon_registry.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_beta_acceptance_gate.dart';

const String _manifestArtifact =
    'docs/planning/v1.2/sprint_116_beta_acceptance_gate.json';

Sprint116CertificationFinding _finding(
  String provider, {
  String step = '116.21',
  String path =
      'docs/planning/v1.2/sprint_116_openai_connector_certification.json',
  String manifestStatus = 'VERIFIED-LOCAL',
  String recordStatus = 'UNVERIFIED',
  String connectorVerdict = '',
  int recordCount = 1,
}) => Sprint116CertificationFinding(
  providerId: provider,
  step: step,
  sourcePath: path,
  manifestStatus: manifestStatus,
  recordStatus: recordStatus,
  connectorVerdict: connectorVerdict,
  recordCount: recordCount,
);

List<Sprint116LedgerGateStatus> _ledger(
  List<String> steps, {
  String status = 'VERIFIED-LOCAL',
}) => [
  for (final step in steps)
    Sprint116LedgerGateStatus(step: step, status: status),
];

Map<String, String?> _manifests(List<String> steps) => {
  for (final step in steps) step: step,
};

Sprint116BetaAcceptanceInput _healthyInput({
  Map<String, int>? registryCounts,
  List<Sprint116CertificationFinding>? findings,
  List<Sprint116LedgerGateStatus>? ledgerGates,
  Map<String, String?>? gateManifests,
  Sprint116BetaCoveragePlan? coveragePlan,
  Sprint116RolloutPlan? rolloutPlan,
  String pubspecVersion = '1.3.0-beta.1',
  bool omitCoveragePlan = false,
  bool omitRolloutPlan = false,
}) => Sprint116BetaAcceptanceInput(
  registryCounts:
      registryCounts ??
      <String, int>{
        for (final source
            in Sprint116BetaAcceptanceContract.registryCountSources.keys)
          source: Sprint116BetaAcceptanceContract.registryProviders.length,
      },
  findings: findings ?? <Sprint116CertificationFinding>[_finding('openai')],
  ledgerGates:
      ledgerGates ?? _ledger(Sprint116BetaAcceptanceContract.requiredGateSteps),
  gateManifests:
      gateManifests ??
      _manifests(Sprint116BetaAcceptanceContract.requiredGateSteps),
  coveragePlan: omitCoveragePlan ? null : coveragePlan ?? _coveragePlan(),
  rolloutPlan: omitRolloutPlan ? null : rolloutPlan ?? _rolloutPlan(),
  pubspecVersion: pubspecVersion,
);

Sprint116BetaCoveragePlan _coveragePlan({
  List<String> cohorts = const <String>['cohort_alpha'],
  List<Sprint116BetaCoverageEntry>? coverage,
  List<Sprint116BetaConsentEntry>? consents,
}) => Sprint116BetaCoveragePlan(
  cohorts: cohorts,
  coverage:
      coverage ??
      <Sprint116BetaCoverageEntry>[
        const Sprint116BetaCoverageEntry(
          providerId: 'openai',
          connectorId: 'conn_openai',
          stage: 'committed',
          consentRef: 'consent_openai',
        ),
      ],
  consents:
      consents ??
      <Sprint116BetaConsentEntry>[
        const Sprint116BetaConsentEntry(
          consentId: 'consent_openai',
          cohortId: 'cohort_alpha',
        ),
      ],
);

Sprint116RolloutPlan _rolloutPlan({
  List<Sprint116BetaStage>? stages,
  List<Sprint116BetaFlag>? flags,
  List<String> stopStageIds = const <String>['stage_internal'],
  List<Sprint116BetaRollback>? rollbacks,
  List<Sprint116BetaKillSwitch>? killSwitches,
}) => Sprint116RolloutPlan(
  stages:
      stages ??
      <Sprint116BetaStage>[
        const Sprint116BetaStage(
          stageId: 'stage_internal',
          exposedConnectors: <String>['conn_openai'],
        ),
      ],
  flags:
      flags ??
      <Sprint116BetaFlag>[
        const Sprint116BetaFlag(
          flagKey: 'connector.openai.enabled',
          defaultState: 'OFF',
        ),
      ],
  stopStageIds: stopStageIds,
  rollbacks:
      rollbacks ??
      <Sprint116BetaRollback>[
        const Sprint116BetaRollback(
          rollbackId: 'rb_internal',
          targetScope: 'stage',
          targetId: 'stage_internal',
          touchesLocalData: false,
        ),
      ],
  killSwitches:
      killSwitches ??
      <Sprint116BetaKillSwitch>[
        const Sprint116BetaKillSwitch(
          killId: 'kill_openai',
          providerId: 'openai',
          connectorId: 'conn_openai',
          stages: <String>['stage_internal'],
        ),
      ],
);

void main() {
  group('116.51 Beta Acceptance Gate contract', () {
    test('locks the seven evidence areas the canonical step demands', () {
      expect(Sprint116BetaAcceptanceContract.requiredEvidence, <String>[
        'certification_registry',
        'certified_subset',
        'limited_connectors',
        'blocked_connectors',
        'quality_gates',
        'beta_plan',
        'rollback_readiness',
      ]);
      expect(Sprint116BetaAcceptanceContract.canonicalStep, '116.51');
      expect(
        Sprint116BetaAcceptanceContract.manifestPath,
        'docs/planning/v1.2/sprint_116_beta_acceptance_gate.json',
      );
      expect(
        Sprint116BetaAcceptanceContract.ledgerPath,
        'docs/sprints/sprint-116-connector-certification.md',
      );
      expect(
        Sprint116BetaAcceptanceContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
      expect(Sprint116BetaAcceptanceContract.betaTarget, 'v1.3.0-beta.1');
      expect(Sprint116BetaAcceptanceContract.knownVisibility, <String>[
        'visible',
        'visible_limited',
        'hidden',
      ]);
      expect(Sprint116BetaAcceptanceContract.knownCoverageStages, <String>[
        'committed',
        'planned',
        'deferred',
        'excluded',
      ]);
      expect(Sprint116BetaAcceptanceContract.knownRecordStatuses, <String>[
        'UNVERIFIED',
        'CERTIFIED',
        'LIMITED',
        'BLOCKED',
        'EXPIRED',
      ]);
      expect(Sprint116BetaAcceptanceContract.knownConnectorVerdicts, <String>[
        'BLOCKED',
        'LIMITED',
        'SUPPORTED',
      ]);
      expect(
        Sprint116BetaAcceptanceContract.ledgerKnownStatuses,
        contains('VERIFIED-LOCAL'),
      );
      expect(Sprint116BetaAcceptanceContract.connectorPrefix, 'conn_');
    });

    test('the registry declaration mirrors the 32 provider icon entries', () {
      // Drift guard: the gate declares the canonical registry ids so it can run
      // without importing another feature. A test pins that declaration to the
      // live icon registry instead of trusting the copy.
      expect(Sprint116BetaAcceptanceContract.registryProviders.length, 32);
      expect(
        Set<String>.from(Sprint116BetaAcceptanceContract.registryProviders),
        Set<String>.from(
          ProviderIconRegistry.standard.all.map((e) => e.providerId),
        ),
      );
      expect(
        Sprint116BetaAcceptanceContract.registryProviders.toSet(),
        containsAll(<String>[
          'openai',
          'gemini',
          'github',
          'stripe',
          'paypal',
          'midtrans',
          'saweria',
          'kofi',
          'local_storage',
        ]),
      );
    });

    test('the quality gate and beta plan steps are the certified chain', () {
      expect(Sprint116BetaAcceptanceContract.qualityGateSteps, <String>[
        '116.40',
        '116.41',
        '116.42',
        '116.43',
        '116.44',
        '116.45',
        '116.46',
        '116.47',
        '116.48',
      ]);
      expect(Sprint116BetaAcceptanceContract.betaPlanSteps, <String>[
        '116.49',
        '116.50',
      ]);
      expect(
        Sprint116BetaAcceptanceContract.requiredGateSteps.length,
        Sprint116BetaAcceptanceContract.qualityGateSteps.length +
            Sprint116BetaAcceptanceContract.betaPlanSteps.length,
      );
      expect(
        Sprint116BetaAcceptanceContract.gateManifestPaths.keys,
        containsAll(Sprint116BetaAcceptanceContract.requiredGateSteps),
      );
    });

    test('the certification manifest list covers every declared provider id', () {
      expect(
        Sprint116BetaAcceptanceContract.certificationManifestPaths.length,
        greaterThanOrEqualTo(28),
      );
      for (final path
          in Sprint116BetaAcceptanceContract.certificationManifestPaths) {
        expect(File(path).existsSync(), isTrue, reason: 'missing $path');
      }
      expect(
        Sprint116BetaAcceptanceContract.registryCountSources.keys,
        containsAll(<String>[
          'docs/planning/v1.2/sprint_115_provider_connector_manifest.json',
          'docs/planning/v1.2/sprint_116_provider_registry_reconciliation.json',
        ]),
      );
    });

    test('a healthy synthetic input passes every evidence area', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.pass);
      expect(report.verdict, 'BETA_ACCEPTANCE_LOCAL_READY');
      expect(report.missingEvidence, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.certifiedSubset, <String>['openai']);
      expect(report.limitedConnectors, isEmpty);
      expect(report.blockedConnectors.length, 31);
      expect(
        report.evidenceCoverage.keys,
        containsAll(Sprint116BetaAcceptanceContract.requiredEvidence),
      );
      expect(report.betaVersionCut, isTrue);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });
  });

  group('116.51 live repository evaluation', () {
    test('the live gate passes with a 30 / 1 / 1 certified split', () {
      final report = Sprint116BetaAcceptanceGate().evaluate();
      expect(
        report.state,
        Sprint116BetaAcceptanceStatus.pass,
        reason: report.violations.toString(),
      );
      expect(report.verdict, 'BETA_ACCEPTANCE_LOCAL_READY');
      expect(report.missingEvidence, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.registryProviderCount, 32);
      expect(report.certifiedSubset.length, 30);
      expect(
        report.certifiedSubset,
        containsAll(<String>['openai', 'gemini', 'github', 'stripe']),
      );
      expect(report.certifiedSubset, isNot(contains('saweria')));
      expect(report.certifiedSubset, isNot(contains('kofi')));
      expect(report.limitedConnectors, <String>['kofi']);
      expect(report.blockedConnectors, <String>['saweria']);
      expect(
        report.certifiedSubset.length +
            report.limitedConnectors.length +
            report.blockedConnectors.length,
        32,
      );
      expect(report.visibility['openai'], 'visible');
      expect(report.visibility['kofi'], 'visible_limited');
      expect(report.visibility['saweria'], 'hidden');
      expect(report.visibility.length, 32);
    });

    test('every provider that has not passed is hidden from the beta', () {
      final report = Sprint116BetaAcceptanceGate().evaluate();
      final hidden = report.blockedConnectors.toSet();
      for (final provider in report.certifiedSubset) {
        expect(hidden.contains(provider), isFalse, reason: provider);
        expect(report.visibility[provider], 'visible');
      }
      for (final provider in report.limitedConnectors) {
        expect(report.visibility[provider], 'visible_limited');
      }
      for (final provider in hidden) {
        expect(report.visibility[provider], 'hidden');
      }
      expect(report.hiddenFromBeta, unorderedEquals(report.blockedConnectors));
    });

    test('the live registry counts agree with both authority documents', () {
      final input = const Sprint116BetaAcceptanceInputLoader().load();
      expect(input.registryCounts, <String, int>{
        'docs/planning/v1.2/sprint_115_provider_connector_manifest.json': 32,
        'docs/planning/v1.2/sprint_116_provider_registry_reconciliation.json':
            32,
      });
      final report = Sprint116BetaAcceptanceGate().evaluateWith(input);
      expect(report.evidenceCoverage['certification_registry'], 32);
    });

    test(
      'the live quality gate chain is VERIFIED-LOCAL in the active ledger',
      () {
        final report = Sprint116BetaAcceptanceGate().evaluate();
        expect(report.qualityGates.length, 11);
        for (final gate in report.qualityGates) {
          expect(gate.ledgerStatus, 'VERIFIED-LOCAL', reason: gate.step);
          expect(gate.manifestPresent, isTrue, reason: gate.step);
          expect(gate.canonicalStepMatches, isTrue, reason: gate.step);
        }
        expect(report.evidenceCoverage['quality_gates'], 11);
      },
    );

    test(
      'the live beta plan only exposes providers inside the certified subset',
      () {
        final report = Sprint116BetaAcceptanceGate().evaluate();
        final allowed = <String>{
          ...report.certifiedSubset,
          ...report.limitedConnectors,
        };
        expect(report.betaPlanExposedConnectors, isNotEmpty);
        for (final connector in report.betaPlanExposedConnectors) {
          expect(
            connector,
            startsWith(Sprint116BetaAcceptanceContract.connectorPrefix),
          );
        }
        expect(report.betaPlanCoverageProviders, <String>['openai', 'gemini']);
        for (final provider in report.betaPlanCoverageProviders) {
          expect(allowed.contains(provider), isTrue, reason: provider);
        }
        expect(report.rollbackReady, isTrue);
        expect(report.betaPlanCohorts, greaterThanOrEqualTo(1));
        expect(report.betaPlanConsents, greaterThanOrEqualTo(1));
      },
    );

    test(
      'the acceptance target is declared against the current pubspec version',
      () {
        final report = Sprint116BetaAcceptanceGate().evaluate();
        expect(report.betaTarget, 'v1.3.0-beta.1');
        expect(report.pubspecVersion, isNotEmpty);
        expect(
          report.betaVersionCut,
          report.pubspecVersion == '1.3.0-beta.1',
          reason: 'release cut is an open item, not a certification claim',
        );
        expect(report.openItems, contains(startsWith('release_cut_pending')));
        expect(report.limitations.join(' '), contains('DEFERRED-EXTERNAL'));
      },
    );

    test('the committed manifest matches the live gate result', () {
      final report = Sprint116BetaAcceptanceGate().evaluate();
      final manifest =
          jsonDecode(
                File(
                  Sprint116BetaAcceptanceContract.manifestPath,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '116.51');
      expect(manifest['status'], 'UNVERIFIED');
      expect(manifest['live_beta_executed'], isFalse);
      expect(
        manifest['required_evidence'],
        Sprint116BetaAcceptanceContract.requiredEvidence,
      );
      expect(manifest['beta_target'], report.betaTarget);
      expect(manifest['pubspec_version'], report.pubspecVersion);
      expect(manifest['beta_version_cut'], report.betaVersionCut);
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['registry_provider_count'], report.registryProviderCount);
      expect(manifest['certified_subset'], report.certifiedSubset);
      expect(manifest['limited_connectors'], report.limitedConnectors);
      expect(manifest['blocked_connectors'], report.blockedConnectors);
      expect(manifest['rollback_ready'], report.rollbackReady);
    });

    test('the committed manifest carries no secret material', () {
      final raw = File(_manifestArtifact).readAsStringSync();
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      final report = Sprint116BetaAcceptanceGate().evaluate();
      final vocabulary = <String>{
        ...Sprint116BetaAcceptanceContract.requiredEvidence,
        ...Sprint116BetaAcceptanceContract.knownVisibility,
        ...Sprint116BetaAcceptanceContract.knownCoverageStages,
        ...report.certifiedSubset,
        ...report.limitedConnectors,
        ...report.blockedConnectors,
        ...report.betaPlanExposedConnectors,
      };

      bool carriesSecret(Object? node) {
        if (node is Map) {
          for (final entry in node.entries) {
            if (entry.key.toString().toLowerCase().contains('api_key') ||
                entry.key.toString().toLowerCase().contains('secret')) {
              return true;
            }
            if (carriesSecret(entry.value)) return true;
          }
          return false;
        }
        if (node is List) return node.any(carriesSecret);
        final text = node.toString();
        if (vocabulary.contains(text)) return false;
        return text.toLowerCase().contains('api_key') ||
            text.toLowerCase().contains('bearer') ||
            text.toLowerCase().contains('private_key');
      }

      expect(carriesSecret(manifest), isFalse);
      expect(raw.contains('sk-'), isFalse);
    });
  });

  group('116.51 fail-closed certification registry', () {
    test('no certification findings at all blocks the registry area', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(findings: const <Sprint116CertificationFinding>[]),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.blocked);
      expect(report.missingEvidence, contains('certification_registry'));
    });

    test(
      'a registry count source that never loaded blocks the registry area',
      () {
        final report = Sprint116BetaAcceptanceGate().evaluateWith(
          _healthyInput(registryCounts: const <String, int>{}),
        );
        expect(report.state, Sprint116BetaAcceptanceStatus.blocked);
        expect(report.missingEvidence, contains('certification_registry'));
      },
    );

    test('a registry count that contradicts the declared ids is blocked', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          registryCounts: <String, int>{
            'docs/planning/v1.2/sprint_115_provider_connector_manifest.json':
                31,
            'docs/planning/v1.2/sprint_116_provider_registry_reconciliation.json':
                32,
          },
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.blocked);
      expect(report.missingEvidence, contains('certification_registry'));
      expect(
        report.violations.any((v) => v.startsWith('registry_count:')),
        isTrue,
        reason: report.violations.toString(),
      );
    });

    test('certifying a provider outside the registry is a phantom claim', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          findings: <Sprint116CertificationFinding>[
            _finding('openai'),
            _finding('not_a_registry_provider'),
          ],
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(
        report.violations,
        contains('phantom_provider:not_a_registry_provider'),
      );
    });

    test(
      'a certification sourced from a non-verified manifest is rejected',
      () {
        final report = Sprint116BetaAcceptanceGate().evaluateWith(
          _healthyInput(
            findings: <Sprint116CertificationFinding>[
              _finding('openai', manifestStatus: 'PENDING'),
              _finding('gemini', step: '116.22'),
            ],
          ),
        );
        expect(report.state, Sprint116BetaAcceptanceStatus.fail);
        expect(
          report.violations.any(
            (v) => v.startsWith('certification_source:openai'),
          ),
          isTrue,
          reason: report.violations.toString(),
        );
        expect(report.visibility['openai'], 'hidden');
      },
    );

    test('an unknown record status is rejected instead of assumed healthy', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          findings: <Sprint116CertificationFinding>[
            _finding('openai', recordStatus: 'PROBABLY_FINE'),
            _finding('gemini', step: '116.22'),
          ],
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(
        report.violations.any((v) => v.startsWith('record_status:openai')),
        isTrue,
        reason: report.violations.toString(),
      );
    });

    test(
      'an unknown connector verdict is rejected instead of assumed passing',
      () {
        final report = Sprint116BetaAcceptanceGate().evaluateWith(
          _healthyInput(
            findings: <Sprint116CertificationFinding>[
              _finding('openai', connectorVerdict: 'SEEMS_FINE'),
              _finding('gemini', step: '116.22'),
            ],
          ),
        );
        expect(report.state, Sprint116BetaAcceptanceStatus.fail);
        expect(
          report.violations.any(
            (v) => v.startsWith('connector_verdict:openai'),
          ),
          isTrue,
          reason: report.violations.toString(),
        );
      },
    );

    test(
      'a BLOCKED verdict hides the provider and it never joins the subset',
      () {
        final report = Sprint116BetaAcceptanceGate().evaluateWith(
          _healthyInput(
            findings: <Sprint116CertificationFinding>[
              _finding('openai', connectorVerdict: 'BLOCKED'),
            ],
          ),
        );
        expect(report.visibility['openai'], 'hidden');
        expect(report.certifiedSubset, isEmpty);
        expect(report.blockedConnectors, contains('openai'));
        expect(report.missingEvidence, contains('certified_subset'));
        expect(report.state, Sprint116BetaAcceptanceStatus.blocked);
      },
    );

    test('a LIMITED verdict keeps the provider visible only as limited', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          findings: <Sprint116CertificationFinding>[
            _finding('openai'),
            _finding('gemini', connectorVerdict: 'LIMITED'),
          ],
        ),
      );
      expect(report.visibility['gemini'], 'visible_limited');
      expect(report.limitedConnectors, <String>['gemini']);
      expect(report.certifiedSubset, <String>['openai']);
      expect(report.state, Sprint116BetaAcceptanceStatus.pass);
    });

    test('an expired certification is treated as not passed', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          findings: <Sprint116CertificationFinding>[
            _finding('openai', recordStatus: 'EXPIRED'),
            _finding('gemini'),
          ],
        ),
      );
      expect(report.visibility['openai'], 'hidden');
      expect(report.blockedConnectors, contains('openai'));
      expect(report.certifiedSubset, <String>['gemini']);
    });

    test(
      'a provider without any certification record is hidden, not guessed',
      () {
        final report = Sprint116BetaAcceptanceGate().evaluateWith(
          _healthyInput(),
        );
        expect(report.visibility['saweria'], 'hidden');
        expect(report.blockedConnectors, contains('saweria'));
        expect(report.violations, isEmpty);
        expect(report.certifiedSubset, <String>['openai']);
      },
    );

    test(
      'an empty certified subset blocks the acceptance instead of passing it',
      () {
        final report = Sprint116BetaAcceptanceGate().evaluateWith(
          _healthyInput(findings: const <Sprint116CertificationFinding>[]),
        );
        expect(report.missingEvidence, contains('certification_registry'));
        expect(report.missingEvidence, contains('certified_subset'));
        expect(report.state, Sprint116BetaAcceptanceStatus.blocked);
      },
    );
  });

  group('116.51 quality gates', () {
    test('a required gate step missing from the ledger fails the gate', () {
      final gates = _ledger(
        Sprint116BetaAcceptanceContract.requiredGateSteps,
      ).where((g) => g.step != '116.45').toList();
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(ledgerGates: gates),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(report.violations, contains('quality_gate:116.45'));
    });

    test('a gate step still PENDING in the ledger fails the gate', () {
      final gates = _ledger(Sprint116BetaAcceptanceContract.requiredGateSteps);
      final replaced = <Sprint116LedgerGateStatus>[
        for (final gate in gates)
          gate.step == '116.50'
              ? Sprint116LedgerGateStatus(step: gate.step, status: 'PENDING')
              : gate,
      ];
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(ledgerGates: replaced),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(report.violations, contains('quality_gate:116.50'));
    });

    test('a gate manifest that never landed fails the gate', () {
      final manifests = _manifests(
        Sprint116BetaAcceptanceContract.requiredGateSteps,
      )..remove('116.47');
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(gateManifests: manifests),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(report.violations, contains('gate_manifest:116.47'));
    });

    test('a gate manifest pointing at another step fails the gate', () {
      final manifests = _manifests(
        Sprint116BetaAcceptanceContract.requiredGateSteps,
      )..['116.46'] = '116.45';
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(gateManifests: manifests),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(report.violations, contains('gate_manifest_step:116.46'));
    });

    test('with no gate evidence at all the quality area blocks', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          ledgerGates: const <Sprint116LedgerGateStatus>[],
          gateManifests: const <String, String?>{},
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.blocked);
      expect(report.missingEvidence, contains('quality_gates'));
    });
  });

  group('116.51 beta plan', () {
    test('an absent beta plan blocks the beta_plan area', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(omitCoveragePlan: true),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.blocked);
      expect(report.missingEvidence, contains('beta_plan'));
    });

    test('a beta plan without consent records blocks the beta_plan area', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          coveragePlan: _coveragePlan(
            consents: const <Sprint116BetaConsentEntry>[],
          ),
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.blocked);
      expect(report.missingEvidence, contains('beta_plan'));
    });

    test('coverage of a provider outside the registry is rejected', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          coveragePlan: _coveragePlan(
            coverage: <Sprint116BetaCoverageEntry>[
              const Sprint116BetaCoverageEntry(
                providerId: 'not_in_registry',
                connectorId: 'conn_openai',
                stage: 'committed',
                consentRef: 'consent_openai',
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(
        report.violations,
        contains('unknown_coverage_provider:not_in_registry'),
      );
    });

    test('an unknown coverage stage is rejected', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          coveragePlan: _coveragePlan(
            coverage: <Sprint116BetaCoverageEntry>[
              const Sprint116BetaCoverageEntry(
                providerId: 'openai',
                connectorId: 'conn_openai',
                stage: 'whenever',
                consentRef: 'consent_openai',
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(
        report.violations.any((v) => v.startsWith('coverage_stage:')),
        isTrue,
      );
    });

    test('coverage without a resolvable consent reference is rejected', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          coveragePlan: _coveragePlan(
            coverage: <Sprint116BetaCoverageEntry>[
              const Sprint116BetaCoverageEntry(
                providerId: 'openai',
                connectorId: 'conn_openai',
                stage: 'committed',
                consentRef: 'consent_missing',
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(report.violations, contains('consent_ref:consent_missing'));
    });

    test('a consent pointing at a cohort nobody selected is rejected', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          coveragePlan: _coveragePlan(
            consents: <Sprint116BetaConsentEntry>[
              const Sprint116BetaConsentEntry(
                consentId: 'consent_openai',
                cohortId: 'cohort_ghost',
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(report.violations, contains('consent_cohort:consent_openai'));
    });

    test('coverage of a provider that has not passed is rejected', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          findings: <Sprint116CertificationFinding>[
            _finding('openai', connectorVerdict: 'BLOCKED'),
            _finding('gemini', step: '116.22'),
          ],
          coveragePlan: _coveragePlan(),
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(report.violations, contains('beta_plan_blocked:openai'));
    });

    test('a stage exposing a connector of a hidden provider is rejected', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          rolloutPlan: _rolloutPlan(
            stages: <Sprint116BetaStage>[
              const Sprint116BetaStage(
                stageId: 'stage_internal',
                exposedConnectors: <String>['conn_saweria'],
              ),
            ],
            killSwitches: <Sprint116BetaKillSwitch>[
              const Sprint116BetaKillSwitch(
                killId: 'kill_saweria',
                providerId: 'saweria',
                connectorId: 'conn_saweria',
                stages: <String>['stage_internal'],
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(
        report.violations,
        contains('exposed_blocked:stage_internal:conn_saweria'),
      );
    });

    test('a stage exposing an unknown connector is rejected', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          rolloutPlan: _rolloutPlan(
            stages: <Sprint116BetaStage>[
              const Sprint116BetaStage(
                stageId: 'stage_internal',
                exposedConnectors: <String>['openai'],
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(
        report.violations,
        contains('exposed_unknown_connector:stage_internal:openai'),
      );
    });

    test('a beta flag that defaults ON has no rollback left', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          rolloutPlan: _rolloutPlan(
            flags: <Sprint116BetaFlag>[
              const Sprint116BetaFlag(
                flagKey: 'beta.connectors.enabled',
                defaultState: 'ON',
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(
        report.violations,
        contains('flag_default:beta.connectors.enabled'),
      );
    });

    test('an unknown flag state is rejected', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          rolloutPlan: _rolloutPlan(
            flags: <Sprint116BetaFlag>[
              const Sprint116BetaFlag(
                flagKey: 'beta.connectors.enabled',
                defaultState: 'MAYBE',
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(
        report.violations,
        contains('flag_default:beta.connectors.enabled'),
      );
    });
  });

  group('116.51 rollback readiness', () {
    test('an absent rollout plan blocks the rollback_readiness area', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(omitRolloutPlan: true),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.blocked);
      expect(report.missingEvidence, contains('rollback_readiness'));
    });

    test(
      'a rollout plan without rollback records blocks the readiness area',
      () {
        final report = Sprint116BetaAcceptanceGate().evaluateWith(
          _healthyInput(
            rolloutPlan: _rolloutPlan(
              rollbacks: const <Sprint116BetaRollback>[],
            ),
          ),
        );
        expect(report.state, Sprint116BetaAcceptanceStatus.blocked);
        expect(report.missingEvidence, contains('rollback_readiness'));
      },
    );

    test('a stage without a stop condition is not ready', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          rolloutPlan: _rolloutPlan(stopStageIds: const <String>[]),
        ),
      );
      expect(report.violations, contains('stage_stop_coverage:stage_internal'));
      expect(report.rollbackReady, isFalse);
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
    });

    test('a stage without a rollback path is not ready', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          rolloutPlan: _rolloutPlan(rollbacks: const <Sprint116BetaRollback>[]),
        ),
      );
      expect(report.missingEvidence, contains('rollback_readiness'));
      expect(report.rollbackReady, isFalse);
    });

    test('a rollback that touches local project data is forbidden', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          rolloutPlan: _rolloutPlan(
            rollbacks: <Sprint116BetaRollback>[
              const Sprint116BetaRollback(
                rollbackId: 'rb_internal',
                targetScope: 'stage',
                targetId: 'stage_internal',
                touchesLocalData: true,
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint116BetaAcceptanceStatus.fail);
      expect(report.violations, contains('rollback_local_data:rb_internal'));
      expect(report.rollbackReady, isFalse);
    });

    test(
      'an exposed connector without a kill switch covering its stage fails',
      () {
        final report = Sprint116BetaAcceptanceGate().evaluateWith(
          _healthyInput(
            rolloutPlan: _rolloutPlan(
              killSwitches: const <Sprint116BetaKillSwitch>[],
            ),
          ),
        );
        expect(
          report.violations,
          contains('kill_switch_coverage:stage_internal:conn_openai'),
        );
        expect(report.rollbackReady, isFalse);
      },
    );

    test('a kill switch list that never loaded blocks the readiness area', () {
      final report = Sprint116BetaAcceptanceGate().evaluateWith(
        _healthyInput(
          rolloutPlan: _rolloutPlan(
            killSwitches: const <Sprint116BetaKillSwitch>[],
          ),
        ),
      );
      expect(report.missingEvidence, contains('rollback_readiness'));
    });
  });
}
