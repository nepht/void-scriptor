// Sprint 111.13 - Alchemy Consistency Validation.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_alchemy.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_alchemy_validation.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_effect.dart";

AlchemyRecipe _recipeWithIngredient(String ingredientId) {
  return AlchemyRecipe.validated(
    recipeId: "r1",
    name: "Dream Brew",
    ingredients: [
      RecipeIngredient.validated(
        ingredientId: ingredientId,
        quantity: 2,
        unit: "grams",
      ),
    ],
  );
}

void main() {
  group("AlchemyValidationKind", () {
    test("has four kinds with labels", () {
      expect(AlchemyValidationKind.values.length, 4);
      for (final k in AlchemyValidationKind.values) {
        expect(k.label, isNotEmpty);
      }
    });
  });

  group("AlchemyValidationIssue", () {
    test("rejects empty issue id", () {
      expect(
        () => AlchemyValidationIssue.validated(
          issueId: " ",
          recipeId: "r1",
          kind: AlchemyValidationKind.missingIngredient,
          message: "Missing",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty recipe id", () {
      expect(
        () => AlchemyValidationIssue.validated(
          issueId: "i1",
          recipeId: "",
          kind: AlchemyValidationKind.missingIngredient,
          message: "Missing",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty message", () {
      expect(
        () => AlchemyValidationIssue.validated(
          issueId: "i1",
          recipeId: "r1",
          kind: AlchemyValidationKind.missingIngredient,
          message: " ",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty ingredient id when provided", () {
      expect(
        () => AlchemyValidationIssue.validated(
          issueId: "i1",
          recipeId: "r1",
          kind: AlchemyValidationKind.missingIngredient,
          message: "Missing",
          ingredientId: " ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps issue fields", () {
      final i = AlchemyValidationIssue.validated(
        issueId: "i1",
        recipeId: "r1",
        kind: AlchemyValidationKind.effectConflict,
        message: "Toxic ingredient",
        ingredientId: "vb",
      );
      expect(i.issueId, "i1");
      expect(i.recipeId, "r1");
      expect(i.kind, AlchemyValidationKind.effectConflict);
      expect(i.message, "Toxic ingredient");
      expect(i.ingredientId, "vb");
    });
    test("accepts issue without ingredient id", () {
      final i = AlchemyValidationIssue.validated(
        issueId: "i1",
        recipeId: "r1",
        kind: AlchemyValidationKind.preparationConflict,
        message: "Condition mismatch",
      );
      expect(i.ingredientId, isNull);
    });
  });

  group("ManualException", () {
    test("rejects empty exception id", () {
      expect(
        () => ManualException.validated(
          exceptionId: " ",
          recipeId: "r1",
          kind: AlchemyValidationKind.missingIngredient,
          reason: "Deliberate",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty recipe id", () {
      expect(
        () => ManualException.validated(
          exceptionId: "e1",
          recipeId: "",
          kind: AlchemyValidationKind.missingIngredient,
          reason: "Deliberate",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty reason", () {
      expect(
        () => ManualException.validated(
          exceptionId: "e1",
          recipeId: "r1",
          kind: AlchemyValidationKind.missingIngredient,
          reason: " ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps exception fields", () {
      final e = ManualException.validated(
        exceptionId: "e1",
        recipeId: "r1",
        kind: AlchemyValidationKind.missingIngredient,
        reason: "Deliberate ritual omission",
      );
      expect(e.exceptionId, "e1");
      expect(e.recipeId, "r1");
      expect(e.kind, AlchemyValidationKind.missingIngredient);
      expect(e.reason, "Deliberate ritual omission");
    });
  });

  group("missing ingredient detection", () {
    test("flags an ingredient not in available set", () {
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb"),
        availableIngredients: const {"sage"},
      );
      expect(report.hasIssues, isTrue);
      expect(
        report.issuesOf(AlchemyValidationKind.missingIngredient),
        hasLength(1),
      );
    });
    test("accepts an available ingredient", () {
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb"),
        availableIngredients: const {"vb"},
      );
      expect(report.hasIssues, isFalse);
    });
    test("accepts a registered substitute ingredient", () {
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb_alt"),
        availableIngredients: const {"sage"},
        allowedSubstitutions: const {
          "vb": {"vb_alt"},
        },
      );
      expect(report.issuesOf(AlchemyValidationKind.missingIngredient), isEmpty);
    });
  });

  group("invalid substitution detection", () {
    test("flags a declared substitution that is not registered", () {
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb_alt"),
        availableIngredients: const {"sage"},
        allowedSubstitutions: const {
          "vb": {"vb_alt2"},
        },
        declaredSubstitutions: const {"vb_alt"},
      );
      expect(
        report.issuesOf(AlchemyValidationKind.invalidSubstitution),
        hasLength(1),
      );
    });
    test("accepts a declared substitution that is registered", () {
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb_alt"),
        availableIngredients: const {"sage"},
        allowedSubstitutions: const {
          "vb": {"vb_alt"},
        },
        declaredSubstitutions: const {"vb_alt"},
      );
      expect(
        report.issuesOf(AlchemyValidationKind.invalidSubstitution),
        isEmpty,
      );
      expect(report.hasIssues, isFalse);
    });
  });

  group("effect conflict detection", () {
    test("flags an ingredient with a forbidden effect kind", () {
      final cat = EffectCatalog.withRecords([
        EffectRecord.validated(
          ingredientId: "vb",
          effects: [
            EffectEntry.validated(
              effectId: "pain",
              description: "Deadens pain",
              kind: EffectKind.harmful,
            ),
          ],
        ),
      ]);
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb"),
        availableIngredients: const {"vb"},
        effectCatalog: cat,
        forbiddenEffectKinds: const {EffectKind.harmful},
      );
      expect(
        report.issuesOf(AlchemyValidationKind.effectConflict),
        hasLength(1),
      );
    });
    test("accepts an ingredient without forbidden effects", () {
      final cat = EffectCatalog.withRecords([
        EffectRecord.validated(
          ingredientId: "vb",
          effects: [
            EffectEntry.validated(
              effectId: "calm",
              description: "Calms nerves",
              kind: EffectKind.restorative,
            ),
          ],
        ),
      ]);
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb"),
        availableIngredients: const {"vb"},
        effectCatalog: cat,
        forbiddenEffectKinds: const {EffectKind.harmful},
      );
      expect(report.issuesOf(AlchemyValidationKind.effectConflict), isEmpty);
    });
  });

  group("preparation conflict detection", () {
    test("flags a step condition not declared in recipe conditions", () {
      final recipe = AlchemyRecipe.validated(
        recipeId: "r1",
        name: "Dream Brew",
        ingredients: [
          RecipeIngredient.validated(
            ingredientId: "vb",
            quantity: 2,
            unit: "grams",
          ),
        ],
        conditions: [
          RecipeCondition.validated(
            conditionId: "daylight",
            description: "Daylight",
          ),
        ],
        orderedSteps: [
          RecipeStep.validated(
            stepNumber: 1,
            instruction: "Boil",
            condition: "full_moon",
          ),
        ],
      );
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: recipe,
        availableIngredients: const {"vb"},
      );
      expect(
        report.issuesOf(AlchemyValidationKind.preparationConflict),
        hasLength(1),
      );
    });
    test("accepts a step condition declared in recipe conditions", () {
      final recipe = AlchemyRecipe.validated(
        recipeId: "r1",
        name: "Dream Brew",
        ingredients: [
          RecipeIngredient.validated(
            ingredientId: "vb",
            quantity: 2,
            unit: "grams",
          ),
        ],
        conditions: [
          RecipeCondition.validated(
            conditionId: "full_moon",
            description: "Full moon",
          ),
        ],
        orderedSteps: [
          RecipeStep.validated(
            stepNumber: 1,
            instruction: "Boil",
            condition: "full_moon",
          ),
        ],
      );
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: recipe,
        availableIngredients: const {"vb"},
      );
      expect(
        report.issuesOf(AlchemyValidationKind.preparationConflict),
        isEmpty,
      );
      expect(report.hasIssues, isFalse);
    });
  });

  group("required effect detection", () {
    test("flags when no ingredient provides a required effect kind", () {
      final cat = EffectCatalog.withRecords([
        EffectRecord.validated(
          ingredientId: "vb",
          effects: [
            EffectEntry.validated(
              effectId: "calm",
              description: "Calms nerves",
              kind: EffectKind.restorative,
            ),
          ],
        ),
      ]);
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb"),
        availableIngredients: const {"vb"},
        effectCatalog: cat,
        requiredEffectKinds: const {EffectKind.harmful},
      );
      expect(
        report.issuesOf(AlchemyValidationKind.effectConflict),
        hasLength(1),
      );
    });
    test("accepts when an ingredient provides a required effect kind", () {
      final cat = EffectCatalog.withRecords([
        EffectRecord.validated(
          ingredientId: "vb",
          effects: [
            EffectEntry.validated(
              effectId: "pain",
              description: "Deadens pain",
              kind: EffectKind.harmful,
            ),
          ],
        ),
      ]);
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb"),
        availableIngredients: const {"vb"},
        effectCatalog: cat,
        requiredEffectKinds: const {EffectKind.harmful},
      );
      expect(report.issuesOf(AlchemyValidationKind.effectConflict), isEmpty);
    });
  });

  group("validation report describe", () {
    test("describe returns non-empty explanation", () {
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb"),
        availableIngredients: const {"sage"},
      );
      expect(report.describe(), isNotEmpty);
    });
    test("accepts manual exception that suppresses an issue", () {
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb"),
        availableIngredients: const {"sage"},
        exceptions: [
          ManualException.validated(
            exceptionId: "e1",
            recipeId: "r1",
            kind: AlchemyValidationKind.missingIngredient,
            reason: "Deliberate ritual omission",
          ),
        ],
      );
      expect(report.hasIssues, isFalse);
    });
    test("manual exception must match recipe id to suppress", () {
      const v = AlchemyConsistencyValidator();
      final report = v.validate(
        recipe: _recipeWithIngredient("vb"),
        availableIngredients: const {"sage"},
        exceptions: [
          ManualException.validated(
            exceptionId: "e1",
            recipeId: "other_recipe",
            kind: AlchemyValidationKind.missingIngredient,
            reason: "Wrong recipe",
          ),
        ],
      );
      expect(report.hasIssues, isTrue);
    });
  });
}
