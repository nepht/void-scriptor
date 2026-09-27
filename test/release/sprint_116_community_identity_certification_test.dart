import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_community_identity_certification.dart';

void main() {
  group('116.13 Community Identity Certification', () {
    test('keeps Discord, X, and Facebook identity scopes separate', () {
      expect(Sprint116CommunityIdentityContract.requiredFields, <String>[
        'provider_id',
        'identity_flow',
        'minimum_scopes',
      ]);
      expect(Sprint116CommunityIdentityContract.providers, <String>[
        'discord',
        'x',
        'facebook',
      ]);
    });

    test('synthetic local records pass without live provider claims', () {
      final report = Sprint116CommunityIdentityCertification().evaluate([
        for (final provider in Sprint116CommunityIdentityContract.providers)
          Sprint116CommunityIdentityRecord(
            providerId: provider,
            identityFlow: 'synthetic identity flow fixture',
            minimumScopes: 'synthetic minimum identity scope fixture',
          ),
      ]);
      expect(report.state, Sprint116CommunityIdentityState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing identity controls fail closed per provider', () {
      final report = Sprint116CommunityIdentityCertification().evaluate([
        Sprint116CommunityIdentityRecord(
          providerId: 'discord',
          identityFlow: '',
          minimumScopes: '',
        ),
      ]);
      expect(report.state, Sprint116CommunityIdentityState.fail);
      expect(report.invalidRecords, contains('identity_flow:discord'));
      expect(report.invalidRecords, contains('minimum_scopes:discord'));
    });

    test(
      'manifest is local-only and keeps each community provider unverified',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116CommunityIdentityContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.13');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['records'], hasLength(3));
        expect(
          (manifest['records'] as List<dynamic>)
              .map((record) => (record as Map<String, dynamic>)['provider_id'])
              .toList(),
          <String>['discord', 'x', 'facebook'],
        );
        for (final record in manifest['records'] as List<dynamic>) {
          expect((record as Map<String, dynamic>)['status'], 'UNVERIFIED');
        }
      },
    );
  });
}
