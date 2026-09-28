import 'dart:convert';
import 'dart:io';

enum Sprint116LocalAiState { pass, fail, blocked }

class Sprint116LocalAiRecord {
  Sprint116LocalAiRecord({
    required this.providerId,
    required this.modelDiscovery,
    required this.hardwareLimits,
    required this.storage,
    required this.lifecycle,
    required this.privacy,
    required this.offlineUse,
    required this.failureIsolation,
  });

  final String providerId;
  final String modelDiscovery;
  final String hardwareLimits;
  final String storage;
  final String lifecycle;
  final String privacy;
  final String offlineUse;
  final String failureIsolation;
}

class Sprint116LocalAiReport {
  Sprint116LocalAiReport({required this.state, required this.invalidRecords});

  final Sprint116LocalAiState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116LocalAiContract.externalGates;
}

abstract final class Sprint116LocalAiContract {
  static const String canonicalStep = '116.26';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_local_ai_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'model_discovery',
    'hardware_limits',
    'storage',
    'lifecycle',
    'privacy',
    'offline_use',
    'failure_isolation',
  ];
}

class Sprint116LocalAiCertification {
  Sprint116LocalAiReport evaluate([List<Sprint116LocalAiRecord>? records]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116LocalAiReport(
        state: Sprint116LocalAiState.blocked,
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
      final values = <String, String>{
        'model_discovery': record.modelDiscovery,
        'hardware_limits': record.hardwareLimits,
        'storage': record.storage,
        'lifecycle': record.lifecycle,
        'privacy': record.privacy,
        'offline_use': record.offlineUse,
        'failure_isolation': record.failureIsolation,
      };
      for (final entry in values.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116LocalAiReport(
      state: invalid.isEmpty
          ? Sprint116LocalAiState.pass
          : Sprint116LocalAiState.fail,
      invalidRecords: invalid,
    );
  }

  static Map<String, dynamic> readManifestForTest() {
    return jsonDecode(
          File(Sprint116LocalAiContract.manifestPath).readAsStringSync(),
        )
        as Map<String, dynamic>;
  }

  List<Sprint116LocalAiRecord> _readManifestRecords() {
    final file = File(Sprint116LocalAiContract.manifestPath);
    if (!file.existsSync()) return <Sprint116LocalAiRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116LocalAiRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116LocalAiRecord(
              providerId: item['provider_id']?.toString() ?? '',
              modelDiscovery: item['model_discovery']?.toString() ?? '',
              hardwareLimits: item['hardware_limits']?.toString() ?? '',
              storage: item['storage']?.toString() ?? '',
              lifecycle: item['lifecycle']?.toString() ?? '',
              privacy: item['privacy']?.toString() ?? '',
              offlineUse: item['offline_use']?.toString() ?? '',
              failureIsolation: item['failure_isolation']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116LocalAiRecord>[];
    }
  }
}
