import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.13 — Feature Flag Dependency Validation.
///
/// Validates that the feature flag manifest covers default matrix,
/// dependency matrix, enable/disable, kill-switch, state preservation,
/// and graceful fallback.
class FeatureFlagDependencyValidation {
  /// Canonical step identifier.
  static const String canonicalStep = '113.13';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_feature_flag_dependency_validation.json';

  /// Required top-level keys.
  static const List<String> requiredKeys = [
    'canonical_step',
    'title',
    'default_matrix',
    'dependency_matrix',
    'enable_disable',
    'kill_switch',
    'state_preservation',
    'graceful_fallback',
    'limits',
    'decision',
  ];

  /// Validate the manifest structure.
  static FeatureFlagDependencyValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return FeatureFlagDependencyValidationResult(false, errors);
    }

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    if (document['canonical_step'] != canonicalStep) {
      errors.add(
        'canonical_step is ${document['canonical_step']}, expected $canonicalStep',
      );
    }

    for (final key in requiredKeys) {
      if (!document.containsKey(key)) {
        errors.add('Required key missing: $key');
      }
    }

    // Validate default_matrix
    final defaults = document['default_matrix'] as Map<String, dynamic>?;
    if (defaults == null) {
      errors.add('default_matrix is missing');
    } else {
      if (defaults['flags_count'] != 13) {
        errors.add('default_matrix.flags_count must be 13');
      }
      if (defaults['default_state'] != 'OFF') {
        errors.add('default_matrix.default_state must be OFF');
      }
    }

    // Validate kill_switch
    final killSwitch = document['kill_switch'] as Map<String, dynamic>?;
    if (killSwitch == null) {
      errors.add('kill_switch is missing');
    } else {
      if (killSwitch['engages_clears_all'] != true) {
        errors.add('kill_switch.engages_clears_all must be true');
      }
      if (killSwitch['explicit_enable_clears_kill_switch'] != true) {
        errors.add(
          'kill_switch.explicit_enable_clears_kill_switch must be true',
        );
      }
    }

    // Validate limits
    final limits = document['limits'] as List<dynamic>?;
    if (limits == null || limits.length < 2) {
      errors.add('limits must have at least 2 entries');
    }

    // Validate decision
    final decision = document['decision'] as String?;
    if (decision == null || decision.isEmpty) {
      errors.add('decision must not be empty');
    }

    return FeatureFlagDependencyValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Feature Flag Dependency Validation.
class FeatureFlagDependencyValidationResult {
  final bool isValid;
  final List<String> errors;

  const FeatureFlagDependencyValidationResult(this.isValid, this.errors);

  @override
  String toString() =>
      'FeatureFlagDependencyValidationResult(isValid: $isValid, errors: $errors)';
}
