import 'dart:convert';
import 'dart:io';

enum Sprint116OpenRouterState { pass, fail, blocked }

class Sprint116OpenRouterRecord {
  Sprint116OpenRouterRecord({
    required this.providerId,
    required this.routingMetadata,
    required this.models,
    required this.providerFallback,
    required this.usage,
    required this.cost,
    required this.privacyDestination,
    required this.errors,
    required this.limitations,
  });

  final String providerId;
  final String routingMetadata;
  final String models;
  final String providerFallback;
  final String usage;
  final String cost;
  final String privacyDestination;
  final String errors;
  final String limitations;
}

class Sprint116OpenRouterReport {
  Sprint116OpenRouterReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116OpenRouterState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116OpenRouterContract.externalGates;
}

abstract final class Sprint116OpenRouterContract {
  static const String canonicalStep = '116.25';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_openrouter_connector_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'routing_metadata',
    'models',
    'provider_fallback',
    'usage',
    'cost',
    'privacy_destination',
    'errors',
    'limitations',
  ];
}

class Sprint116OpenRouterCertification {
  Sprint116OpenRouterReport evaluate([
    List<Sprint116OpenRouterRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116OpenRouterReport(
        state: Sprint116OpenRouterState.blocked,
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
        'routing_metadata': record.routingMetadata,
        'models': record.models,
        'provider_fallback': record.providerFallback,
        'usage': record.usage,
        'cost': record.cost,
        'privacy_destination': record.privacyDestination,
        'errors': record.errors,
        'limitations': record.limitations,
      };
      for (final entry in values.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116OpenRouterReport(
      state: invalid.isEmpty
          ? Sprint116OpenRouterState.pass
          : Sprint116OpenRouterState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116OpenRouterRecord> _readManifestRecords() {
    final file = File(Sprint116OpenRouterContract.manifestPath);
    if (!file.existsSync()) return <Sprint116OpenRouterRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116OpenRouterRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116OpenRouterRecord(
              providerId: item['provider_id']?.toString() ?? '',
              routingMetadata: item['routing_metadata']?.toString() ?? '',
              models: item['models']?.toString() ?? '',
              providerFallback: item['provider_fallback']?.toString() ?? '',
              usage: item['usage']?.toString() ?? '',
              cost: item['cost']?.toString() ?? '',
              privacyDestination: item['privacy_destination']?.toString() ?? '',
              errors: item['errors']?.toString() ?? '',
              limitations: item['limitations']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116OpenRouterRecord>[];
    }
  }
}
