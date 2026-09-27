import 'dart:convert';
import 'dart:io';

enum Sprint116EmailIdentityState { pass, fail, blocked }

class Sprint116EmailIdentityRecord {
  Sprint116EmailIdentityRecord({
    required this.providerId,
    required this.registration,
    required this.verification,
    required this.login,
    required this.recovery,
    required this.rateLimiting,
    required this.accountLinking,
  });

  final String providerId;
  final String registration;
  final String verification;
  final String login;
  final String recovery;
  final String rateLimiting;
  final String accountLinking;
}

class Sprint116EmailIdentityReport {
  Sprint116EmailIdentityReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116EmailIdentityState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116EmailIdentityContract.externalGates;
}

abstract final class Sprint116EmailIdentityContract {
  static const String canonicalStep = '116.8';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_email_identity_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'provider_id',
    'registration',
    'verification',
    'login',
    'recovery',
    'rate_limiting',
    'account_linking',
  ];
}

class Sprint116EmailIdentityCertification {
  Sprint116EmailIdentityReport evaluate([
    List<Sprint116EmailIdentityRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116EmailIdentityReport(
        state: Sprint116EmailIdentityState.blocked,
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
      if (record.registration.trim().isEmpty) invalid.add('registration:$id');
      if (record.verification.trim().isEmpty) invalid.add('verification:$id');
      if (record.login.trim().isEmpty) invalid.add('login:$id');
      if (record.recovery.trim().isEmpty) invalid.add('recovery:$id');
      if (record.rateLimiting.trim().isEmpty) {
        invalid.add('rate_limiting:$id');
      }
      if (record.accountLinking.trim().isEmpty) {
        invalid.add('account_linking:$id');
      }
    }
    return Sprint116EmailIdentityReport(
      state: invalid.isEmpty
          ? Sprint116EmailIdentityState.pass
          : Sprint116EmailIdentityState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116EmailIdentityRecord> _readManifestRecords() {
    final file = File(Sprint116EmailIdentityContract.manifestPath);
    if (!file.existsSync()) return <Sprint116EmailIdentityRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116EmailIdentityRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116EmailIdentityRecord(
              providerId: item['provider_id']?.toString() ?? '',
              registration: item['registration']?.toString() ?? '',
              verification: item['verification']?.toString() ?? '',
              login: item['login']?.toString() ?? '',
              recovery: item['recovery']?.toString() ?? '',
              rateLimiting: item['rate_limiting']?.toString() ?? '',
              accountLinking: item['account_linking']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116EmailIdentityRecord>[];
    }
  }
}
