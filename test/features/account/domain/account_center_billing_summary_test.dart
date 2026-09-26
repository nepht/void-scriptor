import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_billing_summary.dart';
import 'package:void_scriptor/features/account/domain/account_center_subscription_entitlement_model.dart'
    show PlanBillingCycle;

const String _productSpecPath =
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
    'referenced-chatgpt-conversation-this-is-an-2/outputs/'
    'account_cloud_center_spec.json';

void main() {
  group('AccountCenterBillingSummary', () {
    test('manifest preserves every canonical 115.35 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_billing_account_cost_summary.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.35');
      expect(manifest['acceptance'], <String>[
        'billing_identity',
        'currency',
        'tax',
        'billing_cycle',
        'charges',
        'credits',
        'estimated_label',
        'status',
      ]);
      expect(
        manifest['implementation'],
        'lib/features/account/domain/account_center_billing_summary.dart',
      );
      expect(
        manifest['evidence'],
        'test/features/account/domain/account_center_billing_summary_test.dart',
      );
    });

    test('product-spec billing contract stays PLANNED_NOT_VERIFIED', () {
      final spec =
          jsonDecode(File(_productSpecPath).readAsStringSync())
              as Map<String, Object?>;
      final billing = spec['billing_contract'] as Map<String, Object?>;

      expect(
        billing['status'],
        AccountCenterBillingSummary.billingContractStatus,
      );
      expect(
        billing['separation'],
        containsAll(<String>[
          'subscription',
          'application_credits',
          'tax',
          'invoice',
        ]),
      );
      expect(billing['rules'], contains('Never store raw card data.'));
    });

    test('billing identity is required, trimmed, and never blank', () {
      final summary = _summary();
      expect(summary.identity.billingId, 'bill-001');
      expect(summary.identity.displayName, 'Choirudin');
      expect(summary.identity.contactEmail, 'choirudin@example.invalid');

      final minimal = BillingIdentity(
        billingId: '  bill-002  ',
        displayName: 'Minimal',
      );
      expect(minimal.billingId, 'bill-002');
      expect(minimal.contactEmail, isNull);

      expect(
        () => BillingIdentity(billingId: '   ', displayName: 'X'),
        throwsArgumentError,
      );
      expect(
        () => BillingIdentity(billingId: 'id', displayName: '  '),
        throwsArgumentError,
      );
      expect(
        () => BillingIdentity(
          billingId: 'id',
          displayName: 'X',
          contactEmail: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('currency is a normalized ISO 4217 code shared by every amount', () {
      final summary = _summary(currency: ' USD ');
      expect(summary.currency, 'usd');
      expect(
        summary.charges.every((charge) => charge.currency == 'usd'),
        isTrue,
      );
      expect(summary.credits.currency, 'usd');
      expect(summary.estimate!.currency, 'usd');

      expect(() => _summary(currency: 'US'), throwsArgumentError);
      expect(() => _summary(currency: '1us'), throwsArgumentError);
      expect(
        () => _summary(
          charges: [_charge(chargeId: 'ch-eur', currency: 'eur')],
        ),
        throwsArgumentError,
      );
      expect(
        () => _summary(
          credits: CreditBalance(
            currency: 'eur',
            amount: 5,
            asOf: DateTime.utc(2026, 9, 26),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => _summary(
          estimate: BillingEstimate(
            amount: 9.99,
            currency: 'eur',
            label: 'Estimated next invoice',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('tax separates applies, does not apply, and unavailable', () {
      final summary = _summary();
      expect(summary.tax.status, TaxStatus.applies);
      expect(summary.tax.rate, 10);
      expect(summary.tax.regionCode, 'id');

      final exempt = BillingTax(status: TaxStatus.doesNotApply);
      expect(exempt.rate, isNull);
      expect(exempt.regionCode, isNull);

      final unavailable = BillingTax(status: TaxStatus.unavailable);
      expect(unavailable.rate, isNull);
      expect(unavailable.regionCode, isNull);

      expect(() => BillingTax(status: TaxStatus.applies), throwsArgumentError);
      expect(
        () => BillingTax(status: TaxStatus.applies, rate: 10),
        throwsArgumentError,
      );
      expect(
        () =>
            BillingTax(status: TaxStatus.applies, rate: 10, regionCode: '   '),
        throwsArgumentError,
      );
      expect(
        () => BillingTax(
          status: TaxStatus.doesNotApply,
          rate: 0,
          regionCode: 'id',
        ),
        throwsArgumentError,
      );
      expect(
        () => BillingTax(status: TaxStatus.unavailable, rate: 0),
        throwsArgumentError,
      );
      expect(
        () => BillingTax(status: TaxStatus.unavailable, regionCode: 'id'),
        throwsArgumentError,
      );
      expect(
        () => BillingTax(status: TaxStatus.applies, rate: -1, regionCode: 'id'),
        throwsArgumentError,
      );
      expect(
        () =>
            BillingTax(status: TaxStatus.applies, rate: 101, regionCode: 'id'),
        throwsArgumentError,
      );
      expect(
        () => BillingTax(
          status: TaxStatus.applies,
          rate: double.nan,
          regionCode: 'id',
        ),
        throwsArgumentError,
      );
    });

    test('billing cycle binds a paid period and frees a none cycle', () {
      final summary = _summary();
      expect(summary.cycle.cycle, PlanBillingCycle.monthly);
      expect(summary.cycle.periodStart, DateTime.utc(2026, 9, 1));
      expect(summary.cycle.periodEnd, DateTime.utc(2026, 10, 1));

      final free = BillingCycleInfo(cycle: PlanBillingCycle.none);
      expect(free.periodStart, isNull);
      expect(free.periodEnd, isNull);

      expect(
        () => BillingCycleInfo(
          cycle: PlanBillingCycle.none,
          periodStart: DateTime.utc(2026, 9, 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => BillingCycleInfo(cycle: PlanBillingCycle.monthly),
        throwsArgumentError,
      );
      expect(
        () => BillingCycleInfo(
          cycle: PlanBillingCycle.monthly,
          periodStart: DateTime.utc(2026, 9, 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => BillingCycleInfo(
          cycle: PlanBillingCycle.monthly,
          periodStart: DateTime.utc(2026, 10, 1),
          periodEnd: DateTime.utc(2026, 9, 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => BillingCycleInfo(
          cycle: PlanBillingCycle.yearly,
          periodStart: DateTime(2026, 9, 1),
          periodEnd: DateTime.utc(2027, 9, 1),
        ),
        throwsArgumentError,
      );
    });

    test('charges stay unique, UTC, non-negative, and immutable', () {
      final summary = _summary();
      expect(summary.charges.map((charge) => charge.chargeId), <String>[
        'ch-001',
        'ch-002',
      ]);
      expect(() => summary.charges.clear(), throwsUnsupportedError);
      // Money is summed in minor units: 9.99 + 10 must not leak 19.990000000000002.
      expect(summary.chargesTotal, 19.99);

      // A voided charge is never owed, so it leaves the total.
      final withVoided = _summary(
        charges: [
          _charge(
            chargeId: 'ch-void',
            amount: 5,
            status: BillingChargeStatus.voided,
          ),
        ],
      );
      expect(withVoided.chargesTotal, 0);

      expect(() => _charge(chargeId: '   '), throwsArgumentError);
      expect(() => _charge(description: '  '), throwsArgumentError);
      expect(() => _charge(amount: -0.01), throwsArgumentError);
      expect(() => _charge(amount: double.infinity), throwsArgumentError);
      expect(
        () => _charge(issuedAt: DateTime(2026, 9, 1)),
        throwsArgumentError,
      );
      expect(
        () => _summary(
          charges: [
            _charge(chargeId: 'ch-001'),
            _charge(chargeId: 'ch-001'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('credits never fabricate a balance when unavailable', () {
      final summary = _summary();
      expect(summary.credits.amount, 42.5);
      expect(summary.credits.asOf, DateTime.utc(2026, 9, 26));

      // Delivery rule: mock_credit_in_production_allowed = false. Unknown is
      // explicit null, never a fabricated zero.
      final unavailable = CreditBalance(currency: 'usd');
      expect(unavailable.amount, isNull);
      expect(unavailable.asOf, isNull);

      expect(
        () => CreditBalance(
          currency: 'usd',
          amount: -1,
          asOf: DateTime.utc(2026, 9, 26),
        ),
        throwsArgumentError,
      );
      expect(
        () => CreditBalance(
          currency: 'usd',
          amount: double.nan,
          asOf: DateTime.utc(2026, 9, 26),
        ),
        throwsArgumentError,
      );
      expect(
        () => CreditBalance(currency: 'usd', amount: 10),
        throwsArgumentError,
      );
      expect(
        () => CreditBalance(currency: 'usd', asOf: DateTime.utc(2026, 9, 26)),
        throwsArgumentError,
      );
      expect(
        () => CreditBalance(
          currency: 'usd',
          amount: 10,
          asOf: DateTime(2026, 9, 26),
        ),
        throwsArgumentError,
      );
    });

    test('every estimate carries an explicit estimate label', () {
      final summary = _summary();
      expect(summary.estimate, isNotNull);
      expect(summary.estimate!.label, 'Estimated next invoice');
      expect(summary.estimate!.isEstimate, isTrue);
      expect(summary.estimate!.amount, 9.99);
      expect(summary.estimate!.generatedAt, DateTime.utc(2026, 9, 26));

      // No estimate available is an explicit null, never a fabricated zero.
      final noEstimate = _summary(includeEstimate: false);
      expect(noEstimate.estimate, isNull);

      expect(
        () => BillingEstimate(amount: 1, currency: 'usd', label: '   '),
        throwsArgumentError,
      );
      expect(
        () => BillingEstimate(amount: -1, currency: 'usd', label: 'Estimated'),
        throwsArgumentError,
      );
      expect(
        () => BillingEstimate(
          amount: 1,
          currency: 'usd',
          label: 'Estimated',
          generatedAt: DateTime(2026, 9, 26),
        ),
        throwsArgumentError,
      );
      expect(
        () => BillingEstimate(amount: 1, currency: 'U', label: 'Estimated'),
        throwsArgumentError,
      );
    });

    test('billing status is an explicit vocabulary with timestamped debt', () {
      final summary = _summary();
      expect(summary.status.status, BillingStatus.active);
      expect(summary.status.asOf, DateTime.utc(2026, 9, 26));
      expect(summary.status.reason, isNull);

      final unknown = BillingStatusInfo(status: BillingStatus.unknown);
      expect(unknown.asOf, isNull);
      expect(unknown.reason, isNull);

      expect(
        () => BillingStatusInfo(status: BillingStatus.pastDue),
        throwsArgumentError,
      );
      expect(
        () => BillingStatusInfo(status: BillingStatus.unpaid),
        throwsArgumentError,
      );
      expect(
        () => BillingStatusInfo(
          status: BillingStatus.active,
          reason: 'delinquent',
        ),
        throwsArgumentError,
      );
      expect(
        () => BillingStatusInfo(
          status: BillingStatus.pastDue,
          asOf: DateTime(2026, 9, 26),
        ),
        throwsArgumentError,
      );
      expect(
        () => BillingStatusInfo(status: BillingStatus.paused, reason: '   '),
        throwsArgumentError,
      );

      final pastDue = BillingStatusInfo(
        status: BillingStatus.pastDue,
        asOf: DateTime.utc(2026, 9, 26),
        reason: 'Invoice ch-001 unpaid',
      );
      expect(pastDue.reason, 'Invoice ch-001 unpaid');
    });

    test(
      'aggregate fail-closes on mismatched data across the eight fields',
      () {
        final summary = _summary();
        expect(summary.identity, isA<BillingIdentity>());
        expect(summary.currency, isA<String>());
        expect(summary.tax, isA<BillingTax>());
        expect(summary.cycle, isA<BillingCycleInfo>());
        expect(summary.charges, isA<List<BillingCharge>>());
        expect(summary.credits, isA<CreditBalance>());
        expect(summary.estimate, isA<BillingEstimate?>());
        expect(summary.status, isA<BillingStatusInfo>());
        expect(
          AccountCenterBillingSummary.billingContractStatus,
          'PLANNED_NOT_VERIFIED',
        );

        expect(
          () => _summary(charges: [_charge(currency: 'gbp')]),
          throwsArgumentError,
        );
        expect(
          () => _summary(
            credits: CreditBalance(
              currency: 'gbp',
              amount: 1,
              asOf: DateTime.utc(2026, 9, 26),
            ),
          ),
          throwsArgumentError,
        );
        expect(
          () => _summary(
            estimate: BillingEstimate(
              amount: 1,
              currency: 'gbp',
              label: 'Estimated',
            ),
          ),
          throwsArgumentError,
        );
      },
    );
  });
}

AccountCenterBillingSummary _summary({
  String currency = 'usd',
  List<BillingCharge>? charges,
  CreditBalance? credits,
  BillingEstimate? estimate,
  bool includeEstimate = true,
}) => AccountCenterBillingSummary(
  identity: BillingIdentity(
    billingId: 'bill-001',
    displayName: 'Choirudin',
    contactEmail: 'choirudin@example.invalid',
  ),
  currency: currency,
  tax: BillingTax(status: TaxStatus.applies, rate: 10, regionCode: 'id'),
  cycle: BillingCycleInfo(
    cycle: PlanBillingCycle.monthly,
    periodStart: DateTime.utc(2026, 9, 1),
    periodEnd: DateTime.utc(2026, 10, 1),
  ),
  charges:
      charges ??
      [_charge(), _charge(chargeId: 'ch-002', amount: 10, currency: currency)],
  credits:
      credits ??
      CreditBalance(
        currency: currency,
        amount: 42.5,
        asOf: DateTime.utc(2026, 9, 26),
      ),
  estimate:
      estimate ??
      (includeEstimate
          ? BillingEstimate(
              amount: 9.99,
              currency: currency,
              label: 'Estimated next invoice',
              generatedAt: DateTime.utc(2026, 9, 26),
            )
          : null),
  status: BillingStatusInfo(
    status: BillingStatus.active,
    asOf: DateTime.utc(2026, 9, 26),
  ),
);

BillingCharge _charge({
  String chargeId = 'ch-001',
  String description = 'Pro plan',
  double amount = 9.99,
  String currency = 'usd',
  BillingChargeStatus status = BillingChargeStatus.paid,
  DateTime? issuedAt,
}) => BillingCharge(
  chargeId: chargeId,
  description: description,
  amount: amount,
  currency: currency,
  status: status,
  issuedAt: issuedAt ?? DateTime.utc(2026, 9, 1),
);
