import 'dart:convert';
import 'dart:io';

enum Sprint116AppleIdentityState { pass, fail, blocked }

class Sprint116AppleIdentityRecord {
  Sprint116AppleIdentityRecord({
    required this.providerId,
    required this.identityFlow,
    required this.privateRelayHandling,
    required this.tokenLifecycle,
    required this.revoke,
    required this.platformConstraints,
  });

  final String providerId;
  final String identityFlow;
  final String privateRelayHandling;
  final String tokenLifecycle;
  final String revoke;
  final String platformConstraints;
}

class Sprint116AppleIdentityReport {
  Sprint116AppleIdentityReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116AppleIdentityState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116AppleIdentityContract.externalGates;
}

abstract final class Sprint116AppleIdentityContract {
  static const String canonicalStep = '116.11';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_apple_identity_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'identity_flow',
    'private_relay_handling',
    'token_lifecycle',
    'revoke',
    'platform_constraints',
  ];
}

class Sprint116AppleIdentityCertification {
  Sprint116AppleIdentityReport evaluate([
    List<Sprint116AppleIdentityRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116AppleIdentityReport(
        state: Sprint116AppleIdentityState.blocked,
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
      if (record.privateRelayHandling.trim().isEmpty) {
        invalid.add('private_relay_handling:$id');
      }
      if (record.tokenLifecycle.trim().isEmpty) {
        invalid.add('token_lifecycle:$id');
      }
      if (record.revoke.trim().isEmpty) invalid.add('revoke:$id');
      if (record.platformConstraints.trim().isEmpty) {
        invalid.add('platform_constraints:$id');
      }
    }
    return Sprint116AppleIdentityReport(
      state: invalid.isEmpty
          ? Sprint116AppleIdentityState.pass
          : Sprint116AppleIdentityState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116AppleIdentityRecord> _readManifestRecords() {
    final file = File(Sprint116AppleIdentityContract.manifestPath);
    if (!file.existsSync()) return <Sprint116AppleIdentityRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116AppleIdentityRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116AppleIdentityRecord(
              providerId: item['provider_id']?.toString() ?? '',
              identityFlow: item['identity_flow']?.toString() ?? '',
              privateRelayHandling:
                  item['private_relay_handling']?.toString() ?? '',
              tokenLifecycle: item['token_lifecycle']?.toString() ?? '',
              revoke: item['revoke']?.toString() ?? '',
              platformConstraints:
                  item['platform_constraints']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116AppleIdentityRecord>[];
    }
  }
}
