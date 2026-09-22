/// Performance Validation Window (Step 113.23).
///
/// Domain-level window that records duration samples per performance
/// category (startup, latency, background work, graph, search, simulation,
/// media, export), computes deterministic nearest-rank percentiles, compares
/// them against the frozen baseline budget, reports peak resource use, and
/// produces a pass/fail/blocked decision.
///
/// Fixtures are deterministic: samples are supplied by the caller instead of
/// being measured from live processes. Real wall-clock startup, process RSS,
/// and native GUI measurement are out of scope (see manifest limits).
library;

/// Performance categories covered by the validation window.
enum PerformanceCategory {
  startup,
  latency,
  backgroundWork,
  graph,
  search,
  simulation,
  media,
  export;

  static const List<PerformanceCategory> all = [
    PerformanceCategory.startup,
    PerformanceCategory.latency,
    PerformanceCategory.backgroundWork,
    PerformanceCategory.graph,
    PerformanceCategory.search,
    PerformanceCategory.simulation,
    PerformanceCategory.media,
    PerformanceCategory.export,
  ];
}

/// Percentile triple computed with the nearest-rank method.
class Percentiles {
  const Percentiles({required this.p50, required this.p95, required this.p99});

  final double p50;
  final double p95;
  final double p99;
}

/// Frozen baseline budget for one category.
class PerformanceBudget {
  const PerformanceBudget({
    required this.baselineP50Ms,
    required this.p50BudgetMs,
    required this.p95BudgetMs,
  });

  /// Recorded baseline p50 (for reporting; the budget already carries
  /// headroom over it).
  final double baselineP50Ms;

  final double p50BudgetMs;
  final double p95BudgetMs;
}

/// Frozen baseline for the whole window.
class PerformanceBaseline {
  const PerformanceBaseline({required this.budgets});

  final Map<PerformanceCategory, PerformanceBudget> budgets;

  PerformanceBudget? budgetFor(PerformanceCategory category) =>
      budgets[category];

  /// Canonical baseline anchored on the frozen acceptance thresholds:
  /// T-03 cold start average <= 8000ms, T-04 search p95 <= 1000ms.
  factory PerformanceBaseline.canonical() {
    return const PerformanceBaseline(
      budgets: {
        PerformanceCategory.startup: PerformanceBudget(
          baselineP50Ms: 5000,
          p50BudgetMs: 8000,
          p95BudgetMs: 8000,
        ),
        PerformanceCategory.latency: PerformanceBudget(
          baselineP50Ms: 200,
          p50BudgetMs: 400,
          p95BudgetMs: 1000,
        ),
        PerformanceCategory.backgroundWork: PerformanceBudget(
          baselineP50Ms: 250,
          p50BudgetMs: 500,
          p95BudgetMs: 1500,
        ),
        PerformanceCategory.graph: PerformanceBudget(
          baselineP50Ms: 150,
          p50BudgetMs: 300,
          p95BudgetMs: 900,
        ),
        PerformanceCategory.search: PerformanceBudget(
          baselineP50Ms: 500,
          p50BudgetMs: 750,
          p95BudgetMs: 1000,
        ),
        PerformanceCategory.simulation: PerformanceBudget(
          baselineP50Ms: 300,
          p50BudgetMs: 600,
          p95BudgetMs: 1800,
        ),
        PerformanceCategory.media: PerformanceBudget(
          baselineP50Ms: 400,
          p50BudgetMs: 800,
          p95BudgetMs: 2000,
        ),
        PerformanceCategory.export: PerformanceBudget(
          baselineP50Ms: 1000,
          p50BudgetMs: 2000,
          p95BudgetMs: 5000,
        ),
      },
    );
  }
}

/// One recorded observation for a category.
class PerformanceObservation {
  const PerformanceObservation({
    required this.category,
    required this.samplesMs,
    required this.percentiles,
  });

  final PerformanceCategory category;
  final List<double> samplesMs;
  final Percentiles percentiles;
}

/// A budget breach found during evaluation.
class RegressionFinding {
  const RegressionFinding({
    required this.category,
    required this.percentile,
    required this.observedMs,
    required this.budgetMs,
  });

  final PerformanceCategory category;

  /// 'p50' or 'p95'.
  final String percentile;
  final double observedMs;
  final double budgetMs;

  double get regressionFactor =>
      budgetMs <= 0 ? observedMs : observedMs / budgetMs;
}

/// Peak resource use for the window.
class ResourceUseReport {
  const ResourceUseReport({
    required this.peakRssMb,
    required this.rssBudgetMb,
    required this.peakBackgroundJobs,
    required this.backgroundJobsBudget,
  });

  final double peakRssMb;
  final double rssBudgetMb;
  final int peakBackgroundJobs;
  final int backgroundJobsBudget;

  bool get rssWithinBudget => peakRssMb <= rssBudgetMb;
  bool get backgroundJobsWithinBudget =>
      peakBackgroundJobs <= backgroundJobsBudget;
  bool get withinBudget => rssWithinBudget && backgroundJobsWithinBudget;
}

/// Window decision.
enum PerformanceDecision { pass, fail, blocked }

/// Records samples for one category until the window is evaluated.
class PerformanceValidationWindow {
  PerformanceValidationWindow({PerformanceBaseline? baseline})
    : baseline = baseline ?? PerformanceBaseline.canonical();

  final PerformanceBaseline baseline;

  final Map<PerformanceCategory, List<double>> _samples = {};
  double? _peakRssMb;
  double? _rssBudgetMb;
  int? _peakBackgroundJobs;
  int? _backgroundJobsBudget;

  void recordSample(PerformanceCategory category, double durationMs) {
    if (durationMs < 0) {
      throw ArgumentError.value(durationMs, 'durationMs', 'must be >= 0');
    }
    _samples.putIfAbsent(category, () => <double>[]).add(durationMs);
  }

  void recordResourceUse({
    required double peakRssMb,
    required double rssBudgetMb,
    required int peakBackgroundJobs,
    required int backgroundJobsBudget,
  }) {
    _peakRssMb = peakRssMb;
    _rssBudgetMb = rssBudgetMb;
    _peakBackgroundJobs = peakBackgroundJobs;
    _backgroundJobsBudget = backgroundJobsBudget;
  }

  List<PerformanceCategory> get recordedCategories => _samples.keys.toList();

  bool get hasSamples => _samples.isNotEmpty;

  List<double> samplesFor(PerformanceCategory category) =>
      List<double>.unmodifiable(_samples[category] ?? const <double>[]);

  /// Nearest-rank percentiles over the recorded samples.
  Percentiles percentilesFor(PerformanceCategory category) {
    final samples = _samples[category];
    if (samples == null || samples.isEmpty) {
      throw StateError('no samples recorded for ${category.name}');
    }
    final sorted = List<double>.from(samples)..sort();
    return Percentiles(
      p50: _nearestRank(sorted, 0.50),
      p95: _nearestRank(sorted, 0.95),
      p99: _nearestRank(sorted, 0.99),
    );
  }

  static double _nearestRank(List<double> sortedAscending, double p) {
    var rank = (p * sortedAscending.length).ceil() - 1;
    if (rank < 0) rank = 0;
    if (rank >= sortedAscending.length) rank = sortedAscending.length - 1;
    return sortedAscending[rank];
  }

  /// Full observation per recorded category.
  List<PerformanceObservation> results() {
    return [
      for (final category in PerformanceCategory.all)
        if (_samples.containsKey(category))
          PerformanceObservation(
            category: category,
            samplesMs: List<double>.unmodifiable(_samples[category]!),
            percentiles: percentilesFor(category),
          ),
    ];
  }

  /// Budget breaches: p50 over p50 budget or p95 over p95 budget.
  List<RegressionFinding> regressions() {
    final findings = <RegressionFinding>[];
    for (final observation in results()) {
      final budget = baseline.budgetFor(observation.category);
      if (budget == null) continue;
      final p = observation.percentiles;
      if (p.p50 > budget.p50BudgetMs) {
        findings.add(
          RegressionFinding(
            category: observation.category,
            percentile: 'p50',
            observedMs: p.p50,
            budgetMs: budget.p50BudgetMs,
          ),
        );
      }
      if (p.p95 > budget.p95BudgetMs) {
        findings.add(
          RegressionFinding(
            category: observation.category,
            percentile: 'p95',
            observedMs: p.p95,
            budgetMs: budget.p95BudgetMs,
          ),
        );
      }
    }
    return findings;
  }

  ResourceUseReport? get resourceUse {
    final peakRss = _peakRssMb;
    final rssBudget = _rssBudgetMb;
    final peakJobs = _peakBackgroundJobs;
    final jobsBudget = _backgroundJobsBudget;
    if (peakRss == null ||
        rssBudget == null ||
        peakJobs == null ||
        jobsBudget == null) {
      return null;
    }
    return ResourceUseReport(
      peakRssMb: peakRss,
      rssBudgetMb: rssBudget,
      peakBackgroundJobs: peakJobs,
      backgroundJobsBudget: jobsBudget,
    );
  }

  PerformanceDecision decision() {
    if (!hasSamples) return PerformanceDecision.blocked;
    if (regressions().isNotEmpty) return PerformanceDecision.fail;
    final resource = resourceUse;
    if (resource != null && !resource.withinBudget) {
      return PerformanceDecision.fail;
    }
    return PerformanceDecision.pass;
  }
}
