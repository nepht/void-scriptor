import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_apple_identity_certification.dart';

void main() {
  group('116.11 Apple Identity Certification', () {
    test('requires the six Apple identity certification fields', () {
      expect(Sprint116AppleIdentityContract.requiredFields, <String>[
        'provider_id',
        'identity_flow',
        'private_relay_handling',
        'token_lifecycle',
        'revoke',
        'platform_constraints',
      ]);
    });

    test('synthetic local manifest passes without live Apple claims', () {
      final report = Sprint116AppleIdentityCertification().evaluate([
        Sprint116AppleIdentityRecord(
          providerId: 'apple',
          identityFlow: 'synthetic identity flow fixture',
          privateRelayHandling: 'synthetic private relay fixture',
          tokenLifecycle: 'synthetic lifecycle fixture',
          revoke: 'synthetic revoke fixture',
          platformConstraints: 'synthetic platform fixture',
        ),
      ]);
      expect(report.state, Sprint116AppleIdentityState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing identity controls fail closed', () {
      final report = Sprint116AppleIdentityCertification().evaluate([
        Sprint116AppleIdentityRecord(
          providerId: 'apple',
          identityFlow: '',
          privateRelayHandling: '',
          tokenLifecycle: '',
          revoke: '',
          platformConstraints: '',
        ),
      ]);
      expect(report.state, Sprint116AppleIdentityState.fail);
      expect(report.invalidRecords, contains('identity_flow:apple'));
      expect(report.invalidRecords, contains('private_relay_handling:apple'));
      expect(report.invalidRecords, contains('token_lifecycle:apple'));
      expect(report.invalidRecords, contains('revoke:apple'));
      expect(report.invalidRecords, contains('platform_constraints:apple'));
    });

    test(
      'manifest is local-only and does not claim certified Apple access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116AppleIdentityContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.11');
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
