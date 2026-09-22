import 'dart:convert';
import 'dart:io';

/// Domain model for Sprint 113.12 — Migration & Restore Validation.
///
/// Validates that the manifest covers migration, backup, restore, repair,
/// interrupted-migration recovery, and integrity checking.
class MigrationRestoreValidation {
  /// Canonical step identifier.
  static const String canonicalStep = '113.12';

  /// The manifest file.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_113_migration_restore_validation.json';

  /// Required top-level keys.
  static const List<String> requiredKeys = [
    'canonical_step',
    'title',
    'migration_results',
    'backup_results',
    'restore_results',
    'repair_results',
    'interruption_results',
    'integrity_report',
    'limits',
    'decision',
  ];

  /// Validate the manifest structure.
  static MigrationRestoreValidationResult validate() {
    final errors = <String>[];

    final file = File(manifestPath);
    if (!file.existsSync()) {
      errors.add('Manifest $manifestPath does not exist');
      return MigrationRestoreValidationResult(false, errors);
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

    // Validate migration_results
    final migration = document['migration_results'] as Map<String, dynamic>?;
    if (migration == null) {
      errors.add('migration_results is missing');
    } else {
      if (migration['target_schema'] != 62) {
        errors.add('migration_results.target_schema must be 62');
      }
      if (migration['backup_before_migration'] != true) {
        errors.add('migration_results.backup_before_migration must be true');
      }
      final sources = migration['source_schemas'] as List<dynamic>?;
      if (sources == null || sources.isEmpty) {
        errors.add('migration_results.source_schemas must be non-empty');
      }
    }

    // Validate backup_results
    final backup = document['backup_results'] as Map<String, dynamic>?;
    if (backup == null) {
      errors.add('backup_results is missing');
    } else {
      if (backup['backup_integrity_verifiable'] != true) {
        errors.add('backup_results.backup_integrity_verifiable must be true');
      }
    }

    // Validate restore_results
    final restore = document['restore_results'] as Map<String, dynamic>?;
    if (restore == null) {
      errors.add('restore_results is missing');
    } else {
      if (restore['restore_preserves_data'] != true) {
        errors.add('restore_results.restore_preserves_data must be true');
      }
    }

    // Validate repair_results
    final repair = document['repair_results'] as Map<String, dynamic>?;
    if (repair == null) {
      errors.add('repair_results is missing');
    } else {
      if (repair['corrupt_database_detected'] != true) {
        errors.add('repair_results.corrupt_database_detected must be true');
      }
    }

    // Validate interruption_results
    final interruption =
        document['interruption_results'] as Map<String, dynamic>?;
    if (interruption == null) {
      errors.add('interruption_results is missing');
    } else {
      if (interruption['database_lock_during_migration'] == null) {
        errors.add(
          'interruption_results.database_lock_during_migration required',
        );
      }
    }

    // Validate integrity_report
    final integrity = document['integrity_report'] as Map<String, dynamic>?;
    if (integrity == null) {
      errors.add('integrity_report is missing');
    } else {
      if (integrity['expected_result'] != 'ok') {
        errors.add('integrity_report.expected_result must be "ok"');
      }
      if (integrity['schema_version_after_restore'] != 62) {
        errors.add('integrity_report.schema_version_after_restore must be 62');
      }
    }

    // Validate limits
    final limits = document['limits'] as List<dynamic>?;
    if (limits == null || limits.length < 2) {
      errors.add('limits must have at least 2 entries');
    }

    // Validate decision
    final decision = document['decision'] as String?;
    if (decision == null || decision.isEmpty) {
      errors.add('decision must not be empty');
    }

    return MigrationRestoreValidationResult(errors.isEmpty, errors);
  }
}

/// Result of Migration & Restore Validation.
class MigrationRestoreValidationResult {
  final bool isValid;
  final List<String> errors;

  const MigrationRestoreValidationResult(this.isValid, this.errors);

  @override
  String toString() =>
      'MigrationRestoreValidationResult(isValid: $isValid, errors: $errors)';
}
