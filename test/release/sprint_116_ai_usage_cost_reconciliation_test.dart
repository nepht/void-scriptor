import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_ai_usage_cost_reconciliation.dart';

void main() {
  group('116.27 AI Usage & Cost Reconciliation', () {
    test('locks the seven canonical acceptance fields', () {
      expect(Sprint116AiUsageCostContract.acceptance, <String>[
        'usage_units',
        'app_credit_separation',
        'provider_cost',
        'estimated_label',
        'currency',
        'freshness',
        'budget_alert',
      ]);
    });

    test('reconciles usage while keeping application credits separate', () {
      final report = Sprint116AiUsageCostReconciliation().evaluate(
        records: [
          Sprint116AiUsageCostRecord(
            providerId: 'openai',
            usageUnits: 1200,
            providerCost: 0.12,
            currency: 'usd',
            isEstimate: true,
            measuredAt: DateTime.utc(2026, 9, 28, 1),
          ),
        ],
        applicationCreditsRemaining: 42,
        now: DateTime.utc(2026, 9, 28, 2),
        budget: 1,
      );
      expect(report.state, Sprint116AiUsageCostState.pass);
      expect(report.totalUsageUnits, 1200);
      expect(report.providerCost, 0.12);
      expect(report.applicationCreditsRemaining, 42);
      expect(report.providerCost, isNot(report.applicationCreditsRemaining));
      expect(report.costLabel, 'Estimated');
      expect(report.currency, 'USD');
      expect(report.freshness, Sprint116AiFreshness.fresh);
      expect(report.budgetAlert, isFalse);
    });

    test(
      'marks stale data and budget overrun without fabricating a balance',
      () {
        final report = Sprint116AiUsageCostReconciliation().evaluate(
          records: [
            Sprint116AiUsageCostRecord(
              providerId: 'gemini',
              usageUnits: 3,
              providerCost: 2,
              currency: 'eur',
              isEstimate: false,
              measuredAt: DateTime.utc(2026, 9, 20),
            ),
          ],
          applicationCreditsRemaining: null,
          now: DateTime.utc(2026, 9, 28),
          budget: 1,
        );
        expect(report.state, Sprint116AiUsageCostState.pass);
        expect(report.applicationCreditsAvailable, isFalse);
        expect(report.freshness, Sprint116AiFreshness.stale);
        expect(report.budgetAlert, isTrue);
        expect(report.costLabel, 'Reported');
      },
    );

    test(
      'fails closed for mixed currencies, invalid units, or missing records',
      () {
        final report = Sprint116AiUsageCostReconciliation().evaluate(
          records: [
            Sprint116AiUsageCostRecord(
              providerId: 'a',
              usageUnits: 1,
              providerCost: 1,
              currency: 'USD',
              isEstimate: false,
              measuredAt: DateTime.utc(2026, 9, 28),
            ),
            Sprint116AiUsageCostRecord(
              providerId: 'b',
              usageUnits: 1,
              providerCost: 1,
              currency: 'EUR',
              isEstimate: false,
              measuredAt: DateTime.utc(2026, 9, 28),
            ),
          ],
          applicationCreditsRemaining: null,
          now: DateTime.utc(2026, 9, 28),
          budget: 10,
        );
        expect(report.state, Sprint116AiUsageCostState.fail);
        expect(report.invalidReasons, contains('currency'));
      },
    );
  });
}
