import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_bitbucket_developer_certification.dart';

void main() {
  group('116.30 Bitbucket Developer Certification', () {
    test('locks repository scopes and workspace controls separately', () {
      expect(Sprint116BitbucketDeveloperContract.requiredFields, <String>[
        'provider_id',
        'repository_scopes',
        'workspaces',
        'rate_limits',
        'revoke',
        'audit',
      ]);
    });

    test('synthetic local manifest passes without live Bitbucket claims', () {
      final report = Sprint116BitbucketDeveloperCertification().evaluate([
        Sprint116BitbucketDeveloperRecord(
          providerId: 'bitbucket',
          repositoryScopes: 'synthetic repository scope fixture',
          workspaces: 'synthetic workspace fixture',
          rateLimits: 'synthetic rate limit fixture',
          revoke: 'synthetic revoke fixture',
          audit: 'synthetic audit fixture',
        ),
      ]);
      expect(report.state, Sprint116BitbucketDeveloperState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing developer controls fail closed', () {
      final report = Sprint116BitbucketDeveloperCertification().evaluate([
        Sprint116BitbucketDeveloperRecord(
          providerId: 'bitbucket',
          repositoryScopes: '',
          workspaces: '',
          rateLimits: '',
          revoke: '',
          audit: '',
        ),
      ]);
      expect(report.state, Sprint116BitbucketDeveloperState.fail);
      expect(report.invalidRecords, contains('repository_scopes:bitbucket'));
      expect(report.invalidRecords, contains('workspaces:bitbucket'));
      expect(report.invalidRecords, contains('rate_limits:bitbucket'));
      expect(report.invalidRecords, contains('revoke:bitbucket'));
      expect(report.invalidRecords, contains('audit:bitbucket'));
    });

    test(
      'manifest is local-only and does not claim certified Bitbucket access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116BitbucketDeveloperContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.30');
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
