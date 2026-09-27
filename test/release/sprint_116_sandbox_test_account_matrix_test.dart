import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_sandbox_test_account_matrix.dart';

void main() {
  group('116.5 Sandbox & Test Account Matrix', () {
    test('declares the canonical fields and external boundary', () {
      expect(Sprint116SandboxMatrixContract.canonicalStep, '116.5');
      expect(Sprint116SandboxMatrixContract.requiredFields, <String>[
        'provider_id',
        'environment',
        'account_owner',
        'region',
        'test_data',
        'cleanup',
        'limitations',
      ]);
      expect(Sprint116SandboxMatrixContract.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('manifest binds the matrix without claiming live accounts', () {
      final manifest =
          jsonDecode(
                File(
                  Sprint116SandboxMatrixContract.manifestPath,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '116.5');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(
        manifest['required_fields'],
        Sprint116SandboxMatrixContract.requiredFields,
      );
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['records'], isNotEmpty);
    });

    test('empty records block rather than fabricate test-account coverage', () {
      final report = Sprint116SandboxTestAccountMatrix().evaluate(
        const <Sprint116SandboxMatrixRecord>[],
      );
      expect(report.state, Sprint116SandboxMatrixState.blocked);
      expect(report.missingFields, contains('matrix_records'));
    });

    test('live manifest passes only with explicit limitations', () {
      final report = Sprint116SandboxTestAccountMatrix().evaluate();
      expect(report.state, Sprint116SandboxMatrixState.pass);
      expect(report.missingFields, isEmpty);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing required matrix data is reported by provider and field', () {
      final report = Sprint116SandboxTestAccountMatrix().evaluate(
        <Sprint116SandboxMatrixRecord>[
          Sprint116SandboxMatrixRecord(
            providerId: 'fixture_provider',
            environment: 'sandbox',
            accountOwner: 'test-owner',
            region: '',
            testData: const <String>[],
            cleanup: const <String>[],
            limitations: const <String>['fixture only'],
          ),
        ],
      );
      expect(report.state, Sprint116SandboxMatrixState.fail);
      expect(report.missingFields, contains('region:fixture_provider'));
      expect(report.missingFields, contains('test_data:fixture_provider'));
      expect(report.missingFields, contains('cleanup:fixture_provider'));
    });

    test('record round-trips all seven fields', () {
      final record = Sprint116SandboxMatrixRecord(
        providerId: 'fixture_provider',
        environment: 'sandbox',
        accountOwner: 'test-owner',
        region: 'GLOBAL',
        testData: const <String>['synthetic only'],
        cleanup: const <String>['delete fixture'],
        limitations: const <String>['no live credentials'],
      );
      expect(record.toJson(), <String, Object?>{
        'provider_id': 'fixture_provider',
        'environment': 'sandbox',
        'account_owner': 'test-owner',
        'region': 'GLOBAL',
        'test_data': <String>['synthetic only'],
        'cleanup': <String>['delete fixture'],
        'limitations': <String>['no live credentials'],
      });
    });
  });
}
