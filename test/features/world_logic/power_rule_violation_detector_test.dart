import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/power_rule_violation_detector.dart';
import 'package:void_scriptor/features/world_logic/domain/power_rulebook.dart';
import 'package:void_scriptor/features/world_logic/domain/power_usage_ledger.dart';

void main() {
  group('Power Rule Violation Detector', () {
    final walk = PowerPrerequisite.validated(
      id: 'legs',
      description: 'must be able to walk',
    );
    final flight = PowerAbility.validated(
      id: 'fly',
      name: 'Levitation',
      prerequisites: [walk],
      costs: [
        PowerCost.validated(resource: 'mana', amount: 5, reason: 'channeling'),
      ],
      limits: [
        PowerLimit.validated(
          metric: 'altitude',
          maximum: 50,
          reason: 'pressure limit',
        ),
      ],
      sideEffects: [
        PowerSideEffect.validated(description: 'vertigo', severity: 3),
      ],
      counters: [
        PowerCounter.validated(
          description: 'ground anchors',
          effectiveness: 0.7,
        ),
      ],
    );
    final rulebook = PowerRulebook.validated(abilities: [flight]);
    final source = PowerUsageSource.validated(
      revision: 'draft-1',
      reason: 'canon',
    );

    test('prerequisite_check flags missing prerequisite', () {
      final event = PowerUsageEvent.validated(
        id: 'use-1',
        abilityId: 'fly',
        actorId: 'qowner',
        sceneId: 'scene-1',
        tick: 0,
        resourceChanges: const [],
        consequences: const [],
        source: source,
      );
      final detector = PowerRuleViolationDetector(rulebook: rulebook);
      final report = detector.detect(event, satisfiedPrerequisites: const []);
      expect(
        report.violations.map((v) => v.kind),
        contains(PowerViolationKind.missingPrerequisite),
      );
      final prereq = report.violations
          .where((v) => v.kind == PowerViolationKind.missingPrerequisite)
          .single;
      expect(prereq.abilityId, 'fly');
      expect(prereq.prerequisiteId, 'legs');
      expect(prereq.explanation, isNotEmpty);
    });

    test('cost_check flags insufficient resource change', () {
      final event = PowerUsageEvent.validated(
        id: 'use-2',
        abilityId: 'fly',
        actorId: 'qowner',
        sceneId: 'scene-1',
        tick: 1,
        resourceChanges: [
          PowerResourceChange.validated(
            resource: 'mana',
            amount: -2,
            reason: 'channeling',
          ),
        ],
        consequences: const [],
        source: source,
      );
      final detector = PowerRuleViolationDetector(rulebook: rulebook);
      final report = detector.detect(event, satisfiedPrerequisites: ['legs']);
      expect(
        report.violations.map((v) => v.kind),
        contains(PowerViolationKind.insufficientCost),
      );
      final cost = report.violations
          .where((v) => v.kind == PowerViolationKind.insufficientCost)
          .single;
      expect(cost.abilityId, 'fly');
      expect(cost.resource, 'mana');
      expect(cost.expectedAmount, 5);
      expect(cost.actualAmount, -2);
      expect(cost.explanation, isNotEmpty);
    });

    test('cooldown_check flags usage before cooldown elapsed', () {
      final detector = PowerRuleViolationDetector(rulebook: rulebook);
      final first = PowerUsageEvent.validated(
        id: 'use-3',
        abilityId: 'fly',
        actorId: 'qowner',
        sceneId: 'scene-1',
        tick: 10,
        resourceChanges: [
          PowerResourceChange.validated(
            resource: 'mana',
            amount: -5,
            reason: 'channeling',
          ),
        ],
        consequences: const [],
        source: source,
      );
      final second = PowerUsageEvent.validated(
        id: 'use-4',
        abilityId: 'fly',
        actorId: 'qowner',
        sceneId: 'scene-1',
        tick: 11,
        resourceChanges: [
          PowerResourceChange.validated(
            resource: 'mana',
            amount: -5,
            reason: 'channeling',
          ),
        ],
        consequences: const [],
        source: source,
      );
      final report = detector.detectCooldown(
        candidate: second,
        previous: first,
        cooldownTicks: 5,
      );
      expect(
        report.violations.map((v) => v.kind),
        contains(PowerViolationKind.cooldownNotElapsed),
      );
      final cd = report.violations
          .where((v) => v.kind == PowerViolationKind.cooldownNotElapsed)
          .single;
      expect(cd.abilityId, 'fly');
      expect(cd.elapsedTicks, 1);
      expect(cd.requiredTicks, 5);
    });

    test('capability_check flags event referencing unknown ability', () {
      final event = PowerUsageEvent.validated(
        id: 'use-5',
        abilityId: 'unknown',
        actorId: 'qowner',
        sceneId: 'scene-1',
        tick: 0,
        resourceChanges: const [],
        consequences: const [],
        source: source,
      );
      final detector = PowerRuleViolationDetector(rulebook: rulebook);
      final report = detector.detect(event, satisfiedPrerequisites: const []);
      expect(
        report.violations.map((v) => v.kind),
        contains(PowerViolationKind.unknownAbility),
      );
      final cap = report.violations
          .where((v) => v.kind == PowerViolationKind.unknownAbility)
          .single;
      expect(cap.abilityId, 'unknown');
    });

    test('explain_violation reports deterministic ordered explanation', () {
      final event = PowerUsageEvent.validated(
        id: 'use-6',
        abilityId: 'fly',
        actorId: 'qowner',
        sceneId: 'scene-1',
        tick: 0,
        resourceChanges: const [],
        consequences: const [],
        source: source,
      );
      final detector = PowerRuleViolationDetector(rulebook: rulebook);
      final report = detector.detect(event, satisfiedPrerequisites: const []);
      final note = report.explain();
      expect(note, contains('fly'));
      expect(note, contains('legs'));
      expect(note, isNotEmpty);
      expect(report.isClean, isFalse);
    });
  });
}
