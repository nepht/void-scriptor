/// Test for Performance Validation Window (Step 113.23).
/// Validates: baseline, results, percentiles, regressions, resource_use, and
/// decision against the frozen acceptance thresholds.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/performance_validation_window.dart';

void main() {
  group('113.23 Performance Validation Window', () {
    // 1. Baseline
    group('baseline', () {
      test('canonical baseline covers all eight categories', () {
        final baseline = PerformanceBaseline.canonical();
        for (final category in PerformanceCategory.all) {
          expect(
            baseline.budgetFor(category),
            isNotNull,
            reason: 'missing budget for ${category.name}',
          );
        }
        expect(baseline.budgets.length, PerformanceCategory.all.length);
      });

      test('canonical baseline anchors T-03 startup and T-04 search', () {
        final baseline = PerformanceBaseline.canonical();
        final startup = baseline.budgetFor(PerformanceCategory.startup)!;
        expect(startup.p95BudgetMs, 8000, reason: 'T-03 cold start <= 8000ms');
        final search = baseline.budgetFor(PerformanceCategory.search)!;
        expect(search.p95BudgetMs, 1000, reason: 'T-04 search p95 <= 1000ms');
      });

      test('budgets carry headroom over their recorded baseline', () {
        final baseline = PerformanceBaseline.canonical();
        for (final category in PerformanceCategory.all) {
          final budget = baseline.budgetFor(category)!;
          expect(
            budget.p50BudgetMs,
            greaterThanOrEqualTo(budget.baselineP50Ms),
            reason: category.name,
          );
          expect(
            budget.p95BudgetMs,
            greaterThanOrEqualTo(budget.p50BudgetMs),
            reason: category.name,
          );
        }
      });
    });

    // 2. Results
    group('results', () {
      test('observations are produced per recorded category only', () {
        final window = PerformanceValidationWindow();
        window.recordSample(PerformanceCategory.startup, 3000);
        window.recordSample(PerformanceCategory.search, 400);
        final results = window.results();
        expect(results.length, 2);
        expect(
          results.map((r) => r.category),
          containsAll(<PerformanceCategory>[
            PerformanceCategory.startup,
            PerformanceCategory.search,
          ]),
        );
        expect(
          results.any((r) => r.category == PerformanceCategory.media),
          isFalse,
        );
      });

      test('samples are retained in record order and immutable to callers', () {
        final window = PerformanceValidationWindow();
        window.recordSample(PerformanceCategory.latency, 100);
        window.recordSample(PerformanceCategory.latency, 300);
        final samples = window.samplesFor(PerformanceCategory.latency);
        expect(samples, <double>[100, 300]);
        expect(
          () => samples.add(999),
          throwsUnsupportedError,
          reason: 'exposed sample list must be read-only',
        );
      });

      test('negative samples are rejected', () {
        final window = PerformanceValidationWindow();
        expect(
          () => window.recordSample(PerformanceCategory.export, -1),
          throwsArgumentError,
        );
      });
    });

    // 3. Percentiles
    group('percentiles', () {
      test('nearest-rank percentiles are deterministic', () {
        final window = PerformanceValidationWindow();
        for (var i = 1; i <= 10; i++) {
          window.recordSample(PerformanceCategory.search, i * 100.0);
        }
        final p = window.percentilesFor(PerformanceCategory.search);
        expect(p.p50, 500, reason: 'ceil(0.5*10)-1 -> index 4');
        expect(p.p95, 1000, reason: 'ceil(0.95*10)-1 -> index 9');
        expect(p.p99, 1000, reason: 'ceil(0.99*10)-1 -> index 9');
      });

      test('single sample collapses all percentiles to the same value', () {
        final window = PerformanceValidationWindow();
        window.recordSample(PerformanceCategory.graph, 120);
        final p = window.percentilesFor(PerformanceCategory.graph);
        expect(p.p50, 120);
        expect(p.p95, 120);
        expect(p.p99, 120);
      });

      test('percentile of an unrecorded category is rejected', () {
        final window = PerformanceValidationWindow();
        expect(
          () => window.percentilesFor(PerformanceCategory.simulation),
          throwsStateError,
        );
      });
    });

    // 4. Regressions
    group('regressions', () {
      test('samples within budget produce no findings', () {
        final window = PerformanceValidationWindow();
        for (var i = 0; i < 10; i++) {
          window.recordSample(PerformanceCategory.startup, 3000.0 + i);
        }
        window.recordSample(PerformanceCategory.search, 400);
        expect(window.regressions(), isEmpty);
      });

      test('p95 breach against T-04 search budget is reported', () {
        final window = PerformanceValidationWindow();
        window.recordSample(PerformanceCategory.search, 400);
        window.recordSample(PerformanceCategory.search, 1500);
        final findings = window.regressions();
        expect(findings, hasLength(1));
        final finding = findings.single;
        expect(finding.category, PerformanceCategory.search);
        expect(finding.percentile, 'p95');
        expect(finding.observedMs, 1500);
        expect(finding.budgetMs, 1000);
        expect(finding.regressionFactor, closeTo(1.5, 0.0001));
      });

      test('p50 breach is reported independently of p95', () {
        final window = PerformanceValidationWindow();
        // All samples over the p50 budget but under the p95 budget.
        for (var i = 0; i < 10; i++) {
          window.recordSample(PerformanceCategory.media, 900.0 + i);
        }
        final findings = window.regressions();
        expect(findings, hasLength(1));
        expect(findings.single.percentile, 'p50');
        expect(findings.single.category, PerformanceCategory.media);
      });
    });

    // 5. Resource use
    group('resource_use', () {
      test('resource use is null until recorded', () {
        final window = PerformanceValidationWindow();
        window.recordSample(PerformanceCategory.startup, 1000);
        expect(window.resourceUse, isNull);
        expect(
          window.decision(),
          PerformanceDecision.pass,
          reason: 'missing resource data must not fail a clean window',
        );
      });

      test('peaks within budget report within-budget', () {
        final window = PerformanceValidationWindow();
        window.recordSample(PerformanceCategory.startup, 1000);
        window.recordResourceUse(
          peakRssMb: 300,
          rssBudgetMb: 512,
          peakBackgroundJobs: 2,
          backgroundJobsBudget: 4,
        );
        final report = window.resourceUse!;
        expect(report.rssWithinBudget, isTrue);
        expect(report.backgroundJobsWithinBudget, isTrue);
        expect(report.withinBudget, isTrue);
      });

      test('rss or job over-budget is flagged', () {
        final window = PerformanceValidationWindow();
        window.recordSample(PerformanceCategory.startup, 1000);
        window.recordResourceUse(
          peakRssMb: 900,
          rssBudgetMb: 512,
          peakBackgroundJobs: 2,
          backgroundJobsBudget: 4,
        );
        final report = window.resourceUse!;
        expect(report.rssWithinBudget, isFalse);
        expect(report.withinBudget, isFalse);

        final other = PerformanceValidationWindow();
        other.recordSample(PerformanceCategory.startup, 1000);
        other.recordResourceUse(
          peakRssMb: 100,
          rssBudgetMb: 512,
          peakBackgroundJobs: 9,
          backgroundJobsBudget: 4,
        );
        expect(other.resourceUse!.backgroundJobsWithinBudget, isFalse);
      });
    });

    // 6. Decision
    group('decision', () {
      test('empty window is blocked', () {
        final window = PerformanceValidationWindow();
        expect(window.decision(), PerformanceDecision.blocked);
      });

      test('clean window with satisfied resource use passes', () {
        final window = PerformanceValidationWindow();
        window.recordSample(PerformanceCategory.startup, 2500);
        window.recordSample(PerformanceCategory.search, 300);
        window.recordResourceUse(
          peakRssMb: 256,
          rssBudgetMb: 512,
          peakBackgroundJobs: 1,
          backgroundJobsBudget: 4,
        );
        expect(window.decision(), PerformanceDecision.pass);
      });

      test('any regression fails the window', () {
        final window = PerformanceValidationWindow();
        window.recordSample(PerformanceCategory.startup, 9000);
        expect(window.decision(), PerformanceDecision.fail);
      });

      test('resource over-budget fails even without regressions', () {
        final window = PerformanceValidationWindow();
        window.recordSample(PerformanceCategory.startup, 2500);
        window.recordResourceUse(
          peakRssMb: 2048,
          rssBudgetMb: 512,
          peakBackgroundJobs: 1,
          backgroundJobsBudget: 4,
        );
        expect(window.decision(), PerformanceDecision.fail);
      });
    });

    // 7. Manifest & required-evidence contract
    group('manifest', () {
      const manifestPath =
          'docs/planning/v1.2/sprint_113_performance_validation_window.json';

      test('manifest exists with canonical step 113.23', () {
        final file = File(manifestPath);
        expect(file.existsSync(), isTrue, reason: 'missing manifest');
        final document =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(document['canonical_step'], '113.23');
        expect(document['title'], 'Performance Validation Window');
      });

      test('manifest declares all six required evidence groups', () {
        final document =
            jsonDecode(File(manifestPath).readAsStringSync())
                as Map<String, dynamic>;
        final evidence = document['required_evidence'] as Map<String, dynamic>;
        for (final key in [
          'baseline',
          'results',
          'percentiles',
          'regressions',
          'resource_use',
          'decision',
        ]) {
          expect(
            evidence.containsKey(key),
            isTrue,
            reason: 'required_evidence missing $key',
          );
        }
        expect(document['limits'], contains('DEFERRED'));
      });

      test('manifest limits match the domain-scope boundary', () {
        final document =
            jsonDecode(File(manifestPath).readAsStringSync())
                as Map<String, dynamic>;
        expect(document['decision'], contains('domain_level'));
        expect(document['limits'], contains('deterministik'));
      });
    });
  });
}
