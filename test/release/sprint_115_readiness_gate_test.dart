import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_115_readiness_gate_v114.dart';

void main() {
  group('114.43 Sprint 115 Readiness Gate', () {
    final completeEvidence = Sprint115ReadinessEvidence(
      stableReleaseHealthGate: 'VERIFIED-LOCAL',
      patchDecision: 'NO_PATCH',
      remainingIncidents: const <String>[],
      capacity: 'VERIFIED-LOCAL',
      accountCloudCenterScope: 'CORRECTIVE_SCOPE_APPROVED',
      securityPrivacyConstraints: 'VERIFIED-LOCAL',
      releaseState: 'DELAYED',
    );

    test('declares the six canonical readiness evidence fields', () {
      expect(Sprint115ReadinessGateContract.canonicalStep, '114.43');
      expect(Sprint115ReadinessGateContract.requiredEvidence, <String>[
        'stable_release_health_gate',
        'patch_decision',
        'remaining_incidents',
        'capacity',
        'account_cloud_center_scope',
        'security_privacy_constraints',
      ]);
      expect(
        Sprint115ReadinessGateContract.manifestPath,
        endsWith('sprint_115_readiness_gate.json'),
      );
    });

    test('absent readiness evidence is blocked with every missing field', () {
      final report = Sprint115ReadinessGate().evaluate(null);

      expect(report.state, Sprint115ReadinessState.blocked);
      expect(
        report.missingEvidence,
        Sprint115ReadinessGateContract.requiredEvidence,
      );
      expect(report.violations, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('delayed path may be ready only for approved corrective scope', () {
      final report = Sprint115ReadinessGate().evaluate(completeEvidence);

      expect(report.state, Sprint115ReadinessState.pass);
      expect(report.verdict, 'CORRECTIVE_SCOPE_APPROVED');
      expect(report.missingEvidence, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('unapproved Account & Cloud Center scope fails closed', () {
      final report = Sprint115ReadinessGate().evaluate(
        completeEvidence.copyWith(
          accountCloudCenterScope: 'FEATURE_SCOPE_ONLY',
        ),
      );

      expect(report.state, Sprint115ReadinessState.fail);
      expect(
        report.violations,
        contains('account_cloud_center_scope_unapproved'),
      );
    });

    test('remaining incidents block readiness even on the delayed path', () {
      final report = Sprint115ReadinessGate().evaluate(
        completeEvidence.copyWith(
          remainingIncidents: const <String>['INC-114-01'],
        ),
      );

      expect(report.state, Sprint115ReadinessState.blocked);
      expect(report.missingEvidence, contains('remaining_incidents'));
    });

    test('missing local gates block and do not become local passes', () {
      final report = Sprint115ReadinessGate().evaluate(
        completeEvidence.copyWith(
          stableReleaseHealthGate: 'DEFERRED-EXTERNAL',
          patchDecision: 'UNKNOWN',
          capacity: ' ',
          securityPrivacyConstraints: 'DEFERRED-EXTERNAL',
        ),
      );

      expect(report.state, Sprint115ReadinessState.blocked);
      expect(
        report.missingEvidence,
        containsAll(<String>[
          'stable_release_health_gate',
          'capacity',
          'security_privacy_constraints',
        ]),
      );
      expect(report.violations, contains('unsupported_patch_decision_UNKNOWN'));
    });

    test(
      'released path requires local health and zero remaining incidents',
      () {
        final report = Sprint115ReadinessGate().evaluate(
          completeEvidence.copyWith(
            releaseState: 'RELEASED',
            accountCloudCenterScope: 'FULL_SCOPE_APPROVED',
          ),
        );

        expect(report.state, Sprint115ReadinessState.pass);
        expect(report.verdict, 'STABLE_RELEASE_READY');
      },
    );

    test(
      'a stable release with unresolved incident or failed local gate cannot advance',
      () {
        final unresolved = Sprint115ReadinessGate().evaluate(
          completeEvidence.copyWith(
            releaseState: 'RELEASED',
            accountCloudCenterScope: 'FULL_SCOPE_APPROVED',
            remainingIncidents: const <String>['INC-114-02'],
          ),
        );
        final failedSecurity = Sprint115ReadinessGate().evaluate(
          completeEvidence.copyWith(
            releaseState: 'RELEASED',
            accountCloudCenterScope: 'FULL_SCOPE_APPROVED',
            securityPrivacyConstraints: 'FAILED',
          ),
        );

        expect(unresolved.state, Sprint115ReadinessState.blocked);
        expect(unresolved.missingEvidence, contains('remaining_incidents'));
        expect(failedSecurity.state, Sprint115ReadinessState.fail);
        expect(
          failedSecurity.violations,
          contains('security_privacy_constraints_not_verified'),
        );
      },
    );

    test('unknown release state and scope are rejected', () {
      final report = Sprint115ReadinessGate().evaluate(
        completeEvidence.copyWith(
          releaseState: 'PUBLISHED_UNKNOWN',
          accountCloudCenterScope: 'UNAPPROVED',
        ),
      );

      expect(report.state, Sprint115ReadinessState.fail);
      expect(
        report.violations,
        containsAll(<String>[
          'unsupported_release_state_PUBLISHED_UNKNOWN',
          'account_cloud_center_scope_unapproved',
        ]),
      );
    });

    test('manifest records corrective readiness and external boundary', () {
      final file = File(Sprint115ReadinessGateContract.manifestPath);
      expect(file.existsSync(), isTrue);
      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(manifest['canonical_step'], '114.43');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['release_state'], 'DELAYED');
      expect(
        manifest['required_evidence'],
        Sprint115ReadinessGateContract.requiredEvidence,
      );
      expect(manifest['verdict'], 'CORRECTIVE_SCOPE_APPROVED');
      expect(manifest['remaining_incidents'], isEmpty);
      expect(
        manifest['account_cloud_center_scope'],
        'CORRECTIVE_SCOPE_APPROVED',
      );
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['limitations'], isNotEmpty);
    });
  });
}
