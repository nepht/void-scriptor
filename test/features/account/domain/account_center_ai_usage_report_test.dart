import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_ai_usage_credits_cost_view.dart';
import 'package:void_scriptor/features/account/domain/account_center_ai_usage_report.dart';

const String _productSpecPath =
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
    'referenced-chatgpt-conversation-this-is-an-2/outputs/'
    'account_cloud_center_spec.json';

final DateTime _now = DateTime.utc(2026, 9, 26, 12);

BillingPeriod _period(int year, int month) =>
    BillingPeriod.month(year: year, month: month);

ProviderUsageRecord _record({
  String providerId = 'openai',
  String modelId = 'gpt-5.6',
  AiUsageType usageType = AiUsageType.tokens,
  double quantity = 1000,
  String unit = 'tokens',
  double? estimatedCost = 1.5,
  String? currency = 'usd',
  BillingPeriod? billingPeriod,
  DateTime? measuredAt,
  AiUsageSource source = AiUsageSource.providerApi,
  bool isEstimate = false,
}) => ProviderUsageRecord(
  providerId: providerId,
  modelId: modelId,
  usageType: usageType,
  quantity: quantity,
  unit: unit,
  estimatedCost: estimatedCost,
  currency: currency,
  billingPeriod: billingPeriod ?? _period(2026, 8),
  measuredAt: measuredAt ?? DateTime.utc(2026, 8, 20),
  source: source,
  isEstimate: isEstimate,
);

List<ProviderUsageRecord> _records(Iterable<ProviderUsageRecord> items) =>
    items.toList(growable: false);

AccountCenterAiUsageReport _report(
  Iterable<ProviderUsageRecord> records, {
  AiUsageFilter? filter,
  DateTime? now,
  AiUsageFreshnessPolicy? freshness,
}) => AccountCenterAiUsageReport.build(
  view: AccountCenterAiUsageCreditsCostView(
    applicationCredits: ApplicationCreditBalance.available(
      remaining: 250,
      measuredAt: _now,
    ),
    providerUsage: records,
  ),
  filter: filter ?? AiUsageFilter.all(),
  now: now ?? _now,
  freshness: freshness,
);

void main() {
  group('AccountCenterAiUsageReport', () {
    test('manifest preserves every canonical 115.40 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_ai_usage_chart_detail_table.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.40');
      expect(manifest['acceptance'], <String>[
        'chart',
        'text_summary',
        'data_table',
        'filters',
        'freshness',
        'estimate_label',
        'empty_state',
      ]);
      expect(
        manifest['implementation'],
        'lib/features/account/domain/account_center_ai_usage_report.dart',
      );
      expect(
        manifest['evidence'],
        'test/features/account/domain/account_center_ai_usage_report_test.dart',
      );
    });

    test('acceptance list is pinned to canonical sprint 115.40', () {
      final file = File(AccountCenterAiUsageReport.canonicalSprintPath);
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final step = (json['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '115.40');

      expect(step['title'], 'AI Usage Chart & Detail Table');
      expect(
        step['acceptance'],
        AccountCenterAiUsageReport.canonicalAcceptance,
      );
      expect(
        AccountCenterAiUsageReport.canonicalSprintSha256,
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
      );
    });

    test('product spec keeps estimate marking and analytics privacy rules', () {
      final spec =
          jsonDecode(File(_productSpecPath).readAsStringSync())
              as Map<String, Object?>;
      final contract = spec['ai_usage_contract'] as Map<String, Object?>;

      expect(
        (contract['rules'] as List<dynamic>),
        contains('Mark estimated costs clearly.'),
      );
      expect(
        (contract['rules'] as List<dynamic>),
        contains('Separate application credits from provider billing.'),
      );
      expect(
        (contract['rules'] as List<dynamic>),
        contains(
          'Do not include prompt or creative content in usage analytics.',
        ),
      );
      expect(
        (contract['rules'] as List<dynamic>),
        contains(
          'Never claim provider balance when the provider does not expose it.',
        ),
      );
      expect(
        (spec['acceptance_invariants'] as List<dynamic>),
        contains(
          'storage_and_credit_values_are_api_backed_or_explicitly_unavailable',
        ),
      );
      expect((spec['ui_states'] as List<dynamic>), contains('EMPTY'));
      expect((spec['ui_states'] as List<dynamic>), contains('PARTIAL_DATA'));
    });

    test('external gates stay declared, never claimed', () {
      expect(
        AccountCenterAiUsageReport.billingContractStatus,
        'PLANNED_NOT_VERIFIED',
      );
      expect(AccountCenterAiUsageReport.referenceMockValuesAllowed, isFalse);
      expect(
        AccountCenterAiUsageReport.externalGateStatus,
        'DEFERRED-EXTERNAL',
      );
    });

    group('chart', () {
      test('bars carry a non-blank text alternative', () {
        final report = _report(_records([_record()]));

        for (final series in report.chart.series) {
          expect(series.textAlternative.trim(), isNotEmpty);
          for (final bar in series.bars) {
            expect(bar.textAlternative.trim(), isNotEmpty);
            expect(bar.textAlternative, contains(series.unit));
          }
        }
      });

      test('a usage type is never summed across different units', () {
        final report = _report(
          _records([
            _record(quantity: 1000, unit: 'tokens'),
            _record(usageType: AiUsageType.images, quantity: 4, unit: 'images'),
          ]),
        );

        final tokens = report.seriesFor(
          const AiUsageSeriesKey(AiUsageType.tokens, 'tokens'),
        );
        final images = report.seriesFor(
          const AiUsageSeriesKey(AiUsageType.images, 'images'),
        );

        expect(tokens, isNotNull);
        expect(images, isNotNull);
        expect(tokens!.bars.single.quantity, 1000);
        expect(images!.bars.single.quantity, 4);
        expect(report.chart.series, hasLength(2));
      });

      test('a missing period is a gap, never a zero', () {
        final report = _report(
          _records([
            _record(
              billingPeriod: _period(2026, 6),
              measuredAt: DateTime.utc(2026, 6, 10),
            ),
            _record(
              billingPeriod: _period(2026, 8),
              measuredAt: DateTime.utc(2026, 8, 10),
            ),
          ]),
        );

        final series = report.seriesFor(
          const AiUsageSeriesKey(AiUsageType.tokens, 'tokens'),
        )!;
        expect(series.bars.map((bar) => bar.period.label), <String>[
          '2026-06',
          '2026-07',
          '2026-08',
        ]);
        final gap = series.bars[1];
        expect(gap.hasData, isFalse);
        expect(gap.quantity, isNull);
        expect(gap.textAlternative.toLowerCase(), contains('no data'));
      });

      test('a series with a zero maximum is unrenderable, not divided', () {
        final report = _report(
          _records([_record(quantity: 0, estimatedCost: 0)]),
        );

        final series = report.seriesFor(
          const AiUsageSeriesKey(AiUsageType.tokens, 'tokens'),
        )!;
        expect(series.maxQuantity, 0);
        expect(series.isRenderable, isFalse);
        expect(series.textAlternative.trim(), isNotEmpty);
        expect(report.chart.hasRenderableSeries, isFalse);
      });

      test('bars are ordered by period and the axis is bounded', () {
        final report = _report(
          _records([
            _record(
              billingPeriod: _period(2026, 8),
              measuredAt: DateTime.utc(2026, 8, 10),
            ),
            _record(
              billingPeriod: _period(2026, 6),
              measuredAt: DateTime.utc(2026, 6, 10),
            ),
          ]),
        );

        final series = report.seriesFor(
          const AiUsageSeriesKey(AiUsageType.tokens, 'tokens'),
        )!;
        expect(series.bars.map((bar) => bar.period.label).toList(), <String>[
          '2026-06',
          '2026-07',
          '2026-08',
        ]);
        expect(() {
          _report(
            _records([
              _record(
                billingPeriod: _period(1990, 1),
                measuredAt: DateTime.utc(1990, 1, 5),
              ),
              _record(
                billingPeriod: _period(2026, 8),
                measuredAt: DateTime.utc(2026, 8, 5),
              ),
            ]),
          );
        }, throwsA(isA<StateError>()));
      });
    });

    group('text_summary', () {
      test('a summary is always produced, including with no data', () {
        final report = _report(const []);

        expect(report.textSummary.trim(), isNotEmpty);
        expect(report.isEmpty, isTrue);
        expect(report.textSummary, contains('No AI usage'));
      });

      test('a summary with estimates never states an exact cost total', () {
        final report = _report(
          _records([_record(estimatedCost: 12.5, isEstimate: true)]),
        );

        expect(report.costIsExact, isFalse);
        expect(report.textSummary.toLowerCase(), contains('estimated'));
        expect(report.textSummary, isNot(contains('exact')));
      });

      test('a summary of reported-only data may state the exact total', () {
        final report = _report(
          _records([
            _record(estimatedCost: 10, isEstimate: false),
            _record(estimatedCost: 2.5, isEstimate: false),
          ]),
        );

        expect(report.costIsExact, isTrue);
        expect(report.textSummary, contains('12.5'));
        expect(report.textSummary, isNot(contains('Estimated')));
      });

      test('the summary names the freshness it is describing', () {
        final report = _report(
          _records([
            _record(
              billingPeriod: _period(2026, 9),
              measuredAt: DateTime.utc(2026, 9, 26, 11),
            ),
            // 3.5 days old: inside the stale band the policy defines.
            _record(
              billingPeriod: _period(2026, 8),
              measuredAt: DateTime.utc(2026, 9, 23),
            ),
          ]),
        );

        expect(report.textSummary.toLowerCase(), contains('stale'));
        expect(report.freshnessCounts[AiUsageFreshness.stale]!, greaterThan(0));
        expect(report.freshnessCounts[AiUsageFreshness.live]!, greaterThan(0));
      });
    });

    group('data_table', () {
      test('the table has one row per surviving record', () {
        final report = _report(
          _records([
            _record(providerId: 'openai'),
            _record(providerId: 'gemini'),
            _record(providerId: 'deepseek'),
          ]),
        );

        expect(report.rows, hasLength(3));
        expect(report.rows.map((row) => row.providerId).toSet(), <String>{
          'openai',
          'gemini',
          'deepseek',
        });
      });

      test('a row exposes only the closed public field set', () {
        final report = _report(_records([_record()]));
        final json = report.rows.single.toPublicJson();

        expect(json.keys.toSet(), AiUsageRow.publicFields.toSet());
        expect(
          json.keys.map((key) => key.toLowerCase()).toList(),
          isNot(
            contains(
              anyOf(contains('prompt'), contains('content'), contains('text')),
            ),
          ),
        );
        expect(json['source'], 'provider_api');
        expect(json['unit'], 'tokens');
        expect(json['billing_period'], '2026-08');
      });

      test('cost cells are labelled from the record, never invented', () {
        final report = _report(
          _records([
            _record(estimatedCost: 1.25, isEstimate: true),
            _record(estimatedCost: 3, isEstimate: false),
            _record(estimatedCost: null, currency: null),
          ]),
        );

        expect(report.rows[0].costLabel, 'Estimated');
        expect(report.rows[1].costLabel, 'Reported');
        expect(report.rows[2].costLabel, 'Cost unavailable');
        expect(report.rows[2].costAmount, isNull);
        expect(report.rows[2].costText, 'Cost unavailable');
      });

      test('a row with no cost is never displayed as zero', () {
        final report = _report(
          _records([_record(estimatedCost: null, currency: null)]),
        );

        expect(report.rows.single.costText, isNot(contains('0')));
        expect(report.costTotals, isEmpty);
      });
    });

    group('filters', () {
      test('a provider filter narrows the rows and reports what it hid', () {
        final all = _records([
          _record(providerId: 'openai'),
          _record(providerId: 'gemini'),
          _record(providerId: 'deepseek'),
        ]);
        final report = _report(
          all,
          filter: AiUsageFilter(providerIds: <String>{'openai'}),
        );

        expect(report.rows, hasLength(1));
        expect(report.totalRecordCount, 3);
        expect(report.hiddenRecordCount, 2);
        expect(report.filtersAreNarrowing, isTrue);
        expect(report.textSummary, contains('2'));
      });

      test('model, usage type, estimate, and period filters compose', () {
        final all = _records([
          _record(modelId: 'gpt-5.6', quantity: 1, estimatedCost: 1),
          _record(modelId: 'gpt-5.6-mini', quantity: 2, estimatedCost: 2),
          _record(
            modelId: 'gpt-5.6',
            usageType: AiUsageType.images,
            unit: 'images',
            quantity: 3,
            estimatedCost: 3,
          ),
          _record(
            modelId: 'gpt-5.6',
            billingPeriod: _period(2026, 1),
            measuredAt: DateTime.utc(2026, 1, 9),
            quantity: 4,
            estimatedCost: 4,
          ),
          _record(isEstimate: true, quantity: 5, estimatedCost: 5),
        ]);

        final report = _report(
          all,
          filter: AiUsageFilter(
            providerIds: <String>{'openai'},
            modelIds: <String>{'gpt-5.6'},
            usageTypes: <AiUsageType>{AiUsageType.tokens},
            periodFrom: null,
            periodTo: null,
            includeEstimates: false,
          ),
        );

        expect(
          report.rows.map((row) => row.quantity).toList()..sort(),
          // Record 4 is the only other openai/gpt-5.6/tokens/reported record:
          // its January period is inside the (absent) range filter.
          <double>[1, 4],
        );
        expect(report.totalRecordCount, 5);
        expect(report.hiddenRecordCount, 3);
      });

      test('a period range filter keeps only records inside the range', () {
        final all = _records([
          _record(billingPeriod: _period(2026, 5)),
          _record(
            billingPeriod: _period(2026, 6),
            measuredAt: DateTime.utc(2026, 6, 4),
          ),
          _record(
            billingPeriod: _period(2026, 7),
            measuredAt: DateTime.utc(2026, 7, 4),
          ),
        ]);

        final report = _report(
          all,
          filter: AiUsageFilter(
            periodFrom: AiUsagePeriodBound(2026, 6),
            periodTo: AiUsagePeriodBound(2026, 7),
          ),
        );

        expect(report.rows, hasLength(2));
        expect(report.rows.first.period.label, '2026-06');
        expect(report.rows.last.period.label, '2026-07');
      });

      test('an inverted period range is rejected instead of matching all', () {
        expect(
          () => AiUsageFilter(
            periodFrom: AiUsagePeriodBound(2026, 8),
            periodTo: AiUsagePeriodBound(2026, 2),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('an unknown filter value fails closed to an empty report', () {
        final all = _records([_record(providerId: 'openai')]);
        final report = _report(
          all,
          filter: AiUsageFilter(providerIds: <String>{'not-a-provider'}),
        );

        expect(report.rows, isEmpty);
        expect(report.unknownFilterValues, contains('not-a-provider'));
        expect(report.isEmpty, isTrue);
        expect(report.emptyReason, AiUsageEmptyReason.filteredOut);
        expect(report.textSummary.toLowerCase(), contains('not-a-provider'));
      });
    });

    group('freshness', () {
      test('rows are aged against the injected clock, not the wall clock', () {
        final report = _report(
          _records([
            // 1 hour before the injected clock: live.
            _record(
              billingPeriod: _period(2026, 9),
              measuredAt: DateTime.utc(2026, 9, 26, 11),
            ),
            // 3.5 days before: past staleAfter (48h), inside expiresAfter (7d).
            _record(
              billingPeriod: _period(2026, 8),
              measuredAt: DateTime.utc(2026, 9, 23),
            ),
            // 56 days before: expired.
            _record(
              billingPeriod: _period(2026, 7),
              measuredAt: DateTime.utc(2026, 8, 1),
            ),
          ]),
        );

        final byLabel = <String, AiUsageFreshness>{
          for (final row in report.rows) row.period.label: row.freshness,
        };
        expect(byLabel['2026-09'], AiUsageFreshness.live);
        expect(byLabel['2026-08'], AiUsageFreshness.stale);
        expect(byLabel['2026-07'], AiUsageFreshness.expired);
      });

      test('a future timestamp is flagged, never counted as fresh', () {
        final report = _report(
          _records([_record(measuredAt: DateTime.utc(2026, 10, 5))]),
        );

        expect(
          report.rows.single.freshness,
          AiUsageFreshness.futureTimestamped,
        );
        expect(report.rows.single.isCurrent, isFalse);
        expect(report.freshnessCounts[AiUsageFreshness.futureTimestamped]!, 1);
        expect(report.costIsCurrent, isFalse);
      });

      test('a stale or expired row is never presented as current', () {
        final report = _report(
          _records([
            _record(
              billingPeriod: _period(2026, 7),
              measuredAt: DateTime.utc(2026, 7, 1),
            ),
            _record(
              billingPeriod: _period(2026, 6),
              measuredAt: DateTime.utc(2026, 6, 1),
            ),
          ]),
        );

        for (final row in report.rows) {
          expect(row.isCurrent, isFalse);
        }
        expect(report.costIsCurrent, isFalse);
        expect(report.freshnessLabel, isNotEmpty);
        expect(report.lastUpdatedAt, isNotNull);
      });

      test('an all-live report reports a real last-updated stamp', () {
        final report = _report(
          _records([_record(measuredAt: DateTime.utc(2026, 9, 26, 10))]),
        );

        expect(report.lastUpdatedAt, DateTime.utc(2026, 9, 26, 10));
        expect(report.costIsCurrent, isTrue);
        expect(report.freshnessLabel.trim(), isNotEmpty);
      });

      test('a missing freshness policy window is rejected', () {
        expect(
          () => AiUsageFreshnessPolicy(staleAfter: const Duration(days: -1)),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => AiUsageFreshnessPolicy(staleAfter: const Duration(days: 9)),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('estimate_label', () {
      test('totals are grouped per currency and never mixed', () {
        final report = _report(
          _records([
            _record(estimatedCost: 10, currency: 'usd'),
            _record(estimatedCost: 20, currency: 'eur'),
            _record(estimatedCost: 5, currency: 'usd'),
          ]),
        );

        expect(report.costTotals, hasLength(2));
        final usd = report.costTotals.firstWhere(
          (total) => total.currency == 'USD',
        );
        expect(usd.subtotal, 15);
        expect(usd.label, 'Reported');
      });

      test('a group missing one cost refuses to sum the rest', () {
        final report = _report(
          _records([
            _record(estimatedCost: 10, isEstimate: false),
            _record(estimatedCost: null, currency: null),
          ]),
        );

        final total = report.costTotals.single;
        expect(total.subtotal, isNull);
        expect(total.recordsMissingCost, 1);
        expect(total.reason, isNotEmpty);
        expect(total.label, contains('Incomplete'));
      });

      test('a mixed-estimate bucket is labelled estimated, never exact', () {
        final report = _report(
          _records([
            _record(estimatedCost: 10, isEstimate: false),
            _record(estimatedCost: 5, isEstimate: true),
          ]),
        );

        final total = report.costTotals.single;
        expect(total.isEstimate, isTrue);
        expect(total.label, 'Estimated');
        expect(report.costIsExact, isFalse);
      });
    });

    group('empty_state', () {
      test('no data at all is distinct from data the filter excluded', () {
        final empty = _report(const []);
        final filtered = _report(
          _records([_record()]),
          filter: AiUsageFilter(modelIds: <String>{'other-model'}),
        );

        expect(empty.emptyReason, AiUsageEmptyReason.noData);
        expect(filtered.emptyReason, AiUsageEmptyReason.filteredOut);
        expect(empty.textSummary, isNot(filtered.textSummary));
        expect(empty.rows, isEmpty);
        expect(empty.chart.series, isEmpty);
        expect(filtered.hiddenRecordCount, 1);
      });

      test('an empty report never invents a total or a zero cost', () {
        final report = _report(const []);

        expect(report.costTotals, isEmpty);
        expect(report.quantityTotals, isEmpty);
        expect(report.costIsExact, isFalse);
        expect(report.textSummary, isNot(contains('\$0')));
        expect(report.lastUpdatedAt, isNull);
      });

      test('an empty report names the ui state it represents', () {
        final report = _report(const []);

        expect(report.uiState, 'EMPTY');
        expect(report.suggestedAction.trim(), isNotEmpty);
      });
    });
  });
}
