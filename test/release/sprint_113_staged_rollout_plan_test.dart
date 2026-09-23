// 113.41 — Staged Rollout Plan.
//
// Contract for the seven canonical plan fields and the evaluation rule
// that keeps "plan written" separate from "rollout approved".
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/staged_rollout_plan.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.2/sprint_113_staged_rollout_plan.json',
  );

  group('113.41 staged rollout plan', () {
    test('declares the seven canonical required fields', () {
      expect(kStagedRolloutRequiredFields, <String>[
        'stage',
        'exposure',
        'duration',
        'health_criteria',
        'stop_conditions',
        'rollback_owner',
        'approval',
      ]);
      expect(kStagedRolloutRequiredFields.toSet().length, 7);
    });

    test('planning manifest exists with all seven fields per stage', () {
      expect(
        manifestFile.existsSync(),
        isTrue,
        reason:
            'missing docs/planning/v1.2/'
            'sprint_113_staged_rollout_plan.json',
      );
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['canonical_step'], '113.41');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      final stages = manifest['stages'] as List<dynamic>;
      expect(stages, isNotEmpty);

      for (final raw in stages) {
        final stage = raw as Map<String, dynamic>;
        for (final field in kStagedRolloutRequiredFields) {
          expect(
            stage.containsKey(field),
            isTrue,
            reason: 'stage ${stage['stage']} lacks field $field',
          );
          expect(stage[field], isNotNull);
        }
        expect(stage['exposure'], greaterThan(0));
        expect(stage['exposure'], lessThanOrEqualTo(100));
        expect(stage['duration'], greaterThan(0));
        expect(stage['health_criteria'] as List<dynamic>, isNotEmpty);
        expect(stage['stop_conditions'] as List<dynamic>, isNotEmpty);
        expect((stage['rollback_owner'] as String).trim(), isNotEmpty);
        expect(
          stage['approval'],
          isIn(<String>['APPROVED', 'PENDING_CHOIRUDIN']),
        );
      }

      // Exposure must be monotonic and finish at 100%.
      final exposures = stages
          .map((raw) => (raw as Map<String, dynamic>)['exposure'] as int)
          .toList();
      for (var i = 1; i < exposures.length; i++) {
        expect(
          exposures[i],
          greaterThanOrEqualTo(exposures[i - 1]),
          reason: 'exposure must never decrease across stages',
        );
      }
      expect(exposures.last, 100);

      // Rollback owner must be the same accountable person everywhere.
      final owners = stages
          .map((raw) => (raw as Map<String, dynamic>)['rollback_owner'])
          .toSet();
      expect(
        owners.length,
        1,
        reason: 'rollback owner must be a single accountable owner',
      );
    });

    test('plan approval stays pending until explicit Choi approval', () {
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['approval_state'], 'PENDING_CHOIRUDIN');
      expect(
        manifest['approval_note'],
        contains('explicit'),
        reason: 'the manifest must state that explicit approval is required',
      );
      expect(
        manifest['execution_authorized'],
        isFalse,
        reason: 'a pending plan must never authorize execution',
      );
    });

    test('domain evaluation blocks, fails pending, and passes approved', () {
      // Nothing recorded -> blocked.
      expect(StagedRolloutPlan.evaluate(null).state, RolloutPlanState.blocked);

      // Structurally incomplete -> fail with the canonical names.
      const incomplete = StagedRolloutPlan(
        stages: <RolloutStage>[
          RolloutStage(
            stage: 'canary',
            exposurePercent: 5,
            durationHours: 24,
            healthCriteria: null,
            stopConditions: null,
            rollbackOwner: null,
            approval: RolloutApproval.approved,
          ),
        ],
      );
      final failed = StagedRolloutPlan.evaluate(incomplete);
      expect(failed.state, RolloutPlanState.fail);
      expect(failed.notes.single, contains('health_criteria'));
      expect(failed.notes.single, contains('stop_conditions'));
      expect(failed.notes.single, contains('rollback_owner'));

      // Complete but pending -> fail with explicit approval note.
      const pending = StagedRolloutPlan(
        stages: <RolloutStage>[
          RolloutStage(
            stage: 'canary',
            exposurePercent: 5,
            durationHours: 24,
            healthCriteria: <String>['crash-free >= 99.5%'],
            stopConditions: <String>['crash rate > 1%'],
            rollbackOwner: 'Choirudin',
            approval: RolloutApproval.pending,
          ),
          RolloutStage(
            stage: 'ga',
            exposurePercent: 100,
            durationHours: 48,
            healthCriteria: <String>['crash-free >= 99.9%'],
            stopConditions: <String>['update failures reported'],
            rollbackOwner: 'Choirudin',
            approval: RolloutApproval.pending,
          ),
        ],
      );
      final pendingEval = StagedRolloutPlan.evaluate(pending);
      expect(pendingEval.state, RolloutPlanState.fail);
      expect(pendingEval.notes.single, contains('approval pending'));
      expect(pendingEval.notes.single, contains('Choirudin'));

      // Explicitly approved -> pass with counts.
      const approved = StagedRolloutPlan(
        stages: <RolloutStage>[
          RolloutStage(
            stage: 'canary',
            exposurePercent: 5,
            durationHours: 24,
            healthCriteria: <String>['crash-free >= 99.5%'],
            stopConditions: <String>['crash rate > 1%'],
            rollbackOwner: 'Choirudin',
            approval: RolloutApproval.approved,
          ),
          RolloutStage(
            stage: 'broad',
            exposurePercent: 50,
            durationHours: 48,
            healthCriteria: <String>['crash-free >= 99.9%'],
            stopConditions: <String>['rollback trigger hit'],
            rollbackOwner: 'Choirudin',
            approval: RolloutApproval.approved,
          ),
          RolloutStage(
            stage: 'ga',
            exposurePercent: 100,
            durationHours: 72,
            healthCriteria: <String>['crash-free >= 99.9%'],
            stopConditions: <String>['support spike'],
            rollbackOwner: 'Choirudin',
            approval: RolloutApproval.approved,
          ),
        ],
      );
      final passed = StagedRolloutPlan.evaluate(approved);
      expect(passed.state, RolloutPlanState.pass);
      expect(passed.notes.join(' '), contains('stages: 3'));
      expect(passed.notes.join(' '), contains('max exposure: 100%'));
      expect(passed.notes.join(' '), contains('total duration: 144h'));
      expect(passed.notes.join(' '), contains('rollback owner: Choirudin'));
    });

    test('missingFields names every absent required field when empty', () {
      expect(
        StagedRolloutPlan.missingFields(const StagedRolloutPlan()),
        kStagedRolloutRequiredFields,
      );

      // Bad exposure values are rejected as exposure.
      const badExposure = StagedRolloutPlan(
        stages: <RolloutStage>[
          RolloutStage(
            stage: 'canary',
            exposurePercent: 0,
            durationHours: 24,
            healthCriteria: <String>['a'],
            stopConditions: <String>['b'],
            rollbackOwner: 'Choirudin',
            approval: RolloutApproval.approved,
          ),
        ],
      );
      expect(
        StagedRolloutPlan.missingFields(badExposure),
        contains('exposure'),
      );
    });
  });
}
