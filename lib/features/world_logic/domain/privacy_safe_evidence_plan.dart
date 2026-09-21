import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.4 Privacy-Safe Evidence Plan.
///
/// Validates that the evidence plan defines minimum evidence collection
/// without collecting creative content by default.
class PrivacySafeEvidencePlan {
  /// Canonical step identifier.
  static const String canonicalStep = '113.4';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_privacy_safe_evidence_plan.json';

  /// Required top-level keys for a valid evidence plan.
  static const List<String> requiredKeys = [
    'canonical_step',
    'title',
    'objective',
    'evidence_types',
    'collection_principles',
    'excluded_evidence',
    'storage_policy',
    'decision',
    'limits',
  ];

  /// Minimum number of evidence types to define.
  static const int minEvidenceTypes = 5;

  /// IDs of evidence types that must be present per the step contract.
  static const List<String> requiredEvidenceTypeIds = [
    'explicit_feedback',
    'local_diagnostic_export',
    'crash_signature',
    'performance_metrics',
    'workflow_outcomes',
  ];

  /// Validate the manifest structure.
  static EvidencePlanValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return EvidencePlanValidationResult(false, errors);
    }

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    if (document['canonical_step'] != '113.4') {
      errors.add(
        'canonical_step is ${document['canonical_step']}, expected 113.4',
      );
    }

    // Check required keys
    for (final key in requiredKeys) {
      if (!document.containsKey(key)) {
        errors.add('Required key missing: $key');
      }
    }

    // Validate evidence types
    final evidenceTypes = document['evidence_types'] as List<dynamic>?;
    if (evidenceTypes == null || evidenceTypes.length < minEvidenceTypes) {
      errors.add(
        'Expected at least $minEvidenceTypes evidence types, '
        'found ${evidenceTypes?.length ?? 0}',
      );
    } else {
      final typeIds = evidenceTypes
          .map((e) => (e as Map<String, dynamic>)['id'].toString())
          .toList();
      for (final required in requiredEvidenceTypeIds) {
        if (!typeIds.contains(required)) {
          errors.add('Evidence type $required missing');
        }
      }
    }

    // Validate excluded evidence
    final excluded = document['excluded_evidence'] as List<dynamic>?;
    if (excluded == null || excluded.isEmpty) {
      errors.add('excluded_evidence must not be empty');
    }

    // Validate storage policy
    final storage = document['storage_policy'] as Map<String, dynamic>?;
    if (storage == null) {
      errors.add('storage_policy missing');
    } else {
      if (!storage.containsKey('retention_period')) {
        errors.add('storage_policy missing retention_period');
      }
      if (!storage.containsKey('access_control')) {
        errors.add('storage_policy missing access_control');
      }
    }

    // Validate collection principles
    final principles = document['collection_principles'] as List<dynamic>?;
    if (principles == null || principles.isEmpty) {
      errors.add('collection_principles must not be empty');
    }

    return EvidencePlanValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Privacy-Safe Evidence Plan validation.
class EvidencePlanValidationResult {
  /// Whether all validations passed.
  final bool isValid;

  /// List of validation errors (empty if valid).
  final List<String> errors;

  const EvidencePlanValidationResult(this.isValid, this.errors);

  @override
  String toString() =>
      'EvidencePlanValidationResult(isValid: $isValid, errors: $errors)';
}
