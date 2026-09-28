import 'dart:convert';
import 'dart:io';

enum Sprint116GithubDeveloperState { pass, fail, blocked }

class Sprint116GithubDeveloperRecord {
  Sprint116GithubDeveloperRecord({
    required this.providerId,
    required this.repositoryScopes,
    required this.identityScopesSeparation,
    required this.organizationPolicy,
    required this.rateLimits,
    required this.revoke,
    required this.audit,
  });

  final String providerId;
  final String repositoryScopes;
  final String identityScopesSeparation;
  final String organizationPolicy;
  final String rateLimits;
  final String revoke;
  final String audit;
}

class Sprint116GithubDeveloperReport {
  Sprint116GithubDeveloperReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116GithubDeveloperState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116GithubDeveloperContract.externalGates;
}

abstract final class Sprint116GithubDeveloperContract {
  static const String canonicalStep = '116.28';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_github_developer_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'repository_scopes',
    'identity_scopes_separation',
    'organization_policy',
    'rate_limits',
    'revoke',
    'audit',
  ];
}

class Sprint116GithubDeveloperCertification {
  Sprint116GithubDeveloperReport evaluate([
    List<Sprint116GithubDeveloperRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116GithubDeveloperReport(
        state: Sprint116GithubDeveloperState.blocked,
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
        'identity_scopes_separation': record.identityScopesSeparation,
        'organization_policy': record.organizationPolicy,
        'rate_limits': record.rateLimits,
        'revoke': record.revoke,
        'audit': record.audit,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116GithubDeveloperReport(
      state: invalid.isEmpty
          ? Sprint116GithubDeveloperState.pass
          : Sprint116GithubDeveloperState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116GithubDeveloperRecord> _readManifestRecords() {
    final file = File(Sprint116GithubDeveloperContract.manifestPath);
    if (!file.existsSync()) return <Sprint116GithubDeveloperRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116GithubDeveloperRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116GithubDeveloperRecord(
              providerId: item['provider_id']?.toString() ?? '',
              repositoryScopes: item['repository_scopes']?.toString() ?? '',
              identityScopesSeparation:
                  item['identity_scopes_separation']?.toString() ?? '',
              organizationPolicy: item['organization_policy']?.toString() ?? '',
              rateLimits: item['rate_limits']?.toString() ?? '',
              revoke: item['revoke']?.toString() ?? '',
              audit: item['audit']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116GithubDeveloperRecord>[];
    }
  }
}
