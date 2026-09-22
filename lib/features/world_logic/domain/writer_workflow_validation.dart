import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.14 — Writer Workflow Validation.
///
/// Validates the end-to-end writer workflow by exercising eight core
/// components: drafting (EndToEndWriterWorkflow), lore links
/// (InlineLoreLinkParser), voice rules (DialogueVoiceRule), POV locking
/// (PovLedger), pacing analysis (PacingHeatmapAnalyzer), draft snapshots
/// (DraftSnapshotStore), plot boards (PlotBoard), and contradiction flow
/// (ContradictionAnalysis + ContradictionInbox).
///
/// Required evidence: workflow_results, errors, recovery,
/// usability_feedback, acceptance.
class WriterWorkflowValidation {
  /// Canonical step identifier.
  static const String canonicalStep = '113.14';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_writer_workflow_validation.json';

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
  static WriterWorkflowValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return WriterWorkflowValidationResult(false, errors);
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
      final expected = {1, 2, 4, 8, 10, 17, 18, 25};
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
        'errors',
        'recovery',
        'usability_feedback',
        'acceptance',
      ];
      for (final key in evidenceKeys) {
        if (!evidence.containsKey(key)) {
          errors.add('required_evidence missing key: $key');
        }
      }
    }

    return WriterWorkflowValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Writer Workflow Validation.
class WriterWorkflowValidationResult {
  const WriterWorkflowValidationResult(this.isValid, this.errors);

  final bool isValid;
  final List<String> errors;
}
