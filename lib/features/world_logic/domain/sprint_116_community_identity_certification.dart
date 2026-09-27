import 'dart:convert';
import 'dart:io';

enum Sprint116CommunityIdentityState { pass, fail, blocked }

class Sprint116CommunityIdentityRecord {
  Sprint116CommunityIdentityRecord({
    required this.providerId,
    required this.identityFlow,
    required this.minimumScopes,
  });

  final String providerId;
  final String identityFlow;
  final String minimumScopes;
}

class Sprint116CommunityIdentityReport {
  Sprint116CommunityIdentityReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116CommunityIdentityState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116CommunityIdentityContract.externalGates;
}

abstract final class Sprint116CommunityIdentityContract {
  static const String canonicalStep = '116.13';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_community_identity_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> providers = <String>['discord', 'x', 'facebook'];
  static const List<String> requiredFields = <String>[
    'provider_id',
    'identity_flow',
    'minimum_scopes',
  ];
}

class Sprint116CommunityIdentityCertification {
  Sprint116CommunityIdentityReport evaluate([
    List<Sprint116CommunityIdentityRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116CommunityIdentityReport(
        state: Sprint116CommunityIdentityState.blocked,
        invalidRecords: const <String>['records'],
      );
    }
    final invalid = <String>[];
    for (final record in effective) {
      final id = record.providerId.trim();
      if (!Sprint116CommunityIdentityContract.providers.contains(id)) {
        invalid.add('provider_id:$id');
        continue;
      }
      if (record.identityFlow.trim().isEmpty) {
        invalid.add('identity_flow:$id');
      }
      if (record.minimumScopes.trim().isEmpty) {
        invalid.add('minimum_scopes:$id');
      }
    }
    return Sprint116CommunityIdentityReport(
      state: invalid.isEmpty
          ? Sprint116CommunityIdentityState.pass
          : Sprint116CommunityIdentityState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116CommunityIdentityRecord> _readManifestRecords() {
    final file = File(Sprint116CommunityIdentityContract.manifestPath);
    if (!file.existsSync()) return <Sprint116CommunityIdentityRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116CommunityIdentityRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116CommunityIdentityRecord(
              providerId: item['provider_id']?.toString() ?? '',
              identityFlow: item['identity_flow']?.toString() ?? '',
              minimumScopes: item['minimum_scopes']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116CommunityIdentityRecord>[];
    }
  }
}
