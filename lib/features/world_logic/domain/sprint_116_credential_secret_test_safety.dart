import 'dart:convert';
import 'dart:io';

enum Sprint116CredentialSafetyState { pass, fail, blocked }

class Sprint116CredentialSafetyRecord {
  Sprint116CredentialSafetyRecord({
    required this.providerId,
    required this.credentialClass,
    required this.environment,
    required this.privilegeScope,
    required this.rotationPlan,
    required this.redactionPolicy,
    required this.artifactScan,
    required this.revocationPlan,
    required this.limitations,
  });

  final String providerId;
  final String credentialClass;
  final String environment;
  final String privilegeScope;
  final String rotationPlan;
  final String redactionPolicy;
  final String artifactScan;
  final String revocationPlan;
  final List<String> limitations;

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_id': providerId,
    'credential_class': credentialClass,
    'environment': environment,
    'privilege_scope': privilegeScope,
    'rotation': rotationPlan,
    'redaction': redactionPolicy,
    'no_artifact_leak': artifactScan,
    'revocation': revocationPlan,
    'limitations': List<String>.from(limitations),
  };
}

class Sprint116CredentialSafetyReport {
  Sprint116CredentialSafetyReport({
    required this.state,
    required this.missingControls,
    required this.invalidRecords,
  });

  final Sprint116CredentialSafetyState state;
  final List<String> missingControls;
  final List<String> invalidRecords;
  String get externalGates => Sprint116CredentialSafetyContract.externalGates;
}

abstract final class Sprint116CredentialSafetyContract {
  static const String canonicalStep = '116.6';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_credential_secret_test_safety.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredControls = <String>[
    'test_only_credentials',
    'least_privilege',
    'rotation',
    'redaction',
    'no_artifact_leak',
    'revocation',
  ];
}

class Sprint116CredentialSecretTestSafety {
  Sprint116CredentialSafetyReport evaluate([
    List<Sprint116CredentialSafetyRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116CredentialSafetyReport(
        state: Sprint116CredentialSafetyState.blocked,
        missingControls: <String>['records'],
        invalidRecords: const <String>[],
      );
    }
    final missing = <String>[];
    final invalid = <String>[];
    for (final record in effective) {
      final id = record.providerId.trim();
      if (id.isEmpty) {
        invalid.add('provider_id');
      }
      final label = id.isEmpty ? '<missing>' : id;
      if (record.credentialClass.trim().isEmpty) {
        missing.add('test_only_credentials:$label');
      }
      if (record.environment.trim().isEmpty ||
          record.privilegeScope.trim().isEmpty) {
        missing.add('least_privilege:$label');
      }
      if (record.rotationPlan.trim().isEmpty) {
        missing.add('rotation:$label');
      }
      if (record.redactionPolicy.trim().isEmpty) {
        missing.add('redaction:$label');
      }
      if (record.artifactScan.trim().isEmpty) {
        missing.add('no_artifact_leak:$label');
      }
      if (record.revocationPlan.trim().isEmpty) {
        missing.add('revocation:$label');
      }
      if (record.limitations.isEmpty) {
        invalid.add('limitations:$label');
      }
    }
    return Sprint116CredentialSafetyReport(
      state: missing.isNotEmpty || invalid.isNotEmpty
          ? Sprint116CredentialSafetyState.fail
          : Sprint116CredentialSafetyState.pass,
      missingControls: missing,
      invalidRecords: invalid,
    );
  }

  List<Sprint116CredentialSafetyRecord> _readManifestRecords() {
    final file = File(Sprint116CredentialSafetyContract.manifestPath);
    if (!file.existsSync()) return <Sprint116CredentialSafetyRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116CredentialSafetyRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map((item) {
            List<String> list(String key) =>
                (item[key] as List? ?? const <dynamic>[])
                    .map((value) => value.toString())
                    .toList(growable: false);
            return Sprint116CredentialSafetyRecord(
              providerId: item['provider_id']?.toString() ?? '',
              credentialClass: item['credential_class']?.toString() ?? '',
              environment: item['environment']?.toString() ?? '',
              privilegeScope: item['privilege_scope']?.toString() ?? '',
              rotationPlan: item['rotation']?.toString() ?? '',
              redactionPolicy: item['redaction']?.toString() ?? '',
              artifactScan: item['no_artifact_leak']?.toString() ?? '',
              revocationPlan: item['revocation']?.toString() ?? '',
              limitations: list('limitations'),
            );
          })
          .toList(growable: false);
    } on FormatException {
      return <Sprint116CredentialSafetyRecord>[];
    }
  }
}
