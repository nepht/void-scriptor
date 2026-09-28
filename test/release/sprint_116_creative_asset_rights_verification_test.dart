import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_creative_asset_rights_verification.dart';

void main() {
  group('116.35 Creative Asset Rights Verification', () {
    test(
      'locks source, license, attribution, usage rights, export rights and retention',
      () {
        expect(Sprint116CreativeAssetRightsContract.requiredFields, <String>[
          'source',
          'license',
          'attribution',
          'usage_rights',
          'export_rights',
          'retention',
        ]);
      },
    );

    test(
      'synthetic local asset records pass without live license or rights claims',
      () {
        final report = Sprint116CreativeAssetRightsVerification().evaluate([
          Sprint116CreativeAssetRightsRecord(
            assetId: 'synthetic_imported_reference_asset',
            source: 'synthetic source fixture',
            license: 'synthetic license fixture',
            attribution: 'synthetic attribution fixture',
            usageRights: 'synthetic usage rights fixture',
            exportRights: 'synthetic export rights fixture',
            retention: 'synthetic retention fixture',
          ),
          Sprint116CreativeAssetRightsRecord(
            assetId: 'synthetic_exported_bundle_asset',
            source: 'synthetic source fixture',
            license: 'synthetic license fixture',
            attribution: 'synthetic attribution fixture',
            usageRights: 'synthetic usage rights fixture',
            exportRights: 'synthetic export rights fixture',
            retention: 'synthetic retention fixture',
          ),
        ]);
        expect(report.state, Sprint116CreativeAssetRightsState.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test('missing rights fields fail closed per asset', () {
      final report = Sprint116CreativeAssetRightsVerification().evaluate([
        Sprint116CreativeAssetRightsRecord(
          assetId: 'synthetic_imported_reference_asset',
          source: '',
          license: '',
          attribution: '',
          usageRights: '',
          exportRights: '',
          retention: '',
        ),
        Sprint116CreativeAssetRightsRecord(
          assetId: 'synthetic_exported_bundle_asset',
          source: 'synthetic source fixture',
          license: 'synthetic license fixture',
          attribution: 'synthetic attribution fixture',
          usageRights: 'synthetic usage rights fixture',
          exportRights: 'synthetic export rights fixture',
          retention: '',
        ),
      ]);
      expect(report.state, Sprint116CreativeAssetRightsState.fail);
      expect(
        report.invalidRecords,
        contains('source:synthetic_imported_reference_asset'),
      );
      expect(
        report.invalidRecords,
        contains('license:synthetic_imported_reference_asset'),
      );
      expect(
        report.invalidRecords,
        contains('attribution:synthetic_imported_reference_asset'),
      );
      expect(
        report.invalidRecords,
        contains('usage_rights:synthetic_imported_reference_asset'),
      );
      expect(
        report.invalidRecords,
        contains('export_rights:synthetic_imported_reference_asset'),
      );
      expect(
        report.invalidRecords,
        contains('retention:synthetic_imported_reference_asset'),
      );
      expect(
        report.invalidRecords,
        contains('retention:synthetic_exported_bundle_asset'),
      );
      expect(report.invalidRecords.length, 7);
    });

    test('empty record set is blocked, not a pass', () {
      final report = Sprint116CreativeAssetRightsVerification().evaluate([]);
      expect(report.state, Sprint116CreativeAssetRightsState.blocked);
      expect(report.invalidRecords, contains('records'));
    });

    test(
      'manifest is local-only and does not claim verified license or rights',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116CreativeAssetRightsContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.35');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['records'], isNotEmpty);
        final ids = (manifest['records'] as List<dynamic>)
            .map((record) => (record as Map<String, dynamic>)['asset_id'])
            .toList();
        expect(
          ids,
          containsAll(<String>[
            'synthetic_imported_reference_asset',
            'synthetic_exported_bundle_asset',
          ]),
        );
        for (final record in manifest['records'] as List<dynamic>) {
          expect((record as Map<String, dynamic>)['status'], 'UNVERIFIED');
        }
      },
    );
  });
}
