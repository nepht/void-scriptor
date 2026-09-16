import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.5 freezes schema and contract evolution rules', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_schema_contract_freeze.json',
    );
    expect(file.existsSync(), isTrue, reason: '112.5 manifest must exist');

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.5');
    expect(document['release_channel'], 'v1.2.0-rc.1');

    final schema = document['schema_manifest'] as Map<String, dynamic>;
    expect(schema['project_format_major'], 1);
    expect(schema['project_format_schema'], 16);
    expect(schema['database_schema'], 62);
    expect(schema['plugin_api_major'], 1);
    expect(schema['workflow_schema'], 1);
    expect(schema['automation_rule_schema'], 1);
    expect(schema['trigger_schema'], 1);
    expect(schema['execution_record_schema'], 1);

    final contracts = document['contract_versions'] as Map<String, dynamic>;
    expect(
      contracts.keys,
      containsAll(<String>[
        'project_format',
        'database_schema',
        'plugin_api',
        'workflow_automation',
      ]),
    );
    expect(contracts.values.every((value) => value is String), isTrue);

    final compatibility =
        document['compatibility_policy'] as Map<String, dynamic>;
    expect(compatibility['future_versions'], 'reject_without_guessing');
    expect(compatibility['database_upgrade'], 'backup_then_forward_migrate');
    expect(
      compatibility['database_downgrade'],
      'restore_backup_or_safe_export',
    );
    expect(compatibility['unknown_fields'], 'preserve_when_reading');

    final deprecation = document['deprecation_policy'] as Map<String, dynamic>;
    expect(deprecation['breaking_changes_in_rc'], false);
    expect(deprecation['notice_required'], true);
    expect(deprecation['removal_requires_major'], true);

    final evolution =
        document['post_release_evolution'] as Map<String, dynamic>;
    expect(evolution['schema_changes'], 'next_migration_only');
    expect(evolution['contract_changes'], 'additive_until_next_major');
    expect(evolution['rollback'], 'pre_migration_backup');
  });
}
