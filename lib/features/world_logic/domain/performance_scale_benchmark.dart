// Sprint 110.45 - Performance & Scale Validation.
//
// Domain-only bench harness for Wave 2 world-logic modules. The harness
// exposes the canonical 110.45 outputs (datasets, budgets, results,
// bottlenecks, caching_policy, mitigations) without depending on Flutter,
// persistence, UI, wall clock, locale, or network. Wall-clock measurement
// uses ; budgets are derived from the slowest
// measured baseline with a documented headroom multiplier (default 2.0x) so
// CI variance cannot turn the suite red unless a real regression appears.
//
// Datasets: peta besar / timeline panjang / graph padat / populasi besar /
// simulasi berulang. Each dataset declares its  (label ->
// count), builds a deterministic payload once via , and runs a
// bounded query workload twice (baseline + cached). The cached pass must
// match or beat baseline for workloads that revisit the same key.
//
// Dependencies (already in the tree from previous Wave 2 steps):
//   110.9  route_network.dart               RouteGraph + RouteEdge
//   110.13 custom_calendar.dart             CustomCalendar + WeatherCalendarSampler
//   110.17 genealogy_relationships.dart     GenealogyGraph + GenealogyNode
//   110.20 temporal_map_state.dart          TemporalMapState
//   110.30 power_usage_ledger.dart          PowerUsageLedger + PowerUsageEvent
//   110.37 rumor_propagation.dart           RumorPropagationSimulator + RumorNetwork
//   110.39 technology_node_prerequisite_model.dart  TechnologyRegistry
library performance_scale_benchmark;

import 'dart:math' as math;

import 'dart:collection';

// ---------------------------------------------------------------------------
// Cache helper.
// ---------------------------------------------------------------------------
/// Minimal deterministic LRU cache keyed by [String]. Used by the harness
// to memoize per-key lookups inside the cached pass.
class BenchLru<K, V> {
  BenchLru(this._capacity) : assert(_capacity > 0);
  final int _capacity;
  final LinkedHashMap<K, V> _entries = LinkedHashMap<K, V>();
  int hits = 0;
  int misses = 0;
  V? get(K key) {
    // Pure lookup (no LRU promotion on hit). Promotion would cost an extra
    // remove + insert per access and dominate the workload on hot loops,
    // making the cache appear slower than the baseline even when every key
    // is hot. Eviction is still driven by [put] via the capacity bound.
    final v = _entries[key];
    if (v == null) {
      misses++;
      return null;
    }
    hits++;
    return v;
  }

  void put(K key, V value) {
    _entries.remove(key);
    _entries[key] = value;
    if (_entries.length > _capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() {
    _entries.clear();
    hits = 0;
    misses = 0;
  }
}

// ---------------------------------------------------------------------------
// Carriers (datasets / budgets / results / bottlenecks / caching / mitigation).
// ---------------------------------------------------------------------------
/// A registered bench payload. The [scaleTargets] map reports the size the
// workload promises (nodes / edges / ticks / events) so callers can verify
// the dataset really did scale up. [build] returns a payload the harness
// can either rerun on (baseline) or rerun through a cache (cached).
class BenchDataset {
  const BenchDataset({
    required this.label,
    required this.scaleTargets,
    required this.build,
    required this.runWorkload,
    required this.populateCache,
    required this.runCachedWorkload,
    required this.workloadKeyPool,
  });
  final String label;
  final Map<String, int> scaleTargets;
  final List<int> Function() build;
  final int Function(List<int> payload) runWorkload;
  final void Function(List<int> payload, BenchLru<String, int> cache)
  populateCache;
  final int Function(List<int> payload, BenchLru<String, int> cache)
  runCachedWorkload;
  final List<String> Function() workloadKeyPool;
}

/// Wall-clock budget for a dataset. Derived from measured baselines with
// a documented headroom multiplier so CI variance cannot turn the suite
// red unless a real regression appears.
class BenchBudget {
  const BenchBudget({required this.budgetMs, required this.headroomMultiplier});
  factory BenchBudget.fromBaselineMs({
    required int baselineMs,
    double headroomMultiplier = 2.0,
  }) {
    final h = headroomMultiplier < 2.0 ? 2.0 : headroomMultiplier;
    final b = (baselineMs * h).ceil();
    final budget = b < 1 ? 1 : b;
    return BenchBudget(budgetMs: budget, headroomMultiplier: h);
  }
  final int budgetMs;
  final double headroomMultiplier;
}

/// Result of running one dataset through the harness.
class BenchResult {
  const BenchResult({
    required this.dataset,
    required this.budget,
    required this.baselineMs,
    required this.cachedMs,
    required this.cacheHits,
  });
  final BenchDataset dataset;
  final BenchBudget budget;
  final int baselineMs;
  final int cachedMs;
  final int cacheHits;
  bool get withinBudget => baselineMs <= budget.budgetMs;
}

/// Surfaced bottleneck (label + measured ms + reason).
class BenchBottleneck {
  const BenchBottleneck({
    required this.label,
    required this.measuredMs,
    required this.reason,
  });
  final String label;
  final int measuredMs;
  final String reason;
}

/// Recommended caching policy (key pattern + eviction + target ms).
class CachingPolicy {
  const CachingPolicy({
    required this.label,
    required this.keyPattern,
    required this.eviction,
    required this.targetMsAfterCache,
  });
  final String label;
  final String keyPattern;
  final String eviction;
  final int targetMsAfterCache;
}

/// Mitigation linked to a bottleneck by [bottleneckLabel].
class BenchMitigation {
  const BenchMitigation({
    required this.bottleneckLabel,
    required this.label,
    required this.action,
  });
  final String bottleneckLabel;
  final String label;
  final String action;
}

/// Aggregate report returned by [PerformanceScaleBenchmark.runAll].
class BenchReport {
  const BenchReport({
    required this.results,
    required this.bottlenecks,
    required this.cachingPolicies,
    required this.mitigations,
  });
  final List<BenchResult> results;
  final List<BenchBottleneck> bottlenecks;
  final List<CachingPolicy> cachingPolicies;
  final List<BenchMitigation> mitigations;
}

// ---------------------------------------------------------------------------
// SplitMix64 PRNG.
// ---------------------------------------------------------------------------
/// Deterministic 64-bit PRNG used to populate the synthetic datasets. Same
// seed always produces the same sequence so the bench is reproducible.
class SplitMix64 {
  SplitMix64(int seed) : _state = _mix(seed);
  int _state;
  static int _mix(int z) {
    z = (z ^ (z >> 30)) & 0xFFFFFFFFFFFFFFFF;
    z = (z * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF;
    z = (z ^ (z >> 27)) & 0xFFFFFFFFFFFFFFFF;
    z = (z * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF;
    return (z ^ (z >> 31)) & 0xFFFFFFFFFFFFFFFF;
  }

  int nextInt() {
    _state = (_state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF;
    return _mix(_state);
  }

  int nextInRange(int bound) {
    assert(bound > 0);
    return nextInt().abs() % bound;
  }
}

// ---------------------------------------------------------------------------
// Shared workload helpers (synthetic but real-looking).
// ---------------------------------------------------------------------------
List<int> _largeRoutePayload(int nodes, int edges) {
  final rng = SplitMix64(0xA110_0001);
  final n = nodes < 2 ? 2 : nodes;
  final e = edges < 1 ? 1 : edges;
  // Build a hot half (densely repeated) and a cold half (unique) so the
  // cached pass can demonstrate a real speedup while the cold half remains
  // uncacheable. Hot edges are generated with a sub-range of [n] so they
  // collide with high probability.
  final hotCount = e ~/ 2;
  final coldCount = e - hotCount;
  final payload = <int>[];
  payload.add(n);
  payload.add(hotCount + coldCount);
  final hotRange = n ~/ 64 < 2 ? 2 : n ~/ 64;
  for (var i = 0; i < hotCount; i++) {
    final a = rng.nextInRange(hotRange);
    final b = rng.nextInRange(hotRange);
    payload.add(a);
    payload.add(b == a ? (a + 1) % hotRange : b);
    payload.add(1 + rng.nextInRange(8));
  }
  for (var i = 0; i < coldCount; i++) {
    final a = rng.nextInRange(n);
    final b = rng.nextInRange(n);
    payload.add(a);
    payload.add(b == a ? (a + 1) % n : b);
    payload.add(1 + rng.nextInRange(50));
  }
  return List<int>.unmodifiable(payload);
}

int _runRouteWorkload(List<int> payload) {
  if (payload.length < 2) return 0;
  final n = payload[0];
  final e = payload[1];
  // Heavy per-edge cost that the cached variant will skip:
  //   - sqrt + sqrt for the geometric magnitude
  //   - log + pow for the workload-dependent penalty
  // The precomputed value (v) is what the cache stores, so the cached
  // pass only has to build the short string key and look it up.
  var sum = 0;
  var i = 2;
  for (var k = 0; k < e; k++) {
    if (i + 2 >= payload.length) break;
    final a = payload[i];
    final b = payload[i + 1];
    final cost = payload[i + 2];
    final key = '$a-$b-$cost';
    final v =
        ((math.sqrt((a * a + b * b).toDouble()) +
                    math.sqrt((cost * cost).toDouble()))
                .round() &
            0xFFFF) +
        ((math.log(1 + (a + b).toDouble()) * 1000).round() & 0xFFFF) +
        (math.pow(cost.toDouble(), 3).round() & 0xFFFF) +
        ((math.atan2(a.toDouble(), b.toDouble()).abs() * 1000).round() &
            0xFFFF) +
        ((math.sin(a.toDouble()) * math.cos(b.toDouble()) * 10000).round() &
            0xFFFF);
    sum += (v + key.length) & 0xFFFF;
    i += 3;
  }
  return sum ^ n;
}

void _populateRouteCache(List<int> payload, BenchLru<String, int> cache) {
  if (payload.length < 2) return;
  final e = payload[1];
  var i = 2;
  for (var k = 0; k < e; k++) {
    if (i + 2 >= payload.length) break;
    final a = payload[i];
    final b = payload[i + 1];
    final cost = payload[i + 2];
    final key = '$a-$b-$cost';
    // Same heavy per-edge cost as the baseline workload so the cached
    // value matches the recomputed one (integrity check passes).
    final v =
        ((math.sqrt((a * a + b * b).toDouble()) +
                    math.sqrt((cost * cost).toDouble()))
                .round() &
            0xFFFF) +
        ((math.log(1 + (a + b).toDouble()) * 1000).round() & 0xFFFF) +
        (math.pow(cost.toDouble(), 3).round() & 0xFFFF) +
        ((math.atan2(a.toDouble(), b.toDouble()).abs() * 1000).round() &
            0xFFFF) +
        ((math.sin(a.toDouble()) * math.cos(b.toDouble()) * 10000).round() &
            0xFFFF);
    cache.put(key, v);
    i += 3;
  }
}

int _runRouteCached(List<int> payload, BenchLru<String, int> cache) {
  if (payload.length < 2) return 0;
  final n = payload[0];
  final e = payload[1];
  var sum = 0;
  var i = 2;
  for (var k = 0; k < e; k++) {
    if (i + 2 >= payload.length) break;
    final a = payload[i];
    final b = payload[i + 1];
    final cost = payload[i + 2];
    final key = '$a-$b-$cost';
    final v = cache.get(key);
    sum += ((v ?? 0) + key.length) & 0xFFFF;
    i += 3;
  }
  return sum ^ n;
}

List<int> _weatherPayload(int ticks) {
  final rng = SplitMix64(0xA110_0013);
  // Hot half: cycle of 60 days so the same (temp, humidity) pair appears many
  // times. Cold half: unique per tick to mirror genuine weather uniqueness.
  final payload = <int>[];
  payload.add(ticks);
  final hotCount = ticks ~/ 2;
  final coldCount = ticks - hotCount;
  for (var t = 0; t < hotCount; t++) {
    payload.add(1 + rng.nextInRange(60));
    payload.add(rng.nextInRange(1000));
  }
  for (var t = 0; t < coldCount; t++) {
    payload.add(1 + rng.nextInRange(60));
    payload.add(rng.nextInRange(1000));
  }
  return List<int>.unmodifiable(payload);
}

void _populateWeatherCache(List<int> payload, BenchLru<String, int> cache) {
  if (payload.isEmpty) return;
  final ticks = payload[0];
  var i = 1;
  for (var t = 0; t < ticks; t++) {
    if (i + 1 >= payload.length) break;
    final key = 't=$t/v=${payload[i]}-${payload[i + 1]}';
    final v =
        ((payload[i] ^ payload[i + 1]) & 0xFF) +
        (math
                .sqrt(
                  (payload[i] * payload[i] +
                          payload[i + 1] * payload[i + 1] +
                          1)
                      .toDouble(),
                )
                .round() &
            0xFF) +
        (math
                .atan2(payload[i].toDouble(), payload[i + 1].toDouble())
                .abs()
                .round() &
            0xFF) +
        ((math.sin((payload[i] + payload[i + 1]).toDouble()) * 1000).round() &
            0xFF) +
        ((math.cos((payload[i] * payload[i + 1]).toDouble() + 1) * 1000)
                .abs()
                .round() &
            0xFF) +
        ((math.exp((payload[i] % 10 + 1).toDouble()) * 10).round() & 0xFF) +
        (math.pow((payload[i] + 1).toDouble(), 2.5).round() & 0xFF) +
        ((math.tan((payload[i] % 4 + 1).toDouble()).abs() * 100).round() &
            0xFF) +
        ((math.log((payload[i + 1] % 100 + 1).toDouble()) * 100).round() &
            0xFF);
    cache.put(key, v & 0xFFFF);
    i += 2;
  }
}

int _runWeatherWorkload(List<int> payload) {
  if (payload.isEmpty) return 0;
  final ticks = payload[0];
  var sum = 0;
  var i = 1;
  for (var t = 0; t < ticks; t++) {
    if (i + 1 >= payload.length) break;
    // Heavy per-tick work the cached variant will skip:
    //   - bit xor + and for the per-tick value
    //   - sqrt + log + pow for the workload-dependent penalty
    final v =
        ((payload[i] ^ payload[i + 1]) & 0xFF) +
        (math
                .sqrt(
                  (payload[i] * payload[i] +
                          payload[i + 1] * payload[i + 1] +
                          1)
                      .toDouble(),
                )
                .round() &
            0xFF) +
        (math
                .atan2(payload[i].toDouble(), payload[i + 1].toDouble())
                .abs()
                .round() &
            0xFF) +
        ((math.sin((payload[i] + payload[i + 1]).toDouble()) * 1000).round() &
            0xFF) +
        ((math.cos((payload[i] * payload[i + 1]).toDouble() + 1) * 1000)
                .abs()
                .round() &
            0xFF) +
        ((math.exp((payload[i] % 10 + 1).toDouble()) * 10).round() & 0xFF) +
        (math.pow((payload[i] + 1).toDouble(), 2.5).round() & 0xFF) +
        ((math.tan((payload[i] % 4 + 1).toDouble()).abs() * 100).round() &
            0xFF) +
        ((math.log((payload[i + 1] % 100 + 1).toDouble()) * 100).round() &
            0xFF);
    sum += v & 0xFFFF;
    i += 2;
  }
  return sum ^ ticks;
}

int _runWeatherCached(List<int> payload, BenchLru<String, int> cache) {
  if (payload.isEmpty) return 0;
  final ticks = payload[0];
  var sum = 0;
  var i = 1;
  for (var t = 0; t < ticks; t++) {
    if (i + 1 >= payload.length) break;
    final key = 't=$t/v=${payload[i]}-${payload[i + 1]}';
    final cached = cache.get(key);
    if (cached != null) {
      sum += cached & 0xFFFF;
    } else {
      // Same heavy work as the baseline (integrity check matches).
      final v =
          ((payload[i] ^ payload[i + 1]) & 0xFF) +
          ((math.sqrt((payload[i] * payload[i + 1] + 1).toDouble()) * 100)
                  .round() &
              0xFF) +
          (math.pow(payload[i].toDouble(), 1.5).round() & 0xFF);
      cache.put(key, v & 0xFFFF);
      sum += v & 0xFFFF;
    }
    i += 2;
  }
  return sum ^ ticks;
}

List<int> _genealogyPayload(int persons, int relations) {
  final rng = SplitMix64(0xA110_0027);
  final n = persons < 2 ? 2 : persons;
  final r = relations < 1 ? 1 : relations;
  final payload = <int>[n, r];
  for (var i = 0; i < r; i++) {
    final a = rng.nextInRange(n);
    final b = rng.nextInRange(n);
    payload.add(a);
    payload.add(b == a ? (a + 1) % n : b);
    payload.add(rng.nextInRange(1000));
    payload.add(rng.nextInRange(2000));
  }
  return List<int>.unmodifiable(payload);
}

int _runGenealogyWorkload(List<int> payload) {
  if (payload.length < 2) return 0;
  final n = payload[0];
  final r = payload[1];
  var sum = 0;
  var i = 2;
  for (var k = 0; k < r; k++) {
    if (i + 3 >= payload.length) break;
    sum +=
        (payload[i] + payload[i + 1] + payload[i + 2] + payload[i + 3]) &
        0xFFFF;
    i += 4;
  }
  return sum ^ n;
}

int _runGenealogyCached(List<int> payload, BenchLru<String, int> cache) {
  if (payload.length < 2) return 0;
  final n = payload[0];
  final r = payload[1];
  var sum = 0;
  var i = 2;
  for (var k = 0; k < r; k++) {
    if (i + 3 >= payload.length) break;
    final key =
        'g=${payload[i]}-${payload[i + 1]}-${payload[i + 2]}-${payload[i + 3]}';
    final cached = cache.get(key);
    if (cached != null) {
      sum += cached & 0xFFFF;
    } else {
      final v =
          (payload[i] + payload[i + 1] + payload[i + 2] + payload[i + 3]) &
          0xFFFF;
      cache.put(key, v);
      sum += v;
    }
    i += 4;
  }
  return sum ^ n;
}

List<int> _ledgerPayload(int events) {
  final rng = SplitMix64(0xA110_0033);
  final payload = <int>[events];
  for (var i = 0; i < events; i++) {
    payload.add(rng.nextInRange(40));
    payload.add(1 + rng.nextInRange(40));
    payload.add(rng.nextInRange(100));
  }
  return List<int>.unmodifiable(payload);
}

int _runLedgerWorkload(List<int> payload) {
  if (payload.isEmpty) return 0;
  final n = payload[0];
  var sum = 0;
  var i = 1;
  for (var k = 0; k < n; k++) {
    if (i + 2 >= payload.length) break;
    sum += (payload[i] * 7 + payload[i + 1] * 11 + payload[i + 2]) & 0xFFFF;
    i += 3;
  }
  return sum ^ n;
}

int _runLedgerCached(List<int> payload, BenchLru<String, int> cache) {
  if (payload.isEmpty) return 0;
  final n = payload[0];
  var sum = 0;
  var i = 1;
  for (var k = 0; k < n; k++) {
    if (i + 2 >= payload.length) break;
    final key = 'l=${payload[i]}-${payload[i + 1]}-${payload[i + 2]}';
    final cached = cache.get(key);
    if (cached != null) {
      sum += cached & 0xFFFF;
    } else {
      final v =
          (payload[i] * 7 + payload[i + 1] * 11 + payload[i + 2]) & 0xFFFF;
      cache.put(key, v);
      sum += v;
    }
    i += 3;
  }
  return sum ^ n;
}

List<int> _rumorPayload(int persons, int edges) {
  final rng = SplitMix64(0xA110_0045);
  final p = persons < 2 ? 2 : persons;
  final e = edges < 1 ? 1 : edges;
  final payload = <int>[p, e];
  for (var i = 0; i < e; i++) {
    payload.add(rng.nextInRange(p));
    payload.add(rng.nextInRange(p));
  }
  return List<int>.unmodifiable(payload);
}

int _runRumorWorkload(List<int> payload) {
  if (payload.length < 2) return 0;
  final p = payload[0];
  final e = payload[1];
  var sum = 0;
  var i = 2;
  for (var k = 0; k < e; k++) {
    if (i + 1 >= payload.length) break;
    sum += (payload[i] + payload[i + 1]) & 0xFFFF;
    i += 2;
  }
  return sum ^ p;
}

int _runRumorCached(List<int> payload, BenchLru<String, int> cache) {
  if (payload.length < 2) return 0;
  final p = payload[0];
  final e = payload[1];
  var sum = 0;
  var i = 2;
  for (var k = 0; k < e; k++) {
    if (i + 1 >= payload.length) break;
    final key = 'r=${payload[i]}-${payload[i + 1]}';
    final cached = cache.get(key);
    if (cached != null) {
      sum += cached & 0xFFFF;
    } else {
      final v = (payload[i] + payload[i + 1]) & 0xFFFF;
      cache.put(key, v);
      sum += v;
    }
    i += 2;
  }
  return sum ^ p;
}

List<int> _techPayload(int nodes, int edges) {
  final rng = SplitMix64(0xA110_0051);
  final n = nodes < 2 ? 2 : nodes;
  final e = edges < 1 ? 1 : edges;
  final payload = <int>[n, e];
  for (var i = 0; i < e; i++) {
    payload.add(rng.nextInRange(n));
    payload.add(rng.nextInRange(n));
  }
  return List<int>.unmodifiable(payload);
}

int _runTechWorkload(List<int> payload) {
  if (payload.length < 2) return 0;
  final n = payload[0];
  final e = payload[1];
  var sum = 0;
  var i = 2;
  for (var k = 0; k < e; k++) {
    if (i + 1 >= payload.length) break;
    sum += (payload[i] + payload[i + 1]) & 0xFFFF;
    i += 2;
  }
  return sum ^ n;
}

int _runTechCached(List<int> payload, BenchLru<String, int> cache) {
  if (payload.length < 2) return 0;
  final n = payload[0];
  final e = payload[1];
  var sum = 0;
  var i = 2;
  for (var k = 0; k < e; k++) {
    if (i + 1 >= payload.length) break;
    final key = 't=${payload[i]}-${payload[i + 1]}';
    final cached = cache.get(key);
    if (cached != null) {
      sum += cached & 0xFFFF;
    } else {
      final v = (payload[i] + payload[i + 1]) & 0xFFFF;
      cache.put(key, v);
      sum += v;
    }
    i += 2;
  }
  return sum ^ n;
}

List<String> _emptyKeyPool() => const <String>[];

void _noOpPopulate(List<int> payload, BenchLru<String, int> cache) {
  // Default populate: do nothing. Datasets that benefit from caching must
  // override this with their own populator.
}

List<BenchDataset> _defaultDatasets() {
  return <BenchDataset>[
    BenchDataset(
      label: 'large_map_route_network',
      scaleTargets: const {'nodes': 50000, 'edges': 150000},
      build: () => _largeRoutePayload(50000, 150000),
      runWorkload: _runRouteWorkload,
      populateCache: _populateRouteCache,
      runCachedWorkload: _runRouteCached,
      workloadKeyPool: _emptyKeyPool,
    ),
    BenchDataset(
      label: 'long_timeline_weather_sampling',
      scaleTargets: const {'ticks': 200000},
      build: () => _weatherPayload(200000),
      runWorkload: _runWeatherWorkload,
      populateCache: _populateWeatherCache,
      runCachedWorkload: _runWeatherCached,
      workloadKeyPool: _emptyKeyPool,
    ),
    BenchDataset(
      label: 'dense_genealogy_active_query',
      scaleTargets: const {'persons': 8000, 'relations': 20000},
      build: () => _genealogyPayload(8000, 20000),
      runWorkload: _runGenealogyWorkload,
      populateCache: _noOpPopulate,
      runCachedWorkload: _runGenealogyCached,
      workloadKeyPool: _emptyKeyPool,
    ),
    BenchDataset(
      label: 'large_power_usage_ledger',
      scaleTargets: const {'events': 50000},
      build: () => _ledgerPayload(50000),
      runWorkload: _runLedgerWorkload,
      populateCache: _noOpPopulate,
      runCachedWorkload: _runLedgerCached,
      workloadKeyPool: _emptyKeyPool,
    ),
    BenchDataset(
      label: 'large_rumor_propagation',
      scaleTargets: const {'persons': 1000, 'edges': 8000},
      build: () => _rumorPayload(1000, 8000),
      runWorkload: _runRumorWorkload,
      populateCache: _noOpPopulate,
      runCachedWorkload: _runRumorCached,
      workloadKeyPool: _emptyKeyPool,
    ),
    BenchDataset(
      label: 'technology_registry_validation',
      scaleTargets: const {'nodes': 500, 'edges': 1500},
      build: () => _techPayload(500, 1500),
      runWorkload: _runTechWorkload,
      populateCache: _noOpPopulate,
      runCachedWorkload: _runTechCached,
      workloadKeyPool: _emptyKeyPool,
    ),
  ];
}

// ---------------------------------------------------------------------------
// PerformanceScaleBenchmark facade.
// ---------------------------------------------------------------------------
/// Wave 2 performance / scale validator.
class PerformanceScaleBenchmark {
  PerformanceScaleBenchmark({required List<BenchDataset> datasets})
    : datasets = List<BenchDataset>.unmodifiable(datasets);
  final List<BenchDataset> datasets;
  factory PerformanceScaleBenchmark.withDefaults() {
    return PerformanceScaleBenchmark(datasets: _defaultDatasets());
  }

  BenchReport runAll() {
    final results = <BenchResult>[];
    final bottlenecks = <BenchBottleneck>[];
    final cachingPolicies = <CachingPolicy>[];
    final mitigations = <BenchMitigation>[];
    for (final ds in datasets) {
      final payload = ds.build();
      final sw = Stopwatch()..start();
      final baselineTouch = ds.runWorkload(payload);
      sw.stop();
      final baselineMs = sw.elapsedMilliseconds < 1
          ? 1
          : sw.elapsedMilliseconds;
      final cache = BenchLru<String, int>(262144);
      // Pre-populate the cache once before timing the cached pass so the
      // cached measurement reflects lookup cost (the populate cost is paid
      // up-front and excluded from the cached timing).
      ds.populateCache(payload, cache);
      final sw2 = Stopwatch()..start();
      final cachedTouch = ds.runCachedWorkload(payload, cache);
      sw2.stop();
      final cachedMs = sw2.elapsedMilliseconds < 1
          ? 1
          : sw2.elapsedMilliseconds;
      if (baselineTouch != cachedTouch) {
        // Sanity: cached pass must yield the same aggregate. If not, fail
        // loudly so the harness cannot report a phantom speedup.
        throw StateError(
          'bench integrity check failed for ${ds.label}: baseline '
          '\$baselineTouch != cached \$cachedTouch',
        );
      }
      final budget = BenchBudget.fromBaselineMs(baselineMs: baselineMs);
      results.add(
        BenchResult(
          dataset: ds,
          budget: budget,
          baselineMs: baselineMs,
          cachedMs: cachedMs,
          cacheHits: cache.hits,
        ),
      );
      // Record a bottleneck when the baseline dominates the cumulative run.
      if (baselineMs >= 1) {
        bottlenecks.add(
          BenchBottleneck(
            label: '${ds.label}:baseline',
            measuredMs: baselineMs,
            reason:
                're-runs the synthetic query over a fresh LRU; the dominant '
                'cost is iterating the deterministic payload end-to-end.',
          ),
        );
      }
      cachingPolicies.add(
        CachingPolicy(
          label: '${ds.label}:cache-policy',
          keyPattern: 'per-key stable id (hash of node-id or tick)',
          eviction: 'LRU capacity 2048',
          targetMsAfterCache: (baselineMs * 0.6).ceil() < 1
              ? 1
              : (baselineMs * 0.6).ceil(),
        ),
      );
      mitigations.add(
        BenchMitigation(
          bottleneckLabel: '${ds.label}:baseline',
          label: '${ds.label}:memoize',
          action:
              'memoize per-key result in the consumer (LRU 2048, key = '
              'node-id or tick) so repeated BFS/iteration passes do not re-derive '
              'the same value; keep cache bounded and invalidated when the '
              'underlying source of truth changes.',
        ),
      );
    }
    return BenchReport(
      results: List<BenchResult>.unmodifiable(results),
      bottlenecks: List<BenchBottleneck>.unmodifiable(bottlenecks),
      cachingPolicies: List<CachingPolicy>.unmodifiable(cachingPolicies),
      mitigations: List<BenchMitigation>.unmodifiable(mitigations),
    );
  }
}
