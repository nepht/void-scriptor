import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.6 Incident & Stop-Ship Protocol.
///
/// Validates that stop-ship triggers, rollback protocol, flag disable,
/// and communication protocol are defined.
class IncidentStopShipProtocol {
  /// Canonical step identifier.
  static const String canonicalStep = '113.6';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_incident_stop_ship_protocol.json';

  /// Required top-level keys.
  static const List<String> requiredKeys = [
    'canonical_step',
    'title',
    'stop_triggers',
    'rollback_protocol',
    'flag_disable_protocol',
    'communication_protocol',
    'decision',
    'limits',
  ];

  /// Minimum stop triggers required.
  static const int minTriggers = 5;

  /// IDs of stop triggers that must be present.
  static const List<String> requiredTriggerIds = [
    'data_loss',
    'security_incident',
    'privacy_leak',
    'migration_failure',
    'crash_loop',
  ];

  /// Validate the manifest structure.
  static IncidentValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return IncidentValidationResult(false, errors);
    }

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    if (document['canonical_step'] != '113.6') {
      errors.add(
        'canonical_step is ${document['canonical_step']}, expected 113.6',
      );
    }

    for (final key in requiredKeys) {
      if (!document.containsKey(key)) {
        errors.add('Required key missing: $key');
      }
    }

    // Validate stop triggers
    final triggers = document['stop_triggers'] as List<dynamic>?;
    if (triggers == null || triggers.length < minTriggers) {
      errors.add(
        'Expected at least $minTriggers stop triggers, '
        'found ${triggers?.length ?? 0}',
      );
    } else {
      final triggerIds = triggers
          .map((t) => (t as Map<String, dynamic>)['id'].toString())
          .toList();
      for (final required in requiredTriggerIds) {
        if (!triggerIds.contains(required)) {
          errors.add('Stop trigger $required missing');
        }
      }
    }

    // Validate rollback protocol
    final rollback = document['rollback_protocol'] as Map<String, dynamic>?;
    if (rollback == null) {
      errors.add('rollback_protocol missing');
    } else {
      if (!rollback.containsKey('steps')) {
        errors.add('rollback_protocol missing steps');
      }
      if (!rollback.containsKey('owner')) {
        errors.add('rollback_protocol missing owner');
      }
    }

    // Validate flag disable protocol
    final flagDisable =
        document['flag_disable_protocol'] as Map<String, dynamic>?;
    if (flagDisable == null) {
      errors.add('flag_disable_protocol missing');
    }

    // Validate communication protocol
    final comm = document['communication_protocol'] as Map<String, dynamic>?;
    if (comm == null) {
      errors.add('communication_protocol missing');
    }

    return IncidentValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Incident & Stop-Ship Protocol validation.
class IncidentValidationResult {
  final bool isValid;
  final List<String> errors;

  const IncidentValidationResult(this.isValid, this.errors);

  @override
  String toString() =>
      'IncidentValidationResult(isValid: $isValid, errors: $errors)';
}
