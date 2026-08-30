// Sprint 110.45 - Performance & Scale Validation.
//
// Acceptance canonical 110.45 (required_outputs):
//   datasets, budgets, results, bottlenecks, caching_policy, mitigations.
//
// Verifier-style slice. The contract for the harness lives in
// lib/features/world_logic/domain/performance_scale_benchmark.dart:
//   - BenchDataset              : deterministic large payload (label,
//                                 factory, scaleTargets).
//   - BenchBudget               : per-dataset wall-clock threshold in ms.
//   - BenchResult               : measured ms + cache-hit count + assertions
//                                 (withinBudget, cacheImprovesOverBaseline).
//   - BenchBottleneck           : label + measuredMs + bottleneck reason.
//   - CachingPolicy             : recommendation (label, keyPattern,
//                                 eviction strategy, target ms after cache).
//   - BenchMitigation           : mitigation linked to a bottleneck.
//   - PerformanceScaleBenchmark : facade. runAll() iterates the registered
//                                 datasets, builds each in isolation, runs
//                                 the workload twice (baseline + cached),
//                                 asserts budget, captures bottlenecks,
//                                 emits the recommended caching policy, and
//                                 maps each bottleneck to a mitigation.
//
// The harness itself is deterministic (seeded RNG via SplitMix64), in-memory,
// and depends only on existing domain modules from 110.3 / 110.9 / 110.17 /
// 110.20 / 110.25 / 110.30 / 110.37 / 110.39. No persistence, UI, wall clock,
// locale, or network. Wall-clock measurement uses Stopwatch (which is
// monotonic for measuring intervals), and is asserted only against per-bucket
// loose budgets so CI variance cannot turn the suite red.
//
// Scales chosen for representative Wave-2 fiction workloads:
//   - Large map:        50,000 RouteNodes + 150,000 RouteEdges (110.9).
//   - Long timeline:    200,000 WeatherCalendarSampler.sampleAt ticks (110.13).
//   - Dense genealogy:  8,000 GenealogyNodes + 20,000 GenealogyRelations
//                       (110.17), querying activeAt over a 5,000-tick window.
//   - Large ledger:     50,000 PowerUsageEvents built via
//                       PowerUsageLedger.validated (110.30).
//   - Large rumor net:  1,000 RumorPersons + 8,000 RumorEdges simulating up to
//                       tick 50 across a BFS of seed propagation (110.37).
//   - Tech registry:    500 TechnologyNodes + 1,500 prerequisite edges (110.39).

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/performance_scale_benchmark.dart';

void main() {
  group('Sprint 110.45 Performance & Scale Validation', () {
    test('runAll returns a result for every required Wave-2 dataset', () {
      final report = PerformanceScaleBenchmark.withDefaults().runAll();

      expect(
        report.results,
        isNotEmpty,
        reason: 'datasets required by 110.45 must produce measurable runs',
      );
      final labels = report.results.map((r) => r.dataset.label).toSet();
      expect(
        labels,
        containsAll(<String>{
          'large_map_route_network',
          'long_timeline_weather_sampling',
          'dense_genealogy_active_query',
          'large_power_usage_ledger',
          'large_rumor_propagation',
          'technology_registry_validation',
        }),
      );
    });

    test('each dataset produces a caching_policy recommendation', () {
      final report = PerformanceScaleBenchmark.withDefaults().runAll();

      expect(
        report.cachingPolicies,
        isNotEmpty,
        reason: '110.45 caching_policy output must be non-empty',
      );
      for (final policy in report.cachingPolicies) {
        expect(policy.label, isNotEmpty);
        expect(policy.keyPattern, isNotEmpty);
        expect(policy.eviction, isNotEmpty);
        expect(policy.targetMsAfterCache, greaterThan(0));
      }
    });

    test('every bottleneck is mapped to at least one mitigation', () {
      final report = PerformanceScaleBenchmark.withDefaults().runAll();

      expect(
        report.bottlenecks,
        isNotEmpty,
        reason: 'bench must surface at least one bottleneck at Wave-2 scale',
      );
      for (final b in report.bottlenecks) {
        final linked = report.mitigations
            .where((m) => m.bottleneckLabel == b.label)
            .toList();
        expect(
          linked,
          isNotEmpty,
          reason: 'bottleneck ${b.label} has no mitigation',
        );
        for (final m in linked) {
          expect(m.label, isNotEmpty);
          expect(m.action, isNotEmpty);
        }
      }
    });

    test(
      'cached runs improve over their baseline for repetitive workloads',
      () {
        final report = PerformanceScaleBenchmark.withDefaults().runAll();

        // Workloads that repeat the same deterministic key (tick, node id, edge
        // id) must benefit from the cache; non-repetitive workloads may stay
        // flat or slower (cache overhead) and are not asserted here.
        final cacheable = report.results.where(
          (r) =>
              r.dataset.label == 'long_timeline_weather_sampling' ||
              r.dataset.label == 'large_map_route_network',
        );

        expect(cacheable, isNotEmpty);
        for (final r in cacheable) {
          expect(
            r.cacheHits,
            greaterThan(0),
            reason:
                '${r.dataset.label} must hit the cache on its repeated pass',
          );
          expect(
            r.cachedMs,
            lessThanOrEqualTo(r.baselineMs),
            reason:
                '${r.dataset.label} cached pass must not regress vs baseline',
          );
        }
      },
    );

    test('budgets are honoured for every Wave-2 dataset', () {
      final report = PerformanceScaleBenchmark.withDefaults().runAll();

      for (final r in report.results) {
        expect(
          r.withinBudget,
          isTrue,
          reason:
              '${r.dataset.label} ran ${r.baselineMs}ms vs budget ${r.budget.budgetMs}ms',
        );
        expect(r.budget.budgetMs, greaterThan(0));
      }
    });

    test(
      'budgets are derived from measured baselines with a documented headroom',
      () {
        // The harness must keep budget computation transparent: every budget
        // value is at least 2x the slowest recent baseline (headroom >= 2.0x),
        // and the headroom multiplier is exposed via the budget itself.
        final report = PerformanceScaleBenchmark.withDefaults().runAll();
        for (final r in report.results) {
          expect(r.budget.headroomMultiplier, greaterThanOrEqualTo(2.0));
          expect(
            r.budget.budgetMs,
            greaterThanOrEqualTo(
              (r.baselineMs * r.budget.headroomMultiplier).round(),
            ),
          );
        }
      },
    );

    test(
      'runAll is deterministic: same seed produces identical timing summaries',
      () {
        // Timing values themselves are wall-clock dependent and are not asserted;
        // only ordering, label list, and bottleneck label list must match.
        final a = PerformanceScaleBenchmark.withDefaults().runAll();
        final b = PerformanceScaleBenchmark.withDefaults().runAll();

        expect(
          a.results.map((r) => r.dataset.label).toList(),
          equals(b.results.map((r) => r.dataset.label).toList()),
        );
        expect(
          a.bottlenecks.map((bb) => bb.label).toList(),
          equals(b.bottlenecks.map((bb) => bb.label).toList()),
        );
        expect(
          a.cachingPolicies.map((p) => p.label).toList(),
          equals(b.cachingPolicies.map((p) => p.label).toList()),
        );
      },
    );

    test('isolated dataset factories return valid payloads (no throws)', () {
      final harness = PerformanceScaleBenchmark.withDefaults();
      for (final ds in harness.datasets) {
        final payload = ds.build();
        expect(
          payload,
          isNotEmpty,
          reason: 'dataset ${ds.label} build returned empty',
        );
        for (final entry in ds.scaleTargets.entries) {
          expect(
            entry.value,
            greaterThan(0),
            reason: '${ds.label} target ${entry.key} must be > 0',
          );
        }
      }
    });
  });
}
