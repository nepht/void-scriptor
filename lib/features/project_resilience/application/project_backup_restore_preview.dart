import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/project_package/project_package.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/project_database_service.dart';

/// Compatibility classification for restoring a backup snapshot.
enum RestoreCompatibility {
  /// Backup schema equals the live application schema.
  current,

  /// Backup schema is older; opening will run forward migrations.
  migrationForward,

  /// Backup schema is newer than the application; restore must be blocked.
  blocked,
}

/// Read-only report describing what a backup restore would change.
class RestorePreviewReport {
  const RestorePreviewReport({
    required this.backupId,
    required this.currentName,
    required this.backupName,
    required this.currentSchemaVersion,
    required this.backupSchemaVersion,
    required this.compatibility,
    required this.warnings,
  });

  final String backupId;
  final String? currentName;
  final String? backupName;
  final int? currentSchemaVersion;
  final int? backupSchemaVersion;
  final RestoreCompatibility compatibility;
  final List<String> warnings;
}

/// Restore preview and alternate-destination restore for local backups.
///
/// Reads backup metadata without mutating the live project; the alternate
/// destination restore copies the snapshot into a brand-new package so the
/// user can inspect a backup without overwriting the current project.
class ProjectBackupRestorePreview {
  const ProjectBackupRestorePreview._();

  static Future<String?> _readManifestName(File manifestFile) async {
    if (!await manifestFile.exists()) return null;
    try {
      final decoded = jsonDecode(await manifestFile.readAsString());
      if (decoded is Map<String, dynamic> && decoded['name'] is String) {
        return decoded['name'] as String;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static Future<RestorePreviewReport> compute({
    required ProjectPackage package,
    required Directory backup,
  }) async {
    final manifestFile = File(p.join(backup.path, 'project.json'));
    final databaseFile = File(p.join(backup.path, 'project.db'));
    if (!await manifestFile.exists() || !await databaseFile.exists()) {
      throw StateError('Backup is incomplete: manifest or database missing');
    }
    final warnings = <String>[];
    final backupName = await _readManifestName(manifestFile);
    if (backupName == null) {
      warnings.add('Backup manifest has no readable project name.');
    }
    final currentName = await _readManifestName(package.manifestFile);
    final backupSchemaVersion = await ProjectDatabaseService().schemaVersion(
      databaseFile.path,
    );
    if (backupSchemaVersion == null) {
      throw StateError('Backup database has no readable schema version');
    }
    final currentSchemaVersion = await ProjectDatabaseService().schemaVersion(
      package.databaseFile.path,
    );
    const appSchema = ProjectDatabase.currentSchemaVersion;
    final RestoreCompatibility compatibility;
    if (backupSchemaVersion > appSchema) {
      compatibility = RestoreCompatibility.blocked;
      warnings.add(
        'Backup schema $backupSchemaVersion is newer than application schema $appSchema.',
      );
    } else if (backupSchemaVersion < appSchema) {
      compatibility = RestoreCompatibility.migrationForward;
    } else {
      compatibility = RestoreCompatibility.current;
    }
    return RestorePreviewReport(
      backupId: p.basename(backup.path),
      currentName: currentName,
      backupName: backupName,
      currentSchemaVersion: currentSchemaVersion,
      backupSchemaVersion: backupSchemaVersion,
      compatibility: compatibility,
      warnings: warnings,
    );
  }

  /// Copies a backup into a brand-new package directory under
  /// [destinationRoot] with a fresh UUID, leaving the live package and the
  /// backup itself untouched. Newer-than-application backups are rejected;
  /// older schemas migrate forward on the next open, matching in-place
  /// restore semantics.
  static Future<ProjectPackage> restoreToAlternateDestination({
    required Directory backup,
    required Directory destinationRoot,
  }) async {
    final manifestFile = File(p.join(backup.path, 'project.json'));
    final databaseFile = File(p.join(backup.path, 'project.db'));
    if (!await manifestFile.exists() || !await databaseFile.exists()) {
      throw StateError('Backup is incomplete: manifest or database missing');
    }
    final backupSchemaVersion = await ProjectDatabaseService().schemaVersion(
      databaseFile.path,
    );
    const appSchema = ProjectDatabase.currentSchemaVersion;
    if (backupSchemaVersion != null && backupSchemaVersion > appSchema) {
      throw StateError(
        'Backup schema $backupSchemaVersion is newer than application schema $appSchema',
      );
    }
    final newId = const Uuid().v4();
    final target = Directory(
      p.join(destinationRoot.path, '$newId.voidproject'),
    );
    await target.create(recursive: true);
    try {
      for (final directory in [
        Directory(p.join(target.path, 'manifest')),
        Directory(p.join(target.path, 'database')),
        Directory(p.join(target.path, 'assets')),
        Directory(p.join(target.path, 'cache')),
        Directory(p.join(target.path, 'backups')),
        Directory(p.join(target.path, 'exports')),
        Directory(p.join(target.path, 'recovery')),
        Directory(p.join(target.path, 'trash')),
      ]) {
        await directory.create(recursive: true);
      }
      await File(
        p.join(target.path, 'manifest', 'project.json'),
      ).writeAsBytes(await manifestFile.readAsBytes());
      await File(
        p.join(target.path, 'database', 'project.db'),
      ).writeAsBytes(await databaseFile.readAsBytes());
      await _copySubdirectory(
        Directory(p.join(backup.path, 'assets')),
        Directory(p.join(target.path, 'assets')),
      );
      await _copySubdirectory(
        Directory(p.join(backup.path, 'workspaces')),
        Directory(p.join(target.path, 'workspaces')),
      );
    } catch (_) {
      if (await target.exists()) {
        await target.delete(recursive: true);
      }
      rethrow;
    }
    return ProjectPackage(projectId: newId, root: target);
  }

  static Future<void> _copySubdirectory(
    Directory source,
    Directory target,
  ) async {
    if (!await source.exists()) return;
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final destination = p.join(target.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copySubdirectory(entity, Directory(destination));
      } else if (entity is File) {
        await entity.copy(destination);
      }
    }
  }
}
