import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_connector_disable_safe_degradation.dart';

/// A single disable-review entry. Each test flips exactly the one thing it is
/// about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ConnectorDisableEntry _entry({
  String acceptance = 'per_connector_kill_switch',
  String referenceState = 'kill_switch',
  String source = Sprint118ConnectorDisableContract.drillManifestPath,
  String detail =
      'A misbehaving connector is disabled by its own kill switch without '
      'affecting the Account Center',
  List<String>? limitations,
  bool connectorDisabled = false,
  bool localDataTouched = false,
  bool messageSent = false,
  bool observed = false,
}) {
  return Sprint118ConnectorDisableEntry(
    acceptance: acceptance,
    referenceState: referenceState,
    source: source,
    detail: detail,
    limitations: limitations ?? const <String>['synthetic_local'],
    connectorDisabled: connectorDisabled,
    localDataTouched: localDataTouched,
    messageSent: messageSent,
    observed: observed,
  );
}

Sprint118ConnectorDisableReview _review({
  String releaseState = Sprint118ConnectorDisableContract.delayedReleaseState,
  List<Sprint118ConnectorDisableEntry>? entries,
}) {
  return Sprint118ConnectorDisableReview(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118ConnectorDisableContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one acceptance item replaced, so a test
/// can flip a single field without rebuilding the whole review.
List<Sprint118ConnectorDisableEntry> _replacing(
  String acceptance,
  Sprint118ConnectorDisableEntry replacement,
) {
  return <Sprint118ConnectorDisableEntry>[
    for (final e in Sprint118ConnectorDisableContract.canonicalReview.entries)
      if (e.acceptance == acceptance) replacement else e,
  ];
}

Sprint118ConnectorDisableAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118ConnectorDisableContract.requiredBaselineVerdict,
  String releaseState = Sprint118ConnectorDisableContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118ConnectorDisableContract.requiredCharterVerdict,
  int charterWindowMinutes = 60480,
  String drillState = 'pass',
  String drillVerdict = Sprint118ConnectorDisableContract.requiredDrillVerdict,
  List<String>? drillControls,
  bool rolloutLiveExecuted = false,
  List<String>? outageSignals,
  List<String>? reauthAcceptance,
  List<String>? cachedAcceptance,
  List<String>? rolloutFields,
  List<String>? readableSources,
}) {
  return Sprint118ConnectorDisableAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    drillState: drillState,
    drillVerdict: drillVerdict,
    drillControls:
        drillControls ??
        const <String>[
          'kill_switch',
          'token_revoke',
          'queue_stop',
          'cache_handling',
          'artifact_rollback',
          'communication',
        ],
    rolloutLiveExecuted: rolloutLiveExecuted,
    outageSignals:
        outageSignals ??
        const <String>[
          'timeout',
          'circuit_breaker',
          'retry_after',
          'queue_recovery',
          'cached_state',
          'kill_switch',
          'provider_recovery',
        ],
    reauthAcceptance:
        reauthAcceptance ??
        const <String>[
          'expiry_notice',
          'affected_scope',
          'reauth',
          'retry',
          'revoke',
          'local_data_preserved',
        ],
    cachedAcceptance:
        cachedAcceptance ??
        const <String>[
          'freshness_label',
          'stale_state',
          'remote_disable',
          'local_actions',
          'reconnect',
          'cache_clear',
        ],
    rolloutFields:
        rolloutFields ??
        const <String>[
          'flags',
          'stages',
          'health_metrics',
          'stop_conditions',
          'provider_kill_switches',
          'rollback',
          'communication',
        ],
    readableSources:
        readableSources ?? Sprint118ConnectorDisableContract.canonicalSources,
  );
}

Sprint118ConnectorDisableReport _run(
  Sprint118ConnectorDisableReview review, {
  Sprint118ConnectorDisableAnchor? anchor,
}) {
  return const Sprint118ConnectorDisableGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.25 Connector Disable & Safe Degradation', () {
    test('declares the canonical step, title, acceptance, and paths', () {
      expect(Sprint118ConnectorDisableContract.canonicalStep, '118.25');
      expect(
        Sprint118ConnectorDisableContract.title,
        'Connector Disable & Safe Degradation',
      );
      expect(
        Sprint118ConnectorDisableContract.manifestPath,
        'docs/planning/v1.3/sprint_118_connector_disable_safe_degradation.json',
      );
      expect(Sprint118ConnectorDisableContract.requiredAcceptance, <String>[
        'per_connector_kill_switch',
        'safe_queue_stop',
        'cached_state',
        'local_data_preserved',
        'user_message',
        'recovery_path',
      ]);
      expect(Sprint118ConnectorDisableContract.requiredFields, <String>[
        'acceptance',
        'reference_state',
        'source',
        'detail',
        'limitations',
      ]);
      expect(
        Sprint118ConnectorDisableContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118ConnectorDisableContract.requiredAcceptance.length, 6);
      expect(Sprint118ConnectorDisableContract.canonicalSources.length, 6);
      expect(
        Sprint118ConnectorDisableContract.canonicalReview.entries.length,
        6,
      );
      expect(Sprint118ConnectorDisableContract.requiredFields.length, 5);
    });

    test('derives the reference-state vocabulary from committed witnesses', () {
      final vocabulary =
          Sprint118ConnectorDisableContract.stateVocabulary(<List<String>>[
            _anchor().drillControls,
            _anchor().outageSignals,
            _anchor().reauthAcceptance,
            _anchor().cachedAcceptance,
            _anchor().rolloutFields,
          ]);
      for (final state in <String>[
        'kill_switch',
        'queue_stop',
        'cached_state',
        'local_data_preserved',
        'communication',
        'artifact_rollback',
      ]) {
        expect(
          vocabulary,
          contains(state),
          reason: '$state must be grounded in a witness vocabulary',
        );
      }
      expect(
        vocabulary,
        contains(Sprint118ConnectorDisableContract.noReferenceState),
      );
      expect(vocabulary, isNot(contains('telepathy')));
    });

    test(
      'canonical review covers the six items and claims no live disable',
      () {
        final review = Sprint118ConnectorDisableContract.canonicalReview;
        expect(review.entries.length, 6);
        expect(review.acceptanceItems.toSet(), <String>{
          'per_connector_kill_switch',
          'safe_queue_stop',
          'cached_state',
          'local_data_preserved',
          'user_message',
          'recovery_path',
        });
        for (final entry in review.entries) {
          expect(entry.connectorDisabled, isFalse);
          expect(entry.localDataTouched, isFalse);
          expect(entry.messageSent, isFalse);
          expect(entry.observed, isFalse);
          expect(entry.limitations, isNotEmpty);
          for (final field
              in Sprint118ConnectorDisableContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.acceptance}.$field must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical review', () {
      final report = _run(_review());
      expect(report.state, Sprint118ConnectorDisableState.pass);
      expect(
        report.verdict,
        'CONNECTOR_DISABLE_SAFE_DEGRADATION_VERIFIED_LOCAL',
      );
      expect(report.reviewVerified, isTrue);
      expect(report.declaredAcceptance.length, 6);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118ConnectorDisableGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118ConnectorDisableState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_CONNECTOR_DISABLE_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_connector_disable_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.blocked);
      expect(
        report.blockers,
        contains('baseline_not_frozen:SPRINT_118_BASELINE_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 118.2 charter is not complete', () {
      final report = _run(
        _review(),
        anchor: _anchor(charterVerdict: 'CHARTER_EVIDENCE_VIOLATION'),
      );
      expect(report.state, Sprint118ConnectorDisableState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 118.2 charter window is not positive', () {
      final report = _run(_review(), anchor: _anchor(charterWindowMinutes: 0));
      expect(report.state, Sprint118ConnectorDisableState.blocked);
      expect(
        report.blockers,
        contains(
          'charter_not_complete:${Sprint118ConnectorDisableContract.requiredCharterVerdict}',
        ),
      );
    });

    test('blocks when the 117.8 rollback drill is not defined', () {
      final report = _run(
        _review(),
        anchor: _anchor(drillVerdict: 'PROVIDER_ROLLBACK_DRILL_VIOLATION'),
      );
      expect(report.state, Sprint118ConnectorDisableState.blocked);
      expect(
        report.blockers,
        contains(
          'rollback_drill_not_defined:PROVIDER_ROLLBACK_DRILL_VIOLATION',
        ),
      );
    });

    test('blocks when the rollback drill control vocabulary is missing', () {
      final report = _run(
        _review(),
        anchor: _anchor(drillControls: const <String>[]),
      );
      expect(report.state, Sprint118ConnectorDisableState.blocked);
      expect(report.blockers, contains('rollback_drill_controls_missing'));
    });

    test('fails when the release state disagrees with the baseline anchor', () {
      final report = _run(_review(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(
        report.violations,
        contains('release_state_mismatch:anchor=GA_DELAYED:review=GA_RELEASED'),
      );
    });

    test('fails when a live rollout is claimed on the delayed path', () {
      final report = _run(
        _review(),
        anchor: _anchor(rolloutLiveExecuted: true),
      );
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(
        report.violations,
        contains('rollout_claimed_live_on_delayed_path'),
      );
    });

    test('fails when an acceptance item is unknown', () {
      final report = _run(
        _review(
          entries: _replacing(
            'per_connector_kill_switch',
            _entry(acceptance: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(report.violations, contains('acceptance_unknown:telepathy'));
      expect(
        report.violations,
        contains('acceptance_missing:per_connector_kill_switch'),
      );
    });

    test('fails when an acceptance item is duplicated', () {
      final report = _run(
        _review(
          entries: <Sprint118ConnectorDisableEntry>[
            ...Sprint118ConnectorDisableContract.canonicalReview.entries,
            _entry(acceptance: 'cached_state'),
          ],
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(report.violations, contains('acceptance_duplicate:cached_state'));
    });

    test('fails when an acceptance item is missing', () {
      final report = _run(
        _review(
          entries: <Sprint118ConnectorDisableEntry>[
            for (final e
                in Sprint118ConnectorDisableContract.canonicalReview.entries)
              if (e.acceptance != 'recovery_path') e,
          ],
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(report.violations, contains('acceptance_missing:recovery_path'));
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'safe_queue_stop',
            _entry(acceptance: 'safe_queue_stop', detail: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(report.violations, contains('entry_blank_detail:safe_queue_stop'));
    });

    test('fails when a reference state is not drawn from a witness', () {
      final report = _run(
        _review(
          entries: _replacing(
            'cached_state',
            _entry(acceptance: 'cached_state', referenceState: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:cached_state'),
      );
    });

    test('fails when a source is not a committed readable file', () {
      final report = _run(
        _review(
          entries: _replacing(
            'local_data_preserved',
            _entry(
              acceptance: 'local_data_preserved',
              source: 'docs/planning/v1.3/does_not_exist.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(
        report.violations,
        contains('source_unreadable:local_data_preserved'),
      );
    });

    test('fails when a connector disable is claimed without a release', () {
      final report = _run(
        _review(
          entries: _replacing(
            'per_connector_kill_switch',
            _entry(
              acceptance: 'per_connector_kill_switch',
              connectorDisabled: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(
        report.violations,
        contains(
          'connector_disable_claimed_without_release:per_connector_kill_switch',
        ),
      );
    });

    test('fails when local data is touched by a disable', () {
      final report = _run(
        _review(
          entries: _replacing(
            'local_data_preserved',
            _entry(acceptance: 'local_data_preserved', localDataTouched: true),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(
        report.violations,
        contains('local_data_touched_by_disable:local_data_preserved'),
      );
    });

    test('fails when a user message is claimed sent without a release', () {
      final report = _run(
        _review(
          entries: _replacing(
            'user_message',
            _entry(acceptance: 'user_message', messageSent: true),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(
        report.violations,
        contains('user_message_claimed_sent_without_release:user_message'),
      );
    });

    test('fails when a live observation is claimed', () {
      final report = _run(
        _review(
          entries: _replacing(
            'recovery_path',
            _entry(acceptance: 'recovery_path', observed: true),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.fail);
      expect(
        report.violations,
        contains('live_observation_claimed:recovery_path'),
      );
      expect(report.observedCount, 1);
    });

    test('records an upstream gap when a reference state is unavailable', () {
      final report = _run(
        _review(
          entries: _replacing(
            'cached_state',
            _entry(
              acceptance: 'cached_state',
              referenceState:
                  Sprint118ConnectorDisableContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ConnectorDisableState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:cached_state'),
      );
    });
  });
}
