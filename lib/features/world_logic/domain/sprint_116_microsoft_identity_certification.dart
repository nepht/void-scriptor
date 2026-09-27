import 'dart:convert';
import 'dart:io';

enum Sprint116MicrosoftIdentityState { pass, fail, blocked }

class Sprint116MicrosoftIdentityRecord {
  Sprint116MicrosoftIdentityRecord({
    required this.providerId,
    required this.identityFlow,
    required this.tenantVariants,
    required this.accountVariants,
    required this.scopes,
    required this.tokenLifecycle,
    required this.errors,
    required this.platformConstraints,
  });

  final String providerId;
  final String identityFlow;
  final String tenantVariants;
  final String accountVariants;
  final String scopes;
  final String tokenLifecycle;
  final String errors;
  final String platformConstraints;
}

class Sprint116MicrosoftIdentityReport {
  Sprint116MicrosoftIdentityReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116MicrosoftIdentityState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116MicrosoftIdentityContract.externalGates;
}

abstract final class Sprint116MicrosoftIdentityContract {
  static const String canonicalStep = '116.10';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_microsoft_identity_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'identity_flow',
    'tenant_variants',
    'account_variants',
    'scopes',
    'token_lifecycle',
    'errors',
    'platform_constraints',
  ];
}

class Sprint116MicrosoftIdentityCertification {
  Sprint116MicrosoftIdentityReport evaluate([
    List<Sprint116MicrosoftIdentityRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116MicrosoftIdentityReport(
        state: Sprint116MicrosoftIdentityState.blocked,
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
      if (record.identityFlow.trim().isEmpty) {
        invalid.add('identity_flow:$id');
      }
      if (record.tenantVariants.trim().isEmpty) {
        invalid.add('tenant_variants:$id');
      }
      if (record.accountVariants.trim().isEmpty) {
        invalid.add('account_variants:$id');
      }
      if (record.scopes.trim().isEmpty) invalid.add('scopes:$id');
      if (record.tokenLifecycle.trim().isEmpty) {
        invalid.add('token_lifecycle:$id');
      }
      if (record.errors.trim().isEmpty) invalid.add('errors:$id');
      if (record.platformConstraints.trim().isEmpty) {
        invalid.add('platform_constraints:$id');
      }
    }
    return Sprint116MicrosoftIdentityReport(
      state: invalid.isEmpty
          ? Sprint116MicrosoftIdentityState.pass
          : Sprint116MicrosoftIdentityState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116MicrosoftIdentityRecord> _readManifestRecords() {
    final file = File(Sprint116MicrosoftIdentityContract.manifestPath);
    if (!file.existsSync()) return <Sprint116MicrosoftIdentityRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116MicrosoftIdentityRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116MicrosoftIdentityRecord(
              providerId: item['provider_id']?.toString() ?? '',
              identityFlow: item['identity_flow']?.toString() ?? '',
              tenantVariants: item['tenant_variants']?.toString() ?? '',
              accountVariants: item['account_variants']?.toString() ?? '',
              scopes: item['scopes']?.toString() ?? '',
              tokenLifecycle: item['token_lifecycle']?.toString() ?? '',
              errors: item['errors']?.toString() ?? '',
              platformConstraints:
                  item['platform_constraints']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116MicrosoftIdentityRecord>[];
    }
  }
}
