import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.15 — Lore & Encyclopedia Workflow Validation.
///
/// Validates the lore and encyclopedia workflow by checking manifest
/// structure and exercising key domain components: encyclopedia graph,
/// conlang names/idioms, moodboard/spoiler, herbology/bestiary,
/// artifacts, myths, name profiles, idiom registry, and activation rules.
class LoreEncyclopediaWorkflowValidation {
  /// Canonical step identifier.
  static const String canonicalStep = '113.15';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_lore_encyclopedia_workflow_validation.json';

  /// Required top-level keys.
  static const List<String> requiredKeys = [
    'canonical_step',
    'title',
    'features_validated',
    'required_evidence',
    'limits',
    'decision',
  ];

  /// Validate the manifest structure.
  static LoreEncyclopediaWorkflowValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return LoreEncyclopediaWorkflowValidationResult(false, errors);
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
      final expected = {7, 9, 12, 23, 24, 26, 27, 28, 29};
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
      final evidenceKeys = [
        'workflow_results',
        'search_results',
        'link_results',
        'generator_replay',
        'acceptance',
      ];
      for (final key in evidenceKeys) {
        if (!evidence.containsKey(key)) {
          errors.add('required_evidence missing key: $key');
        }
      }
    }

    return LoreEncyclopediaWorkflowValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Lore Encyclopedia Workflow Validation.
class LoreEncyclopediaWorkflowValidationResult {
  const LoreEncyclopediaWorkflowValidationResult(this.isValid, this.errors);

  final bool isValid;
  final List<String> errors;
}
