import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/project_package/project_package.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/project_database_service.dart';
import 'project_integrity_service.dart';
import 'project_recovery_services.dart';

final class CorruptionRepairPreview {
  const CorruptionRepairPreview({
    required this.quarantinePaths,
    required this.reindex,
  });

  final List<String> quarantinePaths;
  final bool reindex;
}

final class CorruptionScanReport {
  const CorruptionScanReport({
    required this.schemaValid,
    required this.missingPaths,
    required this.orphanPaths,
    required this.indexSynchronized,
    required this.repairPreview,
  });

  final bool schemaValid;
  final List<String> missingPaths;
  final List<String> orphanPaths;
  final bool indexSynchronized;
  final CorruptionRepairPreview repairPreview;
}

final class CorruptionRecoveryResult {
  const CorruptionRecoveryResult({
    required this.backupDirectory,
    required this.recoveryLog,
  });

  final Directory backupDirectory;
  final File recoveryLog;
}

/// Scans a project without changing it, then applies only an explicit repair
/// preview after creating a complete pre-repair backup.
final class CorruptionDetectionRecoveryService {
  CorruptionDetectionRecoveryService(this.package);

  final ProjectPackage package;

  Future<CorruptionScanReport> scan({
    Set<String> referencedPaths = const {},
    File? indexFile,
  }) async {
    final integrity = await ProjectIntegrityService(package).scan(
      referencedPaths: referencedPaths,
      databaseHealthy: await _databaseHealthy(),
    );
    final normalizedReferences = referencedPaths.map(_normalize).toSet();
    final indexed = await _readIndex(indexFile);
    final indexSynchronized =
        indexFile == null || indexed == normalizedReferences;
    final orphanPaths = <String>[];
    if (await package.assetsDirectory.exists()) {
      await for (final entity in package.assetsDirectory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final relative = _relative(entity.path);
          if (!normalizedReferences.contains(relative)) {
            orphanPaths.add(relative);
          }
        }
      }
    }
    orphanPaths.sort();
    final missing =
        normalizedReferences
            .where((path) => !File(package.resolve(path)).existsSync())
            .toList()
          ..sort();
    return CorruptionScanReport(
      schemaValid: integrity.manifestValid && integrity.databaseValid,
      missingPaths: List.unmodifiable(missing),
      orphanPaths: List.unmodifiable(orphanPaths),
      indexSynchronized: indexSynchronized,
      repairPreview: CorruptionRepairPreview(
        quarantinePaths: List.unmodifiable(orphanPaths),
        reindex: !indexSynchronized,
      ),
    );
  }

  Future<CorruptionRecoveryResult> recover(
    CorruptionRepairPreview preview, {
    required Directory backupDestination,
    File? indexFile,
    Set<String> referencedPaths = const {},
  }) async {
    final backup = await ProjectBackupService().create(
      package: package,
      type: 'pre-corruption-repair',
      note: 'Backup before explicit corruption recovery',
      destinationRoot: backupDestination,
    );
    for (final relative in preview.quarantinePaths) {
      final source = File(package.resolve(relative));
      if (!await source.exists()) continue;
      final target = File(p.join(package.trashDirectory.path, relative));
      await target.parent.create(recursive: true);
      await source.rename(target.path);
    }
    if (preview.reindex && indexFile != null) {
      await indexFile.parent.create(recursive: true);
      final paths = referencedPaths.map(_normalize).toList()..sort();
      await indexFile.writeAsString(jsonEncode({'paths': paths}));
    }
    final log = File(p.join(package.recoveryDirectory.path, 'recovery.jsonl'));
    await log.parent.create(recursive: true);
    await log.writeAsString(
      '${jsonEncode({'type': 'corruption-recovery', 'backup': backup.path, 'quarantined': preview.quarantinePaths, 'reindexed': preview.reindex})}\n',
      mode: FileMode.append,
    );
    return CorruptionRecoveryResult(backupDirectory: backup, recoveryLog: log);
  }

  Future<bool> _databaseHealthy() async {
    try {
      final version = await ProjectDatabaseService().schemaVersion(
        package.databaseFile.path,
      );
      return version != null && version <= ProjectDatabase.currentSchemaVersion;
    } on Object {
      return false;
    }
  }

  Future<Set<String>> _readIndex(File? indexFile) async {
    if (indexFile == null || !await indexFile.exists()) return const {};
    try {
      final decoded = jsonDecode(await indexFile.readAsString());
      final paths = decoded is Map<String, dynamic> ? decoded['paths'] : null;
      if (paths is List) {
        return paths.whereType<String>().map(_normalize).toSet();
      }
    } on Object {
      // A malformed index is simply reported as out of sync.
    }
    return const {};
  }

  String _relative(String path) =>
      p.relative(path, from: package.root.path).replaceAll('\\', '/');

  String _normalize(String path) => path.replaceAll('\\', '/');
}
