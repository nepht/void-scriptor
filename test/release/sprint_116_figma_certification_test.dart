import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_figma_certification.dart';

void main() {
  group('116.32 Figma Certification', () {
    test('locks file access and asset boundary controls separately', () {
      expect(Sprint116FigmaContract.requiredFields, <String>[
        'provider_id',
        'file_access',
        'asset_import_export',
        'scopes',
        'attribution',
        'rate_limits',
        'revoke',
      ]);
    });

    test('synthetic local manifest passes without live Figma claims', () {
      final report = Sprint116FigmaCertification().evaluate([
        Sprint116FigmaRecord(
          providerId: 'figma',
          fileAccess: 'synthetic file access fixture',
          assetImportExport: 'synthetic asset import export fixture',
          scopes: 'synthetic scope fixture',
          attribution: 'synthetic attribution fixture',
          rateLimits: 'synthetic rate limit fixture',
          revoke: 'synthetic revoke fixture',
        ),
      ]);
      expect(report.state, Sprint116FigmaState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing certification controls fail closed', () {
      final report = Sprint116FigmaCertification().evaluate([
        Sprint116FigmaRecord(
          providerId: 'figma',
          fileAccess: '',
          assetImportExport: '',
          scopes: '',
          attribution: '',
          rateLimits: '',
          revoke: '',
        ),
      ]);
      expect(report.state, Sprint116FigmaState.fail);
      expect(report.invalidRecords, contains('file_access:figma'));
      expect(report.invalidRecords, contains('asset_import_export:figma'));
      expect(report.invalidRecords, contains('scopes:figma'));
      expect(report.invalidRecords, contains('attribution:figma'));
      expect(report.invalidRecords, contains('rate_limits:figma'));
      expect(report.invalidRecords, contains('revoke:figma'));
    });

    test('empty record set is blocked, not a pass', () {
      final report = Sprint116FigmaCertification().evaluate([]);
      expect(report.state, Sprint116FigmaState.blocked);
      expect(report.invalidRecords, contains('records'));
    });

    test(
      'manifest is local-only and does not claim certified Figma access',
      () {
        final manifest =
            jsonDecode(
                  File(Sprint116FigmaContract.manifestPath).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.32');
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
