import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/rollout_stage_verification.dart';

void main() {
  group('114.8 Rollout Stage Verification', () {
    test('absent rollout record is blocked without claiming exposure', () {
      final report = RolloutStageVerification().verify(null);

      expect(report.state, RolloutStageState.blocked);
      expect(report.currentStage, RolloutStage.notStarted);
      expect(report.exposure, 0);
      expect(report.decision, RolloutDecision.noExposure);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('exposure beyond stage cap and missing rollback owner fail', () {
      final report = RolloutStageVerification().verify(
        const RolloutStageRecord(
          currentStage: RolloutStage.canaryInternal,
          exposurePercent: 40,
          healthResults: <RolloutHealthResult>[
            RolloutHealthResult(name: 'crash_free_sessions', passed: true),
          ],
          stopConditions: <RolloutStopCondition>[
            RolloutStopCondition(id: 'crash_free_below_99', triggered: false),
          ],
          rollbackOwner: '',
          proposedDecision: RolloutDecision.continueExposure,
        ),
      );

      expect(report.state, RolloutStageState.fail);
      expect(report.invalidFields, <String>['exposure', 'rollback_owner']);
      expect(report.allowedExposurePercent, 5);
    });

    test('healthy canary record verifies stage, exposure, and controls', () {
      final report = RolloutStageVerification().verify(
        const RolloutStageRecord(
          currentStage: RolloutStage.canaryInternal,
          exposurePercent: 5,
          healthResults: <RolloutHealthResult>[
            RolloutHealthResult(name: 'crash_free_sessions', passed: true),
            RolloutHealthResult(name: 'install_success', passed: true),
          ],
          stopConditions: <RolloutStopCondition>[
            RolloutStopCondition(id: 'crash_free_below_99', triggered: false),
            RolloutStopCondition(id: 'signature_mismatch', triggered: false),
          ],
          rollbackOwner: 'Choirudin',
          proposedDecision: RolloutDecision.continueExposure,
        ),
      );

      expect(report.state, RolloutStageState.pass);
      expect(report.currentStage, RolloutStage.canaryInternal);
      expect(report.exposure, 5);
      expect(report.allowedExposurePercent, 5);
      expect(report.healthResults.length, 2);
      expect(report.triggeredStopConditions, isEmpty);
      expect(report.rollbackOwner, 'Choirudin');
      expect(report.decision, RolloutDecision.continueExposure);
    });

    test('triggered stop condition with continue decision is ignored', () {
      final ignored = RolloutStageVerification().verify(
        const RolloutStageRecord(
          currentStage: RolloutStage.broadBeta,
          exposurePercent: 50,
          healthResults: <RolloutHealthResult>[
            RolloutHealthResult(name: 'crash_free_sessions', passed: false),
          ],
          stopConditions: <RolloutStopCondition>[
            RolloutStopCondition(id: 'rollback_trigger_open', triggered: true),
          ],
          rollbackOwner: 'Choirudin',
          proposedDecision: RolloutDecision.continueExposure,
        ),
      );

      expect(ignored.state, RolloutStageState.fail);
      expect(ignored.triggeredStopConditions, <String>[
        'rollback_trigger_open',
      ]);
      expect(ignored.violations, <String>['stop_condition_ignored']);

      final halted = RolloutStageVerification().verify(
        const RolloutStageRecord(
          currentStage: RolloutStage.halted,
          exposurePercent: 0,
          healthResults: <RolloutHealthResult>[
            RolloutHealthResult(name: 'crash_free_sessions', passed: false),
          ],
          stopConditions: <RolloutStopCondition>[
            RolloutStopCondition(id: 'rollback_trigger_open', triggered: true),
          ],
          rollbackOwner: 'Choirudin',
          proposedDecision: RolloutDecision.haltExposure,
        ),
      );

      expect(halted.state, RolloutStageState.pass);
      expect(halted.allowedExposurePercent, 0);
      expect(halted.decision, RolloutDecision.haltExposure);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_rollout_stage_verification.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.8');
      expect(document['required_evidence'], <dynamic>[
        'current_stage',
        'exposure',
        'health_results',
        'stop_conditions',
        'rollback_owner',
        'decision',
      ]);
      expect(document['exposure_caps_percent'], <String, dynamic>{
        'not_started': 0,
        'canary_internal': 5,
        'broad_beta': 50,
        'ga_full': 100,
        'halted': 0,
      });
      expect(document['rollback_owner'], 'Choirudin');
      expect(document['external_rollout_execution'], 'DEFERRED-EXTERNAL');
    });
  });
}
