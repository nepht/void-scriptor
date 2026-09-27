import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_github_identity_certification.dart';

void main() {
  group('116.12 GitHub Identity Certification', () {
    test(
      'requires identity-only scopes to remain separate from developer scopes',
      () {
        expect(Sprint116GithubIdentityContract.requiredFields, <String>[
          'provider_id',
          'identity_flow',
          'identity_scopes',
          'developer_scopes_separation',
          'token_lifecycle',
          'revoke',
          'errors',
        ]);
      },
    );

    test('synthetic local manifest passes without live GitHub claims', () {
      final report = Sprint116GithubIdentityCertification().evaluate([
        Sprint116GithubIdentityRecord(
          providerId: 'github',
          identityFlow: 'synthetic identity flow fixture',
          identityScopes: 'synthetic identity-only scope fixture',
          developerScopesSeparation:
              'synthetic developer scope separation fixture',
          tokenLifecycle: 'synthetic lifecycle fixture',
          revoke: 'synthetic revoke fixture',
          errors: 'synthetic error fixture',
        ),
      ]);
      expect(report.state, Sprint116GithubIdentityState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing identity controls fail closed', () {
      final report = Sprint116GithubIdentityCertification().evaluate([
        Sprint116GithubIdentityRecord(
          providerId: 'github',
          identityFlow: '',
          identityScopes: '',
          developerScopesSeparation: '',
          tokenLifecycle: '',
          revoke: '',
          errors: '',
        ),
      ]);
      expect(report.state, Sprint116GithubIdentityState.fail);
      expect(report.invalidRecords, contains('identity_flow:github'));
      expect(report.invalidRecords, contains('identity_scopes:github'));
      expect(
        report.invalidRecords,
        contains('developer_scopes_separation:github'),
      );
      expect(report.invalidRecords, contains('token_lifecycle:github'));
      expect(report.invalidRecords, contains('revoke:github'));
      expect(report.invalidRecords, contains('errors:github'));
    });

    test(
      'manifest is local-only and does not claim certified GitHub access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116GithubIdentityContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.12');
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
