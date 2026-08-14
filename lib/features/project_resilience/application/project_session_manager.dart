import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/persistence/project_manifest.dart';
import '../../../core/project_package/project_package.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/project_database_service.dart';
import 'project_integrity_service.dart';
import 'project_recovery_services.dart';

enum ProjectOpenMode { readWrite, readOnly }

class ProjectSession {
  ProjectSession({
    required this.package,
    required this.manifest,
    required this.database,
    required this.mode,
    required this.openedAt,
    required this.lock,
  });

  final ProjectPackage package;
  final ProjectManifest manifest;
  final ProjectDatabase database;
  final ProjectOpenMode mode;
  final DateTime openedAt;
  final ProjectSessionLock lock;

  Future<void> save() async {
    if (mode == ProjectOpenMode.readOnly) {
      throw StateError('Read-only project sessions cannot be saved');
    }
    await database.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    final updated = ProjectManifest(
      schemaVersion: manifest.schemaVersion,
      id: manifest.id,
      name: manifest.name,
      description: manifest.description,
      projectVersion: manifest.projectVersion,
      createdAt: manifest.createdAt,
      updatedAt: DateTime.now().toUtc(),
      appVersion: manifest.appVersion,
      tags: manifest.tags,
      databaseFilename: manifest.databaseFilename,
    );
    await ProjectManifestWriter(package).write(updated);
  }

  Future<void> close() async {
    await database.close();
    await lock.release();
    if (await package.lockFile.exists()) {
      await package.lockFile.delete();
    }
  }
}

class ProjectSessionManager {
  Future<ProjectSession> open(
    ProjectPackage package, {
    ProjectOpenMode mode = ProjectOpenMode.readWrite,
  }) async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await package.manifestFile.readAsString())
          as Map<String, dynamic>,
    );
    if (manifest.id != package.projectId) {
      throw StateError('Project ID does not match package identity');
    }
    final lock = ProjectSessionLock(package);
    if (mode == ProjectOpenMode.readWrite) {
      await lock.acquire();
      await package.lockFile.writeAsString(
        jsonEncode({
          'sessionId': const Uuid().v4(),
          'projectId': package.projectId,
          'openedAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    }
    try {
      final database = await ProjectDatabaseService().open(
        package.databaseFile.path,
      );
      return ProjectSession(
        package: package,
        manifest: manifest,
        database: database,
        mode: mode,
        openedAt: DateTime.now().toUtc(),
        lock: lock,
      );
    } catch (_) {
      if (mode == ProjectOpenMode.readWrite) await lock.release();
      if (mode == ProjectOpenMode.readWrite &&
          await package.lockFile.exists()) {
        await package.lockFile.delete();
      }
      rethrow;
    }
  }

  Future<void> close(ProjectSession session) => session.close();
}
