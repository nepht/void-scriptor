import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_quota_storage_health.dart';

/// A single quota/storage health entry. Each test flips exactly the one thing
/// it is about, so a test that flips nothing proves the pass path exists and
/// every other test proves one way the gate refuses to take it.
Sprint118QuotaStorageHealthEntry _entry({
  String signal = 'quota_match',
  String referenceState = 'raw_units',
  String source =
      'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
  int window = 1440,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118QuotaStorageHealthEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118QuotaStorageHealthReview _review({
  String releaseState = Sprint118QuotaStorageHealthContract.delayedReleaseState,
  List<Sprint118QuotaStorageHealthEntry>? entries,
}) {
  return Sprint118QuotaStorageHealthReview(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118QuotaStorageHealthContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118QuotaStorageHealthEntry> _replacing(
  String signal,
  Sprint118QuotaStorageHealthEntry replacement,
) {
  return <Sprint118QuotaStorageHealthEntry>[
    for (final e in Sprint118QuotaStorageHealthContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118QuotaStorageHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118QuotaStorageHealthContract.requiredBaselineVerdict,
  String releaseState = Sprint118QuotaStorageHealthContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118QuotaStorageHealthContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118QuotaStorageHealthContract.charterWindowMinutes,
  List<String>? witnessQuotaAcceptance,
  List<String>? witnessAdapterAcceptance,
  List<String>? witnessLocalAcceptance,
  List<String>? witnessAggregationAcceptance,
  List<String>? readableSources,
}) {
  return Sprint118QuotaStorageHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessQuotaAcceptance:
        witnessQuotaAcceptance ??
        const <String>[
          'raw_units',
          'display_units',
          'freshness',
          'unavailable',
          'partial_total',
          'stale_warning',
          'no_mock_values',
        ],
    witnessAdapterAcceptance:
        witnessAdapterAcceptance ??
        const <String>[
          'raw_bytes',
          'provider_timestamp',
          'unit_metadata',
          'quota_unavailable',
          'stale_state',
          'refresh',
        ],
    witnessLocalAcceptance:
        witnessLocalAcceptance ??
        const <String>[
          'local_scan',
          'category_breakdown',
          'free_space',
          'protected_data',
          'regenerable_data',
          'scan_freshness',
        ],
    witnessAggregationAcceptance:
        witnessAggregationAcceptance ??
        const <String>[
          'remote_only_total',
          'partial_indicator',
          'stale_indicator',
          'excluded_accounts',
          'last_updated',
          'no_false_precision',
        ],
    readableSources:
        readableSources ?? Sprint118QuotaStorageHealthContract.canonicalSources,
  );
}

Sprint118QuotaStorageHealthReport _run(
  Sprint118QuotaStorageHealthReview review, {
  Sprint118QuotaStorageHealthAnchor? anchor,
}) {
  return const Sprint118QuotaStorageHealthGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.9 Quota & Storage Health', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118QuotaStorageHealthContract.canonicalStep, '118.9');
      expect(
        Sprint118QuotaStorageHealthContract.title,
        'Quota & Storage Health',
      );
      expect(
        Sprint118QuotaStorageHealthContract.manifestPath,
        'docs/planning/v1.3/sprint_118_quota_storage_health.json',
      );
      expect(Sprint118QuotaStorageHealthContract.requiredFields, <String>[
        'signal',
        'reference_state',
        'source',
        'window',
        'limitations',
      ]);
      expect(
        Sprint118QuotaStorageHealthContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118QuotaStorageHealthContract.requiredFields.length, 5);
      expect(Sprint118QuotaStorageHealthContract.quotaStorageSignals.length, 7);
      expect(Sprint118QuotaStorageHealthContract.canonicalSources.length, 7);
      // Every canonical signal maps to a committed evidence source.
      final sources = <String>{
        for (final s in Sprint118QuotaStorageHealthContract.quotaStorageSignals)
          Sprint118QuotaStorageHealthContract.sourceFor(s),
      };
      expect(sources.length, 7);
      // The reference-state vocabulary is the distinct union of the witness
      // vocabularies, in witness order.
      final vocab = Sprint118QuotaStorageHealthContract.stateVocabulary(
        const <List<String>>[
          <String>['raw_units', 'partial_total'],
          <String>['refresh', 'stale_state'],
          <String>['local_scan', 'partial_total'],
          <String>['no_false_precision', 'refresh'],
        ],
      );
      expect(vocab, <String>[
        'raw_units',
        'partial_total',
        'refresh',
        'stale_state',
        'local_scan',
        'no_false_precision',
      ]);
    });

    test('canonical review covers the seven signals and claims no live '
        'observation', () {
      final review = Sprint118QuotaStorageHealthContract.canonicalReview;
      expect(review.signals.length, 7);
      expect(review.signals.toSet(), <String>{
        'quota_match',
        'refresh_failure',
        'stale_data',
        'partial_total',
        'unit_issue',
        'local_scan',
        'false_precision',
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
      expect(report.state, Sprint118QuotaStorageHealthState.pass);
      expect(report.verdict, 'QUOTA_STORAGE_HEALTH_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.declaredSignals.length, 7);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118QuotaStorageHealthGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_QUOTA_STORAGE_HEALTH_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_quota_storage_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.blocked);
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
      expect(report.state, Sprint118QuotaStorageHealthState.blocked);
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
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'quota_match',
            _entry(
              signal: 'quota_match',
              referenceState: 'raw_units',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      expect(
        report.violations,
        contains('quota_claims_observation_without_release:quota_match'),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'false_precision',
            _entry(signal: 'false_precision', referenceState: 'SOMETHING_ELSE'),
          ),
        ),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unknown_reference_state:false_precision:SOMETHING_ELSE',
        ),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'stale_data',
            _entry(
              signal: 'stale_data',
              referenceState: 'stale_state',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unreadable_source:stale_data:docs/planning/missing.json',
        ),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'quota_match',
            _entry(signal: 'quota_match', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      expect(
        report.violations,
        contains('entry_blank_reference_state:quota_match'),
      );
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'refresh_failure',
            _entry(signal: 'refresh_failure', limitations: const <String>[]),
          ),
        ),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      expect(
        report.violations,
        contains('entry_no_limitations:refresh_failure'),
      );
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'unit_issue',
            _entry(
              signal: 'unit_issue',
              referenceState: 'display_units',
              window: 0,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      expect(
        report.violations,
        contains('entry_nonpositive_window:unit_issue:0'),
      );
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'local_scan',
            _entry(
              signal: 'local_scan',
              referenceState: 'local_scan',
              window: 999999,
            ),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:local_scan:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118QuotaStorageHealthEntry>[
        ...Sprint118QuotaStorageHealthContract.canonicalReview.entries,
        _entry(signal: 'quota_match'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      expect(report.violations, contains('signal_duplicate:quota_match'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118QuotaStorageHealthEntry>[
        for (final e
            in Sprint118QuotaStorageHealthContract.canonicalReview.entries)
          if (e.signal != 'partial_total') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      expect(report.violations, contains('signal_missing:partial_total'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'quota_match',
            _entry(signal: 'unknown_signal', referenceState: 'raw_units'),
          ),
        ),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      // The replacement also removes the real 'quota_match' entry, so both the
      // unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:quota_match'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
          ],
        ),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessQuotaAcceptance: const <String>[],
          witnessAdapterAcceptance: const <String>[],
          witnessLocalAcceptance: const <String>[],
          witnessAggregationAcceptance: const <String>[],
        ),
      );
      expect(report.state, Sprint118QuotaStorageHealthState.blocked);
      expect(report.blockers, contains('upstream_quota_vocabulary_missing'));
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118QuotaStorageHealthContract.sourceFor('quota_match'),
        'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
      );
      expect(
        Sprint118QuotaStorageHealthContract.sourceFor('false_precision'),
        'docs/planning/v1.2/sprint_116_local_storage_certification.json',
      );
      expect(Sprint118QuotaStorageHealthContract.sourceFor('unknown'), '');
    });
  });
}
