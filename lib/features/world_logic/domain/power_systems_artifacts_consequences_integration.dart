import 'encyclopedia_activation_rules.dart';
import 'encyclopedia_artifact.dart';
import 'encyclopedia_artifact_validation.dart';
import 'encyclopedia_ownership_lineage.dart';
import 'power_rule_violation_detector.dart';
import 'power_rulebook.dart';
import 'power_usage_ledger.dart';

/// Domain-only integration boundary for power use and artifact consequences.
///
/// It composes existing rule, artifact, ownership, and usage contracts without
/// persistence, UI, wall-clock, randomness, or network dependencies.
class PowerSystemsArtifactsConsequencesIntegration {
  const PowerSystemsArtifactsConsequencesIntegration();

  PowerSystemsArtifactsConsequencesResult evaluate({
    required PowerRulebook rulebook,
    required ArtifactRecord artifact,
    required ArtifactRules artifactRules,
    required OwnershipLineageRecord? lineage,
    required ArtifactUsageEvent usage,
    required PowerUsageEvent powerEvent,
    required List<String> satisfiedPrerequisites,
  }) {
    if (powerEvent.abilityId != usage.abilityId) {
      throw ArgumentError('power event and artifact usage ability ids differ');
    }
    if (powerEvent.tick != usage.atTick) {
      throw ArgumentError('power event and artifact usage ticks differ');
    }

    final powerViolations = PowerRuleViolationDetector(
      rulebook: rulebook,
    ).detect(powerEvent, satisfiedPrerequisites: satisfiedPrerequisites);
    final artifactValidation = const ArtifactUsageValidator().validate(
      artifact: artifact,
      lineage: lineage,
      usage: usage,
      rules: artifactRules,
    );
    final ledger = PowerUsageLedger.validated(events: [powerEvent]);
    final ability = rulebook.abilityById(powerEvent.abilityId);
    final appliedCosts = ability == null
        ? const <CostEntry>[]
        : artifactRules.costs
              .where(
                (cost) =>
                    cost.resourceLabel == _changedResource(powerEvent, cost),
              )
              .toList(growable: false);
    final consequenceLinks = powerEvent.consequences
        .map((consequence) => '${powerEvent.id}:${consequence.description}')
        .toList(growable: false);

    return PowerSystemsArtifactsConsequencesResult(
      powerViolations: powerViolations,
      artifactValidation: artifactValidation,
      usageLedger: ledger,
      appliedCosts: List.unmodifiable(appliedCosts),
      consequenceLinks: List.unmodifiable(consequenceLinks),
    );
  }

  String? _changedResource(PowerUsageEvent event, CostEntry cost) {
    for (final change in event.resourceChanges) {
      if (change.resource.toLowerCase() == cost.resourceLabel.toLowerCase() &&
          change.amount < 0) {
        return change.resource;
      }
    }
    return null;
  }
}

class PowerSystemsArtifactsConsequencesResult {
  const PowerSystemsArtifactsConsequencesResult({
    required this.powerViolations,
    required this.artifactValidation,
    required this.usageLedger,
    required this.appliedCosts,
    required this.consequenceLinks,
  });

  final PowerViolationReport powerViolations;
  final ArtifactValidationReport artifactValidation;
  final PowerUsageLedger usageLedger;
  final List<CostEntry> appliedCosts;
  final List<String> consequenceLinks;
}
