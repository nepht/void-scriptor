import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_microsoft_identity_certification.dart';

void main() {
  group('116.10 Microsoft Identity Certification', () {
    test('requires the eight Microsoft identity certification fields', () {
      expect(Sprint116MicrosoftIdentityContract.requiredFields, <String>[
        'provider_id',
        'identity_flow',
        'tenant_variants',
        'account_variants',
        'scopes',
        'token_lifecycle',
        'errors',
        'platform_constraints',
      ]);
    });

    test('synthetic local manifest passes without live Microsoft claims', () {
      final report = Sprint116MicrosoftIdentityCertification().evaluate([
        Sprint116MicrosoftIdentityRecord(
          providerId: 'microsoft',
          identityFlow: 'synthetic identity flow fixture',
          tenantVariants: 'synthetic tenant fixture',
          accountVariants: 'synthetic account fixture',
          scopes: 'synthetic minimum-scope fixture',
          tokenLifecycle: 'synthetic lifecycle fixture',
          errors: 'synthetic error fixture',
          platformConstraints: 'synthetic platform fixture',
        ),
      ]);
      expect(report.state, Sprint116MicrosoftIdentityState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing identity controls fail closed', () {
      final report = Sprint116MicrosoftIdentityCertification().evaluate([
        Sprint116MicrosoftIdentityRecord(
          providerId: 'microsoft',
          identityFlow: '',
          tenantVariants: '',
          accountVariants: '',
          scopes: '',
          tokenLifecycle: '',
          errors: '',
          platformConstraints: '',
        ),
      ]);
      expect(report.state, Sprint116MicrosoftIdentityState.fail);
      expect(report.invalidRecords, contains('identity_flow:microsoft'));
      expect(report.invalidRecords, contains('tenant_variants:microsoft'));
      expect(report.invalidRecords, contains('account_variants:microsoft'));
      expect(report.invalidRecords, contains('scopes:microsoft'));
      expect(report.invalidRecords, contains('token_lifecycle:microsoft'));
      expect(report.invalidRecords, contains('errors:microsoft'));
      expect(report.invalidRecords, contains('platform_constraints:microsoft'));
    });

    test(
      'manifest is local-only and does not claim certified Microsoft access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116MicrosoftIdentityContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.10');
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
