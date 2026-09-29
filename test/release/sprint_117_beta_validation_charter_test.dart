import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_beta_validation_charter.dart';

const String _charterArtifact =
    'docs/planning/v1.3/sprint_117_beta_validation_charter.json';
const String _entryArtifact =
    'docs/planning/v1.3/sprint_117_beta_entry_gate.json';

Sprint117CharterWindow _window({
  int startEpochMs = 1759276800000,
  int endEpochMs = 1790294400000,
  // Derived from the epoch range so the fixture cannot contradict the rule
  // that a declared duration must match the window it describes.
  int? durationDays,
  List<Sprint117CharterPhase> phases = const <Sprint117CharterPhase>[
    Sprint117CharterPhase(
      phaseId: 'phase_internal',
      stageId: 'stage_internal',
      startEpochMs: 1759276800000,
      endEpochMs: 1761955200000,
      exitCriterion: 'no_sev1_for_72h',
    ),
    Sprint117CharterPhase(
      phaseId: 'phase_alpha',
      stageId: 'stage_alpha',
      startEpochMs: 1761955200000,
      endEpochMs: 1767225600000,
      exitCriterion: 'no_sev1_for_72h',
    ),
    Sprint117CharterPhase(
      phaseId: 'phase_waitlist',
      stageId: 'stage_waitlist',
      startEpochMs: 1767225600000,
      endEpochMs: 1790294400000,
      exitCriterion: 'no_sev1_for_72h',
    ),
  ],
}) => Sprint117CharterWindow(
  windowId: 'beta_validation_window',
  startEpochMs: startEpochMs,
  endEpochMs: endEpochMs,
  durationDays:
      durationDays ??
      (endEpochMs - startEpochMs) ~/ Sprint117CharterContract.dayInMilliseconds,
  phases: phases,
);

Sprint117CharterSubset _subset({
  List<String> exposed = const <String>['openai', 'gemini', 'kofi'],
  List<String> hidden = const <String>['saweria'],
  List<String> rolloutExposed = const <String>['conn_openai', 'conn_gemini'],
}) => Sprint117CharterSubset(
  exposed: exposed,
  hidden: hidden,
  rolloutExposed: rolloutExposed,
);

Sprint117CharterAnchor _anchor({
  String entryVerdict = 'BETA_ENTRY_LOCAL_READY',
  String betaVersion = 'v1.3.0-beta.1',
  String pubspecVersion = '1.2.0-rc.1',
  bool releaseCut = false,
  List<String> exposedSubset = const <String>['openai', 'gemini', 'kofi'],
  List<String> stages = const <String>[
    'stage_internal',
    'stage_alpha',
    'stage_waitlist',
  ],
  List<String> metrics = const <String>[
    'metric_error_rate',
    'metric_auth_success',
    'metric_crash_rate',
  ],
  List<String> killSwitchConnectors = const <String>[
    'conn_openai',
    'conn_gemini',
  ],
  List<String> openItemIds = const <String>['release_cut_pending'],
}) => Sprint117CharterAnchor(
  entryVerdict: entryVerdict,
  betaVersion: betaVersion,
  pubspecVersion: pubspecVersion,
  releaseCut: releaseCut,
  exposedSubset: exposedSubset,
  stages: stages,
  metrics: metrics,
  killSwitchConnectors: killSwitchConnectors,
  openItemIds: openItemIds,
);

Sprint117CharterInput _healthyInput({
  Sprint117CharterWindow? window,
  List<Sprint117CharterQuestion>? questions,
  Sprint117CharterSubset? subset,
  List<Sprint117CharterEvidencePlan>? evidence,
  List<Sprint117CharterOwner>? owners,
  List<Sprint117CharterStopCondition>? stopConditions,
  List<Sprint117CharterGaCriterion>? gaCriteria,
  Sprint117CharterAnchor? anchor,
  List<String> carriedOpenItems = const <String>[
    'release_cut_pending: pubspec 1.2.0-rc.1 != v1.3.0-beta.1',
  ],
  bool omitWindow = false,
  bool omitQuestions = false,
  bool omitSubset = false,
  bool omitEvidence = false,
  bool omitOwners = false,
  bool omitStopConditions = false,
  bool omitGaCriteria = false,
  bool omitAnchor = false,
}) {
  final resolvedQuestions =
      questions ??
      const <Sprint117CharterQuestion>[
        Sprint117CharterQuestion(
          questionId: 'q_installation_upgrade',
          area: 'installation_upgrade',
          step: '117.9',
          question:
              'Apakah upgrade dari 1.2.0-rc.1 ke build beta mempertahankan proyek pengguna tanpa kehilangan data?',
          measurable: true,
        ),
        Sprint117CharterQuestion(
          questionId: 'q_quota_accuracy',
          area: 'quota_accuracy',
          step: '117.29',
          question:
              'Apakah kuota yang ditampilkan cocok dengan pemakaian yang dilaporkan lintas provider?',
          measurable: true,
        ),
      ];
  final resolvedEvidence =
      evidence ??
      <Sprint117CharterEvidencePlan>[
        for (final question in resolvedQuestions)
          Sprint117CharterEvidencePlan(
            questionId: question.questionId,
            requiredArtifacts: const <String>[
              'docs/evidence/beta_quota_accuracy.json',
            ],
            sourceManifests: const <String>[
              'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_reconciliation.json',
            ],
          ),
      ];
  return Sprint117CharterInput(
    window: omitWindow ? null : window ?? _window(),
    questions: omitQuestions ? null : resolvedQuestions,
    connectorSubset: omitSubset ? null : subset ?? _subset(),
    evidence: omitEvidence ? null : resolvedEvidence,
    owners: omitOwners
        ? null
        : owners ??
              const <Sprint117CharterOwner>[
                Sprint117CharterOwner(
                  ownerId: 'release-owner',
                  role: 'release_owner',
                  scopes: <String>['charter', 'stop_condition', 'ga_criteria'],
                ),
                Sprint117CharterOwner(
                  ownerId: 'support-owner',
                  role: 'support_owner',
                  scopes: <String>['question', 'incident'],
                ),
              ],
    stopConditions: omitStopConditions
        ? null
        : stopConditions ??
              const <Sprint117CharterStopCondition>[
                Sprint117CharterStopCondition(
                  stopId: 'charter_stop_internal_error',
                  stageId: 'stage_internal',
                  metricId: 'metric_error_rate',
                  operator: 'gt',
                  threshold: 0.02,
                  windowMinutes: 60,
                  action: 'halt_rollout',
                  killSwitchRef: 'kill_openai',
                ),
                Sprint117CharterStopCondition(
                  stopId: 'charter_stop_alpha_error',
                  stageId: 'stage_alpha',
                  metricId: 'metric_error_rate',
                  operator: 'gt',
                  threshold: 0.02,
                  windowMinutes: 60,
                  action: 'rollback_stage',
                  killSwitchRef: 'kill_openai',
                ),
                Sprint117CharterStopCondition(
                  stopId: 'charter_stop_waitlist_crash',
                  stageId: 'stage_waitlist',
                  metricId: 'metric_crash_rate',
                  operator: 'gt',
                  threshold: 0.01,
                  windowMinutes: 1440,
                  action: 'halt_rollout',
                  killSwitchRef: 'kill_gemini',
                ),
              ],
    gaCriteria: omitGaCriteria
        ? null
        : gaCriteria ??
              const <Sprint117CharterGaCriterion>[
                Sprint117CharterGaCriterion(
                  criterionId: 'ga_security',
                  gate: 'security',
                  step: '117.32',
                  criterion:
                      'Security assessment selesai tanpa temuan Sev-1 yang terbuka.',
                  evidenceRequired: true,
                ),
                Sprint117CharterGaCriterion(
                  criterionId: 'ga_privacy',
                  gate: 'privacy',
                  step: '117.33',
                  criterion:
                      'Privacy assessment selesai tanpa temuan Sev-1 yang terbuka.',
                  evidenceRequired: true,
                ),
                Sprint117CharterGaCriterion(
                  criterionId: 'ga_accessibility',
                  gate: 'accessibility',
                  step: '117.25',
                  criterion:
                      'Accessibility validation hijau pada seluruh layout yang di-beta.',
                  evidenceRequired: true,
                ),
                Sprint117CharterGaCriterion(
                  criterionId: 'ga_kill_switch',
                  gate: 'kill_switch',
                  step: '117.8',
                  criterion:
                      'Drill kill switch provider dijalankan dan terbukti menghentikan connector.',
                  evidenceRequired: true,
                ),
                Sprint117CharterGaCriterion(
                  criterionId: 'ga_staged_rollout',
                  gate: 'staged_rollout',
                  step: '117.44',
                  criterion:
                      'Staged rollout mencapai tahap akhir tanpa stop condition yang terpicu.',
                  evidenceRequired: true,
                ),
                Sprint117CharterGaCriterion(
                  criterionId: 'ga_rollback',
                  gate: 'rollback',
                  step: '117.43',
                  criterion:
                      'Rollback terverifikasi terhadap artefak beta yang dipublikasikan.',
                  evidenceRequired: true,
                ),
              ],
    anchor: omitAnchor ? null : anchor ?? _anchor(),
    carriedOpenItems: carriedOpenItems,
  );
}

void main() {
  group('117.2 Beta Validation Charter contract', () {
    test('locks the seven fields the canonical step demands', () {
      expect(Sprint117CharterContract.requiredFields, <String>[
        'window',
        'questions',
        'connector_subset',
        'evidence',
        'owners',
        'stop_conditions',
        'ga_criteria',
      ]);
      expect(Sprint117CharterContract.canonicalStep, '117.2');
      expect(
        Sprint117CharterContract.manifestPath,
        'docs/planning/v1.3/sprint_117_beta_validation_charter.json',
      );
      expect(
        Sprint117CharterContract.ledgerPath,
        'docs/sprints/sprint-117-beta-validation.md',
      );
      expect(
        Sprint117CharterContract.entryManifestPath,
        'docs/planning/v1.3/sprint_117_beta_entry_gate.json',
      );
      expect(
        Sprint117CharterContract.rolloutManifestPath,
        'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json',
      );
      expect(Sprint117CharterContract.externalGates, 'DEFERRED-EXTERNAL');
      expect(Sprint117CharterContract.entryVerdict, 'BETA_ENTRY_LOCAL_READY');
    });

    test('a healthy synthetic charter passes every required field', () {
      final report = Sprint117CharterGate().evaluateWith(_healthyInput());
      expect(
        report.state,
        Sprint117CharterState.pass,
        reason: report.violations.toString(),
      );
      expect(report.verdict, 'CHARTER_COMPLETE_LOCAL');
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.questions, hasLength(2));
      expect(report.carriedOpenItems, hasLength(1));
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });
  });

  group('117.2 fail-closed required fields', () {
    for (final field in Sprint117CharterContract.requiredFields) {
      test('an absent $field blocks the charter', () {
        final report = Sprint117CharterGate().evaluateWith(
          _healthyInput(
            omitWindow: field == 'window',
            omitQuestions: field == 'questions',
            omitSubset: field == 'connector_subset',
            omitEvidence: field == 'evidence',
            omitOwners: field == 'owners',
            omitStopConditions: field == 'stop_conditions',
            omitGaCriteria: field == 'ga_criteria',
          ),
        );
        expect(report.state, Sprint117CharterState.blocked);
        expect(report.missingFields, contains(field));
      });
    }

    test('an absent entry anchor blocks the charter', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(omitAnchor: true),
      );
      expect(report.state, Sprint117CharterState.blocked);
      expect(report.missingFields, contains('entry_anchor'));
    });

    test('an entry anchor that did not pass blocks the charter', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(anchor: _anchor(entryVerdict: 'BETA_ENTRY_BLOCKED')),
      );
      expect(report.state, Sprint117CharterState.blocked);
      expect(report.missingFields, contains('entry_anchor'));
    });
  });

  group('117.2 window rules', () {
    test('a window that ends before it starts fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          window: _window(
            startEpochMs: 1790294400000,
            endEpochMs: 1759276800000,
          ),
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains(startsWith('window_order')));
    });

    test('a zero-length window fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          window: _window(
            startEpochMs: 1759276800000,
            endEpochMs: 1759276800000,
            durationDays: 0,
          ),
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('window_duration'));
    });

    test('a window with no phases fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(window: _window(phases: const <Sprint117CharterPhase>[])),
      );
      expect(report.state, Sprint117CharterState.blocked);
      expect(report.missingFields, contains('window'));
    });

    test('a rollout stage no phase covers fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          window: _window(
            phases: const <Sprint117CharterPhase>[
              Sprint117CharterPhase(
                phaseId: 'phase_internal',
                stageId: 'stage_internal',
                startEpochMs: 1759276800000,
                endEpochMs: 1790294400000,
                exitCriterion: 'no_sev1_for_72h',
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('window_stage_uncovered:stage_alpha'));
    });

    test('a phase pointing at an unknown stage fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          window: _window(
            phases: const <Sprint117CharterPhase>[
              Sprint117CharterPhase(
                phaseId: 'phase_internal',
                stageId: 'stage_internal',
                startEpochMs: 1759276800000,
                endEpochMs: 1761955200000,
                exitCriterion: 'no_sev1_for_72h',
              ),
              Sprint117CharterPhase(
                phaseId: 'phase_alpha',
                stageId: 'stage_alpha',
                startEpochMs: 1761955200000,
                endEpochMs: 1767225600000,
                exitCriterion: 'no_sev1_for_72h',
              ),
              Sprint117CharterPhase(
                phaseId: 'phase_ghost',
                stageId: 'stage_ghost',
                startEpochMs: 1767225600000,
                endEpochMs: 1790294400000,
                exitCriterion: 'no_sev1_for_72h',
              ),
            ],
          ),
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('window_stage_unknown:stage_ghost'));
    });
  });

  group('117.2 question rules', () {
    test('a question with a blank id fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          questions: const <Sprint117CharterQuestion>[
            Sprint117CharterQuestion(
              questionId: '  ',
              area: 'quota_accuracy',
              step: '117.29',
              question: 'Apakah kuota akurat?',
              measurable: true,
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('question_id_blank'));
    });

    test('two questions sharing one id fail', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          questions: const <Sprint117CharterQuestion>[
            Sprint117CharterQuestion(
              questionId: 'q_dupe',
              area: 'quota_accuracy',
              step: '117.29',
              question: 'Satu?',
              measurable: true,
            ),
            Sprint117CharterQuestion(
              questionId: 'q_dupe',
              area: 'billing',
              step: '117.30',
              question: 'Dua?',
              measurable: true,
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('question_duplicate:q_dupe'));
    });

    test('a question with no text fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          questions: const <Sprint117CharterQuestion>[
            Sprint117CharterQuestion(
              questionId: 'q_blank',
              area: 'quota_accuracy',
              step: '117.29',
              question: '   ',
              measurable: true,
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('question_text:q_blank'));
    });

    test('a question outside the known area vocabulary fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          questions: const <Sprint117CharterQuestion>[
            Sprint117CharterQuestion(
              questionId: 'q_area',
              area: 'vibes',
              step: '117.29',
              question: 'Apakah rasa fitur ini bagus?',
              measurable: true,
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('question_area:q_area:vibes'));
    });

    test('a question that is not measurable fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          questions: const <Sprint117CharterQuestion>[
            Sprint117CharterQuestion(
              questionId: 'q_vague',
              area: 'quota_accuracy',
              step: '117.29',
              question: 'Apakahakenakal?',
              measurable: false,
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('question_measurable:q_vague'));
    });
  });

  group('117.2 connector subset rules', () {
    test('a subset that drifts from the entry gate fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(subset: _subset(exposed: const <String>['openai'])),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains(startsWith('subset_drift')));
    });

    test('exposing a hidden provider fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          // The anchor itself is widened so the ONLY defect is the contradiction
          // between `exposed` and `hidden`.
          anchor: _anchor(
            exposedSubset: const <String>[
              'openai',
              'gemini',
              'kofi',
              'saweria',
            ],
          ),
          subset: _subset(
            exposed: const <String>['openai', 'gemini', 'kofi', 'saweria'],
            hidden: const <String>['saweria'],
          ),
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('subset_uncertified:saweria'));
    });

    test('a connector the rollout exposes but the charter omits fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          subset: _subset(
            rolloutExposed: const <String>[
              'conn_openai',
              'conn_gemini',
              'conn_local_ai',
            ],
          ),
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('subset_rollout_gap:conn_local_ai'));
    });

    test('an empty exposed subset blocks', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          subset: _subset(
            exposed: const <String>[],
            rolloutExposed: const <String>[],
          ),
        ),
      );
      expect(report.state, Sprint117CharterState.blocked);
      expect(report.missingFields, contains('connector_subset'));
    });
  });

  group('117.2 evidence rules', () {
    test('a question with no evidence plan fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          evidence: const <Sprint117CharterEvidencePlan>[
            Sprint117CharterEvidencePlan(
              questionId: 'q_installation_upgrade',
              requiredArtifacts: <String>['docs/evidence/upgrade.json'],
              sourceManifests: <String>[
                'docs/planning/v1.2/sprint_116_install_upgrade.json',
              ],
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(
        report.violations,
        contains('evidence_uncovered:q_quota_accuracy'),
      );
    });

    test('an evidence plan for an unknown question fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          evidence: const <Sprint117CharterEvidencePlan>[
            Sprint117CharterEvidencePlan(
              questionId: 'q_ghost',
              requiredArtifacts: <String>['docs/evidence/ghost.json'],
              sourceManifests: <String>['docs/planning/v1.2/ghost.json'],
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('evidence_orphan:q_ghost'));
    });

    test('an evidence plan with no artifact fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          questions: const <Sprint117CharterQuestion>[
            Sprint117CharterQuestion(
              questionId: 'q_one',
              area: 'quota_accuracy',
              step: '117.29',
              question: 'Apakah kuota akurat?',
              measurable: true,
            ),
          ],
          evidence: const <Sprint117CharterEvidencePlan>[
            Sprint117CharterEvidencePlan(
              questionId: 'q_one',
              requiredArtifacts: <String>[],
              sourceManifests: <String>[
                'docs/planning/v1.2/sprint_116_quota.json',
              ],
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('evidence_artifact:q_one'));
    });
  });

  group('117.2 owner rules', () {
    test('a scope nobody owns blocks the charter', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          owners: const <Sprint117CharterOwner>[
            Sprint117CharterOwner(
              ownerId: 'release-owner',
              role: 'release_owner',
              scopes: <String>['charter'],
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.blocked);
      expect(report.missingFields, contains('owners'));
    });

    test('an owner with a blank role fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          owners: const <Sprint117CharterOwner>[
            Sprint117CharterOwner(
              ownerId: 'ghost',
              role: '  ',
              // Every scope still has an owner, so the only defect is the blank
              // role rather than an unowned scope.
              scopes: <String>[
                'charter',
                'stop_condition',
                'ga_criteria',
                'question',
                'incident',
              ],
            ),
            Sprint117CharterOwner(
              ownerId: 'support-owner',
              role: 'support_owner',
              scopes: <String>['question', 'incident'],
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('owner_role_blank:ghost'));
    });

    test('two owners sharing one id fail', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          owners: const <Sprint117CharterOwner>[
            Sprint117CharterOwner(
              ownerId: 'dupe',
              role: 'release_owner',
              scopes: <String>[
                'charter',
                'stop_condition',
                'ga_criteria',
                'question',
                'incident',
              ],
            ),
            Sprint117CharterOwner(
              ownerId: 'dupe',
              role: 'support_owner',
              scopes: <String>['question', 'incident'],
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('owner_duplicate:dupe'));
    });
  });

  group('117.2 stop condition rules', () {
    test('a rollout stage with no stop condition fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          stopConditions: const <Sprint117CharterStopCondition>[
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_internal_error',
              stageId: 'stage_internal',
              metricId: 'metric_error_rate',
              operator: 'gt',
              threshold: 0.02,
              windowMinutes: 60,
              action: 'halt_rollout',
              killSwitchRef: 'kill_openai',
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('stop_stage_uncovered:stage_alpha'));
    });

    test('a stop condition naming an unknown metric fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          stopConditions: const <Sprint117CharterStopCondition>[
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_internal_error',
              stageId: 'stage_internal',
              metricId: 'metric_vibes',
              operator: 'gt',
              threshold: 0.02,
              windowMinutes: 60,
              action: 'halt_rollout',
              killSwitchRef: 'kill_openai',
            ),
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_alpha_error',
              stageId: 'stage_alpha',
              metricId: 'metric_error_rate',
              operator: 'gt',
              threshold: 0.02,
              windowMinutes: 60,
              action: 'rollback_stage',
              killSwitchRef: 'kill_openai',
            ),
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_waitlist_crash',
              stageId: 'stage_waitlist',
              metricId: 'metric_crash_rate',
              operator: 'gt',
              threshold: 0.01,
              windowMinutes: 1440,
              action: 'halt_rollout',
              killSwitchRef: 'kill_gemini',
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(
        report.violations,
        contains('stop_metric:charter_stop_internal_error:metric_vibes'),
      );
    });

    test('a stage whose only response is a page fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          stopConditions: const <Sprint117CharterStopCondition>[
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_internal_error',
              stageId: 'stage_internal',
              metricId: 'metric_error_rate',
              operator: 'gt',
              threshold: 0.02,
              windowMinutes: 60,
              action: 'halt_rollout',
              killSwitchRef: 'kill_openai',
            ),
            // `page_oncall` is legitimate triage next to containment, but on
            // its own it never stops exposure, so the whole fixture below
            // drops containment from `stage_alpha` and keeps only the page.
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_alpha_auth',
              stageId: 'stage_alpha',
              metricId: 'metric_auth_success',
              operator: 'lt',
              threshold: 0.95,
              windowMinutes: 60,
              action: 'page_oncall',
              killSwitchRef: 'kill_openai',
            ),
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_waitlist_crash',
              stageId: 'stage_waitlist',
              metricId: 'metric_crash_rate',
              operator: 'gt',
              threshold: 0.01,
              windowMinutes: 1440,
              action: 'halt_rollout',
              killSwitchRef: 'kill_gemini',
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(
        report.violations,
        contains('stop_rollback_action:stage:stage_alpha'),
      );
    });

    test('a page next to containment on the same stage is allowed', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          stopConditions: const <Sprint117CharterStopCondition>[
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_internal_error',
              stageId: 'stage_internal',
              metricId: 'metric_error_rate',
              operator: 'gt',
              threshold: 0.02,
              windowMinutes: 60,
              action: 'halt_rollout',
              killSwitchRef: 'kill_openai',
            ),
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_alpha_error',
              stageId: 'stage_alpha',
              metricId: 'metric_error_rate',
              operator: 'gt',
              threshold: 0.02,
              windowMinutes: 60,
              action: 'rollback_stage',
              killSwitchRef: 'kill_openai',
            ),
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_alpha_auth',
              stageId: 'stage_alpha',
              metricId: 'metric_auth_success',
              operator: 'lt',
              threshold: 0.95,
              windowMinutes: 60,
              action: 'page_oncall',
              killSwitchRef: 'kill_openai',
            ),
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_waitlist_crash',
              stageId: 'stage_waitlist',
              metricId: 'metric_crash_rate',
              operator: 'gt',
              threshold: 0.01,
              windowMinutes: 1440,
              action: 'halt_rollout',
              killSwitchRef: 'kill_gemini',
            ),
          ],
        ),
      );
      expect(
        report.state,
        isNot(Sprint117CharterState.fail),
        reason: report.violations.toString(),
      );
      expect(
        report.violations.where((v) => v.startsWith('stop_rollback_action')),
        isEmpty,
      );
    });

    test('a stop condition with a blank action fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          stopConditions: const <Sprint117CharterStopCondition>[
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_internal_error',
              stageId: 'stage_internal',
              metricId: 'metric_error_rate',
              operator: 'gt',
              threshold: 0.02,
              windowMinutes: 60,
              action: '  ',
              killSwitchRef: 'kill_openai',
            ),
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_alpha_error',
              stageId: 'stage_alpha',
              metricId: 'metric_error_rate',
              operator: 'gt',
              threshold: 0.02,
              windowMinutes: 60,
              action: 'rollback_stage',
              killSwitchRef: 'kill_openai',
            ),
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_waitlist_crash',
              stageId: 'stage_waitlist',
              metricId: 'metric_crash_rate',
              operator: 'gt',
              threshold: 0.01,
              windowMinutes: 1440,
              action: 'halt_rollout',
              killSwitchRef: 'kill_gemini',
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(
        report.violations,
        contains('stop_action:charter_stop_internal_error'),
      );
    });

    test('a stop condition with a zero window fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          stopConditions: const <Sprint117CharterStopCondition>[
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_internal_error',
              stageId: 'stage_internal',
              metricId: 'metric_error_rate',
              operator: 'gt',
              threshold: 0.02,
              windowMinutes: 0,
              action: 'halt_rollout',
              killSwitchRef: 'kill_openai',
            ),
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_alpha_error',
              stageId: 'stage_alpha',
              metricId: 'metric_error_rate',
              operator: 'gt',
              threshold: 0.02,
              windowMinutes: 60,
              action: 'rollback_stage',
              killSwitchRef: 'kill_openai',
            ),
            Sprint117CharterStopCondition(
              stopId: 'charter_stop_waitlist_crash',
              stageId: 'stage_waitlist',
              metricId: 'metric_crash_rate',
              operator: 'gt',
              threshold: 0.01,
              windowMinutes: 1440,
              action: 'halt_rollout',
              killSwitchRef: 'kill_gemini',
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(
        report.violations,
        contains('stop_window:charter_stop_internal_error'),
      );
    });
  });

  group('117.2 GA criteria rules', () {
    test('a GA criterion requiring no evidence fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          gaCriteria: const <Sprint117CharterGaCriterion>[
            Sprint117CharterGaCriterion(
              criterionId: 'ga_security',
              gate: 'security',
              step: '117.32',
              criterion: 'Security assessment selesai.',
              evidenceRequired: false,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_privacy',
              gate: 'privacy',
              step: '117.33',
              criterion: 'Privacy assessment selesai.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_accessibility',
              gate: 'accessibility',
              step: '117.25',
              criterion: 'Accessibility hijau.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_kill_switch',
              gate: 'kill_switch',
              step: '117.8',
              criterion: 'Kill switch terverifikasi.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_staged_rollout',
              gate: 'staged_rollout',
              step: '117.44',
              criterion: 'Staged rollout tuntas.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_rollback',
              gate: 'rollback',
              step: '117.43',
              criterion: 'Rollback terverifikasi.',
              evidenceRequired: true,
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('ga_evidence:ga_security'));
    });

    test('a required gate the charter never names blocks the charter', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          gaCriteria: const <Sprint117CharterGaCriterion>[
            Sprint117CharterGaCriterion(
              criterionId: 'ga_security',
              gate: 'security',
              step: '117.32',
              criterion: 'Security assessment selesai.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_privacy',
              gate: 'privacy',
              step: '117.33',
              criterion: 'Privacy assessment selesai.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_accessibility',
              gate: 'accessibility',
              step: '117.25',
              criterion: 'Accessibility hijau.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_kill_switch',
              gate: 'kill_switch',
              step: '117.8',
              criterion: 'Kill switch terverifikasi.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_staged_rollout',
              gate: 'staged_rollout',
              step: '117.44',
              criterion: 'Staged rollout tuntas.',
              evidenceRequired: true,
            ),
            // The rollback gate is deliberately absent.
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.blocked);
      expect(report.missingFields, contains('ga_criteria'));
    });

    test('two GA criteria sharing one id fail', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          gaCriteria: const <Sprint117CharterGaCriterion>[
            Sprint117CharterGaCriterion(
              criterionId: 'ga_dupe',
              gate: 'security',
              step: '117.32',
              criterion: 'Satu.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_dupe',
              gate: 'privacy',
              step: '117.33',
              criterion: 'Dua.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_accessibility',
              gate: 'accessibility',
              step: '117.25',
              criterion: 'Accessibility hijau.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_kill_switch',
              gate: 'kill_switch',
              step: '117.8',
              criterion: 'Kill switch terverifikasi.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_staged_rollout',
              gate: 'staged_rollout',
              step: '117.44',
              criterion: 'Staged rollout tuntas.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_rollback',
              gate: 'rollback',
              step: '117.43',
              criterion: 'Rollback terverifikasi.',
              evidenceRequired: true,
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('ga_duplicate:ga_dupe'));
    });

    test('a GA criterion naming an unknown gate fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(
          gaCriteria: const <Sprint117CharterGaCriterion>[
            Sprint117CharterGaCriterion(
              criterionId: 'ga_ghost',
              gate: 'vibes',
              step: '117.32',
              criterion: 'Rasa bagus.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_security',
              gate: 'security',
              step: '117.32',
              criterion: 'Security assessment selesai.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_privacy',
              gate: 'privacy',
              step: '117.33',
              criterion: 'Privacy assessment selesai.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_accessibility',
              gate: 'accessibility',
              step: '117.25',
              criterion: 'Accessibility hijau.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_kill_switch',
              gate: 'kill_switch',
              step: '117.8',
              criterion: 'Kill switch terverifikasi.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_staged_rollout',
              gate: 'staged_rollout',
              step: '117.44',
              criterion: 'Staged rollout tuntas.',
              evidenceRequired: true,
            ),
            Sprint117CharterGaCriterion(
              criterionId: 'ga_rollback',
              gate: 'rollback',
              step: '117.43',
              criterion: 'Rollback terverifikasi.',
              evidenceRequired: true,
            ),
          ],
        ),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(report.violations, contains('ga_gate:ga_ghost:vibes'));
    });
  });

  group('117.2 carried open item rules', () {
    test('an open item the charter drops fails', () {
      final report = Sprint117CharterGate().evaluateWith(
        _healthyInput(carriedOpenItems: const <String>[]),
      );
      expect(report.state, Sprint117CharterState.fail);
      expect(
        report.violations,
        contains('open_item_dropped:release_cut_pending'),
      );
    });
  });

  group('117.2 live repository evaluation', () {
    test('the live charter satisfies every canonical required field', () {
      final report = Sprint117CharterGate().evaluate();
      expect(
        report.state,
        isNot(Sprint117CharterState.fail),
        reason: report.violations.toString(),
      );
      expect(
        report.missingFields,
        isEmpty,
        reason:
            'every canonical charter field must resolve: ${report.missingFields}',
      );
      expect(report.questions, isNotEmpty);
      expect(report.evidencePlans, isNotEmpty);
      expect(report.owners, isNotEmpty);
      expect(report.stopConditions, isNotEmpty);
      expect(report.gaCriteria, isNotEmpty);
      expect(report.window, isNotNull);
      expect(report.connectorSubset, isNotNull);
    });

    test('the live charter exposes only the 117.1 entry subset', () {
      final report = Sprint117CharterGate().evaluate();
      final entry =
          jsonDecode(File(_entryArtifact).readAsStringSync())
              as Map<String, dynamic>;
      expect(
        report.connectorSubset!.exposed,
        List<String>.from(entry['exposed_beta_subset'] as List<dynamic>),
      );
      expect(report.anchor!.entryVerdict, 'BETA_ENTRY_LOCAL_READY');
    });

    test('the live charter covers every 116.50 rollout stage and metric', () {
      final report = Sprint117CharterGate().evaluate();
      final anchor = report.anchor!;
      final coveredPhases = report.window!.phases
          .map((phase) => phase.stageId)
          .toSet();
      for (final stage in anchor.stages) {
        expect(coveredPhases, contains(stage), reason: stage);
      }
      final coveredMetrics = report.stopConditions
          .map((stop) => stop.metricId)
          .toSet();
      for (final metric in anchor.metrics) {
        expect(coveredMetrics, contains(metric), reason: metric);
      }
    });

    test('the live charter names every required GA gate', () {
      final report = Sprint117CharterGate().evaluate();
      final gates = report.gaCriteria
          .map((criterion) => criterion.gate)
          .toSet();
      for (final gate in Sprint117CharterContract.requiredGaGates) {
        expect(gates, contains(gate), reason: gate);
      }
    });

    test('the live charter answers every question it declares', () {
      final report = Sprint117CharterGate().evaluate();
      final planned = report.evidencePlans
          .map((plan) => plan.questionId)
          .toSet();
      for (final question in report.questions) {
        expect(
          planned,
          contains(question.questionId),
          reason: question.questionId,
        );
        expect(question.question.trim(), isNotEmpty);
      }
    });

    test('the committed charter manifest matches the live gate result', () {
      final report = Sprint117CharterGate().evaluate();
      final manifest =
          jsonDecode(File(_charterArtifact).readAsStringSync())
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '117.2');
      expect(manifest['status'], 'UNVERIFIED');
      expect(manifest['live_beta_executed'], isFalse);
      expect(
        manifest['required_fields'],
        Sprint117CharterContract.requiredFields,
      );
      expect(manifest['state'], report.state.name);
      expect(manifest['verdict'], report.verdict);
      expect(
        List<String>.from(manifest['missing_fields'] as List<dynamic>),
        report.missingFields,
      );
      expect(
        List<String>.from(manifest['violations'] as List<dynamic>),
        report.violations,
      );
      expect(manifest['beta_version'], report.anchor!.betaVersion);
      expect(manifest['pubspec_version'], report.anchor!.pubspecVersion);
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(
        (manifest['questions'] as List<dynamic>).length,
        report.questions.length,
      );
      expect(
        (manifest['evidence'] as List<dynamic>).length,
        report.evidencePlans.length,
      );
      expect(
        (manifest['owners'] as List<dynamic>).length,
        report.owners.length,
      );
      expect(
        (manifest['stop_conditions'] as List<dynamic>).length,
        report.stopConditions.length,
      );
      expect(
        (manifest['ga_criteria'] as List<dynamic>).length,
        report.gaCriteria.length,
      );
      expect(
        (manifest['window'] as Map<String, dynamic>)['window_id'],
        report.window!.windowId,
      );
      expect(
        List<String>.from(manifest['carried_open_items'] as List<dynamic>),
        report.carriedOpenItems,
      );
    });

    test('the committed charter manifest carries no secret material', () {
      final raw = File(_charterArtifact).readAsStringSync();
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      final report = Sprint117CharterGate().evaluate();
      final vocabulary = <String>{
        ...Sprint117CharterContract.requiredFields,
        ...Sprint117CharterContract.requiredGaGates,
        ...Sprint117CharterContract.knownAreas,
        ...report.anchor!.stages,
        ...report.anchor!.metrics,
        ...report.anchor!.killSwitchConnectors,
        ...report.connectorSubset!.exposed,
        ...report.connectorSubset!.hidden,
      };

      bool carriesSecret(Object? node) {
        if (node is Map) {
          for (final entry in node.entries) {
            final key = entry.key.toString().toLowerCase();
            if (key.contains('api_key') || key.contains('secret')) {
              return true;
            }
            if (carriesSecret(entry.value)) return true;
          }
          return false;
        }
        if (node is List) return node.any(carriesSecret);
        final text = node.toString();
        if (vocabulary.contains(text)) return false;
        return text.toLowerCase().contains('api_key') ||
            text.toLowerCase().contains('bearer') ||
            text.toLowerCase().contains('private_key') ||
            text.contains('sk-');
      }

      expect(carriesSecret(manifest), isFalse);
      expect(raw.contains('sk-'), isFalse);
    });
  });
}
