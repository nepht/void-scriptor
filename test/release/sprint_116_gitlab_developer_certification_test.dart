import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_gitlab_developer_certification.dart';

void main() {
  group('116.29 GitLab Developer Certification', () {
    test('locks deployment types and repository controls separately', () {
      expect(Sprint116GitlabDeveloperContract.requiredFields, <String>[
        'provider_id',
        'deployment_types',
        'repository_scopes',
        'rate_limits',
        'revoke',
        'audit',
      ]);
    });

    test('synthetic local manifest passes without live GitLab claims', () {
      final report = Sprint116GitlabDeveloperCertification().evaluate([
        Sprint116GitlabDeveloperRecord(
          providerId: 'gitlab',
          deploymentTypes: 'synthetic deployment type fixture',
          repositoryScopes: 'synthetic repository scope fixture',
          rateLimits: 'synthetic rate limit fixture',
          revoke: 'synthetic revoke fixture',
          audit: 'synthetic audit fixture',
        ),
      ]);
      expect(report.state, Sprint116GitlabDeveloperState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing developer controls fail closed', () {
      final report = Sprint116GitlabDeveloperCertification().evaluate([
        Sprint116GitlabDeveloperRecord(
          providerId: 'gitlab',
          deploymentTypes: '',
          repositoryScopes: '',
          rateLimits: '',
          revoke: '',
          audit: '',
        ),
      ]);
      expect(report.state, Sprint116GitlabDeveloperState.fail);
      expect(report.invalidRecords, contains('deployment_types:gitlab'));
      expect(report.invalidRecords, contains('repository_scopes:gitlab'));
      expect(report.invalidRecords, contains('rate_limits:gitlab'));
      expect(report.invalidRecords, contains('revoke:gitlab'));
      expect(report.invalidRecords, contains('audit:gitlab'));
    });

    test(
      'manifest is local-only and does not claim certified GitLab access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116GitlabDeveloperContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.29');
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
