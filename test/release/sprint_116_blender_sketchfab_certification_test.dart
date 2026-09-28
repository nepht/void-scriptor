import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_blender_sketchfab_certification.dart';

void main() {
  group('116.34 Blender Cloud & Sketchfab Certification', () {
    test(
      'locks integration availability, asset rights, download/upload scopes, attribution and limitations separately',
      () {
        expect(Sprint116BlenderSketchfabContract.requiredFields, <String>[
          'provider_id',
          'integration_availability',
          'asset_rights',
          'download_scopes',
          'upload_scopes',
          'attribution',
          'limitations',
        ]);
      },
    );

    test(
      'synthetic local manifest passes without live Blender Cloud or Sketchfab claims',
      () {
        final report = Sprint116BlenderSketchfabCertification().evaluate([
          Sprint116BlenderSketchfabRecord(
            providerId: 'blender_cloud',
            integrationAvailability:
                'synthetic integration availability fixture',
            assetRights: 'synthetic asset rights fixture',
            downloadScopes: 'synthetic download scope fixture',
            uploadScopes: 'synthetic upload scope fixture',
            attribution: 'synthetic attribution fixture',
            limitations: 'synthetic limitation fixture',
          ),
          Sprint116BlenderSketchfabRecord(
            providerId: 'sketchfab',
            integrationAvailability:
                'synthetic integration availability fixture',
            assetRights: 'synthetic asset rights fixture',
            downloadScopes: 'synthetic download scope fixture',
            uploadScopes: 'synthetic upload scope fixture',
            attribution: 'synthetic attribution fixture',
            limitations: 'synthetic limitation fixture',
          ),
        ]);
        expect(report.state, Sprint116BlenderSketchfabState.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test('missing certification controls fail closed per provider', () {
      final report = Sprint116BlenderSketchfabCertification().evaluate([
        Sprint116BlenderSketchfabRecord(
          providerId: 'blender_cloud',
          integrationAvailability: '',
          assetRights: '',
          downloadScopes: '',
          uploadScopes: '',
          attribution: '',
          limitations: '',
        ),
        Sprint116BlenderSketchfabRecord(
          providerId: 'sketchfab',
          integrationAvailability: 'synthetic integration availability fixture',
          assetRights: 'synthetic asset rights fixture',
          downloadScopes: 'synthetic download scope fixture',
          uploadScopes: 'synthetic upload scope fixture',
          attribution: 'synthetic attribution fixture',
          limitations: '',
        ),
      ]);
      expect(report.state, Sprint116BlenderSketchfabState.fail);
      expect(
        report.invalidRecords,
        contains('integration_availability:blender_cloud'),
      );
      expect(report.invalidRecords, contains('asset_rights:blender_cloud'));
      expect(report.invalidRecords, contains('download_scopes:blender_cloud'));
      expect(report.invalidRecords, contains('upload_scopes:blender_cloud'));
      expect(report.invalidRecords, contains('attribution:blender_cloud'));
      expect(report.invalidRecords, contains('limitations:blender_cloud'));
      expect(report.invalidRecords, contains('limitations:sketchfab'));
      expect(report.invalidRecords.length, 7);
    });

    test('empty record set is blocked, not a pass', () {
      final report = Sprint116BlenderSketchfabCertification().evaluate([]);
      expect(report.state, Sprint116BlenderSketchfabState.blocked);
      expect(report.invalidRecords, contains('records'));
    });

    test(
      'manifest is local-only and does not claim certified Blender Cloud or Sketchfab access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116BlenderSketchfabContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.34');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['records'], isNotEmpty);
        final ids = (manifest['records'] as List<dynamic>)
            .map((record) => (record as Map<String, dynamic>)['provider_id'])
            .toList();
        expect(ids, containsAll(<String>['blender_cloud', 'sketchfab']));
        for (final record in manifest['records'] as List<dynamic>) {
          expect((record as Map<String, dynamic>)['status'], 'UNVERIFIED');
        }
      },
    );
  });
}
