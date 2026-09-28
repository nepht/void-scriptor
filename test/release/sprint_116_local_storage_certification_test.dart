import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_local_storage_certification.dart';

void main() {
  group('116.19 Local Storage Certification', () {
    test('requires the eight local-storage certification fields', () {
      expect(Sprint116LocalStorageContract.requiredFields, <String>[
        'paths',
        'permissions',
        'free_space',
        'categories',
        'scan_freshness',
        'removable_media',
        'failure_recovery',
        'limitations',
      ]);
    });

    test('synthetic local manifest passes without hardware claims', () {
      final report = Sprint116LocalStorageCertification().evaluate([
        Sprint116LocalStorageRecord(
          paths: 'synthetic paths fixture',
          permissions: 'synthetic permissions fixture',
          freeSpace: 'synthetic free-space fixture',
          categories: 'projects/assets/cache categories',
          scanFreshness: 'synthetic scan freshness fixture',
          removableMedia: 'synthetic removable-media fixture',
          failureRecovery: 'synthetic recovery fixture',
          limitations: 'no live drive or removable-media probe',
        ),
      ]);
      expect(report.state, Sprint116LocalStorageState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing local-storage controls fail closed', () {
      final report = Sprint116LocalStorageCertification().evaluate([
        Sprint116LocalStorageRecord(
          paths: '',
          permissions: '',
          freeSpace: '',
          categories: '',
          scanFreshness: '',
          removableMedia: '',
          failureRecovery: '',
          limitations: '',
        ),
      ]);
      expect(report.state, Sprint116LocalStorageState.fail);
      expect(report.invalidFields, contains('paths'));
      expect(report.invalidFields, contains('permissions'));
      expect(report.invalidFields, contains('free_space'));
      expect(report.invalidFields, contains('categories'));
      expect(report.invalidFields, contains('scan_freshness'));
      expect(report.invalidFields, contains('removable_media'));
      expect(report.invalidFields, contains('failure_recovery'));
      expect(report.invalidFields, contains('limitations'));
    });

    test(
      'manifest is local-only and does not claim certified device access',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116LocalStorageContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.19');
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
