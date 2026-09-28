import 'dart:convert';
import 'dart:io';

enum Sprint116MegaState { pass, fail, blocked }

class Sprint116MegaRecord {
  Sprint116MegaRecord({
    required this.providerId,
    required this.integrationPath,
    required this.authentication,
    required this.transfer,
    required this.quota,
    required this.securityModel,
    required this.limitations,
  });

  final String providerId;
  final String integrationPath;
  final String authentication;
  final String transfer;
  final String quota;
  final String securityModel;
  final String limitations;
}

class Sprint116MegaReport {
  Sprint116MegaReport({required this.state, required this.invalidRecords});

  final Sprint116MegaState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116MegaContract.externalGates;
}

abstract final class Sprint116MegaContract {
  static const String canonicalStep = '116.18';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_mega_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'integration_path',
    'authentication',
    'transfer',
    'quota',
    'security_model',
    'limitations',
  ];
}

class Sprint116MegaCertification {
  Sprint116MegaReport evaluate([List<Sprint116MegaRecord>? records]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116MegaReport(
        state: Sprint116MegaState.blocked,
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
      if (record.integrationPath.trim().isEmpty) {
        invalid.add('integration_path:$id');
      }
      if (record.authentication.trim().isEmpty) {
        invalid.add('authentication:$id');
      }
      if (record.transfer.trim().isEmpty) invalid.add('transfer:$id');
      if (record.quota.trim().isEmpty) invalid.add('quota:$id');
      if (record.securityModel.trim().isEmpty) {
        invalid.add('security_model:$id');
      }
      if (record.limitations.trim().isEmpty) {
        invalid.add('limitations:$id');
      }
    }
    return Sprint116MegaReport(
      state: invalid.isEmpty
          ? Sprint116MegaState.pass
          : Sprint116MegaState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116MegaRecord> _readManifestRecords() {
    final file = File(Sprint116MegaContract.manifestPath);
    if (!file.existsSync()) return <Sprint116MegaRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116MegaRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116MegaRecord(
              providerId: item['provider_id']?.toString() ?? '',
              integrationPath: item['integration_path']?.toString() ?? '',
              authentication: item['authentication']?.toString() ?? '',
              transfer: item['transfer']?.toString() ?? '',
              quota: item['quota']?.toString() ?? '',
              securityModel: item['security_model']?.toString() ?? '',
              limitations: item['limitations']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116MegaRecord>[];
    }
  }
}
