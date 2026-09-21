import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113 GA Entry Gate validation.
///
/// Validates that the six required evidence items for Sprint 113
/// (GA Release Validation & General Availability) are present and
/// structurally valid. This gate ensures the foundation for a
/// validation window exists; it does not authorize public release.
class GaEntryGate {
  /// Canonical step identifier.
  static const String canonicalStep = '113.1';

  /// Expected RC version.
  static const String rcVersion = '1.2.0-rc.1';

  /// The six required evidence categories.
  static const List<String> requiredEvidenceKeys = [
    'rc_approval',
    'signed_rc_artifact',
    'quality_gate_results',
    'known_issues',
    'residual_risks',
    'rollback_readiness',
  ];

  /// Names of quality gate JSON files that must exist for step 113.1.
  static const List<String> qualityGatePaths = [
    'docs/planning/v1.2/sprint_112_full_automated_test_matrix.json',
    'docs/planning/v1.2/sprint_112_contract_compatibility_verification.json',
    'docs/planning/v1.2/sprint_112_determinism_data_integrity_verification.json',
    'docs/planning/v1.2/sprint_112_performance_responsiveness_gate.json',
    'docs/planning/v1.2/sprint_112_memory_storage_index_gate.json',
    'docs/planning/v1.2/sprint_112_security_gate.json',
    'docs/planning/v1.2/sprint_112_privacy_gate.json',
    'docs/planning/v1.2/sprint_112_accessibility_gate.json',
    'docs/planning/v1.2/sprint_112_localization_gate.json',
  ];

  /// Required documentation files.
  static const String knownLimitsPath =
      'docs/release/v1.2.0-rc.1-known-limits.md';
  static const String recoveryGuidePath =
      'docs/release/v1.2.0-rc.1-recovery-guide.md';
  static const String supportPlaybookPath =
      'docs/release/v1.2.0-rc.1-support-playbook.md';
  static const String rcApprovalPath =
      'docs/planning/v1.2/sprint_112_rc_approval_gate.json';
  static const String rcArtifactPath =
      'docs/planning/v1.2/sprint_112_rc_artifact_reproducibility.json';

  /// The 113.1 manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_ga_entry_gate.json';

  /// Release build artifact.
  static const String releaseExe =
      'build/windows/x64/runner/Release/void_scriptor.exe';

  /// Validate the 113.1 manifest structure and required evidence.
  static GaValidationResult validate() {
    final errors = <String>[];

    // 1. Check manifest exists and has correct step
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return GaValidationResult(false, errors);
    }

    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;

    if (manifest['canonical_step'] != '113.1') {
      errors.add(
        'canonical_step is ${manifest['canonical_step']}, expected 113.1',
      );
    }

    // 2. Validate required evidence section
    final evidence = manifest['required_evidence'] as Map<String, dynamic>?;
    if (evidence == null) {
      errors.add('required_evidence section missing from manifest');
      return GaValidationResult(false, errors);
    }

    for (final key in requiredEvidenceKeys) {
      if (!evidence.containsKey(key)) {
        errors.add('Required evidence key missing: $key');
      }
    }

    // 3. Validate RC approval document exists
    if (!File(rcApprovalPath).existsSync()) {
      errors.add('RC approval gate document missing: $rcApprovalPath');
    }

    // 4. Validate RC artifact reproducibility document exists
    if (!File(rcArtifactPath).existsSync()) {
      errors.add(
        'RC artifact reproducibility document missing: $rcArtifactPath',
      );
    }

    // 5. Validate quality gate results (all 9 gates must have manifests)
    final qualityGates =
        evidence['quality_gate_results'] as Map<String, dynamic>?;
    if (qualityGates != null) {
      final gates = qualityGates['gates'] as List<dynamic>?;
      if (gates == null || gates.length != qualityGatePaths.length) {
        errors.add(
          'Expected ${qualityGatePaths.length} quality gates, '
          'found ${gates?.length ?? 0}',
        );
      }
    }

    // 6. Validate known issues document
    if (!File(knownLimitsPath).existsSync()) {
      errors.add('Known limits document missing: $knownLimitsPath');
    }

    // 7. Validate rollback readiness document
    if (!File(recoveryGuidePath).existsSync()) {
      errors.add('Recovery guide missing: $recoveryGuidePath');
    }

    // 8. Validate release build artifact exists
    if (!File(releaseExe).existsSync()) {
      errors.add('Release build artifact missing: $releaseExe');
    }

    // 9. Validate limits section exists
    final limits = manifest['limits'] as List<dynamic>?;
    if (limits == null || limits.isEmpty) {
      errors.add('limits section missing or empty');
    }

    // 10. Validate decision
    if (manifest['decision'] == null) {
      errors.add('decision field missing');
    }

    return GaValidationResult(errors.isEmpty, errors);
  }
}

/// Result of GA Entry Gate validation.
class GaValidationResult {
  /// Whether all validations passed.
  final bool isValid;

  /// List of validation errors (empty if valid).
  final List<String> errors;

  const GaValidationResult(this.isValid, this.errors);

  @override
  String toString() => 'GaValidationResult(isValid: $isValid, errors: $errors)';
}
