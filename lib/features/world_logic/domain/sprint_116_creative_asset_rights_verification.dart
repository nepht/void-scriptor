import 'dart:convert';
import 'dart:io';

enum Sprint116CreativeAssetRightsState { pass, fail, blocked }

class Sprint116CreativeAssetRightsRecord {
  Sprint116CreativeAssetRightsRecord({
    required this.assetId,
    required this.source,
    required this.license,
    required this.attribution,
    required this.usageRights,
    required this.exportRights,
    required this.retention,
  });

  final String assetId;
  final String source;
  final String license;
  final String attribution;
  final String usageRights;
  final String exportRights;
  final String retention;
}

class Sprint116CreativeAssetRightsReport {
  Sprint116CreativeAssetRightsReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116CreativeAssetRightsState state;
  final List<String> invalidRecords;
  String get externalGates =>
      Sprint116CreativeAssetRightsContract.externalGates;
}

abstract final class Sprint116CreativeAssetRightsContract {
  static const String canonicalStep = '116.35';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_creative_asset_rights_verification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'source',
    'license',
    'attribution',
    'usage_rights',
    'export_rights',
    'retention',
  ];
}

class Sprint116CreativeAssetRightsVerification {
  Sprint116CreativeAssetRightsReport evaluate([
    List<Sprint116CreativeAssetRightsRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116CreativeAssetRightsReport(
        state: Sprint116CreativeAssetRightsState.blocked,
        invalidRecords: const <String>['records'],
      );
    }
    final invalid = <String>[];
    for (final record in effective) {
      final label = record.assetId.trim();
      final fields = <String, String>{
        'source': record.source,
        'license': record.license,
        'attribution': record.attribution,
        'usage_rights': record.usageRights,
        'export_rights': record.exportRights,
        'retention': record.retention,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) {
          invalid.add('${entry.key}:$label');
        }
      }
    }
    return Sprint116CreativeAssetRightsReport(
      state: invalid.isEmpty
          ? Sprint116CreativeAssetRightsState.pass
          : Sprint116CreativeAssetRightsState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116CreativeAssetRightsRecord> _readManifestRecords() {
    final file = File(Sprint116CreativeAssetRightsContract.manifestPath);
    if (!file.existsSync()) return <Sprint116CreativeAssetRightsRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116CreativeAssetRightsRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116CreativeAssetRightsRecord(
              assetId: item['asset_id']?.toString() ?? '',
              source: item['source']?.toString() ?? '',
              license: item['license']?.toString() ?? '',
              attribution: item['attribution']?.toString() ?? '',
              usageRights: item['usage_rights']?.toString() ?? '',
              exportRights: item['export_rights']?.toString() ?? '',
              retention: item['retention']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116CreativeAssetRightsRecord>[];
    }
  }
}
