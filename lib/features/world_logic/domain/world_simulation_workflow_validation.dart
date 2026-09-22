import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.16 — World Simulation Workflow Validation.
///
/// Validates ten core world-simulation components:
/// 1. Journey consistency (route, time, supply checks)
/// 2. Custom calendar (dateFromTick, celestial cycles)
/// 3. Genealogy tree (roots, generations, descendants, dynasty)
/// 4. Temporal map (territorial control layers, slider step)
/// 5. Diplomacy history (treaty, conflict, active status)
/// 6. Character age/continuity (age at time, scene presence, alerts)
/// 7. Power rulebook (ability, prerequisite, cost/limit/counter)
/// 8. Economy calculator (price comparison, purchasing power, wealth tier)
/// 9. Rumor propagation (seed, step, distortion, convergence)
/// 10. Tech tree (node, prerequisite, discovery timeline, layout)
///
/// Required evidence: workflow_results, determinism_results,
/// explanation_results, override_results, acceptance.
class WorldSimulationWorkflowValidation {
  /// Canonical step identifier.
  static const String canonicalStep = '113.16';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_world_simulation_workflow_validation.json';

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
  static const List<int> expectedFeatures = [
    3,
    5,
    6,
    11,
    13,
    14,
    15,
    20,
    21,
    22,
  ];

  /// Required evidence sections.
  static const List<String> requiredEvidenceKeys = [
    'workflow_results',
    'determinism_results',
    'explanation_results',
    'override_results',
    'acceptance',
  ];

  /// Validate the manifest structure.
  static WorldSimulationValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return WorldSimulationValidationResult(false, errors);
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

    return WorldSimulationValidationResult(errors.isEmpty, errors);
  }
}

/// Result of World Simulation Workflow Validation.
class WorldSimulationValidationResult {
  const WorldSimulationValidationResult(this.isValid, this.errors);

  final bool isValid;
  final List<String> errors;
}
