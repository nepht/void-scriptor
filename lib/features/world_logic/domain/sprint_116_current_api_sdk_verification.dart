import 'dart:convert';
import 'dart:io';

enum Sprint116ApiSdkVerificationState { pass, fail, blocked }

class Sprint116ApiSdkVerificationRecord {
  Sprint116ApiSdkVerificationRecord({
    required this.providerId,
    required this.primarySources,
    required this.apiVersion,
    required this.sdkVersion,
    required this.deprecations,
    required this.authRequirements,
    required this.quotaCapabilities,
    required this.verificationDate,
    required this.limitations,
  });

  final String providerId;
  final List<String> primarySources;
  final String apiVersion;
  final String sdkVersion;
  final List<String> deprecations;
  final List<String> authRequirements;
  final List<String> quotaCapabilities;
  final String verificationDate;
  final List<String> limitations;
}

class Sprint116ApiSdkVerificationReport {
  Sprint116ApiSdkVerificationReport({
    required this.state,
    required this.verdict,
    required this.missingOutputs,
    required this.invalidRecords,
  });

  final Sprint116ApiSdkVerificationState state;
  final String verdict;
  final List<String> missingOutputs;
  final List<String> invalidRecords;
  String get externalGates => Sprint116ApiSdkVerificationContract.externalGates;
}

abstract final class Sprint116ApiSdkVerificationContract {
  static const String canonicalStep = '116.4';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_current_api_sdk_verification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredOutputs = <String>[
    'primary_sources',
    'api_versions',
    'sdk_versions',
    'deprecations',
    'auth_requirements',
    'quota_capabilities',
    'verification_date',
  ];
}

class Sprint116ApiSdkVerification {
  Sprint116ApiSdkVerificationReport evaluate(
    List<Sprint116ApiSdkVerificationRecord>? records,
  ) {
    final effectiveRecords = records ?? _readManifestRecords();
    if (effectiveRecords.isEmpty) {
      return Sprint116ApiSdkVerificationReport(
        state: Sprint116ApiSdkVerificationState.blocked,
        verdict: 'API_SDK_VERIFICATION_INCOMPLETE',
        missingOutputs: <String>['verification_records'],
        invalidRecords: const <String>[],
      );
    }

    final missing = <String>[];
    final invalid = <String>[];
    for (final record in effectiveRecords) {
      final id = record.providerId.trim();
      if (id.isEmpty) {
        invalid.add('provider_id');
        continue;
      }
      if (record.primarySources.isEmpty) {
        missing.add('primary_sources:$id');
      }
      if (record.apiVersion.trim().isEmpty) {
        missing.add('api_versions:$id');
      }
      if (record.sdkVersion.trim().isEmpty) {
        missing.add('sdk_versions:$id');
      }
      if (record.deprecations.isEmpty) {
        missing.add('deprecations:$id');
      }
      if (record.authRequirements.isEmpty) {
        missing.add('auth_requirements:$id');
      }
      if (record.quotaCapabilities.isEmpty) {
        missing.add('quota_capabilities:$id');
      }
      if (record.verificationDate.trim().isEmpty) {
        missing.add('verification_date:$id');
      }
      if (record.limitations.isEmpty) {
        invalid.add('limitations:$id');
      }
    }

    final state = missing.isNotEmpty || invalid.isNotEmpty
        ? Sprint116ApiSdkVerificationState.fail
        : Sprint116ApiSdkVerificationState.pass;
    return Sprint116ApiSdkVerificationReport(
      state: state,
      verdict: state == Sprint116ApiSdkVerificationState.pass
          ? 'API_SDK_VERIFICATION_SCHEMA_READY'
          : 'API_SDK_VERIFICATION_INCOMPLETE',
      missingOutputs: missing,
      invalidRecords: invalid,
    );
  }

  List<Sprint116ApiSdkVerificationRecord> _readManifestRecords() {
    final file = File(Sprint116ApiSdkVerificationContract.manifestPath);
    if (!file.existsSync()) return <Sprint116ApiSdkVerificationRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116ApiSdkVerificationRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map((item) {
            List<String> list(String key) =>
                (item[key] as List? ?? const <dynamic>[])
                    .map((value) => value.toString())
                    .toList(growable: false);
            return Sprint116ApiSdkVerificationRecord(
              providerId: item['provider_id']?.toString() ?? '',
              primarySources: list('primary_sources'),
              apiVersion: item['api_version']?.toString() ?? '',
              sdkVersion: item['sdk_version']?.toString() ?? '',
              deprecations: list('deprecations'),
              authRequirements: list('auth_requirements'),
              quotaCapabilities: list('quota_capabilities'),
              verificationDate: item['verification_date']?.toString() ?? '',
              limitations: list('limitations'),
            );
          })
          .toList(growable: false);
    } on FormatException {
      return <Sprint116ApiSdkVerificationRecord>[];
    }
  }
}
