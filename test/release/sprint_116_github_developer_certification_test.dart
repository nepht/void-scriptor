import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_github_developer_certification.dart';

void main() {
  group('116.28 GitHub Developer Certification', () {
    test('locks repository scopes separately from identity scopes', () {
      expect(Sprint116GithubDeveloperContract.requiredFields, <String>[
        'provider_id',
        'repository_scopes',
        'identity_scopes_separation',
        'organization_policy',
        'rate_limits',
        'revoke',
        'audit',
      ]);
    });

    test('synthetic local manifest passes without live GitHub claims', () {
      final report = Sprint116GithubDeveloperCertification().evaluate([
        Sprint116GithubDeveloperRecord(
          providerId: 'github',
          repositoryScopes: 'synthetic repository scope fixture',
          identityScopesSeparation: 'synthetic identity separation fixture',
          organizationPolicy: 'synthetic organization policy fixture',
          rateLimits: 'synthetic rate limit fixture',
          revoke: 'synthetic revoke fixture',
          audit: 'synthetic audit fixture',
        ),
      ]);
      expect(report.state, Sprint116GithubDeveloperState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing developer controls fail closed', () {
      final report = Sprint116GithubDeveloperCertification().evaluate([
        Sprint116GithubDeveloperRecord(
          providerId: 'github',
          repositoryScopes: '',
          identityScopesSeparation: '',
          organizationPolicy: '',
          rateLimits: '',
          revoke: '',
          audit: '',
        ),
      ]);
      expect(report.state, Sprint116GithubDeveloperState.fail);
      expect(report.invalidRecords, contains('repository_scopes:github'));
      expect(
        report.invalidRecords,
        contains('identity_scopes_separation:github'),
      );
      expect(report.invalidRecords, contains('organization_policy:github'));
      expect(report.invalidRecords, contains('rate_limits:github'));
      expect(report.invalidRecords, contains('revoke:github'));
      expect(report.invalidRecords, contains('audit:github'));
    });

    test(
      'manifest is local-only and does not claim certified GitHub access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116GithubDeveloperContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.28');
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
