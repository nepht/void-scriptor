import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.3 Validation Cohort & Consent.
///
/// Validates that the consent framework is defined with explicit consent
/// requirements, data boundaries, withdrawal process, support channel,
/// and no fabricated participants.
class ValidationCohortConsent {
  /// Canonical step identifier.
  static const String canonicalStep = '113.3';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_validation_cohort_consent.json';

  /// Required top-level keys.
  static const List<String> requiredKeys = [
    'canonical_step',
    'title',
    'selection_criteria',
    'consent_contract',
    'data_boundaries',
    'withdrawal_process',
    'support_channel',
    'compensation',
    'no_fabricated_participants',
    'decision',
    'limits',
  ];

  /// Consent contract must have these elements.
  static const List<String> requiredConsentElements = [
    'consent_type',
    'required_elements',
    'consent_record_path',
  ];

  /// Data boundaries must define collected and not_collected lists.
  static const List<String> requiredDataBoundaries = [
    'collected',
    'not_collected',
    'retention_period',
    'deletion_policy',
  ];

  /// Validate the manifest structure.
  static CohortValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return CohortValidationResult(false, errors);
    }

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    if (document['canonical_step'] != '113.3') {
      errors.add(
        'canonical_step is ${document['canonical_step']}, expected 113.3',
      );
    }

    // Check required keys
    for (final key in requiredKeys) {
      if (!document.containsKey(key)) {
        errors.add('Required key missing: $key');
      }
    }

    // Validate consent contract
    final consent = document['consent_contract'] as Map<String, dynamic>?;
    if (consent != null) {
      for (final elem in requiredConsentElements) {
        if (!consent.containsKey(elem)) {
          errors.add('consent_contract missing: $elem');
        }
      }
      if (consent['consent_type'] != 'EXPLICIT_WRITTEN') {
        errors.add(
          'consent_type must be EXPLICIT_WRITTEN, '
          'got ${consent['consent_type']}',
        );
      }
    }

    // Validate data boundaries
    final boundaries = document['data_boundaries'] as Map<String, dynamic>?;
    if (boundaries != null) {
      for (final key in requiredDataBoundaries) {
        if (!boundaries.containsKey(key)) {
          errors.add('data_boundaries missing: $key');
        }
      }
      final collected = boundaries['collected'] as List<dynamic>?;
      final notCollected = boundaries['not_collected'] as List<dynamic>?;
      if (collected == null || collected.isEmpty) {
        errors.add('data_boundaries.collected must not be empty');
      }
      if (notCollected == null || notCollected.isEmpty) {
        errors.add('data_boundaries.not_collected must not be empty');
      }
    }

    // Validate no fabricated participants
    final noFabrication =
        document['no_fabricated_participants'] as Map<String, dynamic>?;
    if (noFabrication != null) {
      if (noFabrication['verified'] != true) {
        errors.add('no_fabricated_participants.verified must be true');
      }
    }

    // Validate withdrawal process
    final withdrawal = document['withdrawal_process'] as Map<String, dynamic>?;
    if (withdrawal == null) {
      errors.add('withdrawal_process missing');
    } else {
      if (!withdrawal.containsKey('how')) {
        errors.add('withdrawal_process missing how');
      }
      if (!withdrawal.containsKey('no_penalty')) {
        errors.add('withdrawal_process missing no_penalty');
      }
    }

    // Validate support channel
    final support = document['support_channel'] as Map<String, dynamic>?;
    if (support == null) {
      errors.add('support_channel missing');
    } else {
      if (!support.containsKey('response_time')) {
        errors.add('support_channel missing response_time');
      }
    }

    // Validate compensation
    final compensation = document['compensation'] as Map<String, dynamic>?;
    if (compensation != null) {
      if (compensation['type'] != 'EQUAL_FOR_ALL') {
        errors.add('compensation.type must be EQUAL_FOR_ALL');
      }
    }

    return CohortValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Validation Cohort & Consent validation.
class CohortValidationResult {
  /// Whether all validations passed.
  final bool isValid;

  /// List of validation errors (empty if valid).
  final List<String> errors;

  const CohortValidationResult(this.isValid, this.errors);

  @override
  String toString() =>
      'CohortValidationResult(isValid: $isValid, errors: $errors)';
}
