import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_azure_devops_certification.dart';

void main() {
  group('116.31 Azure DevOps Certification', () {
    test('locks organization and project controls separately', () {
      expect(Sprint116AzureDevOpsContract.requiredFields, <String>[
        'provider_id',
        'organizations',
        'projects',
        'repository_scopes',
        'token_lifecycle',
        'rate_limits',
        'audit',
      ]);
    });

    test(
      'synthetic local manifest passes without live Azure DevOps claims',
      () {
        final report = Sprint116AzureDevOpsCertification().evaluate([
          Sprint116AzureDevOpsRecord(
            providerId: 'azure_devops',
            organizations: 'synthetic organization fixture',
            projects: 'synthetic project fixture',
            repositoryScopes: 'synthetic repository scope fixture',
            tokenLifecycle: 'synthetic token lifecycle fixture',
            rateLimits: 'synthetic rate limit fixture',
            audit: 'synthetic audit fixture',
          ),
        ]);
        expect(report.state, Sprint116AzureDevOpsState.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test('missing certification controls fail closed', () {
      final report = Sprint116AzureDevOpsCertification().evaluate([
        Sprint116AzureDevOpsRecord(
          providerId: 'azure_devops',
          organizations: '',
          projects: '',
          repositoryScopes: '',
          tokenLifecycle: '',
          rateLimits: '',
          audit: '',
        ),
      ]);
      expect(report.state, Sprint116AzureDevOpsState.fail);
      expect(report.invalidRecords, contains('organizations:azure_devops'));
      expect(report.invalidRecords, contains('projects:azure_devops'));
      expect(report.invalidRecords, contains('repository_scopes:azure_devops'));
      expect(report.invalidRecords, contains('token_lifecycle:azure_devops'));
      expect(report.invalidRecords, contains('rate_limits:azure_devops'));
      expect(report.invalidRecords, contains('audit:azure_devops'));
    });

    test('empty record set is blocked, not a pass', () {
      final report = Sprint116AzureDevOpsCertification().evaluate([]);
      expect(report.state, Sprint116AzureDevOpsState.blocked);
      expect(report.invalidRecords, contains('records'));
    });

    test(
      'manifest is local-only and does not claim certified Azure DevOps access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116AzureDevOpsContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.31');
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
