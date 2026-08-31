// Sprint 111.13 - Alchemy Consistency Validation.
//
// Domain-only validator that detects recipe conflicts against canon:
// missing ingredients, invalid substitutions, effect conflicts, and
// preparation conflicts. Produces an explanation report and supports
// explicit manual exceptions.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

import "encyclopedia_alchemy.dart";
import "encyclopedia_effect.dart";

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

/// The kind of consistency issue a validator can report.
enum AlchemyValidationKind {
  missingIngredient('Missing ingredient'),
  invalidSubstitution('Invalid substitution'),
  effectConflict('Effect conflict'),
  preparationConflict('Preparation conflict');

  const AlchemyValidationKind(this.label);

  final String label;
}

/// A single reported consistency issue. [ingredientId] is optional because
/// preparation conflicts do not reference a specific ingredient.
class AlchemyValidationIssue {
  const AlchemyValidationIssue._({
    required this.issueId,
    required this.recipeId,
    required this.kind,
    required this.message,
    this.ingredientId,
  });

  factory AlchemyValidationIssue.validated({
    required String issueId,
    required String recipeId,
    required AlchemyValidationKind kind,
    required String message,
    String? ingredientId,
  }) {
    final trimmedIngredientId = ingredientId?.trim();
    if (trimmedIngredientId != null && trimmedIngredientId.isEmpty) {
      throw ArgumentError('ingredientId must be non-empty when provided');
    }
    return AlchemyValidationIssue._(
      issueId: _requireTrimmed(issueId, 'issueId'),
      recipeId: _requireTrimmed(recipeId, 'recipeId'),
      kind: kind,
      message: _requireTrimmed(message, 'message'),
      ingredientId: trimmedIngredientId,
    );
  }

  final String issueId;
  final String recipeId;
  final AlchemyValidationKind kind;
  final String message;
  final String? ingredientId;
}

/// An explicit, user-recorded exception that suppresses an issue kind for a
/// recipe.
class ManualException {
  const ManualException._({
    required this.exceptionId,
    required this.recipeId,
    required this.kind,
    required this.reason,
  });

  factory ManualException.validated({
    required String exceptionId,
    required String recipeId,
    required AlchemyValidationKind kind,
    required String reason,
  }) {
    return ManualException._(
      exceptionId: _requireTrimmed(exceptionId, 'exceptionId'),
      recipeId: _requireTrimmed(recipeId, 'recipeId'),
      kind: kind,
      reason: _requireTrimmed(reason, 'reason'),
    );
  }

  final String exceptionId;
  final String recipeId;
  final AlchemyValidationKind kind;
  final String reason;

  bool matches(String recipeId, AlchemyValidationKind kind) =>
      this.recipeId == recipeId && this.kind == kind;
}

/// Immutable validation report over a single recipe.
class AlchemyValidationReport {
  const AlchemyValidationReport._(this._issues);

  factory AlchemyValidationReport.of(List<AlchemyValidationIssue> issues) {
    final ids = <String, String>{};
    for (final i in issues) {
      if (ids.containsKey(i.issueId)) {
        throw ArgumentError('duplicate issueId: ${i.issueId}');
      }
      ids[i.issueId] = i.issueId;
    }
    return AlchemyValidationReport._(List.unmodifiable(issues));
  }

  final List<AlchemyValidationIssue> _issues;

  bool get hasIssues => _issues.isNotEmpty;

  int get issueCount => _issues.length;

  List<AlchemyValidationIssue> get issues => _issues;

  List<AlchemyValidationIssue> issuesOf(AlchemyValidationKind kind) {
    return _issues.where((i) => i.kind == kind).toList();
  }

  /// A human-readable explanation of every active issue.
  String describe() {
    if (_issues.isEmpty) return 'No consistency issues.';
    final buffer = StringBuffer('Alchemy consistency issues:');
    for (final i in _issues) {
      buffer.write(' [${i.kind.label}] ${i.message}');
    }
    return buffer.toString();
  }
}

/// Deterministic validator of alchemy recipe consistency against canon.
///
/// - [availableIngredients]: the set of ingredient ids known to exist in the
///   world canon. An ingredient outside the set is reported as missing.
/// - [allowedSubstitutions]: canon-approved substitutions keyed by the
///   original ingredient id. A recipe ingredient whose id is a declared
///   substitute for a canon ingredient is acceptable even when it is not in
///   [availableIngredients].
/// - [declaredSubstitutions]: the set of ingredient ids the recipe itself
///   declares as substitutions. Each must be registered in
///   [allowedSubstitutions], otherwise it is an invalid substitution.
/// - [effectCatalog]: optional ingredient effect records used to check
///   forbidden and required effect kinds.
/// - [forbiddenEffectKinds]: effect kinds that must not appear on any recipe
///   ingredient (per the recipe's canon rules).
/// - [requiredEffectKinds]: effect kinds that at least one recipe ingredient
///   must provide.
/// - [exceptions]: explicit manual exceptions that suppress matching issues.
class AlchemyConsistencyValidator {
  const AlchemyConsistencyValidator();

  AlchemyValidationReport validate({
    required AlchemyRecipe recipe,
    Set<String> availableIngredients = const {},
    Map<String, Set<String>> allowedSubstitutions = const {},
    Set<String> declaredSubstitutions = const {},
    EffectCatalog? effectCatalog,
    Set<EffectKind> forbiddenEffectKinds = const {},
    Set<EffectKind> requiredEffectKinds = const {},
    List<ManualException> exceptions = const [],
  }) {
    final issues = <AlchemyValidationIssue>[];

    for (final ingredient in recipe.ingredients) {
      final id = ingredient.ingredientId;
      if (!availableIngredients.contains(id) &&
          !_isRegisteredSubstitute(id, allowedSubstitutions)) {
        issues.add(
          AlchemyValidationIssue.validated(
            issueId: 'mi_$id',
            recipeId: recipe.recipeId,
            kind: AlchemyValidationKind.missingIngredient,
            message: 'Ingredient "$id" is not available in the canon',
            ingredientId: id,
          ),
        );
      }
      if (declaredSubstitutions.contains(id) &&
          !_isRegisteredSubstitute(id, allowedSubstitutions)) {
        issues.add(
          AlchemyValidationIssue.validated(
            issueId: 'is_$id',
            recipeId: recipe.recipeId,
            kind: AlchemyValidationKind.invalidSubstitution,
            message: 'Substitution "$id" is not registered in canon',
            ingredientId: id,
          ),
        );
      }
    }

    if (effectCatalog != null) {
      for (final ingredient in recipe.ingredients) {
        final id = ingredient.ingredientId;
        final record = effectCatalog.recordFor(id);
        if (record == null) continue;
        for (final forbidden in forbiddenEffectKinds) {
          if (record.hasKind(forbidden)) {
            issues.add(
              AlchemyValidationIssue.validated(
                issueId: 'ef_${forbidden.name}_$id',
                recipeId: recipe.recipeId,
                kind: AlchemyValidationKind.effectConflict,
                message:
                    'Ingredient "$id" has forbidden effect ${forbidden.label}',
                ingredientId: id,
              ),
            );
          }
        }
      }
      for (final required in requiredEffectKinds) {
        var provided = false;
        for (final ingredient in recipe.ingredients) {
          final record = effectCatalog.recordFor(ingredient.ingredientId);
          if (record != null && record.hasKind(required)) {
            provided = true;
            break;
          }
        }
        if (!provided) {
          issues.add(
            AlchemyValidationIssue.validated(
              issueId: 'er_${required.name}',
              recipeId: recipe.recipeId,
              kind: AlchemyValidationKind.effectConflict,
              message:
                  'No ingredient provides required effect ${required.label}',
            ),
          );
        }
      }
    }

    final conditionIds = recipe.conditions.map((c) => c.conditionId).toSet();
    for (final step in recipe.orderedSteps) {
      final condition = step.condition;
      if (condition != null && !conditionIds.contains(condition)) {
        issues.add(
          AlchemyValidationIssue.validated(
            issueId: 'pc_step${step.stepNumber}',
            recipeId: recipe.recipeId,
            kind: AlchemyValidationKind.preparationConflict,
            message:
                'Step ${step.stepNumber} requires undeclared condition "$condition"',
          ),
        );
      }
    }

    final suppressed = issues.where((issue) {
      for (final e in exceptions) {
        if (e.matches(recipe.recipeId, issue.kind)) return true;
      }
      return false;
    }).toSet();

    final active = issues.where((i) => !suppressed.contains(i)).toList();
    return AlchemyValidationReport.of(active);
  }

  bool _isRegisteredSubstitute(
    String ingredientId,
    Map<String, Set<String>> allowedSubstitutions,
  ) {
    for (final substitutes in allowedSubstitutions.values) {
      if (substitutes.contains(ingredientId)) return true;
    }
    return false;
  }
}
