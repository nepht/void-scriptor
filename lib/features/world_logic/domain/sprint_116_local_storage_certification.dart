import 'dart:convert';
import 'dart:io';

enum Sprint116LocalStorageState { pass, fail, blocked }

class Sprint116LocalStorageRecord {
  Sprint116LocalStorageRecord({
    required this.paths,
    required this.permissions,
    required this.freeSpace,
    required this.categories,
    required this.scanFreshness,
    required this.removableMedia,
    required this.failureRecovery,
    required this.limitations,
  });

  final String paths;
  final String permissions;
  final String freeSpace;
  final String categories;
  final String scanFreshness;
  final String removableMedia;
  final String failureRecovery;
  final String limitations;
}

class Sprint116LocalStorageReport {
  Sprint116LocalStorageReport({
    required this.state,
    required this.invalidFields,
  });

  final Sprint116LocalStorageState state;
  final List<String> invalidFields;
  String get externalGates => Sprint116LocalStorageContract.externalGates;
}

abstract final class Sprint116LocalStorageContract {
  static const String canonicalStep = '116.19';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_local_storage_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'paths',
    'permissions',
    'free_space',
    'categories',
    'scan_freshness',
    'removable_media',
    'failure_recovery',
    'limitations',
  ];
}

class Sprint116LocalStorageCertification {
  Sprint116LocalStorageReport evaluate([
    List<Sprint116LocalStorageRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116LocalStorageReport(
        state: Sprint116LocalStorageState.blocked,
        invalidFields: const <String>['records'],
      );
    }
    final invalid = <String>[];
    for (final record in effective) {
      final values = <String, String>{
        'paths': record.paths,
        'permissions': record.permissions,
        'free_space': record.freeSpace,
        'categories': record.categories,
        'scan_freshness': record.scanFreshness,
        'removable_media': record.removableMedia,
        'failure_recovery': record.failureRecovery,
        'limitations': record.limitations,
      };
      for (final field in Sprint116LocalStorageContract.requiredFields) {
        if (values[field]!.trim().isEmpty) invalid.add(field);
      }
    }
    return Sprint116LocalStorageReport(
      state: invalid.isEmpty
          ? Sprint116LocalStorageState.pass
          : Sprint116LocalStorageState.fail,
      invalidFields: invalid,
    );
  }

  List<Sprint116LocalStorageRecord> _readManifestRecords() {
    final file = File(Sprint116LocalStorageContract.manifestPath);
    if (!file.existsSync()) return <Sprint116LocalStorageRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116LocalStorageRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116LocalStorageRecord(
              paths: item['paths']?.toString() ?? '',
              permissions: item['permissions']?.toString() ?? '',
              freeSpace: item['free_space']?.toString() ?? '',
              categories: item['categories']?.toString() ?? '',
              scanFreshness: item['scan_freshness']?.toString() ?? '',
              removableMedia: item['removable_media']?.toString() ?? '',
              failureRecovery: item['failure_recovery']?.toString() ?? '',
              limitations: item['limitations']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116LocalStorageRecord>[];
    }
  }
}
