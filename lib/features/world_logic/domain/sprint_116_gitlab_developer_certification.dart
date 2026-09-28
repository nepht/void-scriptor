import 'dart:convert';
import 'dart:io';

enum Sprint116GitlabDeveloperState { pass, fail, blocked }

class Sprint116GitlabDeveloperRecord {
  Sprint116GitlabDeveloperRecord({
    required this.providerId,
    required this.deploymentTypes,
    required this.repositoryScopes,
    required this.rateLimits,
    required this.revoke,
    required this.audit,
  });

  final String providerId;
  final String deploymentTypes;
  final String repositoryScopes;
  final String rateLimits;
  final String revoke;
  final String audit;
}

class Sprint116GitlabDeveloperReport {
  Sprint116GitlabDeveloperReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116GitlabDeveloperState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116GitlabDeveloperContract.externalGates;
}

abstract final class Sprint116GitlabDeveloperContract {
  static const String canonicalStep = '116.29';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_gitlab_developer_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'deployment_types',
    'repository_scopes',
    'rate_limits',
    'revoke',
    'audit',
  ];
}

class Sprint116GitlabDeveloperCertification {
  Sprint116GitlabDeveloperReport evaluate([
    List<Sprint116GitlabDeveloperRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116GitlabDeveloperReport(
        state: Sprint116GitlabDeveloperState.blocked,
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
        'deployment_types': record.deploymentTypes,
        'repository_scopes': record.repositoryScopes,
        'rate_limits': record.rateLimits,
        'revoke': record.revoke,
        'audit': record.audit,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116GitlabDeveloperReport(
      state: invalid.isEmpty
          ? Sprint116GitlabDeveloperState.pass
          : Sprint116GitlabDeveloperState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116GitlabDeveloperRecord> _readManifestRecords() {
    final file = File(Sprint116GitlabDeveloperContract.manifestPath);
    if (!file.existsSync()) return <Sprint116GitlabDeveloperRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116GitlabDeveloperRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116GitlabDeveloperRecord(
              providerId: item['provider_id']?.toString() ?? '',
              deploymentTypes: item['deployment_types']?.toString() ?? '',
              repositoryScopes: item['repository_scopes']?.toString() ?? '',
              rateLimits: item['rate_limits']?.toString() ?? '',
              revoke: item['revoke']?.toString() ?? '',
              audit: item['audit']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116GitlabDeveloperRecord>[];
    }
  }
}
