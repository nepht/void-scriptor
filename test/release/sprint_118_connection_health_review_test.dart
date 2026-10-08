import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_connection_health_review.dart';

/// A single connection-health entry. Each test flips exactly the one thing it is
/// about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ConnectionHealthEntry _entry({
  String signal = 'connect_success',
  String referenceState = 'CONNECT_SUCCEEDED',
  String source =
      'docs/planning/v1.2/sprint_115_connection_health_state_machine.json',
  int window = 60,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118ConnectionHealthEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118ConnectionHealthReview _review({
  String releaseState = Sprint118ConnectionHealthContract.delayedReleaseState,
  List<Sprint118ConnectionHealthEntry>? entries,
}) {
  return Sprint118ConnectionHealthReview(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118ConnectionHealthContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118ConnectionHealthEntry> _replacing(
  String signal,
  Sprint118ConnectionHealthEntry replacement,
) {
  return <Sprint118ConnectionHealthEntry>[
    for (final e in Sprint118ConnectionHealthContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118ConnectionHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118ConnectionHealthContract.requiredBaselineVerdict,
  String releaseState = Sprint118ConnectionHealthContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118ConnectionHealthContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118ConnectionHealthContract.charterWindowMinutes,
  List<String>? witnessConnectionStates,
  List<String>? witnessHealthStates,
  List<String>? witnessTransitions,
  List<String>? readableSources,
}) {
  return Sprint118ConnectionHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessConnectionStates:
        witnessConnectionStates ??
        const <String>[
          'NOT_CONFIGURED',
          'CONNECTING',
          'CONNECTED',
          'DEGRADED',
          'EXPIRED',
          'REVOKED',
          'ERROR',
          'UNAVAILABLE',
        ],
    witnessHealthStates:
        witnessHealthStates ??
        const <String>[
          'UNKNOWN',
          'HEALTHY',
          'DEGRADED',
          'OUTAGE',
          'RATE_LIMITED',
        ],
    witnessTransitions:
        witnessTransitions ??
        const <String>[
          'BEGIN_CONNECTING',
          'CONNECT_SUCCEEDED',
          'ERROR',
          'UNAVAILABLE',
          'EXPIRE',
          'REVOKE',
          'REFRESH_HEALTH',
          'REAUTHENTICATE',
          'RETRY',
        ],
    readableSources:
        readableSources ?? Sprint118ConnectionHealthContract.canonicalSources,
  );
}

Sprint118ConnectionHealthReport _run(
  Sprint118ConnectionHealthReview review, {
  Sprint118ConnectionHealthAnchor? anchor,
}) {
  return const Sprint118ConnectionHealthGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.7 Connection Health Review', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118ConnectionHealthContract.canonicalStep, '118.7');
      expect(
        Sprint118ConnectionHealthContract.title,
        'Connection Health Review',
      );
      expect(
        Sprint118ConnectionHealthContract.manifestPath,
        'docs/planning/v1.3/sprint_118_connection_health_review.json',
      );
      expect(Sprint118ConnectionHealthContract.requiredFields, <String>[
        'signal',
        'reference_state',
        'source',
        'window',
        'limitations',
      ]);
      expect(
        Sprint118ConnectionHealthContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118ConnectionHealthContract.requiredFields.length, 5);
      expect(
        Sprint118ConnectionHealthContract.connectionHealthSignals.length,
        7,
      );
      expect(Sprint118ConnectionHealthContract.canonicalSources.length, 7);
      // Every canonical signal maps to a distinct committed evidence source.
      final sources = <String>{
        for (final s
            in Sprint118ConnectionHealthContract.connectionHealthSignals)
          Sprint118ConnectionHealthContract.sourceFor(s),
      };
      expect(sources.length, 7);
      // The state vocabulary is the distinct union of the witness vocabularies.
      final vocab = Sprint118ConnectionHealthContract.stateVocabulary(
        const <String>['CONNECTED', 'DEGRADED'],
        const <String>['HEALTHY', 'DEGRADED'],
        const <String>['CONNECT_SUCCEEDED'],
      );
      expect(vocab, <String>[
        'CONNECTED',
        'DEGRADED',
        'HEALTHY',
        'CONNECT_SUCCEEDED',
      ]);
    });

    test('canonical review covers the seven signals and claims no live '
        'observation', () {
      final review = Sprint118ConnectionHealthContract.canonicalReview;
      expect(review.signals.length, 7);
      expect(review.signals.toSet(), <String>{
        'connect_success',
        'expiry',
        'revoke',
        'degraded',
        'outage',
        'latency',
        'disconnect_cleanup',
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
      expect(report.state, Sprint118ConnectionHealthState.pass);
      expect(report.verdict, 'CONNECTION_HEALTH_REVIEW_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.declaredSignals.length, 7);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      // The two signals the committed state-machine witness has no state for
      // are reported honestly rather than dropped.
      expect(
        report.openItems,
        containsAll(<String>[
          'upstream_state_vocabulary_gap:latency',
          'upstream_state_vocabulary_gap:disconnect_cleanup',
        ]),
      );
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118ConnectionHealthGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118ConnectionHealthState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_CONNECTION_HEALTH_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_connection_health_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118ConnectionHealthState.blocked);
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
      expect(report.state, Sprint118ConnectionHealthState.blocked);
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
      expect(report.state, Sprint118ConnectionHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'degraded',
            _entry(
              signal: 'degraded',
              referenceState: 'DEGRADED',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectionHealthState.fail);
      expect(
        report.violations,
        contains('connection_claims_observation_without_release:degraded'),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'revoke',
            _entry(signal: 'revoke', referenceState: 'SOMETHING_ELSE'),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectionHealthState.fail);
      expect(
        report.violations,
        contains('entry_unknown_reference_state:revoke:SOMETHING_ELSE'),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'outage',
            _entry(
              signal: 'outage',
              referenceState: 'OUTAGE',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectionHealthState.fail);
      expect(
        report.violations,
        contains('entry_unreadable_source:outage:docs/planning/missing.json'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'expiry',
            _entry(signal: 'expiry', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectionHealthState.fail);
      expect(report.violations, contains('entry_blank_reference_state:expiry'));
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'connect_success',
            _entry(signal: 'connect_success', limitations: const <String>[]),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectionHealthState.fail);
      expect(
        report.violations,
        contains('entry_no_limitations:connect_success'),
      );
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'connect_success',
            _entry(signal: 'connect_success', window: 0),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectionHealthState.fail);
      expect(
        report.violations,
        contains('entry_nonpositive_window:connect_success:0'),
      );
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'connect_success',
            _entry(signal: 'connect_success', window: 999999),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118ConnectionHealthState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:connect_success:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118ConnectionHealthEntry>[
        ...Sprint118ConnectionHealthContract.canonicalReview.entries,
        _entry(signal: 'connect_success'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118ConnectionHealthState.fail);
      expect(report.violations, contains('signal_duplicate:connect_success'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118ConnectionHealthEntry>[
        for (final e
            in Sprint118ConnectionHealthContract.canonicalReview.entries)
          if (e.signal != 'latency') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118ConnectionHealthState.fail);
      expect(report.violations, contains('signal_missing:latency'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'connect_success',
            _entry(signal: 'unknown_signal', referenceState: 'CONNECTED'),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectionHealthState.fail);
      // The replacement also removes the real 'connect_success' entry, so both
      // the unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:connect_success'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_115_connection_health_state_machine.json',
          ],
        ),
      );
      expect(report.state, Sprint118ConnectionHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness state vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessConnectionStates: const <String>[],
          witnessHealthStates: const <String>[],
          witnessTransitions: const <String>[],
        ),
      );
      expect(report.state, Sprint118ConnectionHealthState.blocked);
      expect(report.blockers, contains('upstream_state_vocabulary_missing'));
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118ConnectionHealthContract.sourceFor('connect_success'),
        'docs/planning/v1.2/sprint_115_connection_health_state_machine.json',
      );
      expect(
        Sprint118ConnectionHealthContract.sourceFor('revoke'),
        'docs/planning/v1.3/sprint_117_provider_rollback_drill.json',
      );
      expect(Sprint118ConnectionHealthContract.sourceFor('unknown'), '');
    });
  });
}
