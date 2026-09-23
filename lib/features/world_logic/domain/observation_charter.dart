import 'dart:convert';
import 'dart:io';

/// Local, privacy-safe charter for delayed Sprint 114 observation.
class ObservationCharter {
  static const String canonicalStep = '114.2';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_114_observation_charter.json';

  static const List<String> requiredFields = <String>[
    'canonical_step',
    'path',
    'window',
    'questions',
    'signals',
    'owners',
    'escalation',
    'stop_conditions',
    'exit_criteria',
    'external_gates',
  ];

  static ObservationCharterResult validate(Map<String, dynamic> manifest) {
    final errors = <String>[];
    for (final field in requiredFields) {
      if (!manifest.containsKey(field)) {
        errors.add('missing required field: $field');
      }
    }
    if (manifest['canonical_step'] != canonicalStep) {
      errors.add('canonical_step mismatch');
    }
    if (manifest['path'] != 'DELAYED') errors.add('path must remain DELAYED');
    final window = manifest['window'];
    if (window is Map<String, dynamic> &&
        window['type'] == 'PRODUCTION_TELEMETRY') {
      errors.add('production telemetry is unavailable');
    }
    if (window is! Map<String, dynamic> ||
        window['type'] != 'LOCAL_CORRECTIVE') {
      errors.add('window must be LOCAL_CORRECTIVE');
    }
    for (final field in <String>[
      'questions',
      'signals',
      'owners',
      'stop_conditions',
      'exit_criteria',
    ]) {
      if (manifest[field] is! List<dynamic>) {
        errors.add('$field must be a list');
      }
    }
    if (manifest['escalation'] is! Map<String, dynamic>) {
      errors.add('escalation must be an object');
    }
    if (manifest['external_gates'] != 'DEFERRED-EXTERNAL') {
      errors.add('external gates must remain DEFERRED-EXTERNAL');
    }
    return ObservationCharterResult(errors.isEmpty, errors);
  }

  static ObservationCharterResult validateManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) {
      return const ObservationCharterResult(false, <String>[
        'manifest missing',
      ]);
    }
    return validate(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  }
}

class ObservationCharterResult {
  final bool isValid;
  final List<String> errors;
  const ObservationCharterResult(this.isValid, this.errors);
}
