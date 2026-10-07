import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_stability_expansion_charter.dart';

/// A fully satisfied charter. Each test flips exactly the one thing it is about,
/// so a test that flips nothing proves the pass path exists and every other test
/// proves one way the gate refuses to take it.
Sprint118StabilityExpansionCharter _charter({
  String releaseState = Sprint118CharterContract.delayedReleaseState,
  Sprint118CharterWindow? window,
  List<Sprint118StabilityQuestion>? questions,
  Sprint118ExpansionBudget? expansionBudget,
  List<Sprint118CharterOwner>? owners,
  List<Sprint118CharterStopCondition>? stopConditions,
  List<Sprint118CharterExitCriterion>? exitCriteria,
}) {
  return Sprint118StabilityExpansionCharter(
    releaseState: releaseState,
    window: window ?? _window(),
    questions: questions ?? _questions(),
    expansionBudget: expansionBudget ?? _budget(),
    owners: owners ?? _owners(),
    stopConditions: stopConditions ?? _stopConditions(),
    exitCriteria: exitCriteria ?? _exitCriteria(),
  );
}

Sprint118CharterWindow _window({bool executed = false}) {
  return Sprint118CharterWindow(
    windowId: 'w',
    startEpochMs: 1000000,
    endEpochMs: 1000000 + 3 * Sprint118CharterContract.dayInMilliseconds,
    durationDays: 3,
    executed: executed,
    phases: <Sprint118CharterPhase>[
      Sprint118CharterPhase(
        phaseId: 'p1',
        startEpochMs: 1000000,
        endEpochMs: 1000000 + Sprint118CharterContract.dayInMilliseconds,
        exitCriterion: 'no_sev1',
      ),
      Sprint118CharterPhase(
        phaseId: 'p2',
        startEpochMs: 1000000 + Sprint118CharterContract.dayInMilliseconds,
        endEpochMs: 1000000 + 2 * Sprint118CharterContract.dayInMilliseconds,
        exitCriterion: 'no_sev1',
      ),
      Sprint118CharterPhase(
        phaseId: 'p3',
        startEpochMs: 1000000 + 2 * Sprint118CharterContract.dayInMilliseconds,
        endEpochMs: 1000000 + 3 * Sprint118CharterContract.dayInMilliseconds,
        exitCriterion: 'no_sev1',
      ),
    ],
  );
}

List<Sprint118StabilityQuestion> _questions() {
  return const <Sprint118StabilityQuestion>[
    Sprint118StabilityQuestion(
      questionId: 'q1',
      area: 'connection_health',
      step: '118.7',
      question: 'healthy?',
      measurable: true,
      signal: 'connect_success',
    ),
    Sprint118StabilityQuestion(
      questionId: 'q2',
      area: 'privacy',
      step: '118.19',
      question: 'safe?',
      measurable: true,
      signal: 'destination_issue',
    ),
  ];
}

Sprint118ExpansionBudget _budget({
  int maxNewCertifiedConnectors = 0,
  bool requiresCertification = true,
  int currentlyCertified = 0,
  int registeredProviders = 32,
  String blockedReason = 'no_certified_connector',
}) {
  return Sprint118ExpansionBudget(
    maxNewCertifiedConnectors: maxNewCertifiedConnectors,
    requiresCertification: requiresCertification,
    currentlyCertified: currentlyCertified,
    currentlyLimited: 0,
    registeredProviders: registeredProviders,
    blockedReason: blockedReason,
  );
}

List<Sprint118CharterOwner> _owners() {
  return const <Sprint118CharterOwner>[
    Sprint118CharterOwner(
      ownerId: 'o1',
      role: 'stability_owner',
      scopes: <String>[
        'stability_question',
        'stop_condition',
        'exit_criterion',
      ],
    ),
    Sprint118CharterOwner(
      ownerId: 'o2',
      role: 'expansion_owner',
      scopes: <String>['expansion_budget'],
    ),
    Sprint118CharterOwner(
      ownerId: 'o3',
      role: 'release_owner',
      scopes: <String>['charter'],
    ),
  ];
}

List<Sprint118CharterStopCondition> _stopConditions() {
  return const <Sprint118CharterStopCondition>[
    Sprint118CharterStopCondition(
      stopId: 's1',
      metricId: 'crash_rate',
      operator: 'gt',
      threshold: 0.01,
      windowMinutes: 60,
      action: 'halt_rollout',
    ),
  ];
}

List<Sprint118CharterExitCriterion> _exitCriteria() {
  return const <Sprint118CharterExitCriterion>[
    Sprint118CharterExitCriterion(
      criterionId: 'e1',
      gate: 'release_state_confirmed',
      description: 'confirmed',
      requiresEvidence: true,
    ),
    Sprint118CharterExitCriterion(
      criterionId: 'e2',
      gate: 'stability_questions_answered',
      description: 'answered',
      requiresEvidence: true,
    ),
    Sprint118CharterExitCriterion(
      criterionId: 'e3',
      gate: 'expansion_budget_respected',
      description: 'respected',
      requiresEvidence: true,
    ),
    Sprint118CharterExitCriterion(
      criterionId: 'e4',
      gate: 'incidents_resolved_or_contained',
      description: 'contained',
      requiresEvidence: true,
    ),
    Sprint118CharterExitCriterion(
      criterionId: 'e5',
      gate: 'maintenance_decision_recorded',
      description: 'recorded',
      requiresEvidence: true,
    ),
    Sprint118CharterExitCriterion(
      criterionId: 'e6',
      gate: 'regression_evidence_present',
      description: 'present',
      requiresEvidence: true,
    ),
  ];
}

Sprint118CharterAnchor _anchor({
  String entryState = 'pass',
  String entryVerdict = Sprint118CharterContract.requiredEntryVerdict,
  String releaseState = Sprint118CharterContract.delayedReleaseState,
  bool? correctiveScopeApproved = true,
  int providerCount = 32,
}) {
  return Sprint118CharterAnchor(
    entryState: entryState,
    entryVerdict: entryVerdict,
    releaseState: releaseState,
    correctiveScopeApproved: correctiveScopeApproved,
    providerCount: providerCount,
  );
}

Sprint118CharterReport _run(
  Sprint118StabilityExpansionCharter charter, {
  Sprint118CharterAnchor? anchor,
}) {
  return const Sprint118StabilityExpansionCharterGate().evaluateWith(
    anchor ?? _anchor(),
    charter,
  );
}

void main() {
  group('118.2 Stability & Expansion Charter', () {
    test('declares the canonical step, fields, and paths', () {
      expect(Sprint118CharterContract.canonicalStep, '118.2');
      expect(Sprint118CharterContract.title, 'Stability & Expansion Charter');
      expect(
        Sprint118CharterContract.manifestPath,
        'docs/planning/v1.3/sprint_118_stability_expansion_charter.json',
      );
      expect(Sprint118CharterContract.requiredFields, <String>[
        'window',
        'stability_questions',
        'expansion_budget',
        'owners',
        'stop_conditions',
        'exit_criteria',
      ]);
      expect(Sprint118CharterContract.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('vocabularies are internally consistent', () {
      // Every containment action must be a known action, otherwise the gate can
      // never accept a stop condition that is allowed to contain.
      expect(
        Sprint118CharterContract.containmentActions,
        everyElement(isIn(Sprint118CharterContract.knownActions)),
      );
      expect(
        Sprint118CharterContract.requiredOwnerScopes,
        everyElement(isIn(Sprint118CharterContract.knownOwnerScopes)),
      );
      expect(
        Sprint118CharterContract.requiredExitGates,
        everyElement(isIn(Sprint118CharterContract.knownExitGates)),
      );
      // Paging alone is not containment: the gate must be able to refuse a stop
      // condition whose only response is to page somebody.
      expect(Sprint118CharterContract.knownActions, contains('page_oncall'));
      expect(
        Sprint118CharterContract.containmentActions,
        isNot(contains('page_oncall')),
      );
    });

    test(
      'the canonical charter passes against the committed 118.1 evidence',
      () {
        final report = const Sprint118StabilityExpansionCharterGate()
            .evaluate();
        expect(report.state, Sprint118CharterState.pass);
        expect(report.verdict, 'CHARTER_COMPLETE_LOCAL');
        expect(report.charterExecutable, isTrue);
        expect(report.violations, isEmpty);
        expect(report.blockers, isEmpty);
        expect(report.liveObservationExecuted, isFalse);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test('an unreadable anchor is blocked, never a pass', () {
      final report = const Sprint118StabilityExpansionCharterGate()
          .evaluateWith(null, Sprint118CharterContract.canonicalCharter);
      expect(report.state, Sprint118CharterState.blocked);
      expect(report.verdict, 'SPRINT_118_CHARTER_EVIDENCE_UNREADABLE');
      expect(report.blockers, contains('committed_entry_evidence_unreadable'));
      expect(report.charterExecutable, isFalse);
    });

    test('a missing canonical field is reported by name', () {
      final report = _run(
        _charter(questions: const <Sprint118StabilityQuestion>[]),
      );
      expect(report.state, Sprint118CharterState.blocked);
      expect(report.verdict, 'SPRINT_118_CHARTER_FIELDS_MISSING');
      expect(report.missingFields, <String>['stability_questions']);
      expect(report.charterExecutable, isFalse);
    });

    test('an entry gate that did not pass blocks the charter', () {
      final report = _run(
        _charter(),
        anchor: _anchor(
          entryState: 'fail',
          entryVerdict: 'SPRINT_118_ENTRY_BLOCKED',
        ),
      );
      expect(report.state, Sprint118CharterState.blocked);
      expect(
        report.blockers,
        contains('entry_gate_not_passed:SPRINT_118_ENTRY_BLOCKED'),
      );
    });

    test('an absent corrective scope approval is never consent', () {
      final report = _run(
        _charter(),
        anchor: _anchor(correctiveScopeApproved: null),
      );
      expect(report.state, Sprint118CharterState.blocked);
      expect(report.blockers, contains('corrective_scope_not_approved'));
    });

    test(
      'a delayed release without the approved corrective scope is blocked',
      () {
        final report = _run(
          _charter(),
          anchor: _anchor(correctiveScopeApproved: false),
        );
        expect(report.state, Sprint118CharterState.blocked);
        expect(report.blockers, contains('corrective_scope_not_approved'));
      },
    );

    test('a charter describing a release the anchor did not record fails', () {
      final report = _run(
        _charter(releaseState: Sprint118CharterContract.releasedReleaseState),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(
        report.violations,
        contains(
          'release_state_mismatch:anchor=GA_DELAYED:charter=GA_RELEASED',
        ),
      );
    });

    test('a window that does not run forward fails', () {
      final report = _run(
        _charter(
          window: Sprint118CharterWindow(
            windowId: 'w',
            startEpochMs: 2000000,
            endEpochMs: 1000000,
            durationDays: -1,
            executed: false,
            phases: <Sprint118CharterPhase>[
              Sprint118CharterPhase(
                phaseId: 'p1',
                startEpochMs: 2000000,
                endEpochMs: 1000000,
                exitCriterion: 'x',
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(report.violations, contains('window_not_forward'));
    });

    test('a window whose declared duration does not add up fails', () {
      final report = _run(
        _charter(
          window: Sprint118CharterWindow(
            windowId: 'w',
            startEpochMs: 1000000,
            endEpochMs:
                1000000 + 3 * Sprint118CharterContract.dayInMilliseconds,
            durationDays: 99,
            executed: false,
            phases: _window().phases,
          ),
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(
        report.violations,
        contains('window_duration_mismatch:declared=99:derived=3'),
      );
    });

    test('a gap between phases fails', () {
      final report = _run(
        _charter(
          window: Sprint118CharterWindow(
            windowId: 'w',
            startEpochMs: 1000000,
            endEpochMs:
                1000000 + 3 * Sprint118CharterContract.dayInMilliseconds,
            durationDays: 3,
            executed: false,
            phases: <Sprint118CharterPhase>[
              Sprint118CharterPhase(
                phaseId: 'p1',
                startEpochMs: 1000000,
                endEpochMs:
                    1000000 + Sprint118CharterContract.dayInMilliseconds,
                exitCriterion: 'x',
              ),
              // p2 starts one day late: the window does not tile.
              Sprint118CharterPhase(
                phaseId: 'p2',
                startEpochMs:
                    1000000 + 2 * Sprint118CharterContract.dayInMilliseconds,
                endEpochMs:
                    1000000 + 3 * Sprint118CharterContract.dayInMilliseconds,
                exitCriterion: 'x',
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(report.violations, contains('window_phase_gap:p2'));
    });

    test('a phase without an exit criterion fails', () {
      final report = _run(
        _charter(
          window: Sprint118CharterWindow(
            windowId: 'w',
            startEpochMs: 1000000,
            endEpochMs: 1000000 + Sprint118CharterContract.dayInMilliseconds,
            durationDays: 1,
            executed: false,
            phases: <Sprint118CharterPhase>[
              Sprint118CharterPhase(
                phaseId: 'p1',
                startEpochMs: 1000000,
                endEpochMs:
                    1000000 + Sprint118CharterContract.dayInMilliseconds,
                exitCriterion: '  ',
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(report.violations, contains('window_phase_no_exit_criterion:p1'));
    });

    test('an executed window on a delayed release fails', () {
      final report = _run(_charter(window: _window(executed: true)));
      expect(report.state, Sprint118CharterState.fail);
      expect(
        report.violations,
        contains('observation_window_executed_without_release'),
      );
    });

    test('a released sprint with no active window is blocked', () {
      final report = _run(
        _charter(releaseState: Sprint118CharterContract.releasedReleaseState),
        anchor: _anchor(
          releaseState: Sprint118CharterContract.releasedReleaseState,
        ),
      );
      expect(report.state, Sprint118CharterState.blocked);
      expect(report.blockers, contains('observation_window_not_active'));
    });

    test('a stability question that is not measurable fails', () {
      final report = _run(
        _charter(
          questions: const <Sprint118StabilityQuestion>[
            Sprint118StabilityQuestion(
              questionId: 'q1',
              area: 'connection_health',
              step: '118.7',
              question: 'healthy?',
              measurable: false,
              signal: 'connect_success',
            ),
          ],
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(report.violations, contains('question_not_measurable:q1'));
    });

    test('a duplicate question id fails', () {
      final report = _run(
        _charter(
          questions: <Sprint118StabilityQuestion>[
            ..._questions(),
            _questions().first,
          ],
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(report.violations, contains('question_duplicate_id:q1'));
    });

    test('a question outside the known areas fails', () {
      final report = _run(
        _charter(
          questions: const <Sprint118StabilityQuestion>[
            Sprint118StabilityQuestion(
              questionId: 'q1',
              area: 'made_up_area',
              step: '118.7',
              question: 'x?',
              measurable: true,
              signal: 's',
            ),
          ],
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(report.violations, contains('question_unknown_area:q1'));
    });

    test('a stability question mapped into the expansion half fails', () {
      final report = _run(
        _charter(
          questions: const <Sprint118StabilityQuestion>[
            Sprint118StabilityQuestion(
              questionId: 'q1',
              area: 'connection_health',
              step: '118.33',
              question: 'x?',
              measurable: true,
              signal: 's',
            ),
          ],
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(
        report.violations,
        contains('question_step_out_of_stability_range:118.33'),
      );
    });

    test('an expansion budget that allows uncertified expansion fails', () {
      final report = _run(
        _charter(expansionBudget: _budget(requiresCertification: false)),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(
        report.violations,
        contains('expansion_budget_allows_uncertified_expansion'),
      );
    });

    test('an expansion budget larger than what is certified fails', () {
      final report = _run(
        _charter(
          expansionBudget: _budget(
            maxNewCertifiedConnectors: 3,
            currentlyCertified: 0,
          ),
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(
        report.violations,
        contains('expansion_budget_exceeds_certified:3:0'),
      );
    });

    test('a zero budget without a reason fails', () {
      final report = _run(
        _charter(expansionBudget: _budget(blockedReason: '   ')),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(
        report.violations,
        contains('expansion_budget_limited_without_reason'),
      );
    });

    test('a budget whose provider count contradicts the anchor fails', () {
      final report = _run(
        _charter(expansionBudget: _budget(registeredProviders: 31)),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(
        report.violations,
        contains(
          'expansion_budget_provider_count_mismatch:charter=31:anchor=32',
        ),
      );
    });

    test('an unowned owner scope fails', () {
      final report = _run(
        _charter(
          owners: const <Sprint118CharterOwner>[
            Sprint118CharterOwner(
              ownerId: 'o1',
              role: 'stability_owner',
              scopes: <String>['stability_question'],
            ),
          ],
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(report.violations, contains('owner_scope_unowned:charter'));
      expect(report.violations, contains('owner_scope_unowned:stop_condition'));
    });

    test('a duplicate owner id fails', () {
      final report = _run(
        _charter(
          owners: <Sprint118CharterOwner>[..._owners(), _owners().first],
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(report.violations, contains('owner_duplicate_id:o1'));
    });

    test('a stop condition on an unknown metric fails', () {
      final report = _run(
        _charter(
          stopConditions: const <Sprint118CharterStopCondition>[
            Sprint118CharterStopCondition(
              stopId: 's1',
              metricId: 'vibes',
              operator: 'gt',
              threshold: 1,
              windowMinutes: 60,
              action: 'halt_rollout',
            ),
          ],
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(
        report.violations,
        contains('stop_condition_unknown_metric:vibes'),
      );
    });

    test('a stop condition with no window fails', () {
      final report = _run(
        _charter(
          stopConditions: const <Sprint118CharterStopCondition>[
            Sprint118CharterStopCondition(
              stopId: 's1',
              metricId: 'crash_rate',
              operator: 'gt',
              threshold: 1,
              windowMinutes: 0,
              action: 'halt_rollout',
            ),
          ],
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(report.violations, contains('stop_condition_zero_window:s1'));
    });

    test('a stop condition that can only page somebody fails', () {
      final report = _run(
        _charter(
          stopConditions: const <Sprint118CharterStopCondition>[
            Sprint118CharterStopCondition(
              stopId: 's1',
              metricId: 'crash_rate',
              operator: 'gt',
              threshold: 1,
              windowMinutes: 60,
              action: 'page_oncall',
            ),
          ],
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(report.violations, contains('stop_condition_page_only:s1'));
    });

    test('an exit criterion that demands no evidence fails', () {
      final report = _run(
        _charter(
          exitCriteria: const <Sprint118CharterExitCriterion>[
            Sprint118CharterExitCriterion(
              criterionId: 'e1',
              gate: 'release_state_confirmed',
              description: 'x',
              requiresEvidence: false,
            ),
          ],
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(report.violations, contains('exit_criterion_without_evidence:e1'));
    });

    test('an uncovered canonical exit gate fails', () {
      final report = _run(
        _charter(
          exitCriteria: const <Sprint118CharterExitCriterion>[
            Sprint118CharterExitCriterion(
              criterionId: 'e1',
              gate: 'release_state_confirmed',
              description: 'x',
              requiresEvidence: true,
            ),
          ],
        ),
      );
      expect(report.state, Sprint118CharterState.fail);
      expect(
        report.violations,
        contains('exit_gate_uncovered:stability_questions_answered'),
      );
    });
  });
}
