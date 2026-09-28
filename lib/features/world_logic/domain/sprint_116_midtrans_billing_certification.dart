import 'dart:convert';
import 'dart:io';

enum Sprint116MidtransBillingState { pass, fail, blocked }

class Sprint116MidtransBillingRecord {
  Sprint116MidtransBillingRecord({
    required this.billingId,
    required this.paymentMethods,
    required this.redirects,
    required this.notifications,
    required this.signature,
    required this.region,
    required this.settlement,
    required this.errors,
  });

  final String billingId;
  final String paymentMethods;
  final String redirects;
  final String notifications;
  final String signature;
  final String region;
  final String settlement;
  final String errors;
}

class Sprint116MidtransBillingReport {
  Sprint116MidtransBillingReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116MidtransBillingState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116MidtransBillingContract.externalGates;
}

abstract final class Sprint116MidtransBillingContract {
  static const String canonicalStep = '116.38';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_midtrans_billing_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'payment_methods',
    'redirects',
    'notifications',
    'signature',
    'region',
    'settlement',
    'errors',
  ];
}

class Sprint116MidtransBillingCertification {
  Sprint116MidtransBillingReport evaluate([
    List<Sprint116MidtransBillingRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116MidtransBillingReport(
        state: Sprint116MidtransBillingState.blocked,
        invalidRecords: const <String>['records'],
      );
    }
    final invalid = <String>[];
    for (final record in effective) {
      final label = record.billingId.trim();
      final fields = <String, String>{
        'payment_methods': record.paymentMethods,
        'redirects': record.redirects,
        'notifications': record.notifications,
        'signature': record.signature,
        'region': record.region,
        'settlement': record.settlement,
        'errors': record.errors,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) {
          invalid.add('${entry.key}:$label');
        }
      }
    }
    return Sprint116MidtransBillingReport(
      state: invalid.isEmpty
          ? Sprint116MidtransBillingState.pass
          : Sprint116MidtransBillingState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116MidtransBillingRecord> _readManifestRecords() {
    final file = File(Sprint116MidtransBillingContract.manifestPath);
    if (!file.existsSync()) return <Sprint116MidtransBillingRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116MidtransBillingRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116MidtransBillingRecord(
              billingId: item['billing_id']?.toString() ?? '',
              paymentMethods: item['payment_methods']?.toString() ?? '',
              redirects: item['redirects']?.toString() ?? '',
              notifications: item['notifications']?.toString() ?? '',
              signature: item['signature']?.toString() ?? '',
              region: item['region']?.toString() ?? '',
              settlement: item['settlement']?.toString() ?? '',
              errors: item['errors']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116MidtransBillingRecord>[];
    }
  }
}
