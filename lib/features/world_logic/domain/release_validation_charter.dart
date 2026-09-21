import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.2 Release Validation Charter.
///
/// Validates that the validation charter defines all required fields:
/// questions, duration, scope, non-goals, evidence, owners, and stop conditions.
class ReleaseValidationCharter {
  /// Canonical step identifier.
  static const String canonicalStep = '113.2';

  /// The charter manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_release_validation_charter.json';

  /// Required top-level keys for a valid charter.
  static const List<String> requiredKeys = [
    'canonical_step',
    'title',
    'validation_questions',
    'validation_window',
    'scope',
    'non_goals',
    'evidence_format',
    'decision_owners',
    'stop_conditions',
    'success_criteria',
    'decision',
    'limits',
  ];

  /// Expected minimum number of validation questions.
  static const int minQuestions = 5;

  /// Expected minimum number of stop conditions.
  static const int minStopConditions = 3;

  /// Validate the charter manifest structure.
  static CharterValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return CharterValidationResult(false, errors);
    }

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    // Check canonical step
    if (document['canonical_step'] != '113.2') {
      errors.add(
        'canonical_step is ${document['canonical_step']}, expected 113.2',
      );
    }

    // Check all required keys
    for (final key in requiredKeys) {
      if (!document.containsKey(key)) {
        errors.add('Required key missing: $key');
      }
    }

    // Validate questions
    final questions = document['validation_questions'] as List<dynamic>?;
    if (questions == null || questions.length < minQuestions) {
      errors.add(
        'Expected at least $minQuestions validation questions, '
        'found ${questions?.length ?? 0}',
      );
    } else {
      for (final q in questions) {
        final map = q as Map<String, dynamic>;
        if (!map.containsKey('id') || !map.containsKey('question')) {
          errors.add('Question missing id or question field');
        }
        if (!map.containsKey('scope')) {
          errors.add('Question ${map['id']} missing scope');
        }
        if (!map.containsKey('owner')) {
          errors.add('Question ${map['id']} missing owner');
        }
      }
    }

    // Validate window
    final window = document['validation_window'] as Map<String, dynamic>?;
    if (window == null) {
      errors.add('validation_window missing');
    } else {
      if (!window.containsKey('duration')) {
        errors.add('validation_window missing duration');
      }
      if (!window.containsKey('owner')) {
        errors.add('validation_window missing owner');
      }
    }

    // Validate scope
    final scope = document['scope'] as Map<String, dynamic>?;
    if (scope == null) {
      errors.add('scope missing');
    } else {
      if (scope['included'] == null || (scope['included'] as List).isEmpty) {
        errors.add('scope.included must not be empty');
      }
      if (scope['excluded'] == null || (scope['excluded'] as List).isEmpty) {
        errors.add('scope.excluded must not be empty');
      }
    }

    // Validate non_goals
    final nonGoals = document['non_goals'] as List<dynamic>?;
    if (nonGoals == null || nonGoals.isEmpty) {
      errors.add('non_goals must not be empty');
    }

    // Validate stop conditions
    final stopConditions = document['stop_conditions'] as List<dynamic>?;
    if (stopConditions == null || stopConditions.length < minStopConditions) {
      errors.add(
        'Expected at least $minStopConditions stop conditions, '
        'found ${stopConditions?.length ?? 0}',
      );
    }

    // Validate decision_owners
    final owners = document['decision_owners'] as Map<String, dynamic>?;
    if (owners == null || owners.isEmpty) {
      errors.add('decision_owners must not be empty');
    }

    // Validate limits
    final limits = document['limits'] as List<dynamic>?;
    if (limits == null || limits.isEmpty) {
      errors.add('limits must not be empty');
    }

    return CharterValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Release Validation Charter validation.
class CharterValidationResult {
  /// Whether all validations passed.
  final bool isValid;

  /// List of validation errors (empty if valid).
  final List<String> errors;

  const CharterValidationResult(this.isValid, this.errors);

  @override
  String toString() =>
      'CharterValidationResult(isValid: $isValid, errors: $errors)';
}
