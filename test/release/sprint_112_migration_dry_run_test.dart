import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/migration_dry_run_service.dart';

void main() {
  late Directory root;
  late Directory source;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-11227-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Migration reference');
    await File(
      '${package.assetsDirectory.path}/references/golden.txt',
    ).writeAsString('stable reference data');
    source = package.root;
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('runs migration against a disposable copy and compares data', () async {
    final report = await MigrationDryRunService().run(source);

    expect(
      report.migrationLogs,
      contains('source copied to disposable target'),
    );
    expect(
      report.migrationLogs,
      contains('target opened through production service'),
    );
    expect(report.recordCounts['assets'], 0);
    expect(report.linkCounts, isNotEmpty);
    expect(report.checksumResults['manifest'], 'MATCH');
    expect(report.warnings, isEmpty);
    expect(report.repairActions, isEmpty);
    expect(report.sourceSchemaVersion, 62);
    expect(report.targetSchemaVersion, 62);
    expect(report.targetRoot.existsSync(), isTrue);

    addTearDown(() async {
      if (await report.targetRoot.exists()) {
        await report.targetRoot.delete(recursive: true);
      }
    });
  });
}
