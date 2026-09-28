import 'dart:convert';
import 'dart:io';

enum Sprint116FluxState { pass, fail, blocked }

class Sprint116FluxRecord {
  Sprint116FluxRecord({
    required this.providerId,
    required this.endpointProviderPath,
    required this.imageJobs,
    required this.progress,
    required this.cancellation,
    required this.usage,
    required this.cost,
    required this.contentSafety,
    required this.errors,
    required this.limitations,
  });

  final String providerId;
  final String endpointProviderPath;
  final String imageJobs;
  final String progress;
  final String cancellation;
  final String usage;
  final String cost;
  final String contentSafety;
  final String errors;
  final String limitations;
}

class Sprint116FluxReport {
  Sprint116FluxReport({required this.state, required this.invalidRecords});

  final Sprint116FluxState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116FluxContract.externalGates;
}

abstract final class Sprint116FluxContract {
  static const String canonicalStep = '116.24';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_flux_connector_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'endpoint_provider_path',
    'image_jobs',
    'progress',
    'cancellation',
    'usage',
    'cost',
    'content_safety',
    'errors',
    'limitations',
  ];
}

class Sprint116FluxCertification {
  Sprint116FluxReport evaluate([List<Sprint116FluxRecord>? records]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116FluxReport(
        state: Sprint116FluxState.blocked,
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
        'endpoint_provider_path': record.endpointProviderPath,
        'image_jobs': record.imageJobs,
        'progress': record.progress,
        'cancellation': record.cancellation,
        'usage': record.usage,
        'cost': record.cost,
        'content_safety': record.contentSafety,
        'errors': record.errors,
        'limitations': record.limitations,
      };
      for (final entry in values.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116FluxReport(
      state: invalid.isEmpty
          ? Sprint116FluxState.pass
          : Sprint116FluxState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116FluxRecord> _readManifestRecords() {
    final file = File(Sprint116FluxContract.manifestPath);
    if (!file.existsSync()) return <Sprint116FluxRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116FluxRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116FluxRecord(
              providerId: item['provider_id']?.toString() ?? '',
              endpointProviderPath:
                  item['endpoint_provider_path']?.toString() ?? '',
              imageJobs: item['image_jobs']?.toString() ?? '',
              progress: item['progress']?.toString() ?? '',
              cancellation: item['cancellation']?.toString() ?? '',
              usage: item['usage']?.toString() ?? '',
              cost: item['cost']?.toString() ?? '',
              contentSafety: item['content_safety']?.toString() ?? '',
              errors: item['errors']?.toString() ?? '',
              limitations: item['limitations']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116FluxRecord>[];
    }
  }
}
