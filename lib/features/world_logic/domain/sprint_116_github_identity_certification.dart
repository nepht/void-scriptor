import 'dart:convert';
import 'dart:io';

enum Sprint116GithubIdentityState { pass, fail, blocked }

class Sprint116GithubIdentityRecord {
  Sprint116GithubIdentityRecord({
    required this.providerId,
    required this.identityFlow,
    required this.identityScopes,
    required this.developerScopesSeparation,
    required this.tokenLifecycle,
    required this.revoke,
    required this.errors,
  });

  final String providerId;
  final String identityFlow;
  final String identityScopes;
  final String developerScopesSeparation;
  final String tokenLifecycle;
  final String revoke;
  final String errors;
}

class Sprint116GithubIdentityReport {
  Sprint116GithubIdentityReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116GithubIdentityState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116GithubIdentityContract.externalGates;
}

abstract final class Sprint116GithubIdentityContract {
  static const String canonicalStep = '116.12';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_github_identity_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'identity_flow',
    'identity_scopes',
    'developer_scopes_separation',
    'token_lifecycle',
    'revoke',
    'errors',
  ];
}

class Sprint116GithubIdentityCertification {
  Sprint116GithubIdentityReport evaluate([
    List<Sprint116GithubIdentityRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116GithubIdentityReport(
        state: Sprint116GithubIdentityState.blocked,
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
        'identity_flow': record.identityFlow,
        'identity_scopes': record.identityScopes,
        'developer_scopes_separation': record.developerScopesSeparation,
        'token_lifecycle': record.tokenLifecycle,
        'revoke': record.revoke,
        'errors': record.errors,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) invalid.add('${entry.key}:$id');
      }
    }
    return Sprint116GithubIdentityReport(
      state: invalid.isEmpty
          ? Sprint116GithubIdentityState.pass
          : Sprint116GithubIdentityState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116GithubIdentityRecord> _readManifestRecords() {
    final file = File(Sprint116GithubIdentityContract.manifestPath);
    if (!file.existsSync()) return <Sprint116GithubIdentityRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116GithubIdentityRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116GithubIdentityRecord(
              providerId: item['provider_id']?.toString() ?? '',
              identityFlow: item['identity_flow']?.toString() ?? '',
              identityScopes: item['identity_scopes']?.toString() ?? '',
              developerScopesSeparation:
                  item['developer_scopes_separation']?.toString() ?? '',
              tokenLifecycle: item['token_lifecycle']?.toString() ?? '',
              revoke: item['revoke']?.toString() ?? '',
              errors: item['errors']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116GithubIdentityRecord>[];
    }
  }
}
