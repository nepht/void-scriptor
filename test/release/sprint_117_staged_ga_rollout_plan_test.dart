import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_staged_ga_rollout_plan.dart';

/// A synthetic, internally consistent anchor used to exercise the gate without
/// touching the committed manifests. Tests mutate one field at a time from this
/// baseline so each assertion isolates a single defect.
Sprint117RolloutAnchor _anchor({
  String exposureVerdict = 'CERTIFICATION_SNAPSHOT_LOCKED_LOCAL',
  String exposureMatrixVerdict = 'BETA_EXPOSURE_MATRIX_DETERMINED_LOCAL',
  String supportVerdict = 'SUPPORT_INCIDENT_READINESS_DEFINED_LOCAL',
  String rollbackVerdict = 'PROVIDER_ROLLBACK_DRILL_DEFINED_LOCAL',
  List<String> certifiedSubset = const <String>['openai', 'gemini'],
  List<String> determinedExposed = const <String>['openai', 'gemini'],
  List<String> enabledSubset = const <String>[],
  String recordedDefault = 'OFF',
  String masterFlagKey = 'beta.connectors.enabled',
  List<String> stagedConnectors = const <String>['conn_openai', 'conn_gemini'],
  List<String> recordedMetricIds = const <String>['metric_error_rate'],
  Map<String, String> stopAction = const <String, String>{
    'stop_internal_error': 'halt_rollout',
  },
  Map<String, String> stopStage = const <String, String>{
    'stop_internal_error': 'stage_internal',
  },
  Map<String, String> stopMetric = const <String, String>{
    'stop_internal_error': 'metric_error_rate',
  },
  Map<String, String> killProvider = const <String, String>{
    'kill_openai': 'openai',
  },
  Map<String, String> rollbackTarget = const <String, String>{
    'rb_internal': 'stage_internal',
  },
  Map<String, String> supportOwnerByProvider = const <String, String>{
    'openai': 'support-owner',
  },
  bool drillExecuted = false,
  List<String> undrilledKillIds = const <String>['kill_openai'],
}) => Sprint117RolloutAnchor(
  exposureVerdict: exposureVerdict,
  exposureMatrixVerdict: exposureMatrixVerdict,
  supportVerdict: supportVerdict,
  rollbackVerdict: rollbackVerdict,
  certifiedSubset: certifiedSubset,
  determinedExposed: determinedExposed,
  enabledSubset: enabledSubset,
  recordedDefault: recordedDefault,
  masterFlagKey: masterFlagKey,
  stagedConnectors: stagedConnectors,
  recordedMetricIds: recordedMetricIds,
  metricDirection: const <String, String>{
    'metric_error_rate': 'higher_is_worse',
  },
  stopAction: stopAction,
  stopStage: stopStage,
  stopMetric: stopMetric,
  killProvider: killProvider,
  rollbackTarget: rollbackTarget,
  supportOwnerByProvider: supportOwnerByProvider,
  charterIncidentOwner: 'incident-owner',
  drillExecuted: drillExecuted,
  undrilledKillIds: undrilledKillIds,
  carriedOpenItems: const <String>[],
);

Sprint117RolloutStageRecord _stage({
  String stageId = 'stage_internal',
  int sequence = 1,
  int exposurePercent = 5,
  List<String> exposedProviders = const <String>['openai'],
  List<String> healthMetricIds = const <String>['metric_error_rate'],
  List<String> stopConditionIds = const <String>['stop_internal_error'],
  List<String> killSwitchIds = const <String>['kill_openai'],
  String rollbackId = 'rb_internal',
  String supportOwner = 'support-owner',
}) => Sprint117RolloutStageRecord(
  stageId: stageId,
  sequence: sequence,
  exposurePercent: exposurePercent,
  exposedProviders: exposedProviders,
  entryCriteria: const <String>['internal_dogfood_green'],
  exitCriteria: const <String>['no_sev1_for_72h'],
  healthMetricIds: healthMetricIds,
  stopConditionIds: stopConditionIds,
  killSwitchIds: killSwitchIds,
  rollbackId: rollbackId,
  supportOwner: supportOwner,
);

void main() {
  group('117.44 contract', () {
    test('names the canonical step, the eight fields, and its sources', () {
      expect(Sprint117RolloutContract.canonicalStep, '117.44');
      expect(Sprint117RolloutContract.requiredFields, <String>[
        'stages',
        'connector_subset',
        'exposure',
        'health_criteria',
        'stop_conditions',
        'kill_switches',
        'rollback',
        'support',
      ]);
      expect(
        Sprint117RolloutContract.manifestPath,
        'docs/planning/v1.3/sprint_117_staged_ga_rollout_plan.json',
      );
      expect(Sprint117RolloutContract.sourceManifests, <String>[
        'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json',
        'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json',
        'docs/planning/v1.3/sprint_117_beta_exposure_flag_matrix.json',
        'docs/planning/v1.3/sprint_117_support_incident_readiness.json',
        'docs/planning/v1.3/sprint_117_provider_rollback_drill.json',
      ]);
      expect(Sprint117RolloutContract.externalGates, 'DEFERRED-EXTERNAL');
      expect(Sprint117RolloutContract.stopActions, contains('halt_rollout'));
    });
  });

  group('117.44 live gate against committed evidence', () {
    final report = const Sprint117RolloutGate().evaluate();

    test('passes, because the plan is fully determined locally', () {
      expect(report.state, Sprint117RolloutState.pass);
      expect(report.verdict, Sprint117RolloutContract.passVerdict);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.undeterminedFields, isEmpty);
    });

    test('every canonical field is covered by every stage', () {
      expect(report.stageCount, 3);
      for (final field in Sprint117RolloutContract.requiredFields) {
        expect(
          report.fieldCoverage[field],
          report.stageCount,
          reason: 'field $field must be determined for every stage',
        );
      }
    });

    test('stages only expose the certified subset 117.4 locked', () {
      expect(report.certifiedSubset, contains('openai'));
      expect(report.certifiedSubset, contains('gemini'));
      expect(report.connectorSubset, <String>['openai', 'gemini']);
      for (final stage in report.stages) {
        for (final provider in stage.exposedProviders) {
          expect(
            report.certifiedSubset,
            contains(provider),
            reason: 'stage ${stage.stageId} exposes $provider uncertified',
          );
          expect(report.determinedExposed, contains(provider));
        }
      }
    });

    test('the rollout determines exposure and enables nothing', () {
      expect(report.enabledSubset, isEmpty);
      expect(report.liveRolloutExecuted, isFalse);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('the master flag and the recorded default are read, not typed', () {
      expect(report.masterFlag, 'beta.connectors.enabled');
      expect(report.recordedDefault, 'OFF');
    });

    test('stage exposure rises with the stage sequence', () {
      final ordered = List<Sprint117RolloutStageRecord>.from(report.stages)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      var previous = 0;
      for (final stage in ordered) {
        expect(stage.exposurePercent, greaterThan(previous));
        previous = stage.exposurePercent;
      }
    });

    test('each stage names a rollback that targets it', () {
      for (final stage in report.stages) {
        expect(
          stage.rollbackId,
          isNotEmpty,
          reason: 'stage ${stage.stageId} has no rollback',
        );
      }
    });

    test('carries open items and never claims a live rollout', () {
      expect(report.openItems, contains('live_rollout_not_executed'));
      expect(report.openItems, contains('cohort_not_verified'));
      expect(report.openItems, contains('rollback_drill_not_executed'));
    });
  });

  group('117.44 fail-closed negatives', () {
    Sprint117RolloutReport evaluate(Sprint117RolloutInput input) =>
        const Sprint117RolloutGate().evaluateWith(input);

    test('an uncertified connector is a violation, not a wider beta', () {
      final report = evaluate(
        Sprint117RolloutInput(
          anchor: _anchor(),
          stages: <Sprint117RolloutStageRecord>[
            _stage(exposedProviders: const <String>['openai', 'mystery']),
          ],
        ),
      );
      expect(report.state, Sprint117RolloutState.fail);
      expect(
        report.violations,
        contains('uncertified_connector:stage_internal:mystery'),
      );
    });

    test('a stage that exposes nothing is reported undetermined', () {
      final report = evaluate(
        Sprint117RolloutInput(
          anchor: _anchor(),
          stages: <Sprint117RolloutStageRecord>[
            _stage(exposedProviders: const <String>[]),
          ],
        ),
      );
      expect(report.state, Sprint117RolloutState.fail);
      expect(
        report.violations,
        contains('stage_exposes_nothing:stage_internal'),
      );
      expect(report.undeterminedFields, contains('connector_subset'));
    });

    test('a stage whose exposure regresses is a violation', () {
      final report = evaluate(
        Sprint117RolloutInput(
          anchor: _anchor(
            certifiedSubset: const <String>['openai'],
            determinedExposed: const <String>['openai'],
            stagedConnectors: const <String>['conn_openai'],
            killProvider: const <String, String>{'kill_openai': 'openai'},
            rollbackTarget: const <String, String>{
              'rb_internal': 'stage_internal',
              'rb_alpha': 'stage_alpha',
            },
            stopAction: const <String, String>{
              'stop_internal_error': 'halt_rollout',
              'stop_alpha_error': 'rollback_stage',
            },
            stopStage: const <String, String>{
              'stop_internal_error': 'stage_internal',
              'stop_alpha_error': 'stage_alpha',
            },
            stopMetric: const <String, String>{
              'stop_internal_error': 'metric_error_rate',
              'stop_alpha_error': 'metric_error_rate',
            },
          ),
          stages: <Sprint117RolloutStageRecord>[
            _stage(stageId: 'stage_internal', sequence: 1, exposurePercent: 25),
            _stage(
              stageId: 'stage_alpha',
              sequence: 2,
              exposurePercent: 5,
              stopConditionIds: const <String>['stop_alpha_error'],
              rollbackId: 'rb_alpha',
            ),
          ],
        ),
      );
      expect(report.state, Sprint117RolloutState.fail);
      expect(
        report.violations,
        contains('exposure_percent_regression:stage_alpha'),
      );
    });

    test('a stop condition outside the action vocabulary is a violation', () {
      final report = evaluate(
        Sprint117RolloutInput(
          anchor: _anchor(
            stopAction: const <String, String>{
              'stop_internal_error': 'ignore_it',
            },
          ),
          stages: <Sprint117RolloutStageRecord>[_stage()],
        ),
      );
      expect(report.state, Sprint117RolloutState.fail);
      expect(
        report.violations,
        contains(
          'stop_action_unknown:stage_internal:stop_internal_error:ignore_it',
        ),
      );
    });

    test('an exposed provider without a kill switch is undetermined', () {
      final report = evaluate(
        Sprint117RolloutInput(
          anchor: _anchor(
            certifiedSubset: const <String>['openai'],
            determinedExposed: const <String>['openai'],
            stagedConnectors: const <String>['conn_openai'],
            killProvider: const <String, String>{'kill_gemini': 'gemini'},
          ),
          stages: <Sprint117RolloutStageRecord>[_stage()],
        ),
      );
      expect(report.undeterminedFields, contains('kill_switches'));
    });

    test('a rollback that targets another stage is a violation', () {
      final report = evaluate(
        Sprint117RolloutInput(
          anchor: _anchor(
            rollbackTarget: const <String, String>{
              'rb_internal': 'stage_alpha',
            },
          ),
          stages: <Sprint117RolloutStageRecord>[_stage()],
        ),
      );
      expect(report.state, Sprint117RolloutState.fail);
      expect(
        report.violations,
        contains('rollback_target_mismatch:stage_internal:rb_internal'),
      );
    });

    test('a missing anchor blocks rather than passes', () {
      final report = evaluate(
        Sprint117RolloutInput(
          anchor: null,
          stages: <Sprint117RolloutStageRecord>[_stage()],
        ),
      );
      expect(report.state, Sprint117RolloutState.blocked);
      expect(report.missingFields, contains('rollout_anchor'));
    });

    test('a drifted certified-subset verdict is a violation', () {
      final report = evaluate(
        Sprint117RolloutInput(
          anchor: _anchor(exposureVerdict: 'CERTIFICATION_SNAPSHOT_DRIFTED'),
          stages: <Sprint117RolloutStageRecord>[_stage()],
        ),
      );
      expect(report.state, Sprint117RolloutState.fail);
      expect(report.violations, contains('certified_subset_drift'));
    });
  });

  group('117.44 committed manifest', () {
    test(
      'the committed manifest records the same verdict as the live gate',
      () {
        final live = const Sprint117RolloutGate().evaluate();
        final file = File(Sprint117RolloutContract.manifestPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'the generated staged GA rollout plan must be committed',
        );
        final manifest =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

        expect(manifest['canonical_step'], '117.44');
        expect(manifest['state'], live.state.name);
        expect(manifest['verdict'], live.verdict);
        expect(
          List<String>.from(manifest['missing_fields'] as List<dynamic>),
          live.missingFields,
        );
        expect(
          List<String>.from(manifest['violations'] as List<dynamic>),
          live.violations,
        );
        expect(manifest['stage_count'], live.stageCount);
        expect(
          List<String>.from(manifest['certified_subset'] as List<dynamic>),
          live.certifiedSubset,
        );
        expect(
          List<String>.from(manifest['connector_subset'] as List<dynamic>),
          live.connectorSubset,
        );
        expect(
          List<String>.from(manifest['enabled_subset'] as List<dynamic>),
          live.enabledSubset,
        );
      },
    );

    test('the manifest pins the eight fields and its sources', () {
      final manifest =
          jsonDecode(
                File(Sprint117RolloutContract.manifestPath).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(
        List<String>.from(manifest['required_fields'] as List<dynamic>),
        Sprint117RolloutContract.requiredFields,
      );
      expect(
        List<String>.from(manifest['source_manifests'] as List<dynamic>),
        Sprint117RolloutContract.sourceManifests,
      );
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['live_rollout_executed'], isFalse);
      expect(manifest['master_flag'], 'beta.connectors.enabled');
      expect(manifest['recorded_default'], 'OFF');
    });

    test('the manifest exposes the eight field blocks', () {
      final manifest =
          jsonDecode(
                File(Sprint117RolloutContract.manifestPath).readAsStringSync(),
              )
              as Map<String, dynamic>;

      for (final block in <String>[
        'stages',
        'health_criteria',
        'stop_conditions',
        'kill_switches',
        'rollback',
        'support',
      ]) {
        expect(
          manifest[block],
          isA<List<dynamic>>(),
          reason: 'manifest must carry the $block block',
        );
        expect((manifest[block] as List<dynamic>), isNotEmpty);
      }
      final coverage = manifest['field_coverage'] as Map<String, dynamic>;
      for (final field in Sprint117RolloutContract.requiredFields) {
        expect(coverage[field], greaterThan(0));
      }
    });
  });
}
