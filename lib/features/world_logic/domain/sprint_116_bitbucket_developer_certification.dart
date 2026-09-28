import 'dart:convert';
import 'dart:io';

enum Sprint116BitbucketDeveloperState { pass, fail, blocked }

class Sprint116BitbucketDeveloperRecord {
  Sprint116BitbucketDeveloperRecord({
    required this.providerId,
    required this.repositoryScopes,
    required this.workspaces,
    required this.rateLimits,
    required this.revoke,
    required this.audit,
  });

  final String providerId;
  final String repositoryScopes;
  final String workspaces;
  final String rateLimits;
  final String revoke;
  final String audit;
}

class Sprint116BitbucketDeveloperReport {
  Sprint116BitbucketDeveloperReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116BitbucketDeveloperState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116BitbucketDeveloperContract.externalGates;
}

abstract final class Sprint116BitbucketDeveloperContract {
  static const String canonicalStep = '116.30';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_bitbucket_developer_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'repository_scopes',
    'workspaces',
    'rate_limits',
    'revoke',
    'audit',
  ];
}

class Sprint116BitbucketDeveloperCertification {
  Sprint116BitbucketDeveloperReport evaluate([
    List<Sprint116BitbucketDeveloperRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116BitbucketDeveloperReport(
        state: Sprint116BitbucketDeveloperState.blocked,
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
        'repository_scopes': record.repositoryScopes,
        'workspaces': record.workspaces,
        'rate_limits': record.rateLimits,
        'revoke': record.revoke,
        'audit': record.audit,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116BitbucketDeveloperReport(
      state: invalid.isEmpty
          ? Sprint116BitbucketDeveloperState.pass
          : Sprint116BitbucketDeveloperState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116BitbucketDeveloperRecord> _readManifestRecords() {
    final file = File(Sprint116BitbucketDeveloperContract.manifestPath);
    if (!file.existsSync()) return <Sprint116BitbucketDeveloperRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116BitbucketDeveloperRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116BitbucketDeveloperRecord(
              providerId: item['provider_id']?.toString() ?? '',
              repositoryScopes: item['repository_scopes']?.toString() ?? '',
              workspaces: item['workspaces']?.toString() ?? '',
              rateLimits: item['rate_limits']?.toString() ?? '',
              revoke: item['revoke']?.toString() ?? '',
              audit: item['audit']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116BitbucketDeveloperRecord>[];
    }
  }
}
