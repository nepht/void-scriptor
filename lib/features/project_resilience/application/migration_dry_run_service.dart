import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/project_package/project_package.dart';
import '../../../database/project/project_database_service.dart';

/// Result of a migration rehearsal performed against a disposable package.
/// The source package is never opened for writing or modified.
final class MigrationDryRunReport {
  const MigrationDryRunReport({
    required this.targetRoot,
    required this.sourceSchemaVersion,
    required this.targetSchemaVersion,
    required this.migrationLogs,
    required this.recordCounts,
    required this.linkCounts,
    required this.checksumResults,
    required this.warnings,
    required this.repairActions,
  });

  final Directory targetRoot;
  final int sourceSchemaVersion;
  final int targetSchemaVersion;
  final List<String> migrationLogs;
  final Map<String, int> recordCounts;
  final Map<String, int> linkCounts;
  final Map<String, String> checksumResults;
  final List<String> warnings;
  final List<String> repairActions;
}

/// Runs the production database open/migration path on a copied reference
/// project, then compares structural data before and after the rehearsal.
final class MigrationDryRunService {
  Future<MigrationDryRunReport> run(Directory sourceRoot) async {
    final sourcePackage = _packageFrom(sourceRoot);
    final sourceSchema = await ProjectDatabaseService().schemaVersion(
      sourcePackage.databaseFile.path,
    );
    if (sourceSchema == null) {
      throw StateError('reference project has no readable schema version');
    }

    final targetRoot = await Directory.systemTemp.createTemp(
      'void-scriptor-migration-dry-run-',
    );
    final targetPackage = _packageFrom(targetRoot);
    await _copyTree(sourceRoot, targetRoot);

    final before = await _snapshot(targetPackage);
    final logs = <String>['source copied to disposable target'];
    final database = await ProjectDatabaseService().open(
      targetPackage.databaseFile.path,
    );
    try {
      logs.add('target opened through production service');
      await database.close();
    } catch (_) {
      await database.close();
      rethrow;
    }

    final after = await _snapshot(targetPackage);
    final warnings = <String>[];
    final repairActions = <String>[];
    final recordCounts = <String, int>{};
    final linkCounts = <String, int>{};
    for (final entry in after.entries) {
      recordCounts[entry.key] = entry.value;
      if (entry.key.contains('link') ||
          entry.key.contains('relation') ||
          entry.key.contains('reference')) {
        linkCounts[entry.key] = entry.value;
      }
      if (before[entry.key] != entry.value) {
        warnings.add(
          'record count changed for ${entry.key}: '
          '${before[entry.key] ?? 0} -> ${entry.value}',
        );
      }
    }

    final checksums = await _compareChecksums(sourceRoot, targetRoot);
    return MigrationDryRunReport(
      targetRoot: targetRoot,
      sourceSchemaVersion: sourceSchema,
      targetSchemaVersion:
          await ProjectDatabaseService().schemaVersion(
            targetPackage.databaseFile.path,
          ) ??
          -1,
      migrationLogs: logs,
      recordCounts: recordCounts,
      linkCounts: linkCounts,
      checksumResults: checksums,
      warnings: warnings,
      repairActions: repairActions,
    );
  }

  ProjectPackage _packageFrom(Directory root) => ProjectPackage(
    projectId: p.basename(root.path).replaceFirst('.voidproject', ''),
    root: root,
  );

  Future<void> _copyTree(Directory source, Directory target) async {
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      final relative = p.relative(entity.path, from: source.path);
      final destination = p.join(target.path, relative);
      if (entity is Directory) {
        await Directory(destination).create(recursive: true);
      } else if (entity is File) {
        await File(destination).parent.create(recursive: true);
        await entity.copy(destination);
      }
    }
  }

  Future<Map<String, int>> _snapshot(ProjectPackage package) async {
    final db = await ProjectDatabaseService().openReadOnly(
      package.databaseFile.path,
    );
    try {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .get();
      final result = <String, int>{};
      for (final row in rows) {
        final name = row.read<String>('name');
        final count = await db
            .customSelect('SELECT COUNT(*) AS count FROM "$name"')
            .getSingle();
        result[name] = count.read<int>('count');
      }
      await db.close();
      return result;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  Future<Map<String, String>> _compareChecksums(
    Directory source,
    Directory target,
  ) async {
    final results = <String, String>{};
    final sourceManifest = File(
      p.join(source.path, 'manifest', 'project.json'),
    );
    final targetManifest = File(
      p.join(target.path, 'manifest', 'project.json'),
    );
    final sourceHash = sha256
        .convert(await sourceManifest.readAsBytes())
        .toString();
    final targetHash = sha256
        .convert(await targetManifest.readAsBytes())
        .toString();
    results['manifest'] = sourceHash == targetHash ? 'MATCH' : 'MISMATCH';
    results['manifest_sha256'] = targetHash;
    return results;
  }
}
