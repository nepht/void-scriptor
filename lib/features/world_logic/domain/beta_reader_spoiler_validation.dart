import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.17 — Beta Reader & Spoiler Validation.
///
/// Validates five core beta-reader/spoiler components:
/// 1. Audience policy (SpoilerRegistry, SpoilerLevel, classification)
/// 2. Redaction (ReaderRedactor, preview, hidden links, no metadata)
/// 3. Share/export (SpoilerSafeExportService, format, preflight)
/// 4. Revocation (grant/revoke lifecycle)
/// 5. Leakage prevention (no spoiler text, no internal links in output)
///
/// Required evidence: audience_results, redaction_results, share_results,
/// revocation_results, leakage_results, acceptance.
class BetaReaderSpoilerValidation {
  /// Canonical step identifier.
  static const String canonicalStep = '113.17';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_beta_reader_spoiler_validation.json';

  /// Required top-level keys.
  static const List<String> requiredKeys = [
    'canonical_step',
    'title',
    'features_validated',
    'required_evidence',
    'limits',
    'decision',
  ];

  /// Expected features for this step.
  static const List<int> expectedFeatures = [16];

  /// Required evidence sections.
  static const List<String> requiredEvidenceKeys = [
    'audience_results',
    'redaction_results',
    'share_results',
    'revocation_results',
    'leakage_results',
    'acceptance',
  ];

  /// Validate the manifest structure.
  static BetaReaderValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return BetaReaderValidationResult(false, errors);
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

    // Validate features_validated
    final features = document['features_validated'] as List<dynamic>?;
    if (features == null || features.isEmpty) {
      errors.add('features_validated is missing or empty');
    } else {
      final expected = expectedFeatures.toSet();
      final actual = features.map((e) => e as int).toSet();
      if (!expected.containsAll(actual)) {
        errors.add(
          'features_validated contains unexpected values: '
          '${actual.difference(expected)}',
        );
      }
      if (!actual.containsAll(expected)) {
        errors.add(
          'features_validated missing expected values: '
          '${expected.difference(actual)}',
        );
      }
    }

    // Validate required_evidence
    final evidence = document['required_evidence'] as Map<String, dynamic>?;
    if (evidence == null) {
      errors.add('required_evidence is missing');
    } else {
      for (final key in requiredEvidenceKeys) {
        if (!evidence.containsKey(key)) {
          errors.add('required_evidence missing key: $key');
        }
      }
    }

    return BetaReaderValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Beta Reader & Spoiler Validation.
class BetaReaderValidationResult {
  const BetaReaderValidationResult(this.isValid, this.errors);

  final bool isValid;
  final List<String> errors;
}
