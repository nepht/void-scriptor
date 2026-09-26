import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_ai_usage_credits_cost_view.dart';

void main() {
  group('AccountCenterAiUsageCreditsCostView', () {
    test('manifest preserves every canonical 115.26 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_ai_usage_credits_cost_view.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.26');
      expect(manifest['acceptance'], <String>[
        'app_credits_separate',
        'provider_usage',
        'estimated_label',
        'currency',
        'billing_period',
        'unavailable_state',
        'no_prompt_collection',
      ]);
    });

    test('keeps application credits separate from provider usage', () {
      final view = AccountCenterAiUsageCreditsCostView(
        applicationCredits: ApplicationCreditBalance.available(
          remaining: 24,
          measuredAt: DateTime.utc(2026, 9, 26),
        ),
        providerUsage: [
          ProviderUsageRecord(
            providerId: 'cloud',
            modelId: 'quality',
            usageType: AiUsageType.tokens,
            quantity: 1200,
            unit: 'tokens',
            estimatedCost: 0.42,
            currency: 'usd',
            billingPeriod: BillingPeriod.month(year: 2026, month: 9),
            measuredAt: DateTime.utc(2026, 9, 25),
            source: AiUsageSource.localLog,
            isEstimate: true,
          ),
        ],
      );

      expect(view.applicationCredits.remaining, 24);
      expect(view.providerUsage.single.quantity, 1200);
      expect(view.providerUsage.single.currency, 'USD');
      expect(view.providerUsage.single.costLabel, 'Estimated');
      expect(view.providerUsage.single.billingPeriod.label, '2026-09');
    });

    test('represents unavailable balances without fabricating zero', () {
      final balance = ApplicationCreditBalance.unavailable();
      final providerBalance = ProviderBalance.unavailable(providerId: 'cloud');

      expect(balance.isAvailable, isFalse);
      expect(balance.remaining, isNull);
      expect(providerBalance.isAvailable, isFalse);
      expect(providerBalance.amount, isNull);
      expect(providerBalance.currency, isNull);
    });

    test('requires exact currency, billing period, and estimate metadata', () {
      expect(
        () => ProviderUsageRecord(
          providerId: 'cloud',
          modelId: 'quality',
          usageType: AiUsageType.tokens,
          quantity: 1,
          unit: 'tokens',
          estimatedCost: 0.1,
          currency: '',
          billingPeriod: BillingPeriod.month(year: 2026, month: 9),
          measuredAt: DateTime.utc(2026, 9, 25),
          source: AiUsageSource.localLog,
          isEstimate: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => BillingPeriod.month(year: 2026, month: 13),
        throwsArgumentError,
      );
      expect(
        () => ProviderUsageRecord(
          providerId: 'cloud',
          modelId: 'quality',
          usageType: AiUsageType.tokens,
          quantity: -1,
          unit: 'tokens',
          estimatedCost: null,
          currency: null,
          billingPeriod: BillingPeriod.month(year: 2026, month: 9),
          measuredAt: DateTime.utc(2026, 9, 25),
          source: AiUsageSource.providerApi,
          isEstimate: false,
        ),
        throwsArgumentError,
      );
    });

    test('exposes usage metadata only and cannot collect prompt content', () {
      const fields = ProviderUsageRecord.publicFields;

      expect(
        fields,
        containsAll(<String>[
          'provider_id',
          'model_id',
          'usage_type',
          'quantity',
          'unit',
          'estimated_cost',
          'currency',
          'billing_period',
          'measured_at',
          'source',
          'is_estimate',
        ]),
      );
      expect(fields, isNot(contains('prompt')));
      expect(fields, isNot(contains('content')));
    });
  });
}
