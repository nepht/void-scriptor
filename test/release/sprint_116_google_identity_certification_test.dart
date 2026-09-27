import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_google_identity_certification.dart';

void main() {
  group('116.9 Google Identity Certification', () {
    test('requires the seven Google identity certification fields', () {
      expect(Sprint116GoogleIdentityContract.requiredFields, <String>[
        'provider_id',
        'oauth',
        'scopes',
        'callback',
        'account_linking',
        'token_lifecycle',
        'revoke',
        'errors',
      ]);
    });

    test('synthetic local manifest passes without live OAuth claims', () {
      final report = Sprint116GoogleIdentityCertification().evaluate([
        Sprint116GoogleIdentityRecord(
          providerId: 'google',
          oauth: 'synthetic OAuth fixture',
          scopes: 'synthetic minimum-scope fixture',
          callback: 'synthetic callback fixture',
          accountLinking: 'synthetic linking fixture',
          tokenLifecycle: 'synthetic lifecycle fixture',
          revoke: 'synthetic revoke fixture',
          errors: 'synthetic error fixture',
        ),
      ]);
      expect(report.state, Sprint116GoogleIdentityState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing identity controls fail closed', () {
      final report = Sprint116GoogleIdentityCertification().evaluate([
        Sprint116GoogleIdentityRecord(
          providerId: 'google',
          oauth: '',
          scopes: '',
          callback: '',
          accountLinking: '',
          tokenLifecycle: '',
          revoke: '',
          errors: '',
        ),
      ]);
      expect(report.state, Sprint116GoogleIdentityState.fail);
      expect(report.invalidRecords, contains('oauth:google'));
      expect(report.invalidRecords, contains('scopes:google'));
      expect(report.invalidRecords, contains('callback:google'));
      expect(report.invalidRecords, contains('account_linking:google'));
      expect(report.invalidRecords, contains('token_lifecycle:google'));
      expect(report.invalidRecords, contains('revoke:google'));
      expect(report.invalidRecords, contains('errors:google'));
    });

    test(
      'manifest is local-only and does not claim certified Google access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116GoogleIdentityContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.9');
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
