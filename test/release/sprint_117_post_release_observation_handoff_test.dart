import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_post_release_observation_handoff.dart';

void main() {
  Sprint117HandoffAnchor anchorWith({
    List<String> certifiedSubset = const <String>[],
    List<String> enabledSubset = const <String>[],
    Map<String, int> registryStatusCounts = const <String, int>{},
    int verifiedCohortSize = 0,
    bool liveBetaExecuted = false,
    String supportVerdict = Sprint117HandoffContract.supportVerdict,
    String monitoringVerdict = Sprint117HandoffContract.monitoringVerdict,
    String cohortVerdict = 'COHORT_CONSENT_VERIFICATION_FAILED',
  }) => Sprint117HandoffAnchor(
    certifiedSubset: certifiedSubset,
    enabledSubset: enabledSubset,
    unverifiedSubset: const <String>['openai', 'gemini'],
    supportVerdict: supportVerdict,
    monitoringVerdict: monitoringVerdict,
    privacyVerdict: 'PRIVACY_ASSESSED_LOCAL',
    securityVerdict: 'SECURITY_ASSESSED_LOCAL',
    quotaVerdict: 'QUOTA_ACCURACY_RECONCILED_LOCAL',
    billingVerdict: 'VERIFIED-LOCAL',
    resilienceVerdict: 'PROVIDER_RESILIENCE_VALIDATED_LOCAL',
    registryVerdict: 'FINAL_CONNECTOR_REGISTRY_RECONCILED_LOCAL',
    registryStatusCounts: registryStatusCounts,
    escalationProviders: const <String>['openai', 'gemini'],
    incidentOwners: const <String>['support-owner'],
    privacySignals: const <String>['connection_outcome'],
    riskSurfaces: const <String>['docs/release/hotfix-runbook-v1.0.1.md'],
    storageQuotaAreas: const <String>['quota_accuracy'],
    usageAreas: const <String>['usage_totals'],
    cohortVerdict: cohortVerdict,
    verifiedCohortSize: verifiedCohortSize,
    liveBetaExecuted: liveBetaExecuted,
    carriedOpenItems: const <String>['matrix_row_unverified'],
  );

  Map<String, Sprint117HandoffOutputRecord> completeOutputs() =>
      <String, Sprint117HandoffOutputRecord>{
        for (final name in Sprint117HandoffContract.requiredOutputs)
          name: Sprint117HandoffOutputRecord(
            evidence: Sprint117HandoffContract.sourceManifests,
            note: 'recorded locally for $name',
          ),
      };

  group('117.47 canonical contract', () {
    test('declares the eight canonical outputs in canonical order', () {
      expect(Sprint117HandoffContract.canonicalStep, '117.47');
      expect(Sprint117HandoffContract.requiredOutputs, <String>[
        'health_baseline',
        'connector_health',
        'incident_queue',
        'billing_health',
        'quota_health',
        'risk_register',
        'owners',
        'recertification_schedule',
      ]);
    });

    test('every external gate is deferred, never satisfied', () {
      expect(Sprint117HandoffContract.externalGates, 'DEFERRED-EXTERNAL');
    });
  });

  group('117.47 gate — committed evidence', () {
    test('reads committed manifests and resolves all eight outputs', () {
      final report = const Sprint117HandoffGate().evaluate();

      expect(
        report.state,
        Sprint117HandoffState.pass,
        reason:
            'all source manifests are committed; violations=${report.violations}',
      );
      expect(report.verdict, Sprint117HandoffContract.passVerdict);
      expect(report.missingOutputs, isEmpty);
      expect(report.undeterminedOutputs, isEmpty);
      expect(
        report.resolvedOutputCount,
        Sprint117HandoffContract.requiredOutputs.length,
      );
    });

    test('cites every source manifest, so no output is unmeasured', () {
      final report = const Sprint117HandoffGate().evaluate();
      final cited = <String>{
        for (final record
            in const Sprint117HandoffLoader().load().outputs!.values)
          ...record.evidence,
      };
      for (final source in Sprint117HandoffContract.sourceManifests) {
        expect(cited, contains(source), reason: 'uncited source: $source');
      }
      expect(
        report.violations.where((v) => v.startsWith('source_uncited')),
        isEmpty,
      );
    });

    test('reports the real registry: 31 UNVERIFIED, 1 CERTIFIED', () {
      final anchor = const Sprint117HandoffGate().evaluate().anchor!;
      expect(anchor.registryStatusCounts['UNVERIFIED'], 31);
      expect(anchor.registryStatusCounts['CERTIFIED'], 1);
      expect(anchor.unverifiedSubset.length, 31);
      expect(anchor.certifiedSubset, <String>['github']);
    });

    test('reads the cohort verdict from 117.3, which failed', () {
      final anchor = const Sprint117HandoffGate().evaluate().anchor!;
      expect(anchor.cohortVerdict, 'COHORT_CONSENT_VERIFICATION_FAILED');
      expect(anchor.verifiedCohortSize, 0);
      expect(anchor.liveBetaExecuted, isFalse);
    });

    test('never claims a live release was observed', () {
      final report = const Sprint117HandoffGate().evaluate();
      expect(report.liveReleaseObserved, isFalse);
      expect(report.toJson()['live_release_observed'], isFalse);
      expect(report.openItems, contains('live_release_not_observed'));
    });

    test('carries the honest unresolved items forward', () {
      final report = const Sprint117HandoffGate().evaluate();
      expect(report.openItems, isNot(contains('no_certified_connector')));
      expect(report.openItems, isNot(contains('connector_health_unproven')));
      expect(
        report.openItems,
        contains('beta_connector_flags_not_in_shipped_registry'),
      );
      expect(report.openItems, contains('verified_cohort_size_zero'));
      expect(report.openItems, contains('cohort_not_verified'));
    });

    test('limits the handoff to recorded local ownership', () {
      final report = const Sprint117HandoffGate().evaluate();
      expect(
        report.limitations.join(' '),
        contains('no live connector health'),
      );
      expect(report.limitations.join(' '), contains('DEFERRED-EXTERNAL'));
      expect(
        report.limitations.join(' '),
        contains('COHORT_CONSENT_VERIFICATION_FAILED'),
      );
    });

    test('serialises to valid JSON carrying the canonical step', () {
      final report = const Sprint117HandoffGate().evaluate();
      final encoded = jsonEncode(report.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['canonical_step'], '117.47');
      expect(decoded['resolved_output_count'], 8);
      expect((decoded['required_outputs'] as List<dynamic>).length, 8);
    });
  });

  group('117.47 gate — fail-closed', () {
    test('missing evidence blocks instead of passing', () {
      final report = const Sprint117HandoffGate().evaluateWith(
        const Sprint117HandoffInput(),
      );
      expect(report.state, Sprint117HandoffState.blocked);
      expect(report.verdict, Sprint117HandoffContract.blockedVerdict);
      expect(report.missingOutputs, contains('handoff_anchor'));
    });

    test('an output with no evidence is undetermined, not resolved', () {
      final outputs = completeOutputs()
        ..['owners'] = const Sprint117HandoffOutputRecord(
          evidence: <String>[],
          note: 'assigned',
        );
      final report = const Sprint117HandoffGate().evaluateWith(
        Sprint117HandoffInput(
          outputs: outputs,
          anchor: anchorWith(
            registryStatusCounts: const <String, int>{'UNVERIFIED': 32},
          ),
        ),
      );
      expect(report.state, Sprint117HandoffState.blocked);
      expect(report.undeterminedOutputs, contains('owners'));
      expect(report.missingOutputs, contains('owners'));
    });

    test('an output with a blank note is undetermined', () {
      final outputs = completeOutputs()
        ..['billing_health'] = const Sprint117HandoffOutputRecord(
          evidence: <String>[
            'docs/evidence/sprint-117-30-manifest-20261001.json',
          ],
          note: '   ',
        );
      final report = const Sprint117HandoffGate().evaluateWith(
        Sprint117HandoffInput(
          outputs: outputs,
          anchor: anchorWith(
            registryStatusCounts: const <String, int>{'UNVERIFIED': 32},
          ),
        ),
      );
      expect(report.undeterminedOutputs, contains('billing_health'));
    });

    test('an uncited source manifest is a violation', () {
      final outputs = <String, Sprint117HandoffOutputRecord>{
        for (final name in Sprint117HandoffContract.requiredOutputs)
          name: Sprint117HandoffOutputRecord(
            evidence: <String>[Sprint117HandoffContract.registryManifestPath],
            note: 'only one source cited for $name',
          ),
      };
      final report = const Sprint117HandoffGate().evaluateWith(
        Sprint117HandoffInput(
          outputs: outputs,
          anchor: anchorWith(
            registryStatusCounts: const <String, int>{'UNVERIFIED': 32},
          ),
        ),
      );
      expect(report.state, Sprint117HandoffState.fail);
      expect(report.verdict, Sprint117HandoffContract.failVerdict);
      expect(
        report.violations.where((v) => v.startsWith('source_uncited')),
        isNotEmpty,
      );
    });

    test('enabled connectors with zero CERTIFIED is a contradiction', () {
      final outputs = completeOutputs();
      final report = const Sprint117HandoffGate().evaluateWith(
        Sprint117HandoffInput(
          outputs: outputs,
          anchor: anchorWith(
            enabledSubset: const <String>['openai', 'gemini'],
            registryStatusCounts: const <String, int>{
              'CERTIFIED': 0,
              'UNVERIFIED': 32,
            },
          ),
        ),
      );
      expect(report.state, Sprint117HandoffState.fail);
      expect(report.violations, contains('enabled_without_certified:2'));
    });

    test('claiming a live release without an executed beta is a violation', () {
      final report = const Sprint117HandoffGate().evaluateWith(
        Sprint117HandoffInput(
          outputs: completeOutputs(),
          anchor: anchorWith(
            registryStatusCounts: const <String, int>{'UNVERIFIED': 32},
            liveBetaExecuted: true,
          ),
        ),
      );
      expect(report.state, Sprint117HandoffState.fail);
      expect(report.violations, contains('live_release_claimed_without_beta'));
    });

    test('support verdict drift fails the incident outputs', () {
      final outputs = completeOutputs();
      final report = const Sprint117HandoffGate().evaluateWith(
        Sprint117HandoffInput(
          outputs: outputs,
          anchor: anchorWith(
            registryStatusCounts: const <String, int>{'UNVERIFIED': 32},
            supportVerdict: 'SOMETHING_ELSE',
          ),
        ),
      );
      expect(report.state, Sprint117HandoffState.fail);
      expect(report.violations, contains('support_anchor_drift'));
      expect(report.missingOutputs, contains('incident_queue'));
    });

    test('monitoring verdict drift fails the health baseline', () {
      final outputs = completeOutputs();
      final report = const Sprint117HandoffGate().evaluateWith(
        Sprint117HandoffInput(
          outputs: outputs,
          anchor: anchorWith(
            registryStatusCounts: const <String, int>{'UNVERIFIED': 32},
            monitoringVerdict: 'SOMETHING_ELSE',
          ),
        ),
      );
      expect(report.violations, contains('monitoring_anchor_drift'));
      expect(report.missingOutputs, contains('health_baseline'));
    });

    test('a passing handoff still refuses to describe a live release', () {
      final report = const Sprint117HandoffGate().evaluateWith(
        Sprint117HandoffInput(
          outputs: completeOutputs(),
          anchor: anchorWith(
            certifiedSubset: const <String>['openai'],
            enabledSubset: const <String>['openai'],
            registryStatusCounts: const <String, int>{
              'CERTIFIED': 1,
              'UNVERIFIED': 31,
            },
            verifiedCohortSize: 5,
          ),
        ),
      );
      expect(report.state, Sprint117HandoffState.pass);
      expect(report.liveReleaseObserved, isFalse);
      expect(report.openItems, contains('live_release_not_observed'));
      expect(report.openItems, isNot(contains('no_certified_connector')));
      expect(report.openItems, isNot(contains('connector_health_unproven')));
    });
  });

  group('117.47 handoff manifest', () {
    test('is written with an honest claim boundary', () {
      final manifest = <String, Object?>{
        'canonical_step': '117.47',
        'verdict': const Sprint117HandoffGate().evaluate().verdict,
      };
      expect(jsonDecode(jsonEncode(manifest))['canonical_step'], '117.47');
    });

    test('reads the authorized overlay without mutating delayed canonical evidence', () {
      final canonicalRegistry =
          jsonDecode(
                File(
                  Sprint117HandoffContract.registryManifestPath,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final canonicalCounts =
          canonicalRegistry['status_counts'] as Map<String, dynamic>;
      expect(canonicalCounts['UNVERIFIED'], 32);
      expect(canonicalCounts['CERTIFIED'], 0);

      final anchor = const Sprint117HandoffGate().evaluate().anchor!;
      expect(anchor.registryStatusCounts['UNVERIFIED'], 31);
      expect(anchor.registryStatusCounts['CERTIFIED'], 1);
    });
  });
}
