import 'dart:convert';
import 'dart:io';

enum Sprint116SandboxMatrixState { pass, fail, blocked }

class Sprint116SandboxMatrixRecord {
  Sprint116SandboxMatrixRecord({
    required this.providerId,
    required this.environment,
    required this.accountOwner,
    required this.region,
    required this.testData,
    required this.cleanup,
    required this.limitations,
  });

  final String providerId;
  final String environment;
  final String accountOwner;
  final String region;
  final List<String> testData;
  final List<String> cleanup;
  final List<String> limitations;

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_id': providerId,
    'environment': environment,
    'account_owner': accountOwner,
    'region': region,
    'test_data': List<String>.from(testData),
    'cleanup': List<String>.from(cleanup),
    'limitations': List<String>.from(limitations),
  };
}

class Sprint116SandboxMatrixReport {
  Sprint116SandboxMatrixReport({
    required this.state,
    required this.missingFields,
    required this.invalidRecords,
  });

  final Sprint116SandboxMatrixState state;
  final List<String> missingFields;
  final List<String> invalidRecords;
  String get externalGates => Sprint116SandboxMatrixContract.externalGates;
}

abstract final class Sprint116SandboxMatrixContract {
  static const String canonicalStep = '116.5';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_sandbox_test_account_matrix.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'environment',
    'account_owner',
    'region',
    'test_data',
    'cleanup',
    'limitations',
  ];
}

class Sprint116SandboxTestAccountMatrix {
  Sprint116SandboxMatrixReport evaluate([
    List<Sprint116SandboxMatrixRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116SandboxMatrixReport(
        state: Sprint116SandboxMatrixState.blocked,
        missingFields: <String>['matrix_records'],
        invalidRecords: const <String>[],
      );
    }
    final missing = <String>[];
    final invalid = <String>[];
    for (final record in effective) {
      final id = record.providerId.trim();
      if (id.isEmpty) {
        invalid.add('provider_id');
        continue;
      }
      if (record.environment.trim().isEmpty) missing.add('environment:$id');
      if (record.accountOwner.trim().isEmpty) missing.add('account_owner:$id');
      if (record.region.trim().isEmpty) missing.add('region:$id');
      if (record.testData.isEmpty) missing.add('test_data:$id');
      if (record.cleanup.isEmpty) missing.add('cleanup:$id');
      if (record.limitations.isEmpty) invalid.add('limitations:$id');
    }
    return Sprint116SandboxMatrixReport(
      state: missing.isNotEmpty || invalid.isNotEmpty
          ? Sprint116SandboxMatrixState.fail
          : Sprint116SandboxMatrixState.pass,
      missingFields: missing,
      invalidRecords: invalid,
    );
  }

  List<Sprint116SandboxMatrixRecord> _readManifestRecords() {
    final file = File(Sprint116SandboxMatrixContract.manifestPath);
    if (!file.existsSync()) return <Sprint116SandboxMatrixRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116SandboxMatrixRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map((item) {
            List<String> list(String key) =>
                (item[key] as List? ?? const <dynamic>[])
                    .map((value) => value.toString())
                    .toList(growable: false);
            return Sprint116SandboxMatrixRecord(
              providerId: item['provider_id']?.toString() ?? '',
              environment: item['environment']?.toString() ?? '',
              accountOwner: item['account_owner']?.toString() ?? '',
              region: item['region']?.toString() ?? '',
              testData: list('test_data'),
              cleanup: list('cleanup'),
              limitations: list('limitations'),
            );
          })
          .toList(growable: false);
    } on FormatException {
      return <Sprint116SandboxMatrixRecord>[];
    }
  }
}
