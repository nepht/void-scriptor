import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_post_release_health_baseline.dart';

/// A fully satisfied baseline. Each test flips exactly the one thing it is
/// about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it. The canonical baseline
/// freezes the ten health signals the 118.4 contract names, each with a
/// threshold drawn from committed evidence, and it observes nothing because the
/// release is delayed -- which is the honest state of the committed evidence.
Sprint118HealthBaselineEntry _entry({
  String signal = 'connection',
  String baseline = 'no_live_observation',
  String threshold = 'gte:0.95',
  String source =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json',
  int window = 60,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118HealthBaselineEntry(
    signal: signal,
    baseline: baseline,
    threshold: threshold,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118PostReleaseHealthBaseline _baseline({
  String releaseState = Sprint118BaselineContract.delayedReleaseState,
  List<Sprint118HealthBaselineEntry>? entries,
}) {
  return Sprint118PostReleaseHealthBaseline(
    releaseState: releaseState,
    entries: entries ?? Sprint118BaselineContract.canonicalBaseline.entries,
  );
}

/// The canonical ten entries with exactly one signal replaced, so a test can
/// flip a single field without rebuilding the whole baseline.
List<Sprint118HealthBaselineEntry> _replacing(
  String signal,
  Sprint118HealthBaselineEntry replacement,
) {
  return <Sprint118HealthBaselineEntry>[
    for (final entry in Sprint118BaselineContract.canonicalBaseline.entries)
      if (entry.signal == signal) replacement else entry,
  ];
}

Sprint118HealthBaselineAnchor _anchor({
  String snapshotState = 'pass',
  String snapshotVerdict = Sprint118BaselineContract.requiredSnapshotVerdict,
  String releaseState = Sprint118BaselineContract.delayedReleaseState,
  int charterWindowMinutes = Sprint118BaselineContract.charterWindowMinutes,
  List<String>? readableSources,
}) {
  return Sprint118HealthBaselineAnchor(
    snapshotState: snapshotState,
    snapshotVerdict: snapshotVerdict,
    releaseState: releaseState,
    charterWindowMinutes: charterWindowMinutes,
    readableSources:
        readableSources ?? Sprint118BaselineContract.canonicalSources,
  );
}

Sprint118HealthBaselineReport _run(
  Sprint118PostReleaseHealthBaseline baseline, {
  Sprint118HealthBaselineAnchor? anchor,
}) {
  return const Sprint118PostReleaseHealthBaselineGate().evaluateWith(
    anchor ?? _anchor(),
    baseline,
  );
}

void main() {
  group('118.4 Post-Release Health Baseline', () {
    test('declares the canonical step, fields, and paths', () {
      expect(Sprint118BaselineContract.canonicalStep, '118.4');
      expect(Sprint118BaselineContract.title, 'Post-Release Health Baseline');
      expect(
        Sprint118BaselineContract.manifestPath,
        'docs/planning/v1.3/sprint_118_post_release_health_baseline.json',
      );
      expect(Sprint118BaselineContract.requiredFields, <String>[
        'signal',
        'baseline',
        'threshold',
        'source',
        'window',
        'limitations',
      ]);
      expect(Sprint118BaselineContract.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118BaselineContract.requiredFields.length, 6);
      expect(Sprint118BaselineContract.canonicalAreas.length, 10);
      expect(
        Sprint118BaselineContract.canonicalAreas,
        containsAll(<String>[
          'connection',
          'reauth',
          'quota',
          'sync',
          'backup',
          'ai',
          'billing',
          'crash',
          'performance',
          'support',
        ]),
      );
      expect(
        Sprint118BaselineContract.thresholdOperators,
        containsAll(<String>['gt', 'gte', 'lt', 'lte', 'eq']),
      );
      // The charter window is 42 days; the contract must agree.
      expect(Sprint118BaselineContract.charterWindowMinutes, 42 * 24 * 60);
    });

    test('canonical baseline covers every canonical area exactly once', () {
      final signals = Sprint118BaselineContract.canonicalBaseline.signals;
      expect(signals.length, Sprint118BaselineContract.canonicalAreas.length);
      expect(signals.toSet(), Sprint118BaselineContract.canonicalAreas.toSet());
      for (final entry in Sprint118BaselineContract.canonicalBaseline.entries) {
        expect(entry.observed, isFalse);
        expect(entry.limitations, isNotEmpty);
        expect(
          Sprint118BaselineContract.thresholdWellFormed(entry.threshold),
          isTrue,
        );
      }
    });

    test('passes on the canonical baseline', () {
      final report = _run(_baseline());
      expect(report.state, Sprint118BaselineState.pass);
      expect(report.verdict, 'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL');
      expect(report.baselineFrozen, isTrue);
      expect(report.baselineSignals.length, 10);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });

    test('passes when every canonical source is readable', () {
      final report = _run(
        _baseline(),
        anchor: _anchor(
          readableSources: Sprint118BaselineContract.canonicalSources,
        ),
      );
      expect(report.state, Sprint118BaselineState.pass);
      expect(report.violations, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118PostReleaseHealthBaselineGate()
          .evaluateWith(null, _baseline());
      expect(report.state, Sprint118BaselineState.blocked);
      expect(report.verdict, 'SPRINT_118_BASELINE_EVIDENCE_UNREADABLE');
      expect(
        report.blockers,
        contains('committed_baseline_evidence_unreadable'),
      );
    });

    test('blocks when the 118.3 snapshot did not freeze', () {
      final report = _run(
        _baseline(),
        anchor: _anchor(
          snapshotVerdict: 'SPRINT_118_SNAPSHOT_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118BaselineState.blocked);
      expect(
        report.blockers,
        contains('snapshot_not_frozen:SPRINT_118_SNAPSHOT_EVIDENCE_VIOLATION'),
      );
    });

    test('fails when the release state disagrees with the snapshot', () {
      final report = _run(
        _baseline(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118BaselineState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a baseline claims observation on a delayed release', () {
      // GA is delayed: no release ran, so a baseline that reports an observed
      // value describes a release that never happened.
      final report = _run(
        _baseline(
          entries: _replacing(
            'connection',
            _entry(signal: 'connection', observed: true),
          ),
        ),
      );
      expect(report.state, Sprint118BaselineState.fail);
      expect(
        report.violations,
        contains('baseline_claims_observation_without_release:connection'),
      );
    });

    test('fails when a canonical area is missing', () {
      final entries = <Sprint118HealthBaselineEntry>[
        for (final entry in Sprint118BaselineContract.canonicalBaseline.entries)
          if (entry.signal != 'support') entry,
      ];
      final report = _run(_baseline(entries: entries));
      expect(report.state, Sprint118BaselineState.fail);
      expect(report.violations, contains('baseline_area_missing:support'));
    });

    test('fails on an unknown area', () {
      final entries = <Sprint118HealthBaselineEntry>[
        ...Sprint118BaselineContract.canonicalBaseline.entries,
        _entry(signal: 'telepathy'),
      ];
      final report = _run(_baseline(entries: entries));
      expect(report.state, Sprint118BaselineState.fail);
      expect(report.violations, contains('baseline_unknown_area:telepathy'));
    });

    test('fails on a duplicate area', () {
      final entries = <Sprint118HealthBaselineEntry>[
        ...Sprint118BaselineContract.canonicalBaseline.entries,
        _entry(signal: 'connection'),
      ];
      final report = _run(_baseline(entries: entries));
      expect(report.state, Sprint118BaselineState.fail);
      expect(report.violations, contains('baseline_duplicate_area:connection'));
    });

    test('fails on blank entry fields', () {
      final blankBaseline = _run(
        _baseline(
          entries: _replacing('quota', _entry(signal: 'quota', baseline: '')),
        ),
      );
      expect(blankBaseline.state, Sprint118BaselineState.fail);
      expect(blankBaseline.violations, contains('entry_blank_baseline:quota'));

      final blankSource = _run(
        _baseline(
          entries: _replacing('quota', _entry(signal: 'quota', source: '')),
        ),
      );
      expect(blankSource.state, Sprint118BaselineState.fail);
      expect(blankSource.violations, contains('entry_blank_source:quota'));

      final blankThreshold = _run(
        _baseline(
          entries: _replacing('quota', _entry(signal: 'quota', threshold: '')),
        ),
      );
      expect(blankThreshold.state, Sprint118BaselineState.fail);
      expect(
        blankThreshold.violations,
        contains('entry_blank_threshold:quota'),
      );
    });

    test('fails on a non-positive window', () {
      final report = _run(
        _baseline(
          entries: _replacing('sync', _entry(signal: 'sync', window: 0)),
        ),
      );
      expect(report.state, Sprint118BaselineState.fail);
      expect(report.violations, contains('entry_nonpositive_window:sync:0'));
    });

    test('fails when a window exceeds the charter window', () {
      // The charter declares a 42-day observation window; a baseline that
      // monitors for longer is not frozen against the charter.
      final report = _run(
        _baseline(),
        anchor: _anchor(charterWindowMinutes: 30),
      );
      expect(report.state, Sprint118BaselineState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('entry_window_exceeds_charter:connection:60:30'),
        ),
        isTrue,
      );
    });

    test('fails when an entry carries no limitation', () {
      final report = _run(
        _baseline(
          entries: _replacing(
            'crash',
            _entry(signal: 'crash', limitations: const <String>[]),
          ),
        ),
      );
      expect(report.state, Sprint118BaselineState.fail);
      expect(report.violations, contains('entry_no_limitations:crash'));
    });

    test('fails on a malformed threshold', () {
      final report = _run(
        _baseline(
          entries: _replacing(
            'performance',
            _entry(signal: 'performance', threshold: 'faster-than-light'),
          ),
        ),
      );
      expect(report.state, Sprint118BaselineState.fail);
      expect(
        report.violations,
        contains('entry_malformed_threshold:performance:faster-than-light'),
      );
    });

    test('fails when a source is not readable', () {
      final report = _run(
        _baseline(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.3/sprint_118_stability_expansion_charter.json',
          ],
        ),
      );
      expect(report.state, Sprint118BaselineState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('entry_unreadable_source:quota:'),
        ),
        isTrue,
      );
    });

    test('thresholdWellFormed accepts operators and refuses garbage', () {
      expect(Sprint118BaselineContract.thresholdWellFormed('gte:0.95'), isTrue);
      expect(Sprint118BaselineContract.thresholdWellFormed('lte:0.01'), isTrue);
      expect(Sprint118BaselineContract.thresholdWellFormed('eq:0.0'), isTrue);
      expect(Sprint118BaselineContract.thresholdWellFormed('gt:1'), isTrue);
      expect(Sprint118BaselineContract.thresholdWellFormed('about:1'), isFalse);
      expect(Sprint118BaselineContract.thresholdWellFormed('gte:'), isFalse);
      expect(Sprint118BaselineContract.thresholdWellFormed('0.95'), isFalse);
      expect(
        Sprint118BaselineContract.thresholdWellFormed('gte:many'),
        isFalse,
      );
    });
  });
}
