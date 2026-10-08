import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_provider_outage_recovery_review.dart';

/// A single outage/recovery entry. Each test flips exactly the one thing it is
/// about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ProviderOutageRecoveryEntry _entry({
  String signal = 'timeout',
  String referenceState = 'timeout',
  String source =
      'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json',
  int window = 1440,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118ProviderOutageRecoveryEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118ProviderOutageRecoveryReview _review({
  String releaseState =
      Sprint118ProviderOutageRecoveryContract.delayedReleaseState,
  List<Sprint118ProviderOutageRecoveryEntry>? entries,
}) {
  return Sprint118ProviderOutageRecoveryReview(
    releaseState: releaseState,
    entries:
        entries ??
        Sprint118ProviderOutageRecoveryContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118ProviderOutageRecoveryEntry> _replacing(
  String signal,
  Sprint118ProviderOutageRecoveryEntry replacement,
) {
  return <Sprint118ProviderOutageRecoveryEntry>[
    for (final e
        in Sprint118ProviderOutageRecoveryContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118ProviderOutageRecoveryAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118ProviderOutageRecoveryContract.requiredBaselineVerdict,
  String releaseState =
      Sprint118ProviderOutageRecoveryContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118ProviderOutageRecoveryContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118ProviderOutageRecoveryContract.charterWindowMinutes,
  List<String>? witnessRetryBackoffCircuitBreaker,
  List<String>? witnessProviderDependency,
  List<String>? witnessOfflineLocalFirst,
  List<String>? witnessRollbackDrill,
  List<String>? witnessOfflineCachedMetadata,
  List<String>? readableSources,
}) {
  return Sprint118ProviderOutageRecoveryAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessRetryBackoffCircuitBreaker:
        witnessRetryBackoffCircuitBreaker ??
        const <String>[
          'idempotency',
          'bounded_retry',
          'exponential_backoff',
          'jitter',
          'retry_after',
          'cancellation',
          'circuit_breaker',
        ],
    witnessProviderDependency:
        witnessProviderDependency ??
        const <String>[
          'provider_availability',
          'timeout',
          'throttling',
          'auth_expiry',
          'cost_visibility',
          'fallback_success',
          'consent_failure',
        ],
    witnessOfflineLocalFirst:
        witnessOfflineLocalFirst ??
        const <String>[
          'offline_open',
          'offline_edit',
          'offline_search',
          'local_analysis',
          'local_export',
          'queue_recovery',
        ],
    witnessRollbackDrill:
        witnessRollbackDrill ??
        const <String>[
          'kill_switch',
          'token_revoke',
          'queue_stop',
          'cache_handling',
          'artifact_rollback',
          'communication',
        ],
    witnessOfflineCachedMetadata:
        witnessOfflineCachedMetadata ??
        const <String>[
          'freshness_label',
          'stale_state',
          'remote_disable',
          'local_actions',
          'reconnect',
          'cache_clear',
        ],
    readableSources:
        readableSources ??
        Sprint118ProviderOutageRecoveryContract.canonicalSources,
  );
}

Sprint118ProviderOutageRecoveryReport _run(
  Sprint118ProviderOutageRecoveryReview review, {
  Sprint118ProviderOutageRecoveryAnchor? anchor,
}) {
  return const Sprint118ProviderOutageRecoveryGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.17 Provider Outage & Recovery Review', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118ProviderOutageRecoveryContract.canonicalStep, '118.17');
      expect(
        Sprint118ProviderOutageRecoveryContract.title,
        'Provider Outage & Recovery Review',
      );
      expect(
        Sprint118ProviderOutageRecoveryContract.manifestPath,
        'docs/planning/v1.3/sprint_118_provider_outage_recovery_review.json',
      );
      expect(Sprint118ProviderOutageRecoveryContract.requiredFields, <String>[
        'signal',
        'reference_state',
        'source',
        'window',
        'limitations',
      ]);
      expect(
        Sprint118ProviderOutageRecoveryContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118ProviderOutageRecoveryContract.requiredFields.length, 5);
      expect(
        Sprint118ProviderOutageRecoveryContract.outageRecoverySignals.length,
        7,
      );
      expect(
        Sprint118ProviderOutageRecoveryContract.canonicalSources.length,
        7,
      );
      // Every canonical signal maps to a committed evidence source.
      for (final s
          in Sprint118ProviderOutageRecoveryContract.outageRecoverySignals) {
        expect(
          Sprint118ProviderOutageRecoveryContract.sourceFor(s),
          isNotEmpty,
        );
      }
      // The reference-state vocabulary is the distinct union of the witness
      // vocabularies, in witness order.
      final vocab = Sprint118ProviderOutageRecoveryContract.stateVocabulary(
        const <List<String>>[
          <String>['circuit_breaker', 'retry_after'],
          <String>['timeout', 'fallback_success'],
          <String>['queue_recovery'],
          <String>['kill_switch', 'cache_handling'],
          <String>['stale_state', 'cache_clear'],
        ],
      );
      expect(vocab, <String>[
        'circuit_breaker',
        'retry_after',
        'timeout',
        'fallback_success',
        'queue_recovery',
        'kill_switch',
        'cache_handling',
        'stale_state',
        'cache_clear',
      ]);
    });

    test('canonical review covers the seven signals and claims no live '
        'observation', () {
      final review = Sprint118ProviderOutageRecoveryContract.canonicalReview;
      expect(review.signals.length, 7);
      expect(review.signals.toSet(), <String>{
        'timeout',
        'circuit_breaker',
        'retry_after',
        'queue_recovery',
        'cached_state',
        'kill_switch',
        'provider_recovery',
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
      expect(report.state, Sprint118ProviderOutageRecoveryState.pass);
      expect(report.verdict, 'PROVIDER_OUTAGE_RECOVERY_REVIEW_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.declaredSignals.length, 7);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      // Every canonical signal has a witness state, so no upstream gap is
      // recorded.
      expect(report.openItems, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118ProviderOutageRecoveryGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_PROVIDER_OUTAGE_RECOVERY_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_provider_outage_recovery_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.blocked);
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
      expect(report.state, Sprint118ProviderOutageRecoveryState.blocked);
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
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'circuit_breaker',
            _entry(
              signal: 'circuit_breaker',
              referenceState: 'circuit_breaker',
              source:
                  'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      expect(
        report.violations,
        contains('outage_claims_observation_without_release:circuit_breaker'),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'kill_switch',
            _entry(
              signal: 'kill_switch',
              referenceState: 'SOMETHING_ELSE',
              source:
                  'docs/planning/v1.3/sprint_117_provider_rollback_drill.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      expect(
        report.violations,
        contains('entry_unknown_reference_state:kill_switch:SOMETHING_ELSE'),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'queue_recovery',
            _entry(
              signal: 'queue_recovery',
              referenceState: 'queue_recovery',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      expect(
        report.violations,
        contains(
          'entry_unreadable_source:queue_recovery:docs/planning/missing.json',
        ),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'timeout',
            _entry(signal: 'timeout', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      expect(
        report.violations,
        contains('entry_blank_reference_state:timeout'),
      );
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'cached_state',
            _entry(
              signal: 'cached_state',
              referenceState: 'stale_state',
              source:
                  'docs/planning/v1.2/sprint_116_offline_cached_metadata_certification.json',
              limitations: const <String>[],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      expect(report.violations, contains('entry_no_limitations:cached_state'));
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'retry_after',
            _entry(
              signal: 'retry_after',
              referenceState: 'retry_after',
              source:
                  'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json',
              window: 0,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      expect(
        report.violations,
        contains('entry_nonpositive_window:retry_after:0'),
      );
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'provider_recovery',
            _entry(
              signal: 'provider_recovery',
              referenceState: 'fallback_success',
              source:
                  'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json',
              window: 999999,
            ),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:provider_recovery:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118ProviderOutageRecoveryEntry>[
        ...Sprint118ProviderOutageRecoveryContract.canonicalReview.entries,
        _entry(signal: 'timeout'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      expect(report.violations, contains('signal_duplicate:timeout'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118ProviderOutageRecoveryEntry>[
        for (final e
            in Sprint118ProviderOutageRecoveryContract.canonicalReview.entries)
          if (e.signal != 'provider_recovery') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      expect(report.violations, contains('signal_missing:provider_recovery'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'timeout',
            _entry(signal: 'unknown_signal', referenceState: 'timeout'),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      // The replacement also removes the real 'timeout' entry, so both the
      // unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:timeout'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json',
          ],
        ),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessRetryBackoffCircuitBreaker: const <String>[],
          witnessProviderDependency: const <String>[],
          witnessOfflineLocalFirst: const <String>[],
          witnessRollbackDrill: const <String>[],
          witnessOfflineCachedMetadata: const <String>[],
        ),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.blocked);
      expect(
        report.blockers,
        contains('upstream_outage_recovery_vocabulary_missing'),
      );
    });

    test('records an open item when a signal carries no_reference_state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'kill_switch',
            _entry(
              signal: 'kill_switch',
              referenceState:
                  Sprint118ProviderOutageRecoveryContract.noReferenceState,
              source:
                  'docs/planning/v1.3/sprint_117_provider_rollback_drill.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderOutageRecoveryState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:kill_switch'),
      );
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118ProviderOutageRecoveryContract.sourceFor('timeout'),
        'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json',
      );
      expect(
        Sprint118ProviderOutageRecoveryContract.sourceFor('kill_switch'),
        'docs/planning/v1.3/sprint_117_provider_rollback_drill.json',
      );
      expect(Sprint118ProviderOutageRecoveryContract.sourceFor('unknown'), '');
    });
  });
}
