import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_brand_asset_icon_certification.dart';

void main() {
  group('116.7 Brand Asset & Icon Certification', () {
    test('requires the eight canonical certification fields', () {
      expect(Sprint116BrandIconContract.requiredFields, <String>[
        'provider_id',
        'asset_source',
        'license_or_permission',
        'asset_version',
        'theme_variants',
        'fallback',
        'accessible_name',
        'review_status',
      ]);
    });

    test(
      'synthetic local manifest passes without claiming live brand approval',
      () {
        final report = Sprint116BrandIconCertification().evaluate([
          Sprint116BrandIconRecord(
            providerId: 'example_provider',
            assetSource: 'synthetic fixture',
            licenseOrPermission: 'not a production mark',
            assetVersion: 'fixture-v1',
            themeVariants: const ['light', 'dark'],
            fallback: 'generic category icon',
            accessibleName: 'Example provider icon',
            reviewStatus: 'UNVERIFIED',
          ),
        ]);
        expect(report.state, Sprint116BrandIconState.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test(
      'missing license, theme, fallback, or accessible name fails closed',
      () {
        final report = Sprint116BrandIconCertification().evaluate([
          Sprint116BrandIconRecord(
            providerId: 'fixture_provider',
            assetSource: '',
            licenseOrPermission: '',
            assetVersion: '',
            themeVariants: const [],
            fallback: '',
            accessibleName: '',
            reviewStatus: 'CERTIFIED',
          ),
        ]);
        expect(report.state, Sprint116BrandIconState.fail);
        expect(
          report.invalidRecords,
          contains('asset_source:fixture_provider'),
        );
        expect(
          report.invalidRecords,
          contains('license_or_permission:fixture_provider'),
        );
        expect(
          report.invalidRecords,
          contains('theme_variants:fixture_provider'),
        );
        expect(report.invalidRecords, contains('fallback:fixture_provider'));
        expect(
          report.invalidRecords,
          contains('accessible_name:fixture_provider'),
        );
        expect(
          report.invalidRecords,
          contains('asset_version:fixture_provider'),
        );
      },
    );

    test('manifest is local-only and keeps all providers unverified', () {
      final manifest =
          jsonDecode(
                File(
                  Sprint116BrandIconContract.manifestPath,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '116.7');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['records'], isNotEmpty);
      for (final record in manifest['records'] as List<dynamic>) {
        expect((record as Map<String, dynamic>)['review_status'], 'UNVERIFIED');
      }
    });
  });
}
