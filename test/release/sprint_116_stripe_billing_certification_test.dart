import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_stripe_billing_certification.dart';

void main() {
  group('116.36 Stripe Billing Certification', () {
    test(
      'locks customer, subscription, payment method tokens, invoices, webhooks, refunds, tax metadata and portal',
      () {
        expect(Sprint116StripeBillingContract.requiredFields, <String>[
          'customer',
          'subscription',
          'payment_method_tokens',
          'invoices',
          'webhooks',
          'refunds',
          'tax_metadata',
          'portal',
        ]);
      },
    );

    test('synthetic local billing records pass without live Stripe claims', () {
      final report = Sprint116StripeBillingCertification().evaluate([
        Sprint116StripeBillingRecord(
          billingId: 'synthetic_customer_subscription_flow',
          customer: 'synthetic customer fixture',
          subscription: 'synthetic subscription fixture',
          paymentMethodTokens: 'synthetic payment method token fixture',
          invoices: 'synthetic invoice fixture',
          webhooks: 'synthetic webhook fixture',
          refunds: 'synthetic refund fixture',
          taxMetadata: 'synthetic tax metadata fixture',
          portal: 'synthetic portal fixture',
        ),
        Sprint116StripeBillingRecord(
          billingId: 'synthetic_invoice_refund_flow',
          customer: 'synthetic customer fixture',
          subscription: 'synthetic subscription fixture',
          paymentMethodTokens: 'synthetic payment method token fixture',
          invoices: 'synthetic invoice fixture',
          webhooks: 'synthetic webhook fixture',
          refunds: 'synthetic refund fixture',
          taxMetadata: 'synthetic tax metadata fixture',
          portal: 'synthetic portal fixture',
        ),
      ]);
      expect(report.state, Sprint116StripeBillingState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing billing controls fail closed per record', () {
      final report = Sprint116StripeBillingCertification().evaluate([
        Sprint116StripeBillingRecord(
          billingId: 'synthetic_customer_subscription_flow',
          customer: '',
          subscription: '',
          paymentMethodTokens: '',
          invoices: '',
          webhooks: '',
          refunds: '',
          taxMetadata: '',
          portal: '',
        ),
        Sprint116StripeBillingRecord(
          billingId: 'synthetic_invoice_refund_flow',
          customer: 'synthetic customer fixture',
          subscription: 'synthetic subscription fixture',
          paymentMethodTokens: 'synthetic payment method token fixture',
          invoices: 'synthetic invoice fixture',
          webhooks: 'synthetic webhook fixture',
          refunds: 'synthetic refund fixture',
          taxMetadata: '',
          portal: 'synthetic portal fixture',
        ),
      ]);
      expect(report.state, Sprint116StripeBillingState.fail);
      expect(
        report.invalidRecords,
        contains('customer:synthetic_customer_subscription_flow'),
      );
      expect(
        report.invalidRecords,
        contains('subscription:synthetic_customer_subscription_flow'),
      );
      expect(
        report.invalidRecords,
        contains('payment_method_tokens:synthetic_customer_subscription_flow'),
      );
      expect(
        report.invalidRecords,
        contains('invoices:synthetic_customer_subscription_flow'),
      );
      expect(
        report.invalidRecords,
        contains('webhooks:synthetic_customer_subscription_flow'),
      );
      expect(
        report.invalidRecords,
        contains('refunds:synthetic_customer_subscription_flow'),
      );
      expect(
        report.invalidRecords,
        contains('tax_metadata:synthetic_customer_subscription_flow'),
      );
      expect(
        report.invalidRecords,
        contains('portal:synthetic_customer_subscription_flow'),
      );
      expect(
        report.invalidRecords,
        contains('tax_metadata:synthetic_invoice_refund_flow'),
      );
      expect(report.invalidRecords.length, 9);
    });

    test('empty record set is blocked, not a pass', () {
      final report = Sprint116StripeBillingCertification().evaluate([]);
      expect(report.state, Sprint116StripeBillingState.blocked);
      expect(report.invalidRecords, contains('records'));
    });

    test(
      'manifest is local-only and carries no production secrets or live billing claims',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116StripeBillingContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.36');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['records'], isNotEmpty);
        final ids = (manifest['records'] as List<dynamic>)
            .map((record) => (record as Map<String, dynamic>)['billing_id'])
            .toList();
        expect(
          ids,
          containsAll(<String>[
            'synthetic_customer_subscription_flow',
            'synthetic_invoice_refund_flow',
          ]),
        );
        for (final record in manifest['records'] as List<dynamic>) {
          expect((record as Map<String, dynamic>)['status'], 'UNVERIFIED');
        }
        expect(
          manifest.keys
              .where(
                (key) =>
                    key.toLowerCase().contains('secret') ||
                    key.toLowerCase().contains('api_key'),
              )
              .toList(),
          isEmpty,
        );
      },
    );
  });
}
