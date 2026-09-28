import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_dropbox_certification.dart';

void main() {
  group('116.17 Dropbox Certification', () {
    test('requires the eight Dropbox certification fields', () {
      expect(Sprint116DropboxContract.requiredFields, <String>[
        'provider_id',
        'app_scope',
        'upload_download',
        'cursor_delta',
        'quota',
        'revoke',
        'errors',
        'limitations',
      ]);
    });

    test('synthetic local manifest passes without live Dropbox claims', () {
      final report = Sprint116DropboxCertification().evaluate([
        Sprint116DropboxRecord(
          providerId: 'dropbox',
          appScope: 'synthetic app-scope fixture',
          uploadDownload: 'synthetic transfer fixture',
          cursorDelta: 'synthetic cursor fixture',
          quota: 'synthetic quota fixture',
          revoke: 'synthetic revoke fixture',
          errors: 'synthetic error fixture',
          limitations: 'synthetic limitations fixture',
        ),
      ]);
      expect(report.state, Sprint116DropboxState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing Dropbox controls fail closed', () {
      final report = Sprint116DropboxCertification().evaluate([
        Sprint116DropboxRecord(
          providerId: 'dropbox',
          appScope: '',
          uploadDownload: '',
          cursorDelta: '',
          quota: '',
          revoke: '',
          errors: '',
          limitations: '',
        ),
      ]);
      expect(report.state, Sprint116DropboxState.fail);
      expect(report.invalidRecords, contains('app_scope:dropbox'));
      expect(report.invalidRecords, contains('upload_download:dropbox'));
      expect(report.invalidRecords, contains('cursor_delta:dropbox'));
      expect(report.invalidRecords, contains('quota:dropbox'));
      expect(report.invalidRecords, contains('revoke:dropbox'));
      expect(report.invalidRecords, contains('errors:dropbox'));
      expect(report.invalidRecords, contains('limitations:dropbox'));
    });

    test(
      'manifest is local-only and does not claim certified Dropbox access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116DropboxContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.17');
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
