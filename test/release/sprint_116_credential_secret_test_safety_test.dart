import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_credential_secret_test_safety.dart';

void main() {
  group('116.6 Credential & Secret Test Safety', () {
    test('declares the fail-closed acceptance contract', () {
      expect(Sprint116CredentialSafetyContract.requiredControls, <String>[
        'test_only_credentials',
        'least_privilege',
        'rotation',
        'redaction',
        'no_artifact_leak',
        'revocation',
      ]);
      expect(
        Sprint116CredentialSafetyContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('empty evidence is blocked rather than inferred as safe', () {
      final report = Sprint116CredentialSecretTestSafety().evaluate(const []);
      expect(report.state, Sprint116CredentialSafetyState.blocked);
      expect(report.missingControls, contains('records'));
    });

    test('a synthetic fixture passes all six controls', () {
      final report = Sprint116CredentialSecretTestSafety().evaluate([
        Sprint116CredentialSafetyRecord(
          providerId: 'example_provider',
          credentialClass: 'synthetic_fixture',
          environment: 'sandbox',
          privilegeScope: 'minimum test scope',
          rotationPlan: 'rotate after every run',
          redactionPolicy: 'redact before logs and reports',
          artifactScan: 'scan build and evidence outputs',
          revocationPlan: 'revoke fixture at teardown',
          limitations: const [
            'no live credentials',
            'provider-owned revocation deferred',
          ],
        ),
      ]);
      expect(report.state, Sprint116CredentialSafetyState.pass);
      expect(report.missingControls, isEmpty);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing controls identify the provider and control', () {
      final report = Sprint116CredentialSecretTestSafety().evaluate([
        Sprint116CredentialSafetyRecord(
          providerId: 'fixture_provider',
          credentialClass: '',
          environment: 'sandbox',
          privilegeScope: '',
          rotationPlan: '',
          redactionPolicy: 'redact',
          artifactScan: '',
          revocationPlan: '',
          limitations: const ['synthetic only'],
        ),
      ]);
      expect(report.state, Sprint116CredentialSafetyState.fail);
      expect(
        report.missingControls,
        contains('test_only_credentials:fixture_provider'),
      );
      expect(
        report.missingControls,
        contains('least_privilege:fixture_provider'),
      );
      expect(report.missingControls, contains('rotation:fixture_provider'));
      expect(
        report.missingControls,
        contains('no_artifact_leak:fixture_provider'),
      );
      expect(report.missingControls, contains('revocation:fixture_provider'));
    });

    test('blank provider and absent limitations are invalid', () {
      final report = Sprint116CredentialSecretTestSafety().evaluate([
        Sprint116CredentialSafetyRecord(
          providerId: ' ',
          credentialClass: 'synthetic',
          environment: 'sandbox',
          privilegeScope: 'minimum',
          rotationPlan: 'rotate',
          redactionPolicy: 'redact',
          artifactScan: 'scan',
          revocationPlan: 'revoke',
          limitations: const [],
        ),
      ]);
      expect(report.state, Sprint116CredentialSafetyState.fail);
      expect(report.invalidRecords, contains('provider_id'));
      expect(report.invalidRecords, contains('limitations:<missing>'));
    });

    test('manifest is local-only and has no credential values', () {
      final manifest =
          jsonDecode(
                File(
                  Sprint116CredentialSafetyContract.manifestPath,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '116.6');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(
        manifest['required_controls'],
        Sprint116CredentialSafetyContract.requiredControls,
      );
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(jsonEncode(manifest), isNot(contains('sk-')));
      expect(jsonEncode(manifest), isNot(contains('AKIA')));
    });

    test(
      'record serialization carries policy evidence without secret material',
      () {
        final record = Sprint116CredentialSafetyRecord(
          providerId: 'fixture_provider',
          credentialClass: 'synthetic_fixture',
          environment: 'sandbox',
          privilegeScope: 'minimum',
          rotationPlan: 'rotate',
          redactionPolicy: 'redact',
          artifactScan: 'scan',
          revocationPlan: 'revoke',
          limitations: const ['no live credentials'],
        );
        expect(record.toJson(), <String, Object?>{
          'provider_id': 'fixture_provider',
          'credential_class': 'synthetic_fixture',
          'environment': 'sandbox',
          'privilege_scope': 'minimum',
          'rotation': 'rotate',
          'redaction': 'redact',
          'no_artifact_leak': 'scan',
          'revocation': 'revoke',
          'limitations': <String>['no live credentials'],
        });
      },
    );
  });
}
