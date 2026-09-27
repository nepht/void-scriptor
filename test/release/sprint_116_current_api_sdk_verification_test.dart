import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_current_api_sdk_verification.dart';

void main() {
  group('116.4 Current API & SDK Verification', () {
    test('declares fail-closed verification outputs', () {
      expect(Sprint116ApiSdkVerificationContract.canonicalStep, '116.4');
      expect(Sprint116ApiSdkVerificationContract.requiredOutputs, <String>[
        'primary_sources',
        'api_versions',
        'sdk_versions',
        'deprecations',
        'auth_requirements',
        'quota_capabilities',
        'verification_date',
      ]);
      expect(
        Sprint116ApiSdkVerificationContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('manifest binds the canonical local evidence boundary', () {
      final manifest =
          jsonDecode(
                File(
                  Sprint116ApiSdkVerificationContract.manifestPath,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '116.4');
      expect(
        manifest['required_outputs'],
        Sprint116ApiSdkVerificationContract.requiredOutputs,
      );
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
    });

    test(
      'empty verification records block rather than fabricate current support',
      () {
        final report = Sprint116ApiSdkVerification().evaluate(
          const <Sprint116ApiSdkVerificationRecord>[],
        );
        expect(report.state, Sprint116ApiSdkVerificationState.blocked);
        expect(report.missingOutputs, contains('verification_records'));
      },
    );

    test('complete record passes with explicit limitations', () {
      final report = Sprint116ApiSdkVerification().evaluate(
        <Sprint116ApiSdkVerificationRecord>[
          Sprint116ApiSdkVerificationRecord(
            providerId: 'synthetic_provider',
            primarySources: const <String>['https://example.invalid/primary'],
            apiVersion: 'v1',
            sdkVersion: 'sdk-1.0.0',
            deprecations: const <String>['none observed in reviewed source'],
            authRequirements: const <String>[
              'explicit user authorization required',
            ],
            quotaCapabilities: const <String>[
              'provider documentation required',
            ],
            verificationDate: '2026-09-27',
            limitations: const <String>[
              'synthetic record; no live provider request',
            ],
          ),
        ],
      );

      expect(report.state, Sprint116ApiSdkVerificationState.pass);
      expect(report.missingOutputs, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });
  });
}
