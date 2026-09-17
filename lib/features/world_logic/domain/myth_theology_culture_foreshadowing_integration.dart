/// Sprint 112.22 domain integration for myth, theology, culture, and clues.
///
/// This boundary composes existing domain records without persistence, UI,
/// network, wall-clock, or random input. It reports whether the six canonical
/// relationships can be resolved from the supplied records.
library;

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_belief_truth.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_usage.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_reveal_links.dart';

class MythTheologyCultureForeshadowingResult {
  const MythTheologyCultureForeshadowingResult({
    required this.beliefVariantsResolved,
    required this.historicalTruthResolved,
    required this.cultureLinksResolved,
    required this.symbolLinksResolved,
    required this.idiomContextResolved,
    required this.revealIntegrity,
  });

  final bool beliefVariantsResolved;
  final bool historicalTruthResolved;
  final bool cultureLinksResolved;
  final bool symbolLinksResolved;
  final bool idiomContextResolved;
  final bool revealIntegrity;

  bool get isValid =>
      beliefVariantsResolved &&
      historicalTruthResolved &&
      cultureLinksResolved &&
      symbolLinksResolved &&
      idiomContextResolved &&
      revealIntegrity;
}

class MythTheologyCultureForeshadowingIntegration {
  const MythTheologyCultureForeshadowingIntegration();

  MythTheologyCultureForeshadowingResult evaluate({
    required BeliefTruthRecord belief,
    required IdiomUsageProfile idiom,
    required RevealLinkRecord reveals,
  }) {
    final truthIds = belief.truthIds.toSet();
    final clueTargetsAreKnown = reveals.clueLinks.every(
      (clue) =>
          clue.targetFactId == null || truthIds.contains(clue.targetFactId),
    );
    final revealLinksArePresent = reveals.revealCount > 0;
    final symbolsAreLinked = reveals.symbols.any(
      (symbol) => symbol.appearances.isNotEmpty,
    );

    return MythTheologyCultureForeshadowingResult(
      beliefVariantsResolved: belief.groupVariants.isNotEmpty,
      historicalTruthResolved: belief.truths.isNotEmpty,
      cultureLinksResolved: idiom.cultures.isNotEmpty,
      symbolLinksResolved: symbolsAreLinked,
      idiomContextResolved: idiom.contexts.isNotEmpty,
      revealIntegrity: clueTargetsAreKnown && revealLinksArePresent,
    );
  }
}
