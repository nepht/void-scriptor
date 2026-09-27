import 'dart:convert';
import 'dart:io';

enum Sprint116GoogleIdentityState { pass, fail, blocked }

class Sprint116GoogleIdentityRecord {
  Sprint116GoogleIdentityRecord({
    required this.providerId,
    required this.oauth,
    required this.scopes,
    required this.callback,
    required this.accountLinking,
    required this.tokenLifecycle,
    required this.revoke,
    required this.errors,
  });

  final String providerId;
  final String oauth;
  final String scopes;
  final String callback;
  final String accountLinking;
  final String tokenLifecycle;
  final String revoke;
  final String errors;
}

class Sprint116GoogleIdentityReport {
  Sprint116GoogleIdentityReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116GoogleIdentityState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116GoogleIdentityContract.externalGates;
}

abstract final class Sprint116GoogleIdentityContract {
  static const String canonicalStep = '116.9';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_google_identity_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'oauth',
    'scopes',
    'callback',
    'account_linking',
    'token_lifecycle',
    'revoke',
    'errors',
  ];
}

class Sprint116GoogleIdentityCertification {
  Sprint116GoogleIdentityReport evaluate([
    List<Sprint116GoogleIdentityRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116GoogleIdentityReport(
        state: Sprint116GoogleIdentityState.blocked,
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
      if (record.oauth.trim().isEmpty) invalid.add('oauth:$id');
      if (record.scopes.trim().isEmpty) invalid.add('scopes:$id');
      if (record.callback.trim().isEmpty) invalid.add('callback:$id');
      if (record.accountLinking.trim().isEmpty) {
        invalid.add('account_linking:$id');
      }
      if (record.tokenLifecycle.trim().isEmpty) {
        invalid.add('token_lifecycle:$id');
      }
      if (record.revoke.trim().isEmpty) invalid.add('revoke:$id');
      if (record.errors.trim().isEmpty) invalid.add('errors:$id');
    }
    return Sprint116GoogleIdentityReport(
      state: invalid.isEmpty
          ? Sprint116GoogleIdentityState.pass
          : Sprint116GoogleIdentityState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116GoogleIdentityRecord> _readManifestRecords() {
    final file = File(Sprint116GoogleIdentityContract.manifestPath);
    if (!file.existsSync()) return <Sprint116GoogleIdentityRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116GoogleIdentityRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116GoogleIdentityRecord(
              providerId: item['provider_id']?.toString() ?? '',
              oauth: item['oauth']?.toString() ?? '',
              scopes: item['scopes']?.toString() ?? '',
              callback: item['callback']?.toString() ?? '',
              accountLinking: item['account_linking']?.toString() ?? '',
              tokenLifecycle: item['token_lifecycle']?.toString() ?? '',
              revoke: item['revoke']?.toString() ?? '',
              errors: item['errors']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116GoogleIdentityRecord>[];
    }
  }
}
