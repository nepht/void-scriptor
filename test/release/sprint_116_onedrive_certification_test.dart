import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_onedrive_certification.dart';

void main() {
  group('116.16 OneDrive Certification', () {
    test('requires the eight OneDrive certification fields', () {
      expect(Sprint116OneDriveContract.requiredFields, <String>[
        'provider_id',
        'file_scope',
        'app_folder_root_choice',
        'upload_download',
        'delta',
        'quota',
        'revoke',
        'errors',
      ]);
    });

    test('synthetic local manifest passes without live OneDrive claims', () {
      final report = Sprint116OneDriveCertification().evaluate([
        Sprint116OneDriveRecord(
          providerId: 'onedrive',
          fileScope: 'synthetic least-scope fixture',
          appFolderRootChoice: 'synthetic app-folder fixture',
          uploadDownload: 'synthetic transfer fixture',
          delta: 'synthetic delta fixture',
          quota: 'synthetic quota fixture',
          revoke: 'synthetic revoke fixture',
          errors: 'synthetic error fixture',
        ),
      ]);
      expect(report.state, Sprint116OneDriveState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing OneDrive controls fail closed', () {
      final report = Sprint116OneDriveCertification().evaluate([
        Sprint116OneDriveRecord(
          providerId: 'onedrive',
          fileScope: '',
          appFolderRootChoice: '',
          uploadDownload: '',
          delta: '',
          quota: '',
          revoke: '',
          errors: '',
        ),
      ]);
      expect(report.state, Sprint116OneDriveState.fail);
      expect(report.invalidRecords, contains('file_scope:onedrive'));
      expect(
        report.invalidRecords,
        contains('app_folder_root_choice:onedrive'),
      );
      expect(report.invalidRecords, contains('upload_download:onedrive'));
      expect(report.invalidRecords, contains('delta:onedrive'));
      expect(report.invalidRecords, contains('quota:onedrive'));
      expect(report.invalidRecords, contains('revoke:onedrive'));
      expect(report.invalidRecords, contains('errors:onedrive'));
    });

    test(
      'manifest is local-only and does not claim certified OneDrive access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116OneDriveContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.16');
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
