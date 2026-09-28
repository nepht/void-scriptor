import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_paypal_billing_certification.dart';

void main() {
  group('116.37 PayPal Billing Certification', () {
    test(
      'locks payment and subscription flow, redirects, webhooks, refunds, region and errors',
      () {
        expect(Sprint116PayPalBillingContract.requiredFields, <String>[
          'payment_subscription_flow',
          'redirects',
          'webhooks',
          'refunds',
          'region',
          'errors',
        ]);
      },
    );

    test('synthetic local billing records pass without live PayPal claims', () {
      final report = Sprint116PayPalBillingCertification().evaluate([
        Sprint116PayPalBillingRecord(
          billingId: 'synthetic_checkout_redirect_flow',
          paymentSubscriptionFlow:
              'synthetic payment and subscription flow fixture',
          redirects: 'synthetic redirect fixture',
          webhooks: 'synthetic webhook fixture',
          refunds: 'synthetic refund fixture',
          region: 'synthetic region fixture',
          errors: 'synthetic error fixture',
        ),
        Sprint116PayPalBillingRecord(
          billingId: 'synthetic_webhook_refund_flow',
          paymentSubscriptionFlow:
              'synthetic payment and subscription flow fixture',
          redirects: 'synthetic redirect fixture',
          webhooks: 'synthetic webhook fixture',
          refunds: 'synthetic refund fixture',
          region: 'synthetic region fixture',
          errors: 'synthetic error fixture',
        ),
      ]);
      expect(report.state, Sprint116PayPalBillingState.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('missing billing controls fail closed per record', () {
      final report = Sprint116PayPalBillingCertification().evaluate([
        Sprint116PayPalBillingRecord(
          billingId: 'synthetic_checkout_redirect_flow',
          paymentSubscriptionFlow: '',
          redirects: '',
          webhooks: '',
          refunds: '',
          region: '',
          errors: '',
        ),
        Sprint116PayPalBillingRecord(
          billingId: 'synthetic_webhook_refund_flow',
          paymentSubscriptionFlow:
              'synthetic payment and subscription flow fixture',
          redirects: 'synthetic redirect fixture',
          webhooks: 'synthetic webhook fixture',
          refunds: 'synthetic refund fixture',
          region: '',
          errors: 'synthetic error fixture',
        ),
      ]);
      expect(report.state, Sprint116PayPalBillingState.fail);
      expect(
        report.invalidRecords,
        contains('payment_subscription_flow:synthetic_checkout_redirect_flow'),
      );
      expect(
        report.invalidRecords,
        contains('redirects:synthetic_checkout_redirect_flow'),
      );
      expect(
        report.invalidRecords,
        contains('webhooks:synthetic_checkout_redirect_flow'),
      );
      expect(
        report.invalidRecords,
        contains('refunds:synthetic_checkout_redirect_flow'),
      );
      expect(
        report.invalidRecords,
        contains('region:synthetic_checkout_redirect_flow'),
      );
      expect(
        report.invalidRecords,
        contains('errors:synthetic_checkout_redirect_flow'),
      );
      expect(
        report.invalidRecords,
        contains('region:synthetic_webhook_refund_flow'),
      );
      expect(report.invalidRecords.length, 7);
    });

    test('empty record set is blocked, not a pass', () {
      final report = Sprint116PayPalBillingCertification().evaluate([]);
      expect(report.state, Sprint116PayPalBillingState.blocked);
      expect(report.invalidRecords, contains('records'));
    });

    test(
      'manifest is local-only and carries no production secrets or live billing claims',
      () {
        final manifest =
            jsonDecode(
                  File(
                    Sprint116PayPalBillingContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.37');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['records'], isNotEmpty);
        final ids = (manifest['records'] as List<dynamic>)
            .map((record) => (record as Map<String, dynamic>)['billing_id'])
            .toList();
        expect(
          ids,
          containsAll(<String>[
            'synthetic_checkout_redirect_flow',
            'synthetic_webhook_refund_flow',
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
