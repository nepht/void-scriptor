import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_google_drive_certification.dart';

void main() {
  group('116.15 Google Drive Certification', () {
    test('requires the eight Google Drive certification fields', () {
      expect(Sprint116GoogleDriveContract.requiredFields, <String>[
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

    test('synthetic local manifest passes without live Drive claims', () {
      final report = Sprint116GoogleDriveCertification().evaluate([
        Sprint116GoogleDriveRecord(
          providerId: 'google_drive',
          fileScope: 'synthetic least-scope fixture',
          appFolderRootChoice: 'synthetic app-folder fixture',
          uploadDownload: 'synthetic transfer fixture',
          delta: 'synthetic delta fixture',
          quota: 'synthetic quota fixture',
          revoke: 'synthetic revoke fixture',
          errors: 'synthetic error fixture',
        ),
      ]);
      expect(report.state, Sprint116GoogleDriveState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing Drive controls fail closed', () {
      final report = Sprint116GoogleDriveCertification().evaluate([
        Sprint116GoogleDriveRecord(
          providerId: 'google_drive',
          fileScope: '',
          appFolderRootChoice: '',
          uploadDownload: '',
          delta: '',
          quota: '',
          revoke: '',
          errors: '',
        ),
      ]);
      expect(report.state, Sprint116GoogleDriveState.fail);
      expect(report.invalidRecords, contains('file_scope:google_drive'));
      expect(
        report.invalidRecords,
        contains('app_folder_root_choice:google_drive'),
      );
      expect(report.invalidRecords, contains('upload_download:google_drive'));
      expect(report.invalidRecords, contains('delta:google_drive'));
      expect(report.invalidRecords, contains('quota:google_drive'));
      expect(report.invalidRecords, contains('revoke:google_drive'));
      expect(report.invalidRecords, contains('errors:google_drive'));
    });

    test(
      'manifest is local-only and does not claim certified Google Drive access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116GoogleDriveContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.15');
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
