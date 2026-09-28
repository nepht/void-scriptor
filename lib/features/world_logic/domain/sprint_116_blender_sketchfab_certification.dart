import 'dart:convert';
import 'dart:io';

enum Sprint116BlenderSketchfabState { pass, fail, blocked }

class Sprint116BlenderSketchfabRecord {
  Sprint116BlenderSketchfabRecord({
    required this.providerId,
    required this.integrationAvailability,
    required this.assetRights,
    required this.downloadScopes,
    required this.uploadScopes,
    required this.attribution,
    required this.limitations,
  });

  final String providerId;
  final String integrationAvailability;
  final String assetRights;
  final String downloadScopes;
  final String uploadScopes;
  final String attribution;
  final String limitations;
}

class Sprint116BlenderSketchfabReport {
  Sprint116BlenderSketchfabReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116BlenderSketchfabState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116BlenderSketchfabContract.externalGates;
}

abstract final class Sprint116BlenderSketchfabContract {
  static const String canonicalStep = '116.34';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_blender_sketchfab_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'integration_availability',
    'asset_rights',
    'download_scopes',
    'upload_scopes',
    'attribution',
    'limitations',
  ];
}

class Sprint116BlenderSketchfabCertification {
  Sprint116BlenderSketchfabReport evaluate([
    List<Sprint116BlenderSketchfabRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116BlenderSketchfabReport(
        state: Sprint116BlenderSketchfabState.blocked,
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
      final fields = <String, String>{
        'integration_availability': record.integrationAvailability,
        'asset_rights': record.assetRights,
        'download_scopes': record.downloadScopes,
        'upload_scopes': record.uploadScopes,
        'attribution': record.attribution,
        'limitations': record.limitations,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116BlenderSketchfabReport(
      state: invalid.isEmpty
          ? Sprint116BlenderSketchfabState.pass
          : Sprint116BlenderSketchfabState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116BlenderSketchfabRecord> _readManifestRecords() {
    final file = File(Sprint116BlenderSketchfabContract.manifestPath);
    if (!file.existsSync()) return <Sprint116BlenderSketchfabRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116BlenderSketchfabRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116BlenderSketchfabRecord(
              providerId: item['provider_id']?.toString() ?? '',
              integrationAvailability:
                  item['integration_availability']?.toString() ?? '',
              assetRights: item['asset_rights']?.toString() ?? '',
              downloadScopes: item['download_scopes']?.toString() ?? '',
              uploadScopes: item['upload_scopes']?.toString() ?? '',
              attribution: item['attribution']?.toString() ?? '',
              limitations: item['limitations']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116BlenderSketchfabRecord>[];
    }
  }
}
