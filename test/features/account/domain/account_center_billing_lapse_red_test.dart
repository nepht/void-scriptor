// RED for canonical step 117.21. Each test states a measured fact that shipped
// billing code gets wrong today. Run against the pre-fix sources these fail;
// they are the necessity witness for the fixes in this slice.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_billing_summary.dart'
    show TaxStatus;
import 'package:void_scriptor/features/account/domain/account_center_invoice_history.dart';
import 'package:void_scriptor/features/account/domain/account_center_subscription_entitlement_model.dart';

DateTime _utc(int y, int m, int d, [int h = 12]) => DateTime.utc(y, m, d, h);

AccountCenterInvoiceHistory _history(bool reauth, {DateTime? now}) =>
    AccountCenterInvoiceHistory(
      'usd',
      () => now ?? _utc(2026, 3, 3),
      () async => reauth,
    );

Invoice _paid(String id, double total, {DateTime? deadline}) => Invoice(
  invoiceId: id,
  number: 'INV-$id',
  issuedAt: _utc(2026, 1, 2),
  currency: 'usd',
  lineItems: <InvoiceLineItem>[
    InvoiceLineItem(
      description: 'seat',
      quantity: 1,
      unitAmount: total,
      currency: 'usd',
    ),
  ],
  tax: TaxStatus.doesNotApply,
  taxLine: null,
  total: total,
  status: InvoiceStatus.closed,
  payment: InvoicePayment(
    state: InvoicePaymentState.paid,
    paidAmount: total,
    paidAt: _utc(2026, 1, 2),
  ),
  disputeDeadline: deadline,
);

/// A paid annual plan whose grant window runs past every instant these tests
/// use, so any lapse they observe comes from the billing lifecycle rather
/// than from the grant expiring on its own.
AccountCenterSubscriptionEntitlementModel _annual({
  DateTime? grantExpires,
  DateTime? renewsAt,
  RenewalMode mode = RenewalMode.auto,
}) => AccountCenterSubscriptionEntitlementModel(
  plan: SubscriptionPlan(
    planId: 'plan-pro-annual',
    displayName: 'Pro Annual',
    tier: PlanTier.premium,
    cycle: PlanBillingCycle.yearly,
    price: PlanPrice(amount: 120, currency: 'usd'),
  ),
  entitlements: <EntitlementGrant>[
    EntitlementGrant(
      key: 'export.pdf',
      state: EntitlementState.granted,
      source: EntitlementSource.signedServer,
      grantedAt: _utc(2025, 1, 1),
      expiresAt: grantExpires ?? _utc(2027, 1, 1),
    ),
  ],
  limits: <EntitlementLimit>[
    EntitlementLimit(key: 'export.pdf', unit: 'per month', limit: 500),
  ],
  renewal: RenewalInfo(mode: mode, renewsAt: renewsAt ?? _utc(2027, 1, 1)),
  cancellation: CancellationInfo(state: CancellationState.none),
  trial: TrialInfo(),
  gracePeriod: GracePeriodInfo(),
  license: OfflineLicenseInfo(
    state: OfflineLicenseState.unlicensed,
    authority: LicenseAuthority.signedServer,
  ),
);

void main() {
  group('117.21 RED: refund and dispute verdicts must not be fail-open', () {
    test('a refund the provider REJECTED gives its budget back', () async {
      // Measured: `refundableRemaining` subtracts every requested refund
      // regardless of how the provider answered, so a rejected 80 leaves 20
      // of a 100 invoice and the remaining 20 is unrefundable. A refusal
      // returned the user's money; it cannot keep holding their budget.
      final history = _history(true);
      history.register(_paid('inv-1', 100));

      final rejected = await history.requestRefund(
        invoiceId: 'inv-1',
        amount: 80,
        reason: 'Service not delivered.',
      );
      rejected.reject(_utc(2026, 3, 4));

      expect(rejected.state, RefundState.rejected);
      expect(
        history.refundableRemaining('inv-1'),
        100.0,
        reason:
            'A rejected refund never left the account, so the whole '
            'collected amount is refundable again.',
      );
      final again = await history.requestRefund(
        invoiceId: 'inv-1',
        amount: 100,
        reason: 'Retried after the provider declined the first attempt.',
      );
      expect(again.state, RefundState.requested);
    });

    test('a CANCELLED refund also releases its budget', () async {
      final history = _history(true);
      history.register(_paid('inv-2', 60));

      final withdrawn = await history.requestRefund(
        invoiceId: 'inv-2',
        amount: 60,
        reason: 'Requested in error.',
      );
      withdrawn.cancel(_utc(2026, 3, 4));

      expect(withdrawn.state, RefundState.cancelled);
      expect(history.refundableRemaining('inv-2'), 60.0);
      expect(
        history.paymentStatusFor('inv-2').state,
        InvoicePaymentState.paid,
        reason:
            'Nothing was ever collected back, so the invoice is still paid.',
      );
    });

    test('only SETTLED refunds consume the refundable budget', () async {
      final history = _history(true);
      history.register(_paid('inv-3', 50));

      final first = await history.requestRefund(
        invoiceId: 'inv-3',
        amount: 20,
        reason: 'Partial refund.',
      );
      expect(
        history.refundableRemaining('inv-3'),
        30.0,
        reason: 'A pending request reserves the budget while it is in flight.',
      );
      first.settle(_utc(2026, 3, 4));
      expect(history.refundableRemaining('inv-3'), 30.0);

      final second = await history.requestRefund(
        invoiceId: 'inv-3',
        amount: 30,
        reason: 'The rest.',
      );
      second.reject(_utc(2026, 3, 5));
      expect(
        history.refundableRemaining('inv-3'),
        30.0,
        reason: 'The settled 20 stays consumed; the rejected 30 comes back.',
      );
      expect(
        history.paymentStatusFor('inv-3').state,
        InvoicePaymentState.partiallyRefunded,
        reason: '20 of 50 collected back is still a partial refund.',
      );
    });

    test('a dispute the provider WON is not an unpaid invoice', () async {
      // Measured: paymentStatusFor only inspects `isOpen`, so a dispute that
      // the provider WON — money returned to the user — reports `paid`. The
      // account is told it owes nothing when the provider has already ruled
      // in its favour.
      final history = _history(true);
      history.register(_paid('inv-4', 80, deadline: _utc(2026, 6, 1)));

      await history.fileDispute(invoiceId: 'inv-4', reason: 'Chargeback.');
      expect(
        history.paymentStatusFor('inv-4').state,
        InvoicePaymentState.disputed,
        reason: 'An open dispute holds the charge.',
      );

      history.disputeFor('inv-4')!.resolve(DisputeState.won, _utc(2026, 4, 1));

      expect(
        history.paymentStatusFor('inv-4').state,
        InvoicePaymentState.refunded,
        reason: 'A dispute the provider won means the charge was returned.',
      );
      expect(
        history.refundableRemaining('inv-4'),
        0.0,
        reason:
            'Nothing is outstanding after a won dispute, so there is '
            'nothing left to refund.',
      );
    });

    test('a LOST dispute leaves the charge payable', () async {
      final history = _history(true);
      history.register(_paid('inv-5', 80, deadline: _utc(2026, 6, 1)));

      await history.fileDispute(invoiceId: 'inv-5', reason: 'Chargeback.');
      history.disputeFor('inv-5')!.resolve(DisputeState.lost, _utc(2026, 4, 1));

      expect(
        history.paymentStatusFor('inv-5').state,
        InvoicePaymentState.paid,
        reason: 'The provider ruled for the merchant; the charge stands.',
      );
      expect(history.refundableRemaining('inv-5'), 80.0);
    });

    test('a WITHDRAWN dispute returns to the underlying charge', () async {
      final history = _history(true);
      history.register(_paid('inv-6', 80, deadline: _utc(2026, 6, 1)));

      await history.fileDispute(invoiceId: 'inv-6', reason: 'Chargeback.');
      history
          .disputeFor('inv-6')!
          .resolve(DisputeState.withdrawn, _utc(2026, 4, 1));

      expect(
        history.paymentStatusFor('inv-6').state,
        InvoicePaymentState.paid,
        reason: 'The user withdrew the claim, so the charge is payable again.',
      );
      expect(history.refundableRemaining('inv-6'), 80.0);
    });
  });

  group('117.21 RED: a terminated subscription keeps its entitlements', () {
    test(
      'a CONFIRMED cancellation revokes the grant at the effective instant',
      () {
        // Measured: confirmCancellation only flips the enum. The grant window
        // still runs to 2027-01-01, so `hasEntitlement` answered true for a
        // subscription the user cancelled and the provider confirmed.
        final model = _annual();
        final scheduled = model.scheduleCancellation(
          at: _utc(2026, 3, 1),
          effectiveAt: _utc(2026, 4, 1),
        );

        expect(
          scheduled.entitlementStateAt('export.pdf', _utc(2026, 3, 31)),
          EntitlementState.granted,
          reason: 'Before the effective instant the paid period is still owed.',
        );

        final confirmed = scheduled.confirmCancellation(at: _utc(2026, 4, 1));

        expect(confirmed.cancellation.state, CancellationState.cancelled);
        expect(
          confirmed.entitlementStateAt('export.pdf', _utc(2026, 4, 1)),
          EntitlementState.denied,
          reason:
              'The cancellation is effective, so the grant is revoked at '
              'that instant.',
        );
        expect(
          confirmed.hasEntitlement('export.pdf', _utc(2026, 4, 1)),
          isFalse,
        );
        expect(
          confirmed.hasEntitlement('export.pdf', _utc(2026, 6, 1)),
          isFalse,
          reason: 'Still revoked a year after the cancellation took effect.',
        );
      },
    );

    test('a confirmed cancellation stops declaring a future renewal', () {
      final model = _annual();
      final confirmed = model
          .scheduleCancellation(
            at: _utc(2026, 3, 1),
            effectiveAt: _utc(2026, 4, 1),
          )
          .confirmCancellation(at: _utc(2026, 4, 1));

      expect(
        confirmed.renewal.mode,
        RenewalMode.none,
        reason:
            'A cancelled subscription has no renewal to charge; leaving '
            'auto/renewsAt in place invites a charge for a dead plan.',
      );
      expect(confirmed.renewal.renewsAt, isNull);
    });

    test('an EXPIRED grace period stops reporting the grant as live', () {
      // 116.40 reconciliation rule: payment_failed grants active_grace only
      // up to grace_end; after that the entitlement reports lapsed. Measured:
      // the grant window ran to 2027-01-01, so a lapsed grace still answered
      // `granted` six months later — the user kept a feature the payment
      // failure had already ended.
      final inGrace = _annual().enterGrace(
        at: _utc(2026, 6, 1),
        endsAt: _utc(2026, 6, 8),
      );

      expect(
        inGrace.entitlementStateAt('export.pdf', _utc(2026, 6, 2)),
        EntitlementState.granted,
        reason: 'Inside the grace window the paid entitlement still stands.',
      );
      expect(inGrace.gracePhaseAt(_utc(2026, 6, 9)), GracePhase.expired);

      expect(
        inGrace.entitlementStateAt('export.pdf', _utc(2026, 6, 9)),
        EntitlementState.denied,
        reason: 'The grace window closed, so the entitlement is lapsed.',
      );
      expect(inGrace.hasEntitlement('export.pdf', _utc(2026, 6, 9)), isFalse);
      expect(
        inGrace.entitlementStateAt('export.pdf', _utc(2026, 12, 9)),
        EntitlementState.denied,
        reason: 'A lapsed grace does not revive itself six months later.',
      );
    });

    test(
      'a cancellation effective during grace still revokes at that instant',
      () {
        final inGrace = _annual().enterGrace(
          at: _utc(2026, 6, 1),
          endsAt: _utc(2026, 6, 8),
        );
        final scheduled = inGrace.scheduleCancellation(
          at: _utc(2026, 6, 2),
          effectiveAt: _utc(2026, 6, 9),
        );

        expect(
          scheduled.entitlementStateAt('export.pdf', _utc(2026, 6, 7)),
          EntitlementState.granted,
          reason:
              'The cancellation is not effective yet, and the grace window '
              'is still open.',
        );
        expect(
          scheduled.entitlementStateAt('export.pdf', _utc(2026, 6, 10)),
          EntitlementState.denied,
          reason: 'The cancellation is effective and the grace has lapsed.',
        );
        expect(
          scheduled
              .confirmCancellation(at: _utc(2026, 6, 9))
              .cancellation
              .state,
          CancellationState.cancelled,
        );
      },
    );
  });
}
