import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_performance_resource_health.dart';

/// A single performance health entry. Each test flips exactly the one thing it
/// is about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118PerformanceResourceHealthEntry _entry({
  String signal = 'render_latency',
  String referenceState = 'render_budget',
  String source = 'docs/planning/v1.2/sprint_115_performance_resilience.json',
  int window = 1440,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118PerformanceResourceHealthEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118PerformanceResourceHealthReview _review({
  String releaseState =
      Sprint118PerformanceResourceHealthContract.delayedReleaseState,
  List<Sprint118PerformanceResourceHealthEntry>? entries,
}) {
  return Sprint118PerformanceResourceHealthReview(
    releaseState: releaseState,
    entries:
        entries ??
        Sprint118PerformanceResourceHealthContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118PerformanceResourceHealthEntry> _replacing(
  String signal,
  Sprint118PerformanceResourceHealthEntry replacement,
) {
  return <Sprint118PerformanceResourceHealthEntry>[
    for (final e
        in Sprint118PerformanceResourceHealthContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118PerformanceResourceHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118PerformanceResourceHealthContract.requiredBaselineVerdict,
  String releaseState =
      Sprint118PerformanceResourceHealthContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118PerformanceResourceHealthContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118PerformanceResourceHealthContract.charterWindowMinutes,
  List<String>? witnessPerformanceResponsiveness,
  List<String>? witnessMemoryStorageCache,
  List<String>? witnessPerformanceResilience,
  List<String>? readableSources,
}) {
  return Sprint118PerformanceResourceHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessPerformanceResponsiveness:
        witnessPerformanceResponsiveness ??
        const <String>[
          'startup',
          'editor_latency',
          'search_latency',
          'graph_latency',
          'simulation_latency',
          'export_duration',
          'background_contention',
        ],
    witnessMemoryStorageCache:
        witnessMemoryStorageCache ??
        const <String>[
          'memory_pressure',
          'storage_growth',
          'snapshot_growth',
          'cache_pressure',
          'temp_growth',
          'index_growth',
        ],
    witnessPerformanceResilience:
        witnessPerformanceResilience ??
        const <String>[
          'render_budget',
          'refresh_budget',
          'slow_api_results',
          'rate_limit_results',
          'outage_results',
          'many_accounts_results',
          'scan_results',
        ],
    readableSources:
        readableSources ??
        Sprint118PerformanceResourceHealthContract.canonicalSources,
  );
}

Sprint118PerformanceResourceHealthReport _run(
  Sprint118PerformanceResourceHealthReview review, {
  Sprint118PerformanceResourceHealthAnchor? anchor,
}) {
  return const Sprint118PerformanceResourceHealthGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.16 Performance & Resource Health', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(
        Sprint118PerformanceResourceHealthContract.canonicalStep,
        '118.16',
      );
      expect(
        Sprint118PerformanceResourceHealthContract.title,
        'Performance & Resource Health',
      );
      expect(
        Sprint118PerformanceResourceHealthContract.manifestPath,
        'docs/planning/v1.3/sprint_118_performance_resource_health.json',
      );
      expect(
        Sprint118PerformanceResourceHealthContract.requiredFields,
        <String>[
          'signal',
          'reference_state',
          'source',
          'window',
          'limitations',
        ],
      );
      expect(
        Sprint118PerformanceResourceHealthContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(
        Sprint118PerformanceResourceHealthContract.requiredFields.length,
        5,
      );
      expect(
        Sprint118PerformanceResourceHealthContract.performanceSignals.length,
        8,
      );
      expect(
        Sprint118PerformanceResourceHealthContract.canonicalSources.length,
        8,
      );
      // Every canonical signal maps to a committed evidence source.
      for (final s
          in Sprint118PerformanceResourceHealthContract.performanceSignals) {
        expect(
          Sprint118PerformanceResourceHealthContract.sourceFor(s),
          isNotEmpty,
        );
      }
      // The reference-state vocabulary is the distinct union of the witness
      // vocabularies, in witness order.
      final vocab = Sprint118PerformanceResourceHealthContract.stateVocabulary(
        const <List<String>>[
          <String>['startup', 'background_contention'],
          <String>['memory_pressure', 'cache_pressure'],
          <String>['render_budget', 'scan_results'],
        ],
      );
      expect(vocab, <String>[
        'startup',
        'background_contention',
        'memory_pressure',
        'cache_pressure',
        'render_budget',
        'scan_results',
      ]);
    });

    test('canonical review covers the eight signals and claims no live '
        'observation', () {
      final review = Sprint118PerformanceResourceHealthContract.canonicalReview;
      expect(review.signals.length, 8);
      expect(review.signals.toSet(), <String>{
        'render_latency',
        'refresh_latency',
        'scan_duration',
        'chart_latency',
        'memory',
        'contention',
        'network',
        'cache_growth',
      });
      for (final entry in review.entries) {
        expect(entry.observed, isFalse);
        expect(entry.window, greaterThan(0));
        expect(entry.limitations, isNotEmpty);
      }
      expect(review.observedCount, 0);
    });

    test('passes on the canonical review', () {
      final report = _run(_review());
      expect(report.state, Sprint118PerformanceResourceHealthState.pass);
      expect(report.verdict, 'PERFORMANCE_RESOURCE_HEALTH_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.declaredSignals.length, 8);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      // chart_latency and network have no witness state, so the upstream gap is
      // recorded as an open item rather than invented away.
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:chart_latency'),
      );
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:network'),
      );
      expect(report.openItems.length, 2);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118PerformanceResourceHealthGate()
          .evaluateWith(null, _review());
      expect(report.state, Sprint118PerformanceResourceHealthState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_PERFORMANCE_RESOURCE_HEALTH_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_performance_resource_health_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.blocked);
      expect(
        report.blockers,
        contains('baseline_not_frozen:SPRINT_118_BASELINE_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 118.2 charter is not complete', () {
      final report = _run(
        _review(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE'),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_INCOMPLETE'),
      );
    });

    test('fails when the release state disagrees with the baseline', () {
      final report = _run(
        _review(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'render_latency',
            _entry(
              signal: 'render_latency',
              referenceState: 'render_budget',
              source:
                  'docs/planning/v1.2/sprint_115_performance_resilience.json',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      expect(
        report.violations,
        contains(
          'performance_claims_observation_without_release:render_latency',
        ),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'cache_growth',
            _entry(
              signal: 'cache_growth',
              referenceState: 'SOMETHING_ELSE',
              source:
                  'docs/planning/v1.2/sprint_114_memory_storage_cache_health.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      expect(
        report.violations,
        contains('entry_unknown_reference_state:cache_growth:SOMETHING_ELSE'),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'scan_duration',
            _entry(
              signal: 'scan_duration',
              referenceState: 'scan_results',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unreadable_source:scan_duration:docs/planning/missing.json',
        ),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'render_latency',
            _entry(signal: 'render_latency', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      expect(
        report.violations,
        contains('entry_blank_reference_state:render_latency'),
      );
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'memory',
            _entry(
              signal: 'memory',
              referenceState: 'memory_pressure',
              source:
                  'docs/planning/v1.2/sprint_114_memory_storage_cache_health.json',
              limitations: const <String>[],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      expect(report.violations, contains('entry_no_limitations:memory'));
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'refresh_latency',
            _entry(
              signal: 'refresh_latency',
              referenceState: 'refresh_budget',
              source:
                  'docs/planning/v1.2/sprint_115_performance_resilience.json',
              window: 0,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      expect(
        report.violations,
        contains('entry_nonpositive_window:refresh_latency:0'),
      );
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'contention',
            _entry(
              signal: 'contention',
              referenceState: 'background_contention',
              source:
                  'docs/planning/v1.2/sprint_114_performance_responsiveness_health.json',
              window: 999999,
            ),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:contention:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118PerformanceResourceHealthEntry>[
        ...Sprint118PerformanceResourceHealthContract.canonicalReview.entries,
        _entry(signal: 'render_latency'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      expect(report.violations, contains('signal_duplicate:render_latency'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118PerformanceResourceHealthEntry>[
        for (final e
            in Sprint118PerformanceResourceHealthContract
                .canonicalReview
                .entries)
          if (e.signal != 'cache_growth') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      expect(report.violations, contains('signal_missing:cache_growth'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'render_latency',
            _entry(signal: 'unknown_signal', referenceState: 'render_budget'),
          ),
        ),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      // The replacement also removes the real 'render_latency' entry, so both
      // the unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:render_latency'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_115_performance_resilience.json',
          ],
        ),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessPerformanceResponsiveness: const <String>[],
          witnessMemoryStorageCache: const <String>[],
          witnessPerformanceResilience: const <String>[],
        ),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.blocked);
      expect(
        report.blockers,
        contains('upstream_performance_vocabulary_missing'),
      );
    });

    test('records an open item when a signal carries no_reference_state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'cache_growth',
            _entry(
              signal: 'cache_growth',
              referenceState:
                  Sprint118PerformanceResourceHealthContract.noReferenceState,
              source:
                  'docs/planning/v1.2/sprint_114_memory_storage_cache_health.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PerformanceResourceHealthState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:cache_growth'),
      );
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118PerformanceResourceHealthContract.sourceFor('render_latency'),
        'docs/planning/v1.2/sprint_115_performance_resilience.json',
      );
      expect(
        Sprint118PerformanceResourceHealthContract.sourceFor('cache_growth'),
        'docs/planning/v1.2/sprint_114_memory_storage_cache_health.json',
      );
      expect(
        Sprint118PerformanceResourceHealthContract.sourceFor('unknown'),
        '',
      );
    });
  });
}
