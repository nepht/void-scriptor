import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_alchemy.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_creature.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_ecology.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_effect.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_harvest.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_harvestable_material.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_ingredient.dart';
import 'package:void_scriptor/features/world_logic/domain/herbology_alchemy_bestiary_ecology_integration.dart';

void main() {
  test('connects sources, harvest, habitat, season, effects, and ecology', () {
    final ingredient = IngredientRecord.validated(
      ingredientId: 'moonleaf',
      name: 'Moonleaf',
      type: IngredientType.flora,
    );
    final harvest = HarvestRecord.validated(
      ingredientId: 'moonleaf',
      rarity: RarityLevel.rare,
      habitats: [HabitatRef.validated(habitatId: 'marsh')],
      seasonality: [SeasonWindow.validated(season: Season.summer)],
    );
    final recipe = AlchemyRecipe.validated(
      recipeId: 'tonic',
      name: 'Night Tonic',
      ingredients: [
        RecipeIngredient.validated(
          ingredientId: 'moonleaf',
          quantity: 1,
          unit: 'leaf',
        ),
      ],
    );
    final species = CreatureSpecies.validated(
      speciesId: 'marsh-stag',
      name: 'Marsh Stag',
      classification: CreatureClassification.animal,
    );
    final ecology = EcologyProfile.validated(
      speciesId: 'marsh-stag',
      habitats: [
        EcologyHabitat.validated(
          habitatId: 'marsh',
          description: 'A flooded reed basin',
        ),
      ],
    );
    final effects = EffectRecord.validated(
      ingredientId: 'moonleaf',
      effects: [
        EffectEntry.validated(
          effectId: 'calm',
          description: 'Calms the drinker',
          kind: EffectKind.restorative,
        ),
      ],
    );
    final material = HarvestableMaterial.validated(
      materialId: 'moonleaf-fiber',
      name: 'Moonleaf Fiber',
      sourceId: 'moonleaf',
      impacts: [
        EcologicalImpact.validated(
          impactId: 'overharvest',
          description: 'Marsh regrowth slows',
          severity: EcologicalImpactSeverity.moderate,
        ),
      ],
    );

    final result = const HerbologyAlchemyBestiaryEcologyIntegration().evaluate(
      ingredient: ingredient,
      harvest: harvest,
      recipe: recipe,
      species: species,
      ecology: ecology,
      effects: effects,
      material: material,
      season: Season.summer,
    );

    expect(result.ingredientSourcesResolved, isTrue);
    expect(result.harvestMaterialsResolved, isTrue);
    expect(result.habitatLinksResolved, isTrue);
    expect(result.seasonalAvailability, isTrue);
    expect(result.recipeEffectsResolved, isTrue);
    expect(result.ecologicalConsequences, isTrue);
  });
}
