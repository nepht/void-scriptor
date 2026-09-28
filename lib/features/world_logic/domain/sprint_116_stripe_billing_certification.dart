import 'dart:convert';
import 'dart:io';

enum Sprint116StripeBillingState { pass, fail, blocked }

class Sprint116StripeBillingRecord {
  Sprint116StripeBillingRecord({
    required this.billingId,
    required this.customer,
    required this.subscription,
    required this.paymentMethodTokens,
    required this.invoices,
    required this.webhooks,
    required this.refunds,
    required this.taxMetadata,
    required this.portal,
  });

  final String billingId;
  final String customer;
  final String subscription;
  final String paymentMethodTokens;
  final String invoices;
  final String webhooks;
  final String refunds;
  final String taxMetadata;
  final String portal;
}

class Sprint116StripeBillingReport {
  Sprint116StripeBillingReport({
    required this.state,
    required this.invalidRecords,
  });

  final Sprint116StripeBillingState state;
  final List<String> invalidRecords;
  String get externalGates => Sprint116StripeBillingContract.externalGates;
}

abstract final class Sprint116StripeBillingContract {
  static const String canonicalStep = '116.36';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_stripe_billing_certification.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredFields = <String>[
    'customer',
    'subscription',
    'payment_method_tokens',
    'invoices',
    'webhooks',
    'refunds',
    'tax_metadata',
    'portal',
  ];
}

class Sprint116StripeBillingCertification {
  Sprint116StripeBillingReport evaluate([
    List<Sprint116StripeBillingRecord>? records,
  ]) {
    final effective = records ?? _readManifestRecords();
    if (effective.isEmpty) {
      return Sprint116StripeBillingReport(
        state: Sprint116StripeBillingState.blocked,
        invalidRecords: const <String>['records'],
      );
    }
    final invalid = <String>[];
    for (final record in effective) {
      final label = record.billingId.trim();
      final fields = <String, String>{
        'customer': record.customer,
        'subscription': record.subscription,
        'payment_method_tokens': record.paymentMethodTokens,
        'invoices': record.invoices,
        'webhooks': record.webhooks,
        'refunds': record.refunds,
        'tax_metadata': record.taxMetadata,
        'portal': record.portal,
      };
      for (final entry in fields.entries) {
        if (entry.value.trim().isEmpty) {
          invalid.add('${entry.key}:$label');
        }
      }
    }
    return Sprint116StripeBillingReport(
      state: invalid.isEmpty
          ? Sprint116StripeBillingState.pass
          : Sprint116StripeBillingState.fail,
      invalidRecords: invalid,
    );
  }

  List<Sprint116StripeBillingRecord> _readManifestRecords() {
    final file = File(Sprint116StripeBillingContract.manifestPath);
    if (!file.existsSync()) return <Sprint116StripeBillingRecord>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic> || decoded['records'] is! List) {
        return <Sprint116StripeBillingRecord>[];
      }
      return (decoded['records'] as List)
          .whereType<Map>()
          .map(
            (item) => Sprint116StripeBillingRecord(
              billingId: item['billing_id']?.toString() ?? '',
              customer: item['customer']?.toString() ?? '',
              subscription: item['subscription']?.toString() ?? '',
              paymentMethodTokens:
                  item['payment_method_tokens']?.toString() ?? '',
              invoices: item['invoices']?.toString() ?? '',
              webhooks: item['webhooks']?.toString() ?? '',
              refunds: item['refunds']?.toString() ?? '',
              taxMetadata: item['tax_metadata']?.toString() ?? '',
              portal: item['portal']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return <Sprint116StripeBillingRecord>[];
    }
  }
}
