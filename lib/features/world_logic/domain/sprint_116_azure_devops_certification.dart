import 'dart:convert';
import 'dart:io';

enum Sprint116AzureDevOpsState { pass, fail, blocked }

class Sprint116AzureDevOpsRecord {
  Sprint116AzureDevOpsRecord({
    required this.providerId,
    required this.organizations,
    required this.projects,
    required this.repositoryScopes,
    required this.tokenLifecycle,
    required this.rateLimits,
    required this.audit,
  });

  final String providerId;
  final String organizations;
  final String projects;
  final String repositoryScopes;
  final String tokenLifecycle;
  final String rateLimits;
  final String audit;
}

class Sprint116AzureDevOpsReport {
  Sprint116AzureDevOpsReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116AzureDevOpsState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116AzureDevOpsContract.externalGates;
}

abstract final class Sprint116AzureDevOpsContract {
  static const String canonicalStep = '116.31';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_azure_devops_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'organizations',
    'projects',
    'repository_scopes',
    'token_lifecycle',
    'rate_limits',
    'audit',
  ];
}

class Sprint116AzureDevOpsCertification {
  Sprint116AzureDevOpsReport evaluate([
    List<Sprint116AzureDevOpsRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116AzureDevOpsReport(
        state: Sprint116AzureDevOpsState.blocked,
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
        'organizations': record.organizations,
        'projects': record.projects,
        'repository_scopes': record.repositoryScopes,
        'token_lifecycle': record.tokenLifecycle,
        'rate_limits': record.rateLimits,
        'audit': record.audit,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116AzureDevOpsReport(
      state: invalid.isEmpty
          ? Sprint116AzureDevOpsState.pass
          : Sprint116AzureDevOpsState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116AzureDevOpsRecord> _readManifestRecords() {
    final file = File(Sprint116AzureDevOpsContract.manifestPath);
    if (!file.existsSync()) return <Sprint116AzureDevOpsRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116AzureDevOpsRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116AzureDevOpsRecord(
              providerId: item['provider_id']?.toString() ?? '',
              organizations: item['organizations']?.toString() ?? '',
              projects: item['projects']?.toString() ?? '',
              repositoryScopes: item['repository_scopes']?.toString() ?? '',
              tokenLifecycle: item['token_lifecycle']?.toString() ?? '',
              rateLimits: item['rate_limits']?.toString() ?? '',
              audit: item['audit']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116AzureDevOpsRecord>[];
    }
  }
}
