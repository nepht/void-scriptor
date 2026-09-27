import 'dart:convert';
import 'dart:io';

enum Sprint116BrandIconState { pass, fail, blocked }

class Sprint116BrandIconRecord {
  Sprint116BrandIconRecord({
    required this.providerId,
    required this.assetSource,
    required this.licenseOrPermission,
    required this.assetVersion,
    required this.themeVariants,
    required this.fallback,
    required this.accessibleName,
    required this.reviewStatus,
  });

  final String providerId;
  final String assetSource;
  final String licenseOrPermission;
  final String assetVersion;
  final List<String> themeVariants;
  final String fallback;
  final String accessibleName;
  final String reviewStatus;
}

class Sprint116BrandIconReport {
  Sprint116BrandIconReport({required this.state, required this.invalidRecords});

  final Sprint116BrandIconState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116BrandIconContract.externalGates;
}

abstract final class Sprint116BrandIconContract {
  static const String canonicalStep = '116.7';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_brand_asset_icon_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'asset_source',
    'license_or_permission',
    'asset_version',
    'theme_variants',
    'fallback',
    'accessible_name',
    'review_status',
  ];
}

class Sprint116BrandIconCertification {
  Sprint116BrandIconReport evaluate([List<Sprint116BrandIconRecord>? records]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116BrandIconReport(
        state: Sprint116BrandIconState.blocked,
        invalidRecords: const <String>['records'],
      );
    }
    final invalid = <String>[];
    for (final record in effective) {
      final id = record.providerId.trim();
      if (id.isEmpty) {
        invalid.add('provider_id');
        continue;
      }
      if (record.assetSource.trim().isEmpty) invalid.add('asset_source:$id');
      if (record.licenseOrPermission.trim().isEmpty) {
        invalid.add('license_or_permission:$id');
      }
      if (record.assetVersion.trim().isEmpty) invalid.add('asset_version:$id');
      if (record.themeVariants.isEmpty) invalid.add('theme_variants:$id');
      if (record.fallback.trim().isEmpty) invalid.add('fallback:$id');
      if (record.accessibleName.trim().isEmpty)
        invalid.add('accessible_name:$id');
      if (record.reviewStatus.trim().isEmpty) invalid.add('review_status:$id');
    }
    return Sprint116BrandIconReport(
      state: invalid.isEmpty
          ? Sprint116BrandIconState.pass
          : Sprint116BrandIconState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116BrandIconRecord> _readManifestRecords() {
    final file = File(Sprint116BrandIconContract.manifestPath);
    if (!file.existsSync()) return <Sprint116BrandIconRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116BrandIconRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116BrandIconRecord(
              providerId: item['provider_id']?.toString() ?? '',
              assetSource: item['asset_source']?.toString() ?? '',
              licenseOrPermission:
                  item['license_or_permission']?.toString() ?? '',
              assetVersion: item['asset_version']?.toString() ?? '',
              themeVariants: _strings(item['theme_variants']),
              fallback: item['fallback']?.toString() ?? '',
              accessibleName: item['accessible_name']?.toString() ?? '',
              reviewStatus: item['review_status']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116BrandIconRecord>[];
    }
  }

  static List<String> _strings(Object? value) => value is List
      ? value.map((item) => item.toString()).toList(growable: false)
      : const <String>[];
}
