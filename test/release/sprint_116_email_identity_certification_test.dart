import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_email_identity_certification.dart';

void main() {
  group('116.8 Email Identity Certification', () {
    test('requires the seven email identity certification fields', () {
      expect(Sprint116EmailIdentityContract.requiredFields, <String>[
        'provider_id',
        'registration',
        'verification',
        'login',
        'recovery',
        'rate_limiting',
        'account_linking',
      ]);
    });

    test('synthetic local manifest passes without live identity claims', () {
      final report = Sprint116EmailIdentityCertification().evaluate([
        Sprint116EmailIdentityRecord(
          providerId: 'email',
          registration: 'synthetic registration fixture',
          verification: 'synthetic verification fixture',
          login: 'synthetic login fixture',
          recovery: 'synthetic recovery fixture',
          rateLimiting: 'synthetic bounded-rate fixture',
          accountLinking: 'synthetic linking fixture',
        ),
      ]);
      expect(report.state, Sprint116EmailIdentityState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing identity controls fail closed', () {
      final report = Sprint116EmailIdentityCertification().evaluate([
        Sprint116EmailIdentityRecord(
          providerId: 'email',
          registration: '',
          verification: '',
          login: '',
          recovery: '',
          rateLimiting: '',
          accountLinking: '',
        ),
      ]);
      expect(report.state, Sprint116EmailIdentityState.fail);
      expect(report.invalidRecords, contains('registration:email'));
      expect(report.invalidRecords, contains('verification:email'));
      expect(report.invalidRecords, contains('login:email'));
      expect(report.invalidRecords, contains('recovery:email'));
      expect(report.invalidRecords, contains('rate_limiting:email'));
      expect(report.invalidRecords, contains('account_linking:email'));
    });

    test(
      'manifest is local-only and does not claim certified email access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116EmailIdentityContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.8');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['records'], isNotEmpty);
        for (final record in manifest['records'] as List<dynamic>) {
          expect((record as Map<String, dynamic>)['status'], 'UNVERIFIED');
        }
      },
    );
  });
}
