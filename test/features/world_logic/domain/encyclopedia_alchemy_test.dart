// Sprint 111.12 - Alchemy Recipe and Preparation Registry.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_alchemy.dart";

void main() {
  group("RecipeIngredient", () {
    test("rejects empty ingredient id", () {
      expect(
        () => RecipeIngredient.validated(
          ingredientId: "  ",
          quantity: 2,
          unit: "grams",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty unit", () {
      expect(
        () => RecipeIngredient.validated(
          ingredientId: "vb",
          quantity: 2,
          unit: " ",
        ),
        throwsArgumentError,
      );
    });
    test("rejects non-positive quantity", () {
      expect(
        () => RecipeIngredient.validated(
          ingredientId: "vb",
          quantity: 0,
          unit: "grams",
        ),
        throwsArgumentError,
      );
    });
    test("keeps ingredient fields", () {
      final i = RecipeIngredient.validated(
        ingredientId: "vb",
        quantity: 2.5,
        unit: "grams",
        note: "Sun-dried",
      );
      expect(i.ingredientId, "vb");
      expect(i.quantity, 2.5);
      expect(i.unit, "grams");
      expect(i.note, "Sun-dried");
    });
    test("accepts ingredient without note", () {
      final i = RecipeIngredient.validated(
        ingredientId: "vb",
        quantity: 1,
        unit: "cup",
      );
      expect(i.note, isNull);
    });
  });

  group("AlchemyTool", () {
    test("rejects empty tool id", () {
      expect(() => AlchemyTool.validated(toolId: " "), throwsArgumentError);
    });
    test("rejects empty note when provided", () {
      expect(
        () => AlchemyTool.validated(toolId: "cauldron", note: " "),
        throwsArgumentError,
      );
    });
    test("keeps tool id with optional note", () {
      final t = AlchemyTool.validated(
        toolId: "cauldron",
        note: "Iron, at least 20L",
      );
      expect(t.toolId, "cauldron");
      expect(t.note, "Iron, at least 20L");
    });
    test("accepts tool without note", () {
      final t = AlchemyTool.validated(toolId: "cauldron");
      expect(t.note, isNull);
    });
  });

  group("RecipeStep", () {
    test("rejects empty instruction", () {
      expect(
        () => RecipeStep.validated(stepNumber: 1, instruction: " "),
        throwsArgumentError,
      );
    });
    test("rejects duplicate step numbers", () {
      expect(
        () => RecipeStep.validated(stepNumber: 1, instruction: "A"),
        returnsNormally,
      );
      expect(
        () => AlchemyRecipe.validated(
          recipeId: "r1",
          name: "Dream Brew",
          orderedSteps: [
            RecipeStep.validated(stepNumber: 1, instruction: "A"),
            RecipeStep.validated(stepNumber: 1, instruction: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("keeps step fields", () {
      final s = RecipeStep.validated(
        stepNumber: 2,
        instruction: "Stir widdershins",
        condition: "Under full moon",
      );
      expect(s.stepNumber, 2);
      expect(s.instruction, "Stir widdershins");
      expect(s.condition, "Under full moon");
    });
    test("accepts step without condition", () {
      final s = RecipeStep.validated(stepNumber: 3, instruction: "Cool");
      expect(s.condition, isNull);
    });
  });

  group("RecipeCondition", () {
    test("rejects empty condition id", () {
      expect(
        () => RecipeCondition.validated(conditionId: " ", description: "Moon"),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => RecipeCondition.validated(conditionId: "c1", description: ""),
        throwsArgumentError,
      );
    });
    test("keeps condition fields", () {
      final c = RecipeCondition.validated(
        conditionId: "full_moon",
        description: "Must be brewed under a full moon",
      );
      expect(c.conditionId, "full_moon");
      expect(c.description, "Must be brewed under a full moon");
    });
  });

  group("RecipeFailureMode", () {
    test("rejects empty failure id", () {
      expect(
        () => RecipeFailureMode.validated(failureId: " ", description: "A"),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => RecipeFailureMode.validated(failureId: "f1", description: " "),
        throwsArgumentError,
      );
    });
    test("rejects empty consequence when provided", () {
      expect(
        () => RecipeFailureMode.validated(
          failureId: "f1",
          description: "Overheats",
          consequence: " ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps failure fields", () {
      final f = RecipeFailureMode.validated(
        failureId: "overheat",
        description: "Mixture boils over",
        consequence: "Cauldron cracks",
      );
      expect(f.failureId, "overheat");
      expect(f.description, "Mixture boils over");
      expect(f.consequence, "Cauldron cracks");
    });
    test("accepts failure without consequence", () {
      final f = RecipeFailureMode.validated(failureId: "f1", description: "A");
      expect(f.consequence, isNull);
    });
  });

  group("RecipeSideEffect", () {
    test("rejects empty side effect id", () {
      expect(
        () => RecipeSideEffect.validated(sideEffectId: " ", description: "A"),
        throwsArgumentError,
      );
    });
    test("rejects empty description", () {
      expect(
        () => RecipeSideEffect.validated(sideEffectId: "s1", description: ""),
        throwsArgumentError,
      );
    });
    test("rejects severity out of 1..5", () {
      expect(
        () => RecipeSideEffect.validated(
          sideEffectId: "s1",
          description: "A",
          severity: 6,
        ),
        throwsArgumentError,
      );
    });
    test("keeps side effect fields", () {
      final s = RecipeSideEffect.validated(
        sideEffectId: "drowsy",
        description: "Drinker drowsy",
        severity: 3,
      );
      expect(s.sideEffectId, "drowsy");
      expect(s.description, "Drinker drowsy");
      expect(s.severity, 3);
    });
    test("accepts side effect without severity", () {
      final s = RecipeSideEffect.validated(
        sideEffectId: "s1",
        description: "A",
      );
      expect(s.severity, isNull);
    });
  });
  group("AlchemyRecipe validated", () {
    test("rejects empty recipe id", () {
      expect(
        () => AlchemyRecipe.validated(recipeId: " ", name: "Dream Brew"),
        throwsArgumentError,
      );
    });
    test("rejects empty name", () {
      expect(
        () => AlchemyRecipe.validated(recipeId: "r1", name: ""),
        throwsArgumentError,
      );
    });
    test("stores basic fields with empty collections", () {
      final r = AlchemyRecipe.validated(recipeId: "r1", name: "Dream Brew");
      expect(r.recipeId, "r1");
      expect(r.name, "Dream Brew");
      expect(r.ingredients, isEmpty);
      expect(r.tools, isEmpty);
      expect(r.orderedSteps, isEmpty);
      expect(r.conditions, isEmpty);
      expect(r.failureModes, isEmpty);
      expect(r.sideEffects, isEmpty);
      expect(r.result, isNull);
      expect(r.notes, isNull);
    });
    test("stores a complete recipe", () {
      final r = AlchemyRecipe.validated(
        recipeId: "r1",
        name: "Dream Brew",
        ingredients: [
          RecipeIngredient.validated(
            ingredientId: "vb",
            quantity: 2,
            unit: "grams",
          ),
        ],
        tools: [AlchemyTool.validated(toolId: "cauldron")],
        orderedSteps: [
          RecipeStep.validated(stepNumber: 1, instruction: "Boil"),
        ],
        conditions: [
          RecipeCondition.validated(
            conditionId: "full_moon",
            description: "Full moon",
          ),
        ],
        failureModes: [
          RecipeFailureMode.validated(
            failureId: "overheat",
            description: "Overheats",
          ),
        ],
        sideEffects: [
          RecipeSideEffect.validated(
            sideEffectId: "drowsy",
            description: "Drowsy",
          ),
        ],
        result: "Silver liquid",
        notes: "Best at midnight",
      );
      expect(r.ingredients, hasLength(1));
      expect(r.tools, hasLength(1));
      expect(r.orderedSteps, hasLength(1));
      expect(r.conditions, hasLength(1));
      expect(r.failureModes, hasLength(1));
      expect(r.sideEffects, hasLength(1));
      expect(r.result, "Silver liquid");
      expect(r.notes, "Best at midnight");
    });
  });

  group("AlchemyRecipe duplicate guards", () {
    test("rejects duplicate ingredient ids", () {
      expect(
        () => AlchemyRecipe.validated(
          recipeId: "r1",
          name: "Dream Brew",
          ingredients: [
            RecipeIngredient.validated(
              ingredientId: "vb",
              quantity: 1,
              unit: "g",
            ),
            RecipeIngredient.validated(
              ingredientId: "vb",
              quantity: 2,
              unit: "g",
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate tool ids", () {
      expect(
        () => AlchemyRecipe.validated(
          recipeId: "r1",
          name: "Dream Brew",
          tools: [
            AlchemyTool.validated(toolId: "cauldron"),
            AlchemyTool.validated(toolId: "cauldron"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate step numbers", () {
      expect(
        () => AlchemyRecipe.validated(
          recipeId: "r1",
          name: "Dream Brew",
          orderedSteps: [
            RecipeStep.validated(stepNumber: 1, instruction: "A"),
            RecipeStep.validated(stepNumber: 1, instruction: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate condition ids", () {
      expect(
        () => AlchemyRecipe.validated(
          recipeId: "r1",
          name: "Dream Brew",
          conditions: [
            RecipeCondition.validated(conditionId: "c1", description: "A"),
            RecipeCondition.validated(conditionId: "c1", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate failure ids", () {
      expect(
        () => AlchemyRecipe.validated(
          recipeId: "r1",
          name: "Dream Brew",
          failureModes: [
            RecipeFailureMode.validated(failureId: "f1", description: "A"),
            RecipeFailureMode.validated(failureId: "f1", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
    test("rejects duplicate side effect ids", () {
      expect(
        () => AlchemyRecipe.validated(
          recipeId: "r1",
          name: "Dream Brew",
          sideEffects: [
            RecipeSideEffect.validated(sideEffectId: "s1", description: "A"),
            RecipeSideEffect.validated(sideEffectId: "s1", description: "B"),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group("AlchemyRecipe behavior", () {
    test("requiresIngredient detects membership", () {
      final r = AlchemyRecipe.validated(
        recipeId: "r1",
        name: "Dream Brew",
        ingredients: [
          RecipeIngredient.validated(
            ingredientId: "vb",
            quantity: 2,
            unit: "grams",
          ),
        ],
      );
      expect(r.requiresIngredient("vb"), isTrue);
      expect(r.requiresIngredient("zz"), isFalse);
    });
    test("requiresTool detects membership", () {
      final r = AlchemyRecipe.validated(
        recipeId: "r1",
        name: "Dream Brew",
        tools: [AlchemyTool.validated(toolId: "cauldron")],
      );
      expect(r.requiresTool("cauldron"), isTrue);
      expect(r.requiresTool("mortar"), isFalse);
    });
    test("hasCondition detects membership", () {
      final r = AlchemyRecipe.validated(
        recipeId: "r1",
        name: "Dream Brew",
        conditions: [
          RecipeCondition.validated(
            conditionId: "full_moon",
            description: "Full moon",
          ),
        ],
      );
      expect(r.hasCondition("full_moon"), isTrue);
      expect(r.hasCondition("daylight"), isFalse);
    });
    test("hasFailureMode detects membership", () {
      final r = AlchemyRecipe.validated(
        recipeId: "r1",
        name: "Dream Brew",
        failureModes: [
          RecipeFailureMode.validated(
            failureId: "overheat",
            description: "Overheats",
          ),
        ],
      );
      expect(r.hasFailureMode("overheat"), isTrue);
      expect(r.hasFailureMode("cold"), isFalse);
    });
    test("sortedSteps returns steps ordered by step number", () {
      final r = AlchemyRecipe.validated(
        recipeId: "r1",
        name: "Dream Brew",
        orderedSteps: [
          RecipeStep.validated(stepNumber: 3, instruction: "Cool"),
          RecipeStep.validated(stepNumber: 1, instruction: "Boil"),
          RecipeStep.validated(stepNumber: 2, instruction: "Stir"),
        ],
      );
      expect(r.sortedSteps.map((s) => s.stepNumber).toList(), [1, 2, 3]);
    });
  });

  group("AlchemyRecipeCatalog", () {
    test("empty catalog has no recipes", () {
      final c = AlchemyRecipeCatalog.empty();
      expect(c.length, 0);
      expect(c.recipeFor("r1"), isNull);
    });
    test("withRecipes guards duplicate recipe ids", () {
      final r = AlchemyRecipe.validated(recipeId: "r1", name: "Dream Brew");
      final c = AlchemyRecipeCatalog.withRecipes([r]);
      expect(c.length, 1);
      expect(c.recipeFor("r1"), same(r));
      expect(
        () => AlchemyRecipeCatalog.withRecipes([r, r]),
        throwsArgumentError,
      );
    });
    test("recipesByIngredient finds matching recipes", () {
      final withVb = AlchemyRecipe.validated(
        recipeId: "r1",
        name: "Dream Brew",
        ingredients: [
          RecipeIngredient.validated(
            ingredientId: "vb",
            quantity: 2,
            unit: "grams",
          ),
        ],
      );
      final withoutVb = AlchemyRecipe.validated(
        recipeId: "r2",
        name: "Plain Tonic",
      );
      final cat = AlchemyRecipeCatalog.withRecipes([withVb, withoutVb]);
      expect(cat.recipesByIngredient("vb").map((r) => r.recipeId).toList(), [
        "r1",
      ]);
      expect(cat.recipesByIngredient("zz"), isEmpty);
    });
    test("recipesByIngredient returns sorted by recipe id", () {
      final z = AlchemyRecipe.validated(
        recipeId: "z",
        name: "Z",
        ingredients: [
          RecipeIngredient.validated(
            ingredientId: "vb",
            quantity: 1,
            unit: "g",
          ),
        ],
      );
      final a = AlchemyRecipe.validated(
        recipeId: "a",
        name: "A",
        ingredients: [
          RecipeIngredient.validated(
            ingredientId: "vb",
            quantity: 1,
            unit: "g",
          ),
        ],
      );
      final cat = AlchemyRecipeCatalog.withRecipes([z, a]);
      expect(cat.recipesByIngredient("vb").map((r) => r.recipeId).toList(), [
        "a",
        "z",
      ]);
    });
  });
}
