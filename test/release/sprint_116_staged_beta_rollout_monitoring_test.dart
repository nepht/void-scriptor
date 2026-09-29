import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_staged_beta_rollout_monitoring.dart';

const int _now = 1700000100000;
const int _base = _now - 604800000;
const String _manifestArtifact =
    'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';

void main() {
  group('116.50 Staged Beta Rollout & Monitoring', () {
    test('locks the seven required fields the canonical step demands', () {
      expect(Sprint116StagedRolloutContract.requiredFields, <String>[
        'flags',
        'stages',
        'health_metrics',
        'stop_conditions',
        'provider_kill_switches',
        'rollback',
        'communication',
      ]);
      expect(Sprint116StagedRolloutContract.canonicalStep, '116.50');
      expect(Sprint116StagedRolloutContract.externalGates, 'DEFERRED-EXTERNAL');
      expect(
        Sprint116StagedRolloutContract.manifestPath,
        'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json',
      );
      expect(Sprint116StagedRolloutContract.supportedSources, <String>[
        'synthetic_local',
        'live',
        'local_run',
      ]);
      expect(Sprint116StagedRolloutContract.evidencedSources, <String>[
        'live',
        'local_run',
      ]);
      // Sprint 116 certification rule: beta feature flags default OFF. A flag
      // that ships ON has no rollback left to fall back to.
      expect(Sprint116StagedRolloutContract.defaultFlagState, 'OFF');
      expect(Sprint116StagedRolloutContract.knownFlagStates, <String>[
        'OFF',
        'ON',
      ]);
      expect(
        Sprint116StagedRolloutContract.knownMetricTypes,
        contains('error_rate'),
      );
      expect(Sprint116StagedRolloutContract.knownMetricDirections, <String>[
        'higher_is_worse',
        'lower_is_worse',
      ]);
      expect(Sprint116StagedRolloutContract.knownStopOperators, <String>[
        'gt',
        'gte',
        'lt',
        'lte',
      ]);
      expect(Sprint116StagedRolloutContract.knownStopActions, <String>[
        'halt_rollout',
        'rollback_stage',
        'page_oncall',
      ]);
      expect(Sprint116StagedRolloutContract.knownKillScopes, <String>[
        'connector_disable',
        'operation_block',
        'stage_exit',
      ]);
      expect(Sprint116StagedRolloutContract.knownTargetScopes, <String>[
        'stage',
        'flag',
        'provider',
      ]);
      expect(Sprint116StagedRolloutContract.knownAudiences, <String>[
        'beta_participants',
        'internal_oncall',
        'status_page',
        'providers',
      ]);
      expect(Sprint116StagedRolloutContract.knownCommChannels, <String>[
        'in_app',
        'email',
        'status_page',
        'issue_tracker',
        'internal_alert',
      ]);
      // Every one of these triggers must have a communication record; a
      // silent incident is an unmanaged one.
      expect(Sprint116StagedRolloutContract.knownCommTriggers, <String>[
        'stage_advance',
        'stop_condition_hit',
        'rollback_executed',
        'kill_switch_used',
      ]);
      expect(Sprint116StagedRolloutContract.maxExposurePercent, 100);
      expect(Sprint116StagedRolloutContract.minExposurePercent, 0);
    });

    test('a complete staged rollout plan certifies', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.coveredFields, <String>[
        'flags',
        'stages',
        'health_metrics',
        'stop_conditions',
        'provider_kill_switches',
        'rollback',
        'communication',
      ]);
      final json = report.toJson();
      expect(json['canonical_step'], '116.50');
      expect(json['live_rollout_executed'], isFalse);
      expect(json['beta_feature_flags_default'], 'OFF');
      expect(json['external_gates'], 'DEFERRED-EXTERNAL');
    });

    test('no reference clock is blocked, not passed', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(),
        asOfEpochMs: 0,
      );
      expect(report.state, Sprint116StagedRolloutStatus.blocked);
      expect(report.invalidRecords, <String>['as_of_epoch_ms']);
    });

    final empties = <String, Sprint116StagedRolloutControlSet Function()>{
      'flags': () => _controls(flags: <Sprint116RolloutFlagRecord>[]),
      'stages': () => _controls(stages: <Sprint116RolloutStageRecord>[]),
      'health_metrics': () =>
          _controls(healthMetrics: <Sprint116RolloutHealthMetricRecord>[]),
      'stop_conditions': () =>
          _controls(stopConditions: <Sprint116RolloutStopConditionRecord>[]),
      'provider_kill_switches': () =>
          _controls(killSwitches: <Sprint116RolloutKillSwitchRecord>[]),
      'rollback': () => _controls(rollback: <Sprint116RolloutRollbackRecord>[]),
      'communication': () =>
          _controls(communication: <Sprint116RolloutCommunicationRecord>[]),
    };
    empties.forEach((name, build) {
      test('an empty $name group is a gap rather than a pass', () {
        final report = Sprint116StagedRolloutPlan().certify(
          controls: build(),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116StagedRolloutStatus.blocked);
        expect(report.invalidRecords, <String>[name]);
      });
    });

    test('a record without identity is rejected on identity', () {
      final flags = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          flags: <Sprint116RolloutFlagRecord>[_flag(flagId: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(flags.state, Sprint116StagedRolloutStatus.fail);
      expect(flags.invalidRecords, contains('record_id:flags'));

      final rollback = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          rollback: <Sprint116RolloutRollbackRecord>[_rollback(rollbackId: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(rollback.state, Sprint116StagedRolloutStatus.fail);
      expect(rollback.invalidRecords, contains('record_id:rollback'));
    });

    test('an unknown source is a mock claim', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          flags: <Sprint116RolloutFlagRecord>[_flag(source: 'made_up')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('no_mock_values:flag_beta_connectors'),
      );
    });

    test('a live claim without an evidence reference is a mock claim', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          flags: <Sprint116RolloutFlagRecord>[_flag(source: 'live')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('no_mock_values:flag_beta_connectors'),
      );
    });

    test('a live claim must cite an artifact registered as evidence', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stages: <Sprint116RolloutStageRecord>[
            _stage(source: 'live', evidenceRef: 'docs/planning/ghost.json'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('evidence_register:stages:stage_internal'),
      );
    });

    test('a registered live claim passes the evidence join', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stages: <Sprint116RolloutStageRecord>[
            _stage(source: 'live', evidenceRef: _manifestArtifact),
            _stage(stageId: 'stage_alpha', sequence: 2, exposurePercent: 25),
            _stage(
              stageId: 'stage_waitlist',
              sequence: 3,
              exposurePercent: 100,
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.pass);
      expect(report.invalidRecords, isEmpty);
    });

    // ---- flags -------------------------------------------------------------

    test('a beta flag that ships ON has no rollback left', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          flags: <Sprint116RolloutFlagRecord>[_flag(defaultState: 'ON')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('flag_default:flag_beta_connectors'),
      );
    });

    test('an unknown flag state is rejected', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          flags: <Sprint116RolloutFlagRecord>[_flag(defaultState: 'MAYBE')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('flag_default:flag_beta_connectors'),
      );
    });

    test('a flag without a key or owner cannot be attributed', () {
      final keyless = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          flags: <Sprint116RolloutFlagRecord>[_flag(flagKey: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(keyless.invalidRecords, contains('flag_key:flag_beta_connectors'));

      final ownerless = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          flags: <Sprint116RolloutFlagRecord>[_flag(owner: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(
        ownerless.invalidRecords,
        contains('flag_owner:flag_beta_connectors'),
      );
    });

    test('a flag linked to no stage is not part of a staged rollout', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          flags: <Sprint116RolloutFlagRecord>[_flag(linkedStages: <String>[])],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('flag_stages:flag_beta_connectors'),
      );
    });

    test('a flag pointing at an unknown stage is rejected', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          flags: <Sprint116RolloutFlagRecord>[
            _flag(linkedStages: const <String>['stage_ghost']),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('flag_stage:flag_beta_connectors'),
      );
    });

    // ---- stages ------------------------------------------------------------

    test('stage sequences must be strictly increasing', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stages: <Sprint116RolloutStageRecord>[
            _stage(sequence: 2),
            _stage(stageId: 'stage_alpha', sequence: 1),
            _stage(stageId: 'stage_waitlist', sequence: 3),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('stage_order:stage_alpha'));
    });

    test('a non-positive stage sequence is rejected', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stages: <Sprint116RolloutStageRecord>[_stage(sequence: 0)],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('stage_sequence:stage_internal'));
    });

    test('exposure outside the 0..100 range is rejected', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stages: <Sprint116RolloutStageRecord>[_stage(exposurePercent: 140)],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('stage_range:stage_internal'));
    });

    test(
      'a later stage that exposes fewer users is a rollback, not a stage',
      () {
        final report = Sprint116StagedRolloutPlan().certify(
          controls: _controls(
            stages: <Sprint116RolloutStageRecord>[
              _stage(exposurePercent: 50),
              _stage(stageId: 'stage_alpha', exposurePercent: 20),
              _stage(stageId: 'stage_waitlist', exposurePercent: 100),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116StagedRolloutStatus.fail);
        expect(report.invalidRecords, contains('stage_exposure:stage_alpha'));
      },
    );

    test('a stage without entry or exit criteria never ends', () {
      final noExit = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stages: <Sprint116RolloutStageRecord>[
            _stage(exitCriteria: <String>[]),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(noExit.invalidRecords, contains('stage_exit:stage_internal'));

      final noEntry = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stages: <Sprint116RolloutStageRecord>[
            _stage(entryCriteria: const <String>['  ']),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(noEntry.invalidRecords, contains('stage_entry:stage_internal'));
    });

    test('an exposed connector is rejected when blank', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stages: <Sprint116RolloutStageRecord>[
            _stage(exposedConnectors: const <String>['']),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('stage_connector:stage_internal'));
    });

    // ---- health metrics ----------------------------------------------------

    test('an unknown health metric type fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          healthMetrics: <Sprint116RolloutHealthMetricRecord>[
            _metric(metricType: 'vibes'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('metric_type:metric_error_rate'));
    });

    test('an unknown health direction fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          healthMetrics: <Sprint116RolloutHealthMetricRecord>[
            _metric(direction: 'whichever'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('metric_direction:metric_error_rate'),
      );
    });

    test('a non-finite or negative threshold fails', () {
      final nan = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          healthMetrics: <Sprint116RolloutHealthMetricRecord>[
            _metric(threshold: double.nan),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(
        nan.invalidRecords,
        contains('metric_threshold:metric_error_rate'),
      );

      final negative = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          healthMetrics: <Sprint116RolloutHealthMetricRecord>[
            _metric(threshold: -0.5),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(
        negative.invalidRecords,
        contains('metric_threshold:metric_error_rate'),
      );
    });

    test('a non-positive measurement window fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          healthMetrics: <Sprint116RolloutHealthMetricRecord>[
            _metric(windowMinutes: 0),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('metric_window:metric_error_rate'),
      );
    });

    test('a health metric nobody acts on is decoration', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          healthMetrics: <Sprint116RolloutHealthMetricRecord>[
            ..._controls().healthMetrics,
            _metric(
              metricId: 'metric_nobody_watches',
              metricName: 'unused_metric',
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('metric_action:metric_nobody_watches'),
      );
    });

    // ---- stop conditions ---------------------------------------------------

    test('an unknown stop operator or action fails', () {
      final operator = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stopConditions: <Sprint116RolloutStopConditionRecord>[
            _stop(operator: 'approximately'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(
        operator.invalidRecords,
        contains('stop_operator:stop_internal_error'),
      );

      final action = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stopConditions: <Sprint116RolloutStopConditionRecord>[
            _stop(action: 'shrug'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(
        action.invalidRecords,
        contains('stop_action:stop_internal_error'),
      );
    });

    test('a non-finite stop threshold or window fails', () {
      final threshold = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stopConditions: <Sprint116RolloutStopConditionRecord>[
            _stop(threshold: double.infinity),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(
        threshold.invalidRecords,
        contains('stop_threshold:stop_internal_error'),
      );

      final window = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stopConditions: <Sprint116RolloutStopConditionRecord>[
            _stop(windowMinutes: 0),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(
        window.invalidRecords,
        contains('stop_window:stop_internal_error'),
      );
    });

    test('a stop condition pointing at an unknown stage fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stopConditions: <Sprint116RolloutStopConditionRecord>[
            _stop(stageId: 'stage_ghost'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('stop_stage:stop_internal_error'));
    });

    test('a stop condition pointing at an unknown metric fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stopConditions: <Sprint116RolloutStopConditionRecord>[
            _stop(metricId: 'metric_ghost'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('stop_metric:stop_internal_error'),
      );
    });

    test('a stage without a stop condition cannot be stopped', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          stopConditions: <Sprint116RolloutStopConditionRecord>[
            _stop(),
            _stop(
              stopId: 'stop_waitlist_error',
              stageId: 'stage_waitlist',
              metricId: 'metric_error_rate',
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('stage_stop:stage_alpha'));
    });

    // ---- provider kill switches -------------------------------------------

    test('an unknown kill switch scope fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          killSwitches: <Sprint116RolloutKillSwitchRecord>[
            _kill(scope: 'yolo'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('kill_scope:kill_openai'));
    });

    test('a kill switch without provider, connector, or stages fails', () {
      final provider = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          killSwitches: <Sprint116RolloutKillSwitchRecord>[
            _kill(providerId: ''),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(provider.invalidRecords, contains('kill_provider:kill_openai'));

      final connector = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          killSwitches: <Sprint116RolloutKillSwitchRecord>[
            _kill(connectorId: ''),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(connector.invalidRecords, contains('kill_connector:kill_openai'));

      final stages = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          killSwitches: <Sprint116RolloutKillSwitchRecord>[
            _kill(stages: const <String>[]),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(stages.invalidRecords, contains('kill_stages:kill_openai'));
    });

    test('a kill switch pointing at an unknown stage fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          killSwitches: <Sprint116RolloutKillSwitchRecord>[
            _kill(stages: const <String>['stage_ghost']),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('kill_stage:kill_openai'));
    });

    test('a kill switch pointing at an unknown flag fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          killSwitches: <Sprint116RolloutKillSwitchRecord>[
            _kill(flagRef: 'flag_ghost'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('kill_flag:kill_openai'));
    });

    test(
      'a verified kill-switch drill without evidence is a claim into thin air',
      () {
        final synthetic = Sprint116StagedRolloutPlan().certify(
          controls: _controls(
            killSwitches: <Sprint116RolloutKillSwitchRecord>[
              _kill(drillVerified: true),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(synthetic.invalidRecords, contains('kill_drill:kill_openai'));

        final undated = Sprint116StagedRolloutPlan().certify(
          controls: _controls(
            killSwitches: <Sprint116RolloutKillSwitchRecord>[
              _kill(
                drillVerified: true,
                drillAtEpochMs: 0,
                source: 'live',
                evidenceRef: _manifestArtifact,
              ),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(undated.invalidRecords, contains('kill_drill:kill_openai'));
      },
    );

    test(
      'an exposed connector without a kill switch covering the stage fails',
      () {
        final report = Sprint116StagedRolloutPlan().certify(
          controls: _controls(
            killSwitches: <Sprint116RolloutKillSwitchRecord>[
              _kill(stages: const <String>['stage_internal', 'stage_alpha']),
              _killGemini(),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116StagedRolloutStatus.fail);
        expect(
          report.invalidRecords,
          contains('kill_switch:conn_openai:stage_waitlist'),
        );
      },
    );

    // ---- rollback ----------------------------------------------------------

    test('a rollback without a procedure is not a rollback', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          rollback: <Sprint116RolloutRollbackRecord>[_rollback(procedure: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('rollback_procedure:rb_internal'));
    });

    test('an unknown rollback target scope fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          rollback: <Sprint116RolloutRollbackRecord>[
            _rollback(targetScope: 'everything'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('rollback_scope:rb_internal'));
    });

    test('a rollback that touches local project data is forbidden', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          rollback: <Sprint116RolloutRollbackRecord>[
            _rollback(localProjectDataTouched: true),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(
        report.invalidRecords,
        contains('rollback_local_data:rb_internal'),
      );
    });

    test('a rollback verified in the future is rejected', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          rollback: <Sprint116RolloutRollbackRecord>[
            _rollback(verifiedAtEpochMs: _now + 86400000),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('rollback_time:rb_internal'));
    });

    test('a rollback claiming verification without evidence fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          rollback: <Sprint116RolloutRollbackRecord>[
            _rollback(verifiedAtEpochMs: _base),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('rollback_verify:rb_internal'));
    });

    test('a rollback pointing at an unknown target fails', () {
      final stage = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          rollback: <Sprint116RolloutRollbackRecord>[
            _rollback(targetId: 'stage_ghost'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(stage.invalidRecords, contains('rollback_target:rb_internal'));

      final flag = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          rollback: <Sprint116RolloutRollbackRecord>[
            _rollback(targetScope: 'flag', targetId: 'flag_ghost'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(flag.invalidRecords, contains('rollback_target:rb_internal'));
    });

    test('a stage without a rollback path fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          rollback: <Sprint116RolloutRollbackRecord>[_rollback()],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('stage_rollback:stage_alpha'));
      expect(report.invalidRecords, contains('stage_rollback:stage_waitlist'));
    });

    // ---- communication -----------------------------------------------------

    test('a communication without a template says nothing', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          communication: <Sprint116RolloutCommunicationRecord>[
            _comm(messageTemplate: ''),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('comm_message:comm_advance'));
    });

    test('an unknown audience or channel fails', () {
      final audience = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          communication: <Sprint116RolloutCommunicationRecord>[
            _comm(audience: 'randoms'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(audience.invalidRecords, contains('comm_audience:comm_advance'));

      final channel = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          communication: <Sprint116RolloutCommunicationRecord>[
            _comm(channel: 'carrier_pigeon'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(channel.invalidRecords, contains('comm_channel:comm_advance'));
    });

    test('an unknown communication trigger fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          communication: <Sprint116RolloutCommunicationRecord>[
            _comm(trigger: 'full_moon'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('comm_trigger_kind:comm_advance'));
    });

    test('a communication drafted in the future is rejected', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          communication: <Sprint116RolloutCommunicationRecord>[
            _comm(draftedAtEpochMs: _now + 86400000),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('comm_time:comm_advance'));
    });

    test('a communication claiming it was sent without evidence fails', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          communication: <Sprint116RolloutCommunicationRecord>[
            _comm(sentAtEpochMs: _base),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('comm_sent:comm_advance'));
    });

    test('every incident trigger has a communication record', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          communication: <Sprint116RolloutCommunicationRecord>[
            _comm(),
            _comm(
              commId: 'comm_stop',
              trigger: 'stop_condition_hit',
              audience: 'internal_oncall',
              channel: 'internal_alert',
            ),
            _comm(commId: 'comm_rollback', trigger: 'rollback_executed'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116StagedRolloutStatus.fail);
      expect(report.invalidRecords, contains('comm_trigger:kill_switch_used'));
    });

    // ---- coverage & manifest ----------------------------------------------

    test('coverage mode reports the field nobody proved', () {
      final report = Sprint116StagedRolloutPlan().certify(
        controls: _controls(
          healthMetrics: <Sprint116RolloutHealthMetricRecord>[
            _metric(metricType: 'vibes'),
          ],
        ),
        asOfEpochMs: _now,
        requireCoverage: true,
      );
      expect(report.invalidRecords, contains('area_coverage:health_metrics'));
    });

    test('the local manifest is UNVERIFIED and free of secrets', () {
      final report = Sprint116StagedRolloutPlan().certify();
      expect(report.state, Sprint116StagedRolloutStatus.pass);
      expect(report.invalidRecords, isEmpty);

      final raw = File(
        Sprint116StagedRolloutContract.manifestPath,
      ).readAsStringSync();
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      expect(manifest['status'], 'UNVERIFIED');
      expect(manifest['live_rollout_executed'], isFalse);
      expect(manifest['beta_feature_flags_default'], 'OFF');
      expect(manifest['certified_on'], '2026-09-29');
      expect(manifest['as_of_epoch_ms'], _now);
      expect(
        manifest['required_fields'],
        Sprint116StagedRolloutContract.requiredFields,
      );

      // Keys and values are inspected rather than raw prose, so limitations
      // text may say "no api key stored" without flagging itself.
      final vocabulary = <String>{
        ...Sprint116StagedRolloutContract.requiredFields,
        ...Sprint116StagedRolloutContract.supportedSources,
        ...Sprint116StagedRolloutContract.knownFlagStates,
        ...Sprint116StagedRolloutContract.knownMetricTypes,
        ...Sprint116StagedRolloutContract.knownMetricDirections,
        ...Sprint116StagedRolloutContract.knownStopOperators,
        ...Sprint116StagedRolloutContract.knownStopActions,
        ...Sprint116StagedRolloutContract.knownKillScopes,
        ...Sprint116StagedRolloutContract.knownTargetScopes,
        ...Sprint116StagedRolloutContract.knownAudiences,
        ...Sprint116StagedRolloutContract.knownCommChannels,
        ...Sprint116StagedRolloutContract.knownCommTriggers,
      };

      for (final secret in <String>[
        'api_key',
        'apikey',
        'access_token',
        'bearer',
        'client_secret',
        'password',
        'private_key',
      ]) {
        bool carriesSecret(Object? node) {
          if (node is Map) {
            for (final entry in node.entries) {
              if (entry.key.toString().toLowerCase().contains(secret)) {
                return true;
              }
              if (carriesSecret(entry.value)) return true;
            }
            return false;
          }
          if (node is List) return node.any(carriesSecret);
          final text = node.toString();
          if (vocabulary.contains(text)) return false;
          return text.toLowerCase().contains(secret);
        }

        expect(
          carriesSecret(manifest),
          isFalse,
          reason: 'manifest must not carry $secret',
        );
      }

      // Positive control: the exemption above is narrow, so a real value in
      // the same shape is still caught. Without this the scanner could be
      // weakened into silence and the assertions above become theatre.
      for (final secret in <String>['api_key', 'password']) {
        bool wouldBeCaught(Map<String, Object?> node) {
          bool walk(Object? value) {
            if (value is Map) {
              for (final entry in value.entries) {
                if (entry.key.toString().toLowerCase().contains(secret)) {
                  return true;
                }
                if (walk(entry.value)) return true;
              }
              return false;
            }
            if (value is List) return value.any(walk);
            final text = value.toString();
            if (vocabulary.contains(text)) return false;
            return text.toLowerCase().contains(secret);
          }

          return walk(node);
        }

        expect(
          wouldBeCaught(<String, Object?>{
            'flags': <Object?>[
              <String, Object?>{'flag_key': '$secret=not-a-real-value'},
            ],
          }),
          isTrue,
          reason: 'a real credential in a flag field must be caught',
        );
      }
    });
  });
}

// The default is the healthy rollout plan. An explicitly passed empty list
// stays empty, so a caller can never assert "this field was not run" by
// accident of the helper filling it back in.
Sprint116StagedRolloutControlSet _controls({
  List<Sprint116RolloutFlagRecord>? flags,
  List<Sprint116RolloutStageRecord>? stages,
  List<Sprint116RolloutHealthMetricRecord>? healthMetrics,
  List<Sprint116RolloutStopConditionRecord>? stopConditions,
  List<Sprint116RolloutKillSwitchRecord>? killSwitches,
  List<Sprint116RolloutRollbackRecord>? rollback,
  List<Sprint116RolloutCommunicationRecord>? communication,
  List<Sprint116RolloutEvidenceRecord>? evidence,
}) {
  return Sprint116StagedRolloutControlSet(
    flags:
        flags ??
        <Sprint116RolloutFlagRecord>[
          _flag(),
          _flag(
            flagId: 'flag_kill_openai',
            flagKey: 'connector.openai.enabled',
            owner: 'release-owner',
          ),
          _flag(
            flagId: 'flag_kill_gemini',
            flagKey: 'connector.gemini.enabled',
            owner: 'release-owner',
          ),
        ],
    stages:
        stages ??
        <Sprint116RolloutStageRecord>[
          _stage(),
          _stage(
            stageId: 'stage_alpha',
            sequence: 2,
            exposurePercent: 25,
            exposedConnectors: const <String>['conn_openai', 'conn_gemini'],
          ),
          _stage(
            stageId: 'stage_waitlist',
            sequence: 3,
            exposurePercent: 100,
            exposedConnectors: const <String>['conn_openai', 'conn_gemini'],
          ),
        ],
    healthMetrics:
        healthMetrics ??
        <Sprint116RolloutHealthMetricRecord>[
          _metric(),
          _metric(
            metricId: 'metric_auth_success',
            metricName: 'auth_success_rate',
            metricType: 'auth_success_rate',
            direction: 'lower_is_worse',
            threshold: 0.95,
          ),
          _metric(
            metricId: 'metric_crash_rate',
            metricName: 'crash_rate',
            metricType: 'crash_rate',
            direction: 'higher_is_worse',
            threshold: 0.01,
            windowMinutes: 1440,
          ),
        ],
    stopConditions:
        stopConditions ??
        <Sprint116RolloutStopConditionRecord>[
          _stop(),
          _stop(
            stopId: 'stop_alpha_error',
            stageId: 'stage_alpha',
            action: 'rollback_stage',
          ),
          _stop(
            stopId: 'stop_alpha_auth',
            stageId: 'stage_alpha',
            metricId: 'metric_auth_success',
            operator: 'lt',
            threshold: 0.95,
            action: 'page_oncall',
          ),
          _stop(
            stopId: 'stop_waitlist_error',
            stageId: 'stage_waitlist',
            action: 'rollback_stage',
          ),
          _stop(
            stopId: 'stop_waitlist_crash',
            stageId: 'stage_waitlist',
            metricId: 'metric_crash_rate',
            threshold: 0.01,
          ),
        ],
    killSwitches:
        killSwitches ??
        <Sprint116RolloutKillSwitchRecord>[_kill(), _killGemini()],
    rollback:
        rollback ??
        <Sprint116RolloutRollbackRecord>[
          _rollback(),
          _rollback(rollbackId: 'rb_alpha', targetId: 'stage_alpha'),
          _rollback(rollbackId: 'rb_waitlist', targetId: 'stage_waitlist'),
        ],
    communication:
        communication ??
        <Sprint116RolloutCommunicationRecord>[
          _comm(),
          _comm(
            commId: 'comm_stop',
            trigger: 'stop_condition_hit',
            audience: 'internal_oncall',
            channel: 'internal_alert',
          ),
          _comm(commId: 'comm_rollback', trigger: 'rollback_executed'),
          _comm(
            commId: 'comm_kill',
            trigger: 'kill_switch_used',
            channel: 'status_page',
          ),
        ],
    evidence: evidence ?? <Sprint116RolloutEvidenceRecord>[_evidence()],
  );
}

Sprint116RolloutFlagRecord _flag({
  String flagId = 'flag_beta_connectors',
  String flagKey = 'beta.connectors.enabled',
  String defaultState = 'OFF',
  String owner = 'release-owner',
  List<String> linkedStages = const <String>[
    'stage_internal',
    'stage_alpha',
    'stage_waitlist',
  ],
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116RolloutFlagRecord(
    flagId: flagId,
    flagKey: flagKey,
    defaultState: defaultState,
    owner: owner,
    linkedStages: linkedStages,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116RolloutStageRecord _stage({
  String stageId = 'stage_internal',
  int sequence = 1,
  int exposurePercent = 5,
  List<String> entryCriteria = const <String>['internal_dogfood_green'],
  List<String> exitCriteria = const <String>['no_sev1_for_72h'],
  List<String> exposedConnectors = const <String>['conn_openai'],
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116RolloutStageRecord(
    stageId: stageId,
    sequence: sequence,
    exposurePercent: exposurePercent,
    entryCriteria: entryCriteria,
    exitCriteria: exitCriteria,
    exposedConnectors: exposedConnectors,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116RolloutHealthMetricRecord _metric({
  String metricId = 'metric_error_rate',
  String metricName = 'error_rate',
  String metricType = 'error_rate',
  String direction = 'higher_is_worse',
  double threshold = 0.02,
  int windowMinutes = 60,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116RolloutHealthMetricRecord(
    metricId: metricId,
    metricName: metricName,
    metricType: metricType,
    direction: direction,
    threshold: threshold,
    windowMinutes: windowMinutes,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116RolloutStopConditionRecord _stop({
  String stopId = 'stop_internal_error',
  String stageId = 'stage_internal',
  String metricId = 'metric_error_rate',
  String operator = 'gt',
  double threshold = 0.02,
  int windowMinutes = 60,
  String action = 'halt_rollout',
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116RolloutStopConditionRecord(
    stopId: stopId,
    stageId: stageId,
    metricId: metricId,
    operator: operator,
    threshold: threshold,
    windowMinutes: windowMinutes,
    action: action,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116RolloutKillSwitchRecord _kill({
  String killId = 'kill_openai',
  String providerId = 'openai',
  String connectorId = 'conn_openai',
  String scope = 'connector_disable',
  String flagRef = 'flag_kill_openai',
  List<String> stages = const <String>[
    'stage_internal',
    'stage_alpha',
    'stage_waitlist',
  ],
  bool drillVerified = false,
  int drillAtEpochMs = 0,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116RolloutKillSwitchRecord(
    killId: killId,
    providerId: providerId,
    connectorId: connectorId,
    scope: scope,
    flagRef: flagRef,
    stages: stages,
    drillVerified: drillVerified,
    drillAtEpochMs: drillAtEpochMs,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116RolloutKillSwitchRecord _killGemini() {
  return Sprint116RolloutKillSwitchRecord(
    killId: 'kill_gemini',
    providerId: 'gemini',
    connectorId: 'conn_gemini',
    scope: 'connector_disable',
    flagRef: 'flag_kill_gemini',
    stages: const <String>['stage_alpha', 'stage_waitlist'],
    drillVerified: false,
    drillAtEpochMs: 0,
    source: 'synthetic_local',
    evidenceRef: null,
  );
}

Sprint116RolloutRollbackRecord _rollback({
  String rollbackId = 'rb_internal',
  String targetScope = 'stage',
  String targetId = 'stage_internal',
  String procedure = 'set flag OFF, restart previous build, notify cohort',
  bool localProjectDataTouched = false,
  int verifiedAtEpochMs = 0,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116RolloutRollbackRecord(
    rollbackId: rollbackId,
    targetScope: targetScope,
    targetId: targetId,
    procedure: procedure,
    localProjectDataTouched: localProjectDataTouched,
    verifiedAtEpochMs: verifiedAtEpochMs,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116RolloutCommunicationRecord _comm({
  String commId = 'comm_advance',
  String audience = 'beta_participants',
  String channel = 'in_app',
  String trigger = 'stage_advance',
  String messageTemplate =
      'Stage {{stage}} now covers {{exposure}}% of the beta cohort.',
  int draftedAtEpochMs = 0,
  int sentAtEpochMs = 0,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116RolloutCommunicationRecord(
    commId: commId,
    audience: audience,
    channel: channel,
    trigger: trigger,
    messageTemplate: messageTemplate,
    draftedAtEpochMs: draftedAtEpochMs == 0 ? _base : draftedAtEpochMs,
    sentAtEpochMs: sentAtEpochMs,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116RolloutEvidenceRecord _evidence({
  String evidenceId = 'ev_rollout_plan',
  String claim = 'staged rollout plan recorded in the repository manifest',
  String artifact = _manifestArtifact,
  int? recordedAtEpochMs,
  String source = 'local_run',
  String? evidenceRef,
}) {
  return Sprint116RolloutEvidenceRecord(
    evidenceId: evidenceId,
    claim: claim,
    artifact: artifact,
    recordedAtEpochMs: recordedAtEpochMs ?? _base,
    source: source,
    evidenceRef: evidenceRef ?? _manifestArtifact,
  );
}
