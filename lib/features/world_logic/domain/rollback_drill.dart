import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.7 Rollback Drill.
///
/// Validates that a rollback drill document covers artifact withdrawal,
/// flag disable, backup restore, communication draft, timings, and findings.
class RollbackDrill {
  /// Canonical step identifier.
  static const String canonicalStep = '113.7';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_rollback_drill.json';

  /// Required top-level keys.
  static const List<String> requiredKeys = [
    'canonical_step',
    'title',
    'drill_script',
    'artifact_withdrawal',
    'flag_disable',
    'backup_restore',
    'communication_draft',
    'timings',
    'findings',
    'decision',
    'limits',
  ];

  /// Validate the manifest structure.
  static RollbackDrillValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return RollbackDrillValidationResult(false, errors);
    }

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    if (document['canonical_step'] != '113.7') {
      errors.add(
        'canonical_step is ${document['canonical_step']}, expected 113.7',
      );
    }

    for (final key in requiredKeys) {
      if (!document.containsKey(key)) {
        errors.add('Required key missing: $key');
      }
    }

    // Validate drill script
    final drillScript = document['drill_script'] as Map<String, dynamic>?;
    if (drillScript == null) {
      errors.add('drill_script missing');
    } else {
      final steps = drillScript['steps'] as List<dynamic>?;
      if (steps == null || steps.length < 3) {
        errors.add('drill_script must have at least 3 steps');
      }
    }

    // Validate timings
    final timings = document['timings'] as Map<String, dynamic>?;
    if (timings == null) {
      errors.add('timings missing');
    }

    // Validate findings
    final findings = document['findings'] as Map<String, dynamic>?;
    if (findings == null) {
      errors.add('findings missing');
    }

    return RollbackDrillValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Rollback Drill validation.
class RollbackDrillValidationResult {
  final bool isValid;
  final List<String> errors;

  const RollbackDrillValidationResult(this.isValid, this.errors);

  @override
  String toString() =>
      'RollbackDrillValidationResult(isValid: $isValid, errors: $errors)';
}
