import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_payment_connector_interface.dart';

void main() {
  final now = DateTime.utc(2026, 3, 1, 12);
  final methodRef = OpaqueRef.tryParse('payref:psp:pm-primary')!;
  final method = PaymentMethodSummary(
    ref: methodRef,
    kind: PaymentMethodKind.card,
    brand: 'visa',
    expiresAtUtc: DateTime.utc(2029, 12, 31),
  );
  final checkoutRef = OpaqueRef.tryParse('chkref:psp:session-01')!;
  final invoiceRef = OpaqueRef.tryParse('invref:psp:invoice-01')!;

  group('119.17 Payment Connector Interface', () {
    test('references are opaque and card-like values are refused outright', () {
      expect(methodRef.value, 'payref:psp:pm-primary');
      expect(methodRef.toString(), '[REDACTED]');
      expect(methodRef.isPaymentMethod, isTrue);
      expect(checkoutRef.isCheckout, isTrue);
      expect(invoiceRef.isInvoice, isTrue);

      expect(OpaqueRef.tryParse('4242424242424242'), isNull);
      expect(OpaqueRef.tryParse('payref:psp:4111111111111111'), isNull);
      expect(OpaqueRef.tryParse('payref:psp:4242-4242-4242-4242'), isNull);
      expect(OpaqueRef.tryParse('123'), isNull);
      expect(OpaqueRef.tryParse('psp/pm-primary'), isNull);

      expect(OpaqueRef.looksLikePan('4242 4242 4242 4242'), isTrue);
      expect(OpaqueRef.looksLikePan('4242-4242-4242-4242'), isTrue);
      expect(OpaqueRef.looksLikePan('pm-primary'), isFalse);
    });

    test(
      'payment method summaries never carry a pan, cvc, or last-four field',
      () {
        final json = method.toJson();
        expect(json['method_ref'], '[REDACTED]');
        expect(json['brand'], 'visa');
        expect(json.keys, isNot(contains('pan')));
        expect(json.keys, isNot(contains('cvc')));
        expect(json.keys, isNot(contains('number')));
        expect(json.keys, isNot(contains('last4')));
        expect(json.toString(), isNot(contains('payref:psp:pm-primary')));
      },
    );

    test('payment methods are validated and raw card data is rejected', () {
      expect(
        PaymentConnectorInterface.validatePaymentMethod(method, now: now),
        isEmpty,
      );
      expect(
        PaymentConnectorInterface.validatePaymentMethod(
          PaymentMethodSummary(
            ref: methodRef,
            kind: PaymentMethodKind.card,
            brand: '4242424242424242',
            expiresAtUtc: DateTime.utc(2029, 12, 31),
          ),
          now: now,
        ),
        contains('raw_card_data_present'),
      );
      expect(
        PaymentConnectorInterface.validatePaymentMethod(
          PaymentMethodSummary(
            ref: methodRef,
            kind: PaymentMethodKind.card,
            brand: '  ',
            expiresAtUtc: DateTime.utc(2029, 12, 31),
          ),
          now: now,
        ),
        contains('brand_missing'),
      );
      expect(
        PaymentConnectorInterface.validatePaymentMethod(
          PaymentMethodSummary(
            ref: methodRef,
            kind: PaymentMethodKind.card,
            brand: 'visa',
            expiresAtUtc: DateTime.utc(2025, 1, 1),
          ),
          now: now,
        ),
        contains('method_expired'),
      );
      expect(
        PaymentConnectorInterface.validatePaymentMethod(
          PaymentMethodSummary(
            ref: methodRef,
            kind: PaymentMethodKind.unknown,
            brand: 'visa',
            expiresAtUtc: null,
          ),
          now: now,
        ),
        contains('method_kind_unknown'),
      );
    });

    test(
      'checkout is denied for unsupported region, currency, and provider',
      () {
        const created = CheckoutSession(
          amountMinorUnits: 2500,
          currency: 'USD',
          region: 'US',
          state: CheckoutState.created,
        );
        const session = CheckoutSession(
          amountMinorUnits: 2500,
          currency: 'USD',
          region: 'US',
          state: CheckoutState.created,
        );
        expect(created.amountMinorUnits, 2500);
        expect(session.currency, 'USD');

        expect(
          PaymentConnectorInterface.checkout(
            session: null,
            availability: const PaymentAvailability(
              state: PaymentAvailabilityState.available,
              region: 'US',
              currency: 'USD',
            ),
          ),
          PaymentOperationResult.deniedUnknownCheckout,
        );
        expect(
          PaymentConnectorInterface.checkout(
            session: session,
            availability: const PaymentAvailability(
              state: PaymentAvailabilityState.regionUnsupported,
              region: 'AQ',
              currency: 'USD',
            ),
          ),
          PaymentOperationResult.deniedUnsupportedRegion,
        );
        expect(
          PaymentConnectorInterface.checkout(
            session: session,
            availability: const PaymentAvailability(
              state: PaymentAvailabilityState.currencyUnsupported,
              region: 'US',
              currency: 'XYZ',
            ),
          ),
          PaymentOperationResult.deniedUnsupportedCurrency,
        );
        expect(
          PaymentConnectorInterface.checkout(
            session: session,
            availability: const PaymentAvailability(
              state: PaymentAvailabilityState.providerUnavailable,
              region: 'US',
              currency: 'USD',
            ),
          ),
          PaymentOperationResult.deniedProviderUnavailable,
        );
        expect(
          PaymentConnectorInterface.checkout(
            session: session,
            availability: const PaymentAvailability(
              state: PaymentAvailabilityState.available,
              region: 'US',
              currency: 'USD',
            ),
          ),
          PaymentOperationResult.ok,
        );
        expect(
          PaymentConnectorInterface.checkout(
            session: const CheckoutSession(
              amountMinorUnits: 2500,
              currency: 'USD',
              region: 'US',
              state: CheckoutState.completed,
            ),
            availability: const PaymentAvailability(
              state: PaymentAvailabilityState.available,
              region: 'US',
              currency: 'USD',
            ),
          ),
          PaymentOperationResult.deniedInvalidState,
        );
      },
    );

    test('the customer portal fails closed without reauthentication', () {
      expect(
        PaymentConnectorInterface.customerPortal(
          portalAvailable: true,
          reauthenticated: false,
        ),
        PaymentOperationResult.deniedAuthenticationRequired,
      );
      expect(
        PaymentConnectorInterface.customerPortal(
          portalAvailable: false,
          reauthenticated: true,
        ),
        PaymentOperationResult.deniedProviderUnavailable,
      );
      expect(
        PaymentConnectorInterface.customerPortal(
          portalAvailable: true,
          reauthenticated: true,
        ),
        PaymentOperationResult.ok,
      );
    });

    test('refunds are only reachable for paid invoices inside the window', () {
      final paid = Invoice(
        ref: invoiceRef,
        amountMinorUnits: 25000,
        currency: 'USD',
        status: InvoiceStatus.paid,
        paidAtUtc: DateTime.utc(2026, 2, 25),
      );
      final open = Invoice(
        ref: invoiceRef,
        amountMinorUnits: 25000,
        currency: 'USD',
        status: InvoiceStatus.open,
        paidAtUtc: null,
      );

      expect(
        PaymentConnectorInterface.refundPath(
          invoice: null,
          daysSincePaid: 4,
        ).allowed,
        isFalse,
      );
      expect(
        PaymentConnectorInterface.refundPath(
          invoice: open,
          daysSincePaid: 4,
        ).allowed,
        isFalse,
      );
      expect(
        PaymentConnectorInterface.refundPath(
          invoice: paid,
          daysSincePaid: -1,
        ).allowed,
        isFalse,
      );
      expect(
        PaymentConnectorInterface.refundPath(
          invoice: paid,
          daysSincePaid: 45,
        ).allowed,
        isFalse,
      );

      final allowed = PaymentConnectorInterface.refundPath(
        invoice: paid,
        daysSincePaid: 4,
      );
      expect(allowed.allowed, isTrue);
      expect(allowed.windowDays, PaymentConnectorInterface.refundWindowDays);
      expect(allowed.requiresReason, isTrue);
    });

    test('invoices are filtered by status and sorted deterministically', () {
      final invoices = <Invoice>[
        Invoice(
          ref: OpaqueRef.tryParse('invref:psp:invoice-02')!,
          amountMinorUnits: 1000,
          currency: 'USD',
          status: InvoiceStatus.paid,
          paidAtUtc: DateTime.utc(2026, 2, 1),
        ),
        Invoice(
          ref: invoiceRef,
          amountMinorUnits: 25000,
          currency: 'USD',
          status: InvoiceStatus.open,
          paidAtUtc: null,
        ),
      ];

      expect(
        PaymentConnectorInterface.invoices(
          invoices,
          status: InvoiceStatus.open,
        ).map((i) => i.ref.value).toList(),
        <String>['invref:psp:invoice-01'],
      );
      expect(
        PaymentConnectorInterface.invoices(
          invoices,
          status: InvoiceStatus.voided,
        ),
        isEmpty,
      );
    });

    test(
      'availability is deterministic and never guesses a region or currency',
      () {
        expect(
          PaymentConnectorInterface.availability(
            region: 'US',
            currency: 'USD',
            providerReachable: false,
          ).state,
          PaymentAvailabilityState.providerUnavailable,
        );
        expect(
          PaymentConnectorInterface.availability(
            region: '  ',
            currency: 'USD',
            providerReachable: true,
          ).state,
          PaymentAvailabilityState.regionUnsupported,
        );
        expect(
          PaymentConnectorInterface.availability(
            region: 'US',
            currency: 'usd',
            providerReachable: true,
          ).state,
          PaymentAvailabilityState.currencyUnsupported,
        );
        expect(
          PaymentConnectorInterface.availability(
            region: 'US',
            currency: 'USD',
            providerReachable: true,
          ).state,
          PaymentAvailabilityState.available,
        );
      },
    );

    test(
      'error vocabulary is closed, redacted, and never echoes a provider message',
      () {
        const declined = PaymentError(code: PaymentErrorCode.cardDeclined);
        expect(declined.isRetryable, isFalse);
        expect(declined.userMessageKey, 'payment.error.cardDeclined');
        expect(declined.toJson()['code'], 'cardDeclined');
        expect(declined.toJson().keys, isNot(contains('provider_message')));
        expect(
          const PaymentError(code: PaymentErrorCode.rateLimited).isRetryable,
          isTrue,
        );
        expect(
          const PaymentError(
            code: PaymentErrorCode.providerUnavailable,
          ).isRetryable,
          isTrue,
        );
        expect(
          const PaymentError(code: PaymentErrorCode.unknown).isRetryable,
          isFalse,
        );
      },
    );

    test('health reports unavailable, degraded, and ok deterministically', () {
      expect(
        PaymentConnectorInterface.health(
          providerReachable: false,
          configured: true,
          regionSupported: true,
        ),
        PaymentHealth.unavailable,
      );
      expect(
        PaymentConnectorInterface.health(
          providerReachable: true,
          configured: true,
          regionSupported: false,
        ),
        PaymentHealth.degraded,
      );
      expect(
        PaymentConnectorInterface.health(
          providerReachable: true,
          configured: true,
          regionSupported: true,
        ),
        PaymentHealth.ok,
      );
    });

    test('diagnostics redact payment references', () {
      expect(
        PaymentConnectorInterface.redact('denied payref:psp:pm-primary'),
        'denied [REDACTED]',
      );
    });

    test('validates the canonical manifest and rejects missing methods', () {
      expect(PaymentConnectorInterface.validateCanonicalManifest(), isEmpty);

      final missing = <String, dynamic>{
        'canonical_step': '119.17',
        'unknown_field_policy': 'REJECT',
        'required_methods': <String>['checkout'],
        'acceptance': <String, dynamic>{},
      };
      expect(
        PaymentConnectorInterface.validateManifest(missing),
        containsAll(<String>[
          'method_missing:refund_path',
          'method_missing:availability',
          'method_missing:health',
          'acceptance_missing:payment_methods',
        ]),
      );
    });
  });
}
