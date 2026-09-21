import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.8 Baseline & Acceptance Thresholds.
///
/// Validates that baseline metrics and acceptance thresholds are defined
/// for stability, performance, migration, recovery, and workflow.
class BaselineAcceptanceThresholds {
  /// Canonical step identifier.
  static const String canonicalStep = '113.8';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_baseline_acceptance_thresholds.json';

  /// Required top-level keys.
  static const List<String> requiredKeys = [
    'canonical_step',
    'title',
    'thresholds',
    'overall_decision_rule',
    'decision',
    'limits',
  ];

  /// Minimum number of thresholds.
  static const int minThresholds = 5;

  /// Validate the manifest structure.
  static BaselineValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return BaselineValidationResult(false, errors);
    }

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    if (document['canonical_step'] != '113.8') {
      errors.add(
        'canonical_step is ${document['canonical_step']}, expected 113.8',
      );
    }

    for (final key in requiredKeys) {
      if (!document.containsKey(key)) {
        errors.add('Required key missing: $key');
      }
    }

    // Validate thresholds
    final thresholds = document['thresholds'] as List<dynamic>?;
    if (thresholds == null || thresholds.length < minThresholds) {
      errors.add(
        'Expected at least $minThresholds thresholds, '
        'found ${thresholds?.length ?? 0}',
      );
    } else {
      for (final t in thresholds) {
        final map = t as Map<String, dynamic>;
        if (!map.containsKey('metric') || !map.containsKey('threshold')) {
          errors.add('Threshold missing metric or threshold');
        }
        if (!map.containsKey('owner')) {
          errors.add('Threshold missing owner');
        }
        if (!map.containsKey('decision_rule')) {
          errors.add('Threshold missing decision_rule');
        }
      }
    }

    // Validate overall decision rule
    final overallRule = document['overall_decision_rule'] as String?;
    if (overallRule == null || overallRule.isEmpty) {
      errors.add('overall_decision_rule must not be empty');
    }

    return BaselineValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Baseline & Acceptance Thresholds validation.
class BaselineValidationResult {
  final bool isValid;
  final List<String> errors;

  const BaselineValidationResult(this.isValid, this.errors);

  @override
  String toString() =>
      'BaselineValidationResult(isValid: $isValid, errors: $errors)';
}
