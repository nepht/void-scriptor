import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart'
    hide CharacterIdentityProfile;
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/rollback_downgrade_boundary.dart';

void main() {
  late Directory root;
  late Directory packageRoot;
  late ProjectPackage package;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-11229-');
    package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Rollback boundary fixture');
    await File(
      '${package.assetsDirectory.path}/references/golden.txt',
    ).writeAsString('stable payload');
    packageRoot = package.root;
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Directory copyPackageToBackup(String name) {
    final backup = Directory('${root.path}/$name')..createSync(recursive: true);
    Directory('${backup.path}/assets/references').createSync(recursive: true);
    File(
      '${packageRoot.path}/manifest/project.json',
    ).copySync('${backup.path}/project.json');
    File(
      '${packageRoot.path}/database/project.db',
    ).copySync('${backup.path}/project.db');
    File(
      '${packageRoot.path}/assets/references/golden.txt',
    ).copySync('${backup.path}/assets/references/golden.txt');
    return backup;
  }

  test(
    'current-schema backup rolls back and downgrade is not blocked',
    () async {
      final backup = copyPackageToBackup('backup-current');
      final service = RollbackDowngradeBoundaryService();
      final schemaBefore = await ProjectDatabaseService().schemaVersion(
        '${packageRoot.path}/database/project.db',
      );

      final report = await service.evaluate(
        package: package,
        backup: backup,
        rollbackProbeRoot: Directory('${root.path}/rollback-probe'),
        exportDestination: Directory('${root.path}/exports-out'),
      );

      expect(report.rollbackAllowed, isTrue);
      expect(report.rollbackVerified, isTrue);
      expect(report.downgradeBlocked, isFalse);
      expect(report.safeExportFile.existsSync(), isTrue);
      expect(report.warnings, isEmpty);
      expect(report.downgradeLimits, isNotEmpty);
      expect(report.supportProcedure.length, greaterThanOrEqualTo(5));
      expect(report.rollbackProbeManifestFile.existsSync(), isTrue);
      expect(
        await report.rollbackProbeManifestFile.length(),
        await File('${backup.path}/project.json').length(),
      );

      // Evaluation must not rewrite the live package database.
      final schemaAfter = await ProjectDatabaseService().schemaVersion(
        '${packageRoot.path}/database/project.db',
      );
      expect(schemaAfter, schemaBefore);
    },
  );

  test(
    'newer-schema backup is blocked with user warnings, live file intact',
    () async {
      final backup = copyPackageToBackup('backup-future');
      final raw = sqlite.sqlite3.open('${backup.path}/project.db');
      raw.execute(
        'PRAGMA user_version = ${ProjectDatabase.currentSchemaVersion + 1}',
      );
      raw.close();

      final report = await RollbackDowngradeBoundaryService().evaluate(
        package: package,
        backup: backup,
        rollbackProbeRoot: Directory('${root.path}/rollback-probe'),
        exportDestination: Directory('${root.path}/exports-out'),
      );

      expect(report.rollbackAllowed, isFalse);
      expect(report.rollbackVerified, isFalse);
      expect(report.downgradeBlocked, isTrue);
      expect(report.warnings, isNotEmpty);
      expect(
        report.warnings.join(' '),
        contains('newer than application schema'),
      );
      // The downgrade-safe export path stays available even when blocked.
      expect(report.safeExportFile.existsSync(), isTrue);
      // No rollback probe package may be materialized for a blocked backup.
      final probeRoot = Directory('${root.path}/rollback-probe');
      expect(!probeRoot.existsSync() || probeRoot.listSync().isEmpty, isTrue);
    },
  );
}
