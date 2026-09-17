import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.26 records the legacy schema and data-variation inventory', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_legacy_data_inventory.json',
    );
    expect(file.existsSync(), isTrue, reason: '112.26 inventory must exist');

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.26');
    expect(document['inventory_scope'], 'local_project_package');
    expect(document['production_data'], false);

    final schemaVersions = document['schema_versions'] as Map<String, dynamic>;
    expect(schemaVersions['current_database_schema'], 62);
    expect(schemaVersions['migration_range'], '1..62');
    expect(schemaVersions['migration_strategy'], 'guarded_forward_migrations');

    final tables = (document['table_inventory'] as List).cast<Map>();
    expect(tables, isNotEmpty);
    expect(tables.length, greaterThanOrEqualTo(160));
    expect(
      tables.every(
        (table) =>
            table['name'] is String &&
            table['category'] is String &&
            table['source'] is String,
      ),
      isTrue,
    );
    expect(
      tables.map((table) => table['name']),
      containsAll(<String>[
        'assets',
        'characters',
        'story_scenes',
        'references',
        'project_backups',
      ]),
    );

    final variants = document['unknown_variants'] as List;
    expect(variants, isNotEmpty);
    expect(
      variants.every(
        (variant) => variant is Map && variant['handling'] is String,
      ),
      isTrue,
    );

    final corruptSamples = document['corrupt_samples'] as List;
    expect(corruptSamples, isNotEmpty);
    expect(
      corruptSamples.every(
        (sample) => sample is Map && sample['safe_action'] is String,
      ),
      isTrue,
    );

    final migrationClasses = document['migration_classes'] as List;
    expect(migrationClasses, isNotEmpty);
    expect(
      migrationClasses.every(
        (migration) =>
            migration is Map &&
            migration['class'] is String &&
            migration['verification'] is String,
      ),
      isTrue,
    );
  });
}
