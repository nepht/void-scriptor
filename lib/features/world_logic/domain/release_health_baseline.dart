import 'dart:convert';
import 'dart:io';

/// Local, privacy-safe baseline contract for Sprint 114.3.
class ReleaseHealthBaseline {
  static const String canonicalStep = '114.3';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_114_release_health_baseline.json';

  static const List<String> requiredFields = <String>[
    'signal',
    'baseline',
    'threshold',
    'source',
    'window',
    'limitations',
  ];

  static BaselineValidationResult validate(Map<String, dynamic> manifest) {
    final errors = <String>[];
    if (manifest['canonical_step'] != canonicalStep) {
      errors.add('canonical_step mismatch');
    }
    if (manifest['path'] != 'DELAYED') {
      errors.add('path must remain DELAYED');
    }
    if (manifest['external_gates'] != 'DEFERRED-EXTERNAL') {
      errors.add('external gates must remain DEFERRED-EXTERNAL');
    }
    final signals = manifest['signals'];
    if (signals is! List<dynamic> || signals.length != 7) {
      errors.add('exactly seven baseline signals are required');
    } else {
      for (final entry in signals) {
        if (entry is! Map<String, dynamic>) {
          errors.add('each signal must be an object');
          continue;
        }
        for (final field in requiredFields) {
          final value = entry[field];
          if (value is! String || value.trim().isEmpty) {
            errors.add('signal field must be non-empty: $field');
          }
        }
        if (entry.containsKey('observed')) {
          errors.add('observed values are not allowed in a local baseline');
        }
      }
    }
    return BaselineValidationResult(errors.isEmpty, errors);
  }

  static BaselineValidationResult validateManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) {
      return const BaselineValidationResult(false, <String>[
        'manifest missing',
      ]);
    }
    return validate(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  }
}

class BaselineValidationResult {
  final bool isValid;
  final List<String> errors;
  const BaselineValidationResult(this.isValid, this.errors);
}
