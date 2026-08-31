// Sprint 111.12 - Alchemy Recipe and Preparation Registry.
//
// Domain-only contract for alchemy recipes: ingredients with quantities,
// tools, ordered preparation steps, required conditions, failure modes,
// and side effects. Includes a deterministic catalog query by ingredient.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

/// An ingredient used in a recipe with its quantity and unit.
class RecipeIngredient {
  const RecipeIngredient._({
    required this.ingredientId,
    required this.quantity,
    required this.unit,
    this.note,
  });

  factory RecipeIngredient.validated({
    required String ingredientId,
    required double quantity,
    required String unit,
    String? note,
  }) {
    if (quantity <= 0) {
      throw ArgumentError('quantity must be positive');
    }
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isEmpty) {
      throw ArgumentError('note must be non-empty when provided');
    }
    return RecipeIngredient._(
      ingredientId: _requireTrimmed(ingredientId, 'ingredientId'),
      quantity: quantity,
      unit: _requireTrimmed(unit, 'unit'),
      note: trimmedNote,
    );
  }

  final String ingredientId;
  final double quantity;
  final String unit;
  final String? note;
}

/// A tool used during preparation, with an optional note.
class AlchemyTool {
  const AlchemyTool._({required this.toolId, this.note});

  factory AlchemyTool.validated({required String toolId, String? note}) {
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isEmpty) {
      throw ArgumentError('note must be non-empty when provided');
    }
    return AlchemyTool._(
      toolId: _requireTrimmed(toolId, 'toolId'),
      note: trimmedNote,
    );
  }

  final String toolId;
  final String? note;
}

/// An ordered preparation step with an optional required condition.
class RecipeStep {
  const RecipeStep._({
    required this.stepNumber,
    required this.instruction,
    this.condition,
  });

  factory RecipeStep.validated({
    required int stepNumber,
    required String instruction,
    String? condition,
  }) {
    if (stepNumber <= 0) {
      throw ArgumentError('stepNumber must be positive');
    }
    final trimmedCondition = condition?.trim();
    if (trimmedCondition != null && trimmedCondition.isEmpty) {
      throw ArgumentError('condition must be non-empty when provided');
    }
    return RecipeStep._(
      stepNumber: stepNumber,
      instruction: _requireTrimmed(instruction, 'instruction'),
      condition: trimmedCondition,
    );
  }

  final int stepNumber;
  final String instruction;
  final String? condition;
}

/// A condition that must hold for a recipe or step to work.
class RecipeCondition {
  const RecipeCondition._({
    required this.conditionId,
    required this.description,
  });

  factory RecipeCondition.validated({
    required String conditionId,
    required String description,
  }) {
    return RecipeCondition._(
      conditionId: _requireTrimmed(conditionId, 'conditionId'),
      description: _requireTrimmed(description, 'description'),
    );
  }

  final String conditionId;
  final String description;
}

/// A documented way a recipe can fail, with an optional consequence.
class RecipeFailureMode {
  const RecipeFailureMode._({
    required this.failureId,
    required this.description,
    this.consequence,
  });

  factory RecipeFailureMode.validated({
    required String failureId,
    required String description,
    String? consequence,
  }) {
    final trimmedConsequence = consequence?.trim();
    if (trimmedConsequence != null && trimmedConsequence.isEmpty) {
      throw ArgumentError('consequence must be non-empty when provided');
    }
    return RecipeFailureMode._(
      failureId: _requireTrimmed(failureId, 'failureId'),
      description: _requireTrimmed(description, 'description'),
      consequence: trimmedConsequence,
    );
  }

  final String failureId;
  final String description;
  final String? consequence;
}

/// A known side effect of consuming or producing a recipe, with optional
/// severity on a 1..5 scale.
class RecipeSideEffect {
  const RecipeSideEffect._({
    required this.sideEffectId,
    required this.description,
    this.severity,
  });

  factory RecipeSideEffect.validated({
    required String sideEffectId,
    required String description,
    int? severity,
  }) {
    final s = severity;
    if (s != null && (s < 1 || s > 5)) {
      throw ArgumentError.value(
        severity,
        'severity',
        'severity must be within 1..5 when provided',
      );
    }
    return RecipeSideEffect._(
      sideEffectId: _requireTrimmed(sideEffectId, 'sideEffectId'),
      description: _requireTrimmed(description, 'description'),
      severity: s,
    );
  }

  final String sideEffectId;
  final String description;
  final int? severity;
}

/// Immutable alchemy recipe. Optional collections are guarded against
/// duplicate identity keys.
class AlchemyRecipe {
  const AlchemyRecipe._({
    required this.recipeId,
    required this.name,
    required this.ingredients,
    required this.tools,
    required this.orderedSteps,
    required this.conditions,
    required this.failureModes,
    required this.sideEffects,
    this.result,
    this.notes,
  });

  factory AlchemyRecipe.validated({
    required String recipeId,
    required String name,
    List<RecipeIngredient> ingredients = const [],
    List<AlchemyTool> tools = const [],
    List<RecipeStep> orderedSteps = const [],
    List<RecipeCondition> conditions = const [],
    List<RecipeFailureMode> failureModes = const [],
    List<RecipeSideEffect> sideEffects = const [],
    String? result,
    String? notes,
  }) {
    final ingredientIds = <String, String>{};
    for (final i in ingredients) {
      if (ingredientIds.containsKey(i.ingredientId)) {
        throw ArgumentError('duplicate ingredientId: ${i.ingredientId}');
      }
      ingredientIds[i.ingredientId] = i.ingredientId;
    }
    final toolIds = <String, String>{};
    for (final t in tools) {
      if (toolIds.containsKey(t.toolId)) {
        throw ArgumentError('duplicate toolId: ${t.toolId}');
      }
      toolIds[t.toolId] = t.toolId;
    }
    final stepNumbers = <int, int>{};
    for (final s in orderedSteps) {
      if (stepNumbers.containsKey(s.stepNumber)) {
        throw ArgumentError('duplicate stepNumber: ${s.stepNumber}');
      }
      stepNumbers[s.stepNumber] = s.stepNumber;
    }
    final conditionIds = <String, String>{};
    for (final c in conditions) {
      if (conditionIds.containsKey(c.conditionId)) {
        throw ArgumentError('duplicate conditionId: ${c.conditionId}');
      }
      conditionIds[c.conditionId] = c.conditionId;
    }
    final failureIds = <String, String>{};
    for (final f in failureModes) {
      if (failureIds.containsKey(f.failureId)) {
        throw ArgumentError('duplicate failureId: ${f.failureId}');
      }
      failureIds[f.failureId] = f.failureId;
    }
    final sideEffectIds = <String, String>{};
    for (final s in sideEffects) {
      if (sideEffectIds.containsKey(s.sideEffectId)) {
        throw ArgumentError('duplicate sideEffectId: ${s.sideEffectId}');
      }
      sideEffectIds[s.sideEffectId] = s.sideEffectId;
    }
    final trimmedResult = result?.trim();
    if (trimmedResult != null && trimmedResult.isEmpty) {
      throw ArgumentError('result must be non-empty when provided');
    }
    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null && trimmedNotes.isEmpty) {
      throw ArgumentError('notes must be non-empty when provided');
    }
    return AlchemyRecipe._(
      recipeId: _requireTrimmed(recipeId, 'recipeId'),
      name: _requireTrimmed(name, 'name'),
      ingredients: List.unmodifiable(ingredients),
      tools: List.unmodifiable(tools),
      orderedSteps: List.unmodifiable(orderedSteps),
      conditions: List.unmodifiable(conditions),
      failureModes: List.unmodifiable(failureModes),
      sideEffects: List.unmodifiable(sideEffects),
      result: trimmedResult,
      notes: trimmedNotes,
    );
  }

  final String recipeId;
  final String name;
  final List<RecipeIngredient> ingredients;
  final List<AlchemyTool> tools;
  final List<RecipeStep> orderedSteps;
  final List<RecipeCondition> conditions;
  final List<RecipeFailureMode> failureModes;
  final List<RecipeSideEffect> sideEffects;
  final String? result;
  final String? notes;

  bool requiresIngredient(String ingredientId) =>
      ingredients.any((i) => i.ingredientId == ingredientId);

  bool requiresTool(String toolId) => tools.any((t) => t.toolId == toolId);

  bool hasCondition(String conditionId) =>
      conditions.any((c) => c.conditionId == conditionId);

  bool hasFailureMode(String failureId) =>
      failureModes.any((f) => f.failureId == failureId);

  /// Steps ordered by [RecipeStep.stepNumber].
  List<RecipeStep> get sortedSteps {
    final steps = List<RecipeStep>.of(orderedSteps)
      ..sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
    return List.unmodifiable(steps);
  }
}

/// Immutable catalog of alchemy recipes with deterministic query support.
class AlchemyRecipeCatalog {
  const AlchemyRecipeCatalog._(this._recipes);

  factory AlchemyRecipeCatalog.empty() => const AlchemyRecipeCatalog._([]);

  factory AlchemyRecipeCatalog.withRecipes(List<AlchemyRecipe> recipes) {
    final ids = <String, String>{};
    for (final r in recipes) {
      if (ids.containsKey(r.recipeId)) {
        throw ArgumentError('duplicate recipeId: ${r.recipeId}');
      }
      ids[r.recipeId] = r.recipeId;
    }
    final sorted = List<AlchemyRecipe>.of(recipes)
      ..sort((a, b) => a.recipeId.compareTo(b.recipeId));
    return AlchemyRecipeCatalog._(List.unmodifiable(sorted));
  }

  final List<AlchemyRecipe> _recipes;

  int get length => _recipes.length;

  AlchemyRecipe? recipeFor(String recipeId) {
    for (final r in _recipes) {
      if (r.recipeId == recipeId) return r;
    }
    return null;
  }

  /// Recipes that require [ingredientId], sorted by recipe id.
  List<AlchemyRecipe> recipesByIngredient(String ingredientId) {
    return _recipes.where((r) => r.requiresIngredient(ingredientId)).toList();
  }
}
