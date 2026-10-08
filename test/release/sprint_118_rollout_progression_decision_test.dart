import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_rollout_progression_decision.dart';

/// A single decision entry. Each test flips exactly the one thing it is about,
/// so a test that flips nothing proves the pass path exists and every other test
/// proves one way the gate refuses to take it.
Sprint118RolloutProgressionEntry _entry({
  String decision = 'HOLD',
  String referenceState = 'stop_conditions',
  String source = Sprint118RolloutProgressionContract.approvalGateManifestPath,
  String detail =
      'The rollout is held at its declared state while the committed approval '
      'gate records a delay',
  List<String>? limitations,
  bool expansionClaimed = false,
  bool rollbackClaimed = false,
  bool connectorDisableClaimed = false,
  bool observed = false,
}) {
  return Sprint118RolloutProgressionEntry(
    decision: decision,
    referenceState: referenceState,
    source: source,
    detail: detail,
    limitations: limitations ?? const <String>['synthetic_local'],
    expansionClaimed: expansionClaimed,
    rollbackClaimed: rollbackClaimed,
    connectorDisableClaimed: connectorDisableClaimed,
    observed: observed,
  );
}

Sprint118RolloutProgressionDecision _decision({
  String releaseState = Sprint118RolloutProgressionContract.delayedReleaseState,
  Sprint118RolloutDecision selectedDecision = Sprint118RolloutDecision.hold,
  List<Sprint118RolloutProgressionEntry>? entries,
}) {
  return Sprint118RolloutProgressionDecision(
    releaseState: releaseState,
    selectedDecision: selectedDecision,
    entries:
        entries ??
        Sprint118RolloutProgressionContract.canonicalDecision.entries,
  );
}

/// The canonical entries with exactly one decision option replaced, so a test
/// can flip a single entry without rebuilding the whole decision.
List<Sprint118RolloutProgressionEntry> _replacing(
  String decision,
  Sprint118RolloutProgressionEntry replacement,
) {
  return <Sprint118RolloutProgressionEntry>[
    for (final e
        in Sprint118RolloutProgressionContract.canonicalDecision.entries)
      if (e.decision == decision) replacement else e,
  ];
}

Sprint118RolloutProgressionAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118RolloutProgressionContract.requiredBaselineVerdict,
  String releaseState = Sprint118RolloutProgressionContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118RolloutProgressionContract.requiredCharterVerdict,
  int charterWindowMinutes = 60480,
  String regressionState = 'pass',
  String regressionVerdict =
      Sprint118RolloutProgressionContract.requiredRegressionVerdict,
  String disableState = 'pass',
  String disableVerdict =
      Sprint118RolloutProgressionContract.requiredDisableVerdict,
  String approvalDecision =
      Sprint118RolloutProgressionContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  bool liveRolloutExecuted = false,
  List<String>? rolloutFields,
  List<String>? drillControls,
  List<String>? disableAcceptance,
  List<String>? regressionSuites,
  List<String>? baselineAreas,
  List<String>? readableSources,
}) {
  return Sprint118RolloutProgressionAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    regressionState: regressionState,
    regressionVerdict: regressionVerdict,
    disableState: disableState,
    disableVerdict: disableVerdict,
    approvalDecision: approvalDecision,
    approvalState: approvalState,
    executionAuthorized: executionAuthorized,
    releaseBlocked: releaseBlocked,
    liveRolloutExecuted: liveRolloutExecuted,
    rolloutFields:
        rolloutFields ??
        const <String>[
          'stages',
          'connector_subset',
          'exposure',
          'health_criteria',
          'stop_conditions',
          'kill_switches',
          'rollback',
          'support',
        ],
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
    disableAcceptance:
        disableAcceptance ??
        const <String>[
          'per_connector_kill_switch',
          'safe_queue_stop',
          'cached_state',
          'local_data_preserved',
          'user_message',
          'recovery_path',
        ],
    regressionSuites:
        regressionSuites ??
        const <String>[
          'unit',
          'connector_contract',
          'auth',
          'sync',
          'billing',
          'security',
          'privacy',
          'accessibility',
          'ui',
          'end_to_end',
        ],
    baselineAreas:
        baselineAreas ??
        const <String>[
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
        ],
    readableSources:
        readableSources ??
        Sprint118RolloutProgressionContract.canonicalSources.toSet().toList(),
  );
}

Sprint118RolloutProgressionReport _run(
  Sprint118RolloutProgressionDecision decision, {
  Sprint118RolloutProgressionAnchor? anchor,
}) {
  return const Sprint118RolloutProgressionGate().evaluateWith(
    anchor ?? _anchor(),
    decision,
  );
}

void main() {
  group('Sprint 118.27 Rollout Progression Decision', () {
    test('the canonical decision vocabulary is the five options', () {
      expect(Sprint118RolloutProgressionContract.requiredDecisions, <String>[
        'EXPAND',
        'HOLD',
        'REDUCE',
        'DISABLE_CONNECTOR',
        'ROLLBACK',
      ]);
      for (final wire
          in Sprint118RolloutProgressionContract.requiredDecisions) {
        expect(
          Sprint118RolloutDecision.fromWire(wire)?.wireName,
          wire,
          reason: '$wire must round-trip through its exact wire name',
        );
      }
      expect(Sprint118RolloutDecision.fromWire('telepathy'), isNull);
      expect(Sprint118RolloutDecision.fromWire('hold'), isNull);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118RolloutProgressionContract.stateVocabulary(
          <List<String>>[
            const <String>['exposure', 'stop_conditions'],
            const <String>['kill_switch', 'artifact_rollback'],
          ],
        );
        expect(vocabulary, contains('exposure'));
        expect(vocabulary, contains('kill_switch'));
        expect(
          vocabulary,
          contains(Sprint118RolloutProgressionContract.noReferenceState),
        );
        // A token only grounds when the witness names it exactly, or when every
        // underscore-separated part is itself a witness-declared value.
        expect(
          Sprint118RolloutProgressionContract.grounds(vocabulary, 'exposure'),
          isTrue,
        );
        expect(
          Sprint118RolloutProgressionContract.grounds(
            vocabulary,
            'kill_switch',
          ),
          isTrue,
        );
        expect(
          Sprint118RolloutProgressionContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
        expect(
          Sprint118RolloutProgressionContract.grounds(const <String>[
            'kill',
            'switch',
          ], 'kill_switch'),
          isTrue,
        );
        expect(
          Sprint118RolloutProgressionContract.grounds(const <String>[
            'kill',
          ], 'kill_switch'),
          isFalse,
        );
      },
    );

    test(
      'canonical decision covers the five options and claims nothing live',
      () {
        final decision = Sprint118RolloutProgressionContract.canonicalDecision;
        expect(decision.entries.length, 5);
        expect(decision.decisionItems.toSet(), <String>{
          'EXPAND',
          'HOLD',
          'REDUCE',
          'DISABLE_CONNECTOR',
          'ROLLBACK',
        });
        expect(decision.selectedDecision, Sprint118RolloutDecision.hold);
        for (final entry in decision.entries) {
          expect(entry.expansionClaimed, isFalse);
          expect(entry.rollbackClaimed, isFalse);
          expect(entry.connectorDisableClaimed, isFalse);
          expect(entry.observed, isFalse);
          expect(entry.limitations, isNotEmpty);
          for (final field
              in Sprint118RolloutProgressionContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.decision}.$field must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical decision and selects HOLD', () {
      final report = _run(_decision());
      expect(report.state, Sprint118RolloutProgressionState.pass);
      expect(report.verdict, 'ROLLOUT_PROGRESSION_DECISION_VERIFIED_LOCAL');
      expect(report.decisionVerified, isTrue);
      expect(report.selectedDecision, 'HOLD');
      expect(report.declaredDecisions.length, 5);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118RolloutProgressionGate().evaluateWith(
        null,
        _decision(),
      );
      expect(report.state, Sprint118RolloutProgressionState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_ROLLOUT_PROGRESSION_EVIDENCE_UNREADABLE',
      );
      expect(report.decisionVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_rollout_progression_evidence_unreadable'),
      );
    });

    test('blocks when the baseline anchor is not a frozen pass', () {
      final report = _run(
        _decision(),
        anchor: _anchor(
          baselineState: 'fail',
          baselineVerdict: 'POST_RELEASE_HEALTH_BASELINE_DRIFT',
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.blocked);
      expect(report.verdict, 'SPRINT_118_ROLLOUT_PROGRESSION_BLOCKED_UPSTREAM');
      expect(
        report.blockers,
        contains('baseline_not_frozen:POST_RELEASE_HEALTH_BASELINE_DRIFT'),
      );
    });

    test('blocks when the charter anchor is incomplete', () {
      final report = _run(
        _decision(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118RolloutProgressionState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_INCOMPLETE_LOCAL'),
      );
    });

    test('blocks when the charter window is not positive', () {
      final report = _run(
        _decision(),
        anchor: _anchor(charterWindowMinutes: 0),
      );
      expect(report.state, Sprint118RolloutProgressionState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_COMPLETE_LOCAL'),
      );
    });

    test('blocks when the regression matrix is not verified', () {
      final report = _run(
        _decision(),
        anchor: _anchor(
          regressionVerdict: 'MAINTENANCE_REGRESSION_MATRIX_PARTIAL_LOCAL',
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.blocked);
      expect(
        report.blockers,
        contains(
          'regression_matrix_not_verified:'
          'MAINTENANCE_REGRESSION_MATRIX_PARTIAL_LOCAL',
        ),
      );
    });

    test('blocks when the connector disable review is not verified', () {
      final report = _run(
        _decision(),
        anchor: _anchor(
          disableVerdict: 'CONNECTOR_DISABLE_SAFE_DEGRADATION_PARTIAL_LOCAL',
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.blocked);
      expect(
        report.blockers,
        contains(
          'connector_disable_not_verified:'
          'CONNECTOR_DISABLE_SAFE_DEGRADATION_PARTIAL_LOCAL',
        ),
      );
    });

    test('blocks when the approval gate does not record a delay', () {
      final report = _run(
        _decision(),
        anchor: _anchor(approvalDecision: 'release'),
      );
      expect(report.state, Sprint118RolloutProgressionState.blocked);
      expect(report.blockers, contains('approval_gate_not_delay:release'));
    });

    test('reads the approval decision with the owner exact grammar', () {
      // 'DELAY' is the manifest-level word, but the approval block's own field
      // uses the lowercase wire name. The gate matches the owner's grammar, so a
      // case-folded word must not be read as a delay.
      final report = _run(
        _decision(),
        anchor: _anchor(approvalDecision: 'DELAY'),
      );
      expect(report.state, Sprint118RolloutProgressionState.blocked);
      expect(report.blockers, contains('approval_gate_not_delay:DELAY'));
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _decision(releaseState: 'GA_RELEASED'),
        anchor: _anchor(),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(
        report.violations,
        contains(
          'release_state_mismatch:anchor=GA_DELAYED:decision=GA_RELEASED',
        ),
      );
    });

    test('fails when a live rollout is claimed on the delayed path', () {
      final report = _run(
        _decision(),
        anchor: _anchor(liveRolloutExecuted: true),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(
        report.violations,
        contains('live_rollout_claimed_on_delayed_path'),
      );
    });

    test('fails when release execution is authorized on the delayed path', () {
      final report = _run(
        _decision(),
        anchor: _anchor(executionAuthorized: true),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(
        report.violations,
        contains('release_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_decision(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(
        report.violations,
        contains('release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when an entry names an unknown decision option', () {
      final report = _run(
        _decision(
          entries: <Sprint118RolloutProgressionEntry>[
            ...Sprint118RolloutProgressionContract.canonicalDecision.entries,
            _entry(decision: 'TELEPATHY', referenceState: 'exposure'),
          ],
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(report.violations, contains('decision_unknown:TELEPATHY'));
    });

    test('fails when an entry drops a required field', () {
      final report = _run(
        _decision(
          entries: _replacing(
            'HOLD',
            _entry(
              decision: 'HOLD',
              referenceState: 'stop_conditions',
              detail: '',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(report.violations, contains('entry_blank_detail:HOLD'));
    });

    test(
      'fails when an entry names a reference state outside the vocabulary',
      () {
        final report = _run(
          _decision(
            entries: _replacing(
              'HOLD',
              _entry(decision: 'HOLD', referenceState: 'telepathy'),
            ),
          ),
        );
        expect(report.state, Sprint118RolloutProgressionState.fail);
        expect(report.violations, contains('reference_state_invalid:HOLD'));
      },
    );

    test('opens an item when an entry honestly marks no reference state', () {
      final report = _run(
        _decision(
          entries: _replacing(
            'HOLD',
            _entry(
              decision: 'HOLD',
              referenceState:
                  Sprint118RolloutProgressionContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.pass);
      expect(report.openItems, contains('upstream_state_vocabulary_gap:HOLD'));
    });

    test('fails when an entry names an unreadable source', () {
      final report = _run(
        _decision(
          entries: _replacing(
            'HOLD',
            _entry(
              decision: 'HOLD',
              referenceState: 'stop_conditions',
              source: 'docs/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(report.violations, contains('source_unreadable:HOLD'));
    });

    test('fails when an entry claims an expansion without a release', () {
      final report = _run(
        _decision(
          entries: _replacing(
            'EXPAND',
            _entry(
              decision: 'EXPAND',
              referenceState: 'exposure',
              source:
                  Sprint118RolloutProgressionContract.rolloutPlanManifestPath,
              expansionClaimed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(
        report.violations,
        contains('expansion_claimed_without_release:EXPAND'),
      );
    });

    test('fails when an entry claims a rollback without a live rollout', () {
      final report = _run(
        _decision(
          entries: _replacing(
            'ROLLBACK',
            _entry(
              decision: 'ROLLBACK',
              referenceState: 'artifact_rollback',
              source:
                  Sprint118RolloutProgressionContract.rollbackDrillManifestPath,
              rollbackClaimed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(
        report.violations,
        contains('rollback_claimed_without_live_rollout:ROLLBACK'),
      );
    });

    test(
      'fails when an entry claims a connector disable without a release',
      () {
        final report = _run(
          _decision(
            entries: _replacing(
              'DISABLE_CONNECTOR',
              _entry(
                decision: 'DISABLE_CONNECTOR',
                referenceState: 'kill_switch',
                source: Sprint118RolloutProgressionContract
                    .connectorDisableManifestPath,
                connectorDisableClaimed: true,
              ),
            ),
          ),
        );
        expect(report.state, Sprint118RolloutProgressionState.fail);
        expect(
          report.violations,
          contains(
            'connector_disable_claimed_without_release:DISABLE_CONNECTOR',
          ),
        );
      },
    );

    test('fails when an entry claims a live observation', () {
      final report = _run(
        _decision(
          entries: _replacing(
            'HOLD',
            _entry(
              decision: 'HOLD',
              referenceState: 'stop_conditions',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(report.violations, contains('live_observation_claimed:HOLD'));
    });

    test('fails when a canonical decision option is missing', () {
      final report = _run(
        _decision(
          entries: <Sprint118RolloutProgressionEntry>[
            for (final e
                in Sprint118RolloutProgressionContract
                    .canonicalDecision
                    .entries)
              if (e.decision != 'REDUCE') e,
          ],
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(report.violations, contains('decision_missing:REDUCE'));
    });

    test('fails when a canonical decision option is duplicated', () {
      final report = _run(
        _decision(
          entries: <Sprint118RolloutProgressionEntry>[
            ...Sprint118RolloutProgressionContract.canonicalDecision.entries,
            _entry(decision: 'HOLD', referenceState: 'stop_conditions'),
          ],
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(report.violations, contains('decision_duplicate:HOLD'));
    });

    test(
      'fails when the selected decision is not HOLD without a live rollout',
      () {
        final report = _run(
          _decision(selectedDecision: Sprint118RolloutDecision.expand),
        );
        expect(report.state, Sprint118RolloutProgressionState.fail);
        expect(
          report.violations,
          contains('progression_decision_without_live_rollout:EXPAND'),
        );
      },
    );

    test('passes when a live rollout executed and EXPAND is selected', () {
      // The other direction: once a release is recorded and a live rollout has
      // genuinely executed, the gate is willing to record a decision other than
      // HOLD. A live rollout is only refused on the delayed path, so both the
      // anchor and the decision must leave GA_DELAYED for this to be coherent.
      final report = _run(
        _decision(
          releaseState: 'GA_RELEASED',
          selectedDecision: Sprint118RolloutDecision.expand,
        ),
        anchor: _anchor(releaseState: 'GA_RELEASED', liveRolloutExecuted: true),
      );
      expect(report.state, Sprint118RolloutProgressionState.pass);
      expect(report.selectedDecision, 'EXPAND');
    });

    test('fails when a required evidence source is unreadable', () {
      final report = _run(
        _decision(),
        anchor: _anchor(
          readableSources: <String>[
            Sprint118RolloutProgressionContract.approvalGateManifestPath,
          ],
        ),
      );
      expect(report.state, Sprint118RolloutProgressionState.fail);
      expect(
        report.violations,
        contains(
          'required_source_unreadable:'
          'docs/planning/v1.3/sprint_117_staged_ga_rollout_plan.json',
        ),
      );
    });

    test('the loader reads the committed witnesses on disk', () {
      final anchor = const Sprint118RolloutProgressionLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.baselineState, 'pass');
      expect(
        anchor.baselineVerdict,
        'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL',
      );
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(anchor.charterWindowMinutes, 60480);
      expect(
        anchor.regressionVerdict,
        'MAINTENANCE_REGRESSION_MATRIX_VERIFIED_LOCAL',
      );
      expect(
        anchor.disableVerdict,
        'CONNECTOR_DISABLE_SAFE_DEGRADATION_VERIFIED_LOCAL',
      );
      expect(anchor.approvalDecision, 'delay');
      expect(anchor.approvalState, 'PENDING_CHOIRUDIN');
      expect(anchor.executionAuthorized, isFalse);
      expect(anchor.releaseBlocked, isTrue);
      expect(anchor.liveRolloutExecuted, isFalse);
      expect(anchor.readableSources.length, 7);
    });

    test('the gate evaluates the committed decision to a pass on HOLD', () {
      final report = const Sprint118RolloutProgressionGate().evaluate();
      expect(report.state, Sprint118RolloutProgressionState.pass);
      expect(report.selectedDecision, 'HOLD');
      expect(report.releaseState, 'GA_DELAYED');
      expect(report.observedCount, 0);
    });
  });
}
