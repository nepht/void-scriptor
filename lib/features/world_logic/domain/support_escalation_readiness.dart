import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.5 Support & Escalation Readiness.
///
/// Validates that support intake, severity matrix, response ownership,
/// recovery guidance, and escalation paths are defined.
class SupportEscalationReadiness {
  /// Canonical step identifier.
  static const String canonicalStep = '113.5';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_support_escalation_readiness.json';

  /// Required top-level keys for a valid manifest.
  static const List<String> requiredKeys = [
    'canonical_step',
    'title',
    'severity_matrix',
    'response_targets',
    'recovery_guides',
    'escalation_paths',
    'decision',
    'limits',
  ];

  /// Severity levels that must be defined.
  static const List<String> requiredSeverityLevels = ['P0', 'P1', 'P2', 'P3'];

  /// Validate the manifest structure.
  static SupportValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return SupportValidationResult(false, errors);
    }

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    if (document['canonical_step'] != '113.5') {
      errors.add(
        'canonical_step is ${document['canonical_step']}, expected 113.5',
      );
    }

    // Check required keys
    for (final key in requiredKeys) {
      if (!document.containsKey(key)) {
        errors.add('Required key missing: $key');
      }
    }

    // Validate severity matrix
    final matrix = document['severity_matrix'] as Map<String, dynamic>?;
    if (matrix == null) {
      errors.add('severity_matrix missing');
    } else {
      for (final level in requiredSeverityLevels) {
        if (!matrix.containsKey(level)) {
          errors.add('severity_matrix missing level $level');
        }
      }
    }

    // Validate response targets
    final targets = document['response_targets'] as Map<String, dynamic>?;
    if (targets == null) {
      errors.add('response_targets missing');
    } else {
      if (!targets.containsKey('P0')) {
        errors.add('response_targets missing P0 target');
      }
    }

    // Validate recovery guides
    final guides = document['recovery_guides'] as List<dynamic>?;
    if (guides == null || guides.isEmpty) {
      errors.add('recovery_guides must not be empty');
    }

    // Validate escalation paths
    final paths = document['escalation_paths'] as List<dynamic>?;
    if (paths == null || paths.isEmpty) {
      errors.add('escalation_paths must not be empty');
    }

    return SupportValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Support & Escalation Readiness validation.
class SupportValidationResult {
  /// Whether all validations passed.
  final bool isValid;

  /// List of validation errors (empty if valid).
  final List<String> errors;

  const SupportValidationResult(this.isValid, this.errors);

  @override
  String toString() =>
      'SupportValidationResult(isValid: $isValid, errors: $errors)';
}
