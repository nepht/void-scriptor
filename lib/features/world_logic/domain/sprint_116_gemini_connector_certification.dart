import 'dart:convert';
import 'dart:io';

enum Sprint116GeminiState { pass, fail, blocked }

class Sprint116GeminiRecord {
  Sprint116GeminiRecord({
    required this.providerId,
    required this.supportedModalities,
    required this.models,
    required this.auth,
    required this.usageMetadata,
    required this.costLabels,
    required this.privacy,
    required this.errors,
    required this.limitations,
  });

  final String providerId;
  final String supportedModalities;
  final String models;
  final String auth;
  final String usageMetadata;
  final String costLabels;
  final String privacy;
  final String errors;
  final String limitations;
}

class Sprint116GeminiReport {
  Sprint116GeminiReport({required this.state, required this.invalidRecords});

  final Sprint116GeminiState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116GeminiContract.externalGates;
}

abstract final class Sprint116GeminiContract {
  static const String canonicalStep = '116.22';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_gemini_connector_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'supported_modalities',
    'models',
    'auth',
    'usage_metadata',
    'cost_labels',
    'privacy',
    'errors',
    'limitations',
  ];
}

class Sprint116GeminiCertification {
  Sprint116GeminiReport evaluate([List<Sprint116GeminiRecord>? records]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116GeminiReport(
        state: Sprint116GeminiState.blocked,
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
        'supported_modalities': record.supportedModalities,
        'models': record.models,
        'auth': record.auth,
        'usage_metadata': record.usageMetadata,
        'cost_labels': record.costLabels,
        'privacy': record.privacy,
        'errors': record.errors,
        'limitations': record.limitations,
      };
      for (final entry in values.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116GeminiReport(
      state: invalid.isEmpty ? Sprint116GeminiState.pass : Sprint116GeminiState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116GeminiRecord> _readManifestRecords() {
    final file = File(Sprint116GeminiContract.manifestPath);
    if (!file.existsSync()) return <Sprint116GeminiRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116GeminiRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116GeminiRecord(
              providerId: item['provider_id']?.toString() ?? '',
              supportedModalities: item['supported_modalities']?.toString() ?? '',
              models: item['models']?.toString() ?? '',
              auth: item['auth']?.toString() ?? '',
              usageMetadata: item['usage_metadata']?.toString() ?? '',
              costLabels: item['cost_labels']?.toString() ?? '',
              privacy: item['privacy']?.toString() ?? '',
              errors: item['errors']?.toString() ?? '',
              limitations: item['limitations']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116GeminiRecord>[];
    }
  }
}
