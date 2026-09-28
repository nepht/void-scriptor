import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_mega_certification.dart';

void main() {
  group('116.18 MEGA Certification', () {
    test('requires the seven MEGA certification fields', () {
      expect(Sprint116MegaContract.requiredFields, <String>[
        'provider_id',
        'integration_path',
        'authentication',
        'transfer',
        'quota',
        'security_model',
        'limitations',
      ]);
    });

    test('synthetic local manifest passes without live MEGA claims', () {
      final report = Sprint116MegaCertification().evaluate([
        Sprint116MegaRecord(
          providerId: 'mega',
          integrationPath: 'synthetic integration fixture',
          authentication: 'synthetic authentication fixture',
          transfer: 'synthetic transfer fixture',
          quota: 'synthetic quota fixture',
          securityModel: 'synthetic security fixture',
          limitations: 'synthetic limitations fixture',
        ),
      ]);
      expect(report.state, Sprint116MegaState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing MEGA controls fail closed', () {
      final report = Sprint116MegaCertification().evaluate([
        Sprint116MegaRecord(
          providerId: 'mega',
          integrationPath: '',
          authentication: '',
          transfer: '',
          quota: '',
          securityModel: '',
          limitations: '',
        ),
      ]);
      expect(report.state, Sprint116MegaState.fail);
      expect(report.invalidRecords, contains('integration_path:mega'));
      expect(report.invalidRecords, contains('authentication:mega'));
      expect(report.invalidRecords, contains('transfer:mega'));
      expect(report.invalidRecords, contains('quota:mega'));
      expect(report.invalidRecords, contains('security_model:mega'));
      expect(report.invalidRecords, contains('limitations:mega'));
    });

    test('manifest is local-only and does not claim certified MEGA access', () {
      final manifest =
          jsonDecode(
                File(Sprint116MegaContract.manifestPath).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '116.18');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['records'], isNotEmpty);
      for (final record in manifest['records'] as List<dynamic>) {
        expect((record as Map<String, dynamic>)['status'], 'UNVERIFIED');
      }
    });
  });
}
