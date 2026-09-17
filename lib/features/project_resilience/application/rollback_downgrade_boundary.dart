import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/project_package/project_package.dart';
import '../../../database/project/project_database.dart';
import 'project_backup_restore_preview.dart';

/// Documented boundary of what rollback can and cannot do (step 112.29).
final class RollbackDowngradeBoundaryReport {
  const RollbackDowngradeBoundaryReport({
    required this.rollbackAllowed,
    required this.rollbackVerified,
    required this.downgradeBlocked,
    required this.rollbackProbeManifestFile,
    required this.safeExportFile,
    required this.downgradeLimits,
    required this.userWarnings,
    required this.supportProcedure,
  });

  final bool rollbackAllowed;
  final bool rollbackVerified;
  final bool downgradeBlocked;
  final File rollbackProbeManifestFile;
  final File safeExportFile;
  final List<String> downgradeLimits;
  final List<String> userWarnings;
  final List<String> supportProcedure;

  List<String> get warnings => userWarnings;
}

/// Evaluates rollback/downgrade behavior for a backup against the live
/// application schema without mutating the live package:
/// a current-schema backup is rolled back into a probe package under a
/// disposable root (never over the live files), a newer-schema backup is
/// blocked from rollback/downgrade while the safe export path stays
/// available, and a downgrade-safe export is always produced from the
/// backup payload.
final class RollbackDowngradeBoundaryService {
  Future<RollbackDowngradeBoundaryReport> evaluate({
    required ProjectPackage package,
    required Directory backup,
    required Directory rollbackProbeRoot,
    required Directory exportDestination,
  }) async {
    final preview = await ProjectBackupRestorePreview.compute(
      package: package,
      backup: backup,
    );
    final warnings = List.of(preview.warnings);
    const appSchema = ProjectDatabase.currentSchemaVersion;

    final rollbackAllowed =
        preview.compatibility != RestoreCompatibility.blocked;
    final downgradeBlocked =
        preview.backupSchemaVersion != null &&
        preview.backupSchemaVersion! > appSchema;

    // Downgrade-safe export: archive the backup payload (manifest + database
    // + assets) with a checksum so a newer application can produce a portable
    // copy without ever writing into the live package.
    final exportFile = await _writeSafeExport(
      backup: backup,
      destinationRoot: exportDestination,
      schemaVersion: preview.backupSchemaVersion,
      warnings: warnings,
    );

    ProjectPackage? probePackage;
    if (rollbackAllowed) {
      probePackage =
          await ProjectBackupRestorePreview.restoreToAlternateDestination(
            backup: backup,
            destinationRoot: rollbackProbeRoot,
          );
    }

    final manifestFile = probePackage == null
        ? File(p.join(rollbackProbeRoot.path, 'absent', 'project.json'))
        : probePackage.manifestFile;

    return RollbackDowngradeBoundaryReport(
      rollbackAllowed: rollbackAllowed,
      rollbackVerified: probePackage != null && manifestFile.existsSync(),
      downgradeBlocked: downgradeBlocked,
      rollbackProbeManifestFile: manifestFile,
      safeExportFile: exportFile,
      downgradeLimits: const [
        'Downgrade is never performed in place: opening a database with a '
            'newer user_version than the application would rewrite newer '
            'schema data, so production open refuses it.',
        'Rollback restores a backup only into a separate probe/restore '
            'package; the live package files are never overwritten by this '
            'evaluation.',
        'A database newer than the application cannot be rolled back by '
            'downgrading; the supported path is exporting the content and '
            'upgrading the application.',
        'Older-schema backups roll forward through the production migration '
            'path on open; forward migration is one-way and not undone.',
        'The safe export carries manifest and database payload plus media '
            'assets, but it is not a settings preset; settings travel only '
            'inside the project manifest.',
      ],
      userWarnings: List.unmodifiable(warnings),
      supportProcedure: const [
        'Close the application before touching any package or backup file.',
        'Identify the backup schema version recorded in the backup metadata '
            'before attempting any restore.',
        'Never hand-edit project.db or manifest/project.json; use the '
            'in-app restore preview to inspect compatibility first.',
        'For a newer-schema backup, run the safe export instead of a '
            'rollback, then upgrade the application before restoring.',
        'If a rollback was interrupted, restore the emergency pre-restore '
            'backup created by the restore flow before retrying.',
        'When the package still refuses to open after these steps, copy the '
            'whole package directory and contact support with the intact '
            'copy; do not attempt manual SQLite repair.',
      ],
    );
  }

  Future<File> _writeSafeExport({
    required Directory backup,
    required Directory destinationRoot,
    required int? schemaVersion,
    required List<String> warnings,
  }) async {
    final manifestFile = File(p.join(backup.path, 'project.json'));
    final databaseFile = File(p.join(backup.path, 'project.db'));
    final assets = Directory(p.join(backup.path, 'assets'));
    if (!await manifestFile.exists() || !await databaseFile.exists()) {
      throw StateError('Backup is incomplete: manifest or database missing');
    }
    await destinationRoot.create(recursive: true);
    final exportFile = File(
      p.join(destinationRoot.path, 'downgrade-safe-export.json'),
    );
    final payload = <String, dynamic>{
      'format': 'voidscriptor-downgrade-safe-export',
      'format_version': 1,
      'source_schema_version': schemaVersion,
      'application_schema_version': ProjectDatabase.currentSchemaVersion,
      'warnings': warnings,
      'files': <String, String>{
        'manifest/project.json': await manifestFile.readAsString(),
        'database/project.db': base64Encode(await databaseFile.readAsBytes()),
        if (await assets.exists())
          'assets': jsonEncode(await _assetPayload(assets)),
      },
    };
    await exportFile.writeAsString(jsonEncode(payload));
    return exportFile;
  }

  Future<Map<String, String>> _assetPayload(Directory directory) async {
    final entries = <File>[];
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) entries.add(entity);
    }
    entries.sort((a, b) => a.path.compareTo(b.path));
    return {
      for (final file in entries)
        p.relative(file.path, from: directory.path).replaceAll('\\', '/'):
            base64Encode(await file.readAsBytes()),
    };
  }
}

/// Minimal package view over a directory so the existing restore preview can
/// classify a backup against the live package without opening the database.
class ProjectPackageLite {
  const ProjectPackageLite(this.root);

  final Directory root;

  File get manifestFile => File(p.join(root.path, 'manifest', 'project.json'));

  File get databaseFile => File(p.join(root.path, 'database', 'project.db'));
}
