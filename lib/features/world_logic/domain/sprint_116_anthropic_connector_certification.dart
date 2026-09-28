import 'dart:convert';
import 'dart:io';

enum Sprint116AnthropicState { pass, fail, blocked }

class Sprint116AnthropicRecord {
  Sprint116AnthropicRecord({
    required this.providerId,
    required this.models,
    required this.auth,
    required this.streaming,
    required this.cancellation,
    required this.usageMetadata,
    required this.costLabels,
    required this.privacy,
    required this.errors,
    required this.limitations,
  });

  final String providerId;
  final String models;
  final String auth;
  final String streaming;
  final String cancellation;
  final String usageMetadata;
  final String costLabels;
  final String privacy;
  final String errors;
  final String limitations;
}

class Sprint116AnthropicReport {
  Sprint116AnthropicReport({required this.state, required this.invalidRecords});

  final Sprint116AnthropicState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116AnthropicContract.externalGates;
}

abstract final class Sprint116AnthropicContract {
  static const String canonicalStep = '116.23';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_anthropic_connector_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'models',
    'auth',
    'streaming',
    'cancellation',
    'usage_metadata',
    'cost_labels',
    'privacy',
    'errors',
    'limitations',
  ];
}

class Sprint116AnthropicCertification {
  Sprint116AnthropicReport evaluate([List<Sprint116AnthropicRecord>? records]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116AnthropicReport(
        state: Sprint116AnthropicState.blocked,
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
        'models': record.models,
        'auth': record.auth,
        'streaming': record.streaming,
        'cancellation': record.cancellation,
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
    return Sprint116AnthropicReport(
      state: invalid.isEmpty
          ? Sprint116AnthropicState.pass
          : Sprint116AnthropicState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116AnthropicRecord> _readManifestRecords() {
    final file = File(Sprint116AnthropicContract.manifestPath);
    if (!file.existsSync()) return <Sprint116AnthropicRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116AnthropicRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116AnthropicRecord(
              providerId: item['provider_id']?.toString() ?? '',
              models: item['models']?.toString() ?? '',
              auth: item['auth']?.toString() ?? '',
              streaming: item['streaming']?.toString() ?? '',
              cancellation: item['cancellation']?.toString() ?? '',
              usageMetadata: item['usage_metadata']?.toString() ?? '',
              costLabels: item['cost_labels']?.toString() ?? '',
              privacy: item['privacy']?.toString() ?? '',
              errors: item['errors']?.toString() ?? '',
              limitations: item['limitations']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116AnthropicRecord>[];
    }
  }
}
