import 'encyclopedia_alchemy.dart';
import 'encyclopedia_creature.dart';
import 'encyclopedia_ecology.dart';
import 'encyclopedia_effect.dart';
import 'encyclopedia_harvest.dart';
import 'encyclopedia_harvestable_material.dart';
import 'encyclopedia_ingredient.dart';

/// Domain-only integration boundary for herbology, alchemy, bestiary, and
/// ecology records.
///
/// The evaluator deliberately reports relationship validity instead of
/// mutating any catalog. Persistence, UI, network, wall-clock, and randomness
/// remain outside this boundary.
class HerbologyAlchemyBestiaryEcologyIntegration {
  const HerbologyAlchemyBestiaryEcologyIntegration();

  HerbologyAlchemyBestiaryEcologyResult evaluate({
    required IngredientRecord ingredient,
    required HarvestRecord harvest,
    required AlchemyRecipe recipe,
    required CreatureSpecies species,
    required EcologyProfile ecology,
    required EffectRecord effects,
    required HarvestableMaterial material,
    required Season season,
  }) {
    if (harvest.ingredientId != ingredient.ingredientId) {
      throw ArgumentError('harvest ingredientId does not match ingredient');
    }
    if (effects.ingredientId != ingredient.ingredientId) {
      throw ArgumentError('effects ingredientId does not match ingredient');
    }
    if (material.sourceId != null &&
        material.sourceId != ingredient.ingredientId) {
      throw ArgumentError('material sourceId does not match ingredient');
    }
    if (ecology.speciesId != species.speciesId) {
      throw ArgumentError('ecology speciesId does not match species');
    }

    final habitatLinksResolved = harvest.habitats.any(
      (harvestHabitat) => ecology.inHabitat(harvestHabitat.habitatId),
    );
    final recipeEffectsResolved =
        recipe.requiresIngredient(ingredient.ingredientId) &&
        effects.effects.isNotEmpty;
    final ecologicalConsequences =
        material.sourceId == ingredient.ingredientId &&
        material.impacts.isNotEmpty;

    return HerbologyAlchemyBestiaryEcologyResult(
      ingredientSourcesResolved: ingredient.ingredientId.isNotEmpty,
      harvestMaterialsResolved: material.sourceId == ingredient.ingredientId,
      habitatLinksResolved: habitatLinksResolved,
      seasonalAvailability: harvest.isHarvestableInSeason(season),
      recipeEffectsResolved: recipeEffectsResolved,
      ecologicalConsequences: ecologicalConsequences,
    );
  }
}

class HerbologyAlchemyBestiaryEcologyResult {
  const HerbologyAlchemyBestiaryEcologyResult({
    required this.ingredientSourcesResolved,
    required this.harvestMaterialsResolved,
    required this.habitatLinksResolved,
    required this.seasonalAvailability,
    required this.recipeEffectsResolved,
    required this.ecologicalConsequences,
  });

  final bool ingredientSourcesResolved;
  final bool harvestMaterialsResolved;
  final bool habitatLinksResolved;
  final bool seasonalAvailability;
  final bool recipeEffectsResolved;
  final bool ecologicalConsequences;
}
