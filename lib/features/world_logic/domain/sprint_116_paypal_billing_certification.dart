import 'dart:convert';
import 'dart:io';

enum Sprint116PayPalBillingState { pass, fail, blocked }

class Sprint116PayPalBillingRecord {
  Sprint116PayPalBillingRecord({
    required this.billingId,
    required this.paymentSubscriptionFlow,
    required this.redirects,
    required this.webhooks,
    required this.refunds,
    required this.region,
    required this.errors,
  });

  final String billingId;
  final String paymentSubscriptionFlow;
  final String redirects;
  final String webhooks;
  final String refunds;
  final String region;
  final String errors;
}

class Sprint116PayPalBillingReport {
  Sprint116PayPalBillingReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116PayPalBillingState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116PayPalBillingContract.externalGates;
}

abstract final class Sprint116PayPalBillingContract {
  static const String canonicalStep = '116.37';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_paypal_billing_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'payment_subscription_flow',
    'redirects',
    'webhooks',
    'refunds',
    'region',
    'errors',
  ];
}

class Sprint116PayPalBillingCertification {
  Sprint116PayPalBillingReport evaluate([
    List<Sprint116PayPalBillingRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116PayPalBillingReport(
        state: Sprint116PayPalBillingState.blocked,
        invalidRecords: const <String>['records'],
      );
    }
    final invalid = <String>[];
    for (final record in effective) {
      final label = record.billingId.trim();
      final fields = <String, String>{
        'payment_subscription_flow': record.paymentSubscriptionFlow,
        'redirects': record.redirects,
        'webhooks': record.webhooks,
        'refunds': record.refunds,
        'region': record.region,
        'errors': record.errors,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) {
          invalid.add('${entry.key}:$label');
        }
      }
    }
    return Sprint116PayPalBillingReport(
      state: invalid.isEmpty
          ? Sprint116PayPalBillingState.pass
          : Sprint116PayPalBillingState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116PayPalBillingRecord> _readManifestRecords() {
    final file = File(Sprint116PayPalBillingContract.manifestPath);
    if (!file.existsSync()) return <Sprint116PayPalBillingRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116PayPalBillingRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116PayPalBillingRecord(
              billingId: item['billing_id']?.toString() ?? '',
              paymentSubscriptionFlow:
                  item['payment_subscription_flow']?.toString() ?? '',
              redirects: item['redirects']?.toString() ?? '',
              webhooks: item['webhooks']?.toString() ?? '',
              refunds: item['refunds']?.toString() ?? '',
              region: item['region']?.toString() ?? '',
              errors: item['errors']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116PayPalBillingRecord>[];
    }
  }
}
