import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_activation_rules.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_artifact.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_artifact_validation.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_ownership_lineage.dart';
import 'package:void_scriptor/features/world_logic/domain/power_rulebook.dart';
import 'package:void_scriptor/features/world_logic/domain/power_usage_ledger.dart';
import 'package:void_scriptor/features/world_logic/domain/power_systems_artifacts_consequences_integration.dart';

void main() {
  test('connects rules, activation, owner, costs, usage, and consequences', () {
    final ability = PowerAbility.validated(
      id: 'ember',
      name: 'Ember',
      costs: [PowerCost.validated(resource: 'mana', amount: 3, reason: 'cast')],
    );
    final powerEvent = PowerUsageEvent.validated(
      id: 'use-1',
      abilityId: 'ember',
      actorId: 'hero',
      sceneId: 'scene-1',
      tick: 4,
      resourceChanges: [
        PowerResourceChange.validated(
          resource: 'mana',
          amount: -3,
          reason: 'cast',
        ),
      ],
      consequences: [
        PowerConsequence.validated(description: 'hand burns', severity: 2),
      ],
      source: PowerUsageSource.validated(revision: 'rev-20', reason: 'fixture'),
    );
    final artifact = ArtifactRecord.validated(
      artifactId: 'torch',
      name: 'Torch',
      authenticity: ArtifactAuthenticity.authentic,
    );
    final rules = ArtifactRules.validated(
      artifactId: 'torch',
      abilities: [AbilityRule.validated(abilityId: 'ember', name: 'Ember')],
      costs: [
        CostEntry.validated(
          costId: 'mana-cost',
          resourceName: 'mana',
          amount: 3,
        ),
      ],
    );
    final usage = ArtifactUsageEvent.validated(
      usageId: 'use-1',
      artifactId: 'torch',
      actorId: 'hero',
      abilityId: 'ember',
      atTick: 4,
    );

    final result = const PowerSystemsArtifactsConsequencesIntegration()
        .evaluate(
          rulebook: PowerRulebook.validated(abilities: [ability]),
          artifact: artifact,
          artifactRules: rules,
          lineage: OwnershipLineageRecord.validated(
            artifactId: 'torch',
            periods: [
              OwnershipPeriod.validated(
                periodId: 'p-1',
                holderId: 'hero',
                holderName: 'Hero',
              ),
            ],
          ),
          usage: usage,
          powerEvent: powerEvent,
          satisfiedPrerequisites: const [],
        );

    expect(result.powerViolations.isClean, isTrue);
    expect(result.artifactValidation.hasIssues, isFalse);
    expect(result.usageLedger.events.single.id, 'use-1');
    expect(result.appliedCosts.single.resourceName, 'mana');
    expect(result.consequenceLinks.single, 'use-1:hand burns');
  });
}
