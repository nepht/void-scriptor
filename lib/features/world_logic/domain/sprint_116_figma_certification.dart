import 'dart:convert';
import 'dart:io';

enum Sprint116FigmaState { pass, fail, blocked }

class Sprint116FigmaRecord {
  Sprint116FigmaRecord({
    required this.providerId,
    required this.fileAccess,
    required this.assetImportExport,
    required this.scopes,
    required this.attribution,
    required this.rateLimits,
    required this.revoke,
  });

  final String providerId;
  final String fileAccess;
  final String assetImportExport;
  final String scopes;
  final String attribution;
  final String rateLimits;
  final String revoke;
}

class Sprint116FigmaReport {
  Sprint116FigmaReport({required this.state, required this.invalidRecords});

  final Sprint116FigmaState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116FigmaContract.externalGates;
}

abstract final class Sprint116FigmaContract {
  static const String canonicalStep = '116.32';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_figma_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'file_access',
    'asset_import_export',
    'scopes',
    'attribution',
    'rate_limits',
    'revoke',
  ];
}

class Sprint116FigmaCertification {
  Sprint116FigmaReport evaluate([List<Sprint116FigmaRecord>? records]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116FigmaReport(
        state: Sprint116FigmaState.blocked,
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
        'file_access': record.fileAccess,
        'asset_import_export': record.assetImportExport,
        'scopes': record.scopes,
        'attribution': record.attribution,
        'rate_limits': record.rateLimits,
        'revoke': record.revoke,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116FigmaReport(
      state: invalid.isEmpty
          ? Sprint116FigmaState.pass
          : Sprint116FigmaState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116FigmaRecord> _readManifestRecords() {
    final file = File(Sprint116FigmaContract.manifestPath);
    if (!file.existsSync()) return <Sprint116FigmaRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116FigmaRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116FigmaRecord(
              providerId: item['provider_id']?.toString() ?? '',
              fileAccess: item['file_access']?.toString() ?? '',
              assetImportExport: item['asset_import_export']?.toString() ?? '',
              scopes: item['scopes']?.toString() ?? '',
              attribution: item['attribution']?.toString() ?? '',
              rateLimits: item['rate_limits']?.toString() ?? '',
              revoke: item['revoke']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116FigmaRecord>[];
    }
  }
}
