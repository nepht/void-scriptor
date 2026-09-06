import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/commands/command_type_registry.dart';
import '../../../core/jobs/background_job.dart';
import '../../../core/jobs/background_job_queue.dart';
import '../../../core/performance/performance_runtime.dart';
import '../../../core/persistence/project_manifest.dart';
import '../../../core/persistence/project_paths.dart';
import '../../../core/project_package/project_package.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/project_database_service.dart';
import '../../character/application/rename_character_command.dart';
import '../../character/application/update_character_command.dart';
import '../../character/application/update_character_identity_command.dart';
import '../../character/data/character_repository_impl.dart';
import '../../timeline/application/create_timeline_service.dart';
import '../../timeline/application/move_timeline_clip_command.dart';
import '../../relations/application/relation_command.dart';
import '../../relations/data/relation_repository_impl.dart';
import 'project_integrity_service.dart';
import 'project_mutation_runtime.dart';
import 'project_version_control_service.dart';
import 'project_recovery_services.dart';

enum ProjectOpenMode { readWrite, readOnly }

typedef ProjectSchemaVersionReader = Future<int?> Function(String databasePath);

class ProjectSession {
  ProjectSession({
    required this.package,
    required this.manifest,
    required this.database,
    required this.mode,
    required this.openedAt,
    required this.lock,
    required this.mutationRuntime,
    required this.versionControl,
    required this.jobs,
    required this.openMetrics,
  });

  final ProjectPackage package;
  final ProjectManifest manifest;
  final ProjectDatabase database;
  final ProjectOpenMode mode;
  final DateTime openedAt;
  final ProjectSessionLock lock;
  final ProjectMutationRuntime mutationRuntime;
  final ProjectVersionControlService versionControl;
  final BackgroundJobQueue jobs;
  final PerformanceMetrics openMetrics;

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
    await mutationRuntime.markSaved();
  }

  Future<void> close() async {
    await mutationRuntime.dispose();
    for (final task in jobs.jobs) {
      if (task.persistence == JobPersistence.transient) {
        await jobs.cancel(task.id);
      }
    }
    await jobs.dispose();
    await database.close();
    await lock.release();
    if (await package.lockFile.exists()) {
      await package.lockFile.delete();
    }
  }
}

class ProjectSessionManager {
  ProjectSessionManager({ProjectSchemaVersionReader? schemaVersionReader})
    : _schemaVersionReader =
          schemaVersionReader ?? ProjectDatabaseService().schemaVersion;

  final ProjectSchemaVersionReader _schemaVersionReader;

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
    final metrics = PerformanceMetrics();
    final manifestStarted = DateTime.now();
    metrics.record(
      'manifest',
      Duration(
        milliseconds: DateTime.now().difference(manifestStarted).inMilliseconds,
      ),
    );
    final lock = ProjectSessionLock(package);
    ProjectDatabase? database;
    var companionWritten = false;
    try {
      if (mode == ProjectOpenMode.readWrite) {
        await lock.acquire();
        await package.lockFile.writeAsString(
          jsonEncode({
            'sessionId': const Uuid().v4(),
            'projectId': package.projectId,
            'openedAt': DateTime.now().toUtc().toIso8601String(),
          }),
        );
        companionWritten = true;
      }
      final existingVersion = await _schemaVersionReader(
        package.databaseFile.path,
      );
      if (mode == ProjectOpenMode.readOnly &&
          existingVersion != null &&
          existingVersion < ProjectDatabase.currentSchemaVersion) {
        throw StateError(
          'Read-only open cannot migrate database v$existingVersion',
        );
      }
      if (mode == ProjectOpenMode.readWrite &&
          existingVersion != null &&
          existingVersion < ProjectDatabase.currentSchemaVersion) {
        await ProjectBackupService().create(
          package: package,
          type: 'pre-migration',
          note:
              'Automatic backup before database migration '
              'v$existingVersion → v${ProjectDatabase.currentSchemaVersion}',
        );
      }
      final databaseService = ProjectDatabaseService();
      final databaseStarted = DateTime.now();
      database = mode == ProjectOpenMode.readOnly
          ? await databaseService.openReadOnly(package.databaseFile.path)
          : await databaseService.open(package.databaseFile.path);
      metrics.record(
        'database',
        Duration(
          milliseconds: DateTime.now()
              .difference(databaseStarted)
              .inMilliseconds,
        ),
      );
      final characterRepository = CharacterRepositoryImpl(
        database: database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      final timelineService = CreateTimelineService(database: database);
      final relationRepository = RelationRepositoryImpl(database: database);
      final commandRegistry = CommandTypeRegistry()
        ..register('character.rename', (record) {
          return RenameCharacterCommand(
            id: record.id,
            projectId: record.projectId,
            repository: characterRepository,
            characterId: record.payload['characterId']! as String,
            oldName: record.payload['oldName']! as String,
            newName: record.payload['newName']! as String,
          );
        })
        ..register('character.update', (record) {
          return UpdateCharacterCommand(
            id: record.id,
            projectId: record.projectId,
            repository: characterRepository,
            oldValue: characterFromData(
              Map<String, Object?>.from(record.payload['old']! as Map),
            ),
            newValue: characterFromData(
              Map<String, Object?>.from(record.payload['new']! as Map),
            ),
            label: record.label,
          );
        })
        ..register('character.identity.update', (record) {
          return UpdateCharacterIdentityCommand(
            id: record.id,
            projectId: record.projectId,
            repository: characterRepository,
            oldValue: characterIdentityFromData(
              Map<String, Object?>.from(record.payload['old']! as Map),
            ),
            newValue: characterIdentityFromData(
              Map<String, Object?>.from(record.payload['new']! as Map),
            ),
          );
        })
        ..register('timeline.clip.move', (record) {
          return MoveTimelineClipCommand.fromRecord(record, timelineService);
        })
        ..register('relation.create', (record) {
          return RelationCommand.fromRecord(record, relationRepository);
        })
        ..register('relation.delete', (record) {
          return RelationCommand.fromRecord(record, relationRepository);
        });
      final mutationRuntime = await ProjectMutationRuntime.open(
        database: database,
        projectId: package.projectId,
        readOnly: mode == ProjectOpenMode.readOnly,
        registry: commandRegistry,
      );
      return ProjectSession(
        package: package,
        manifest: manifest,
        database: database,
        mode: mode,
        openedAt: DateTime.now().toUtc(),
        lock: lock,
        mutationRuntime: mutationRuntime,
        versionControl: ProjectVersionControlService(package),
        jobs: BackgroundJobQueue(),
        openMetrics: metrics,
      );
    } catch (_) {
      if (mode == ProjectOpenMode.readWrite) await lock.release();
      if (mode == ProjectOpenMode.readWrite &&
          companionWritten &&
          await package.lockFile.exists()) {
        await package.lockFile.delete();
      }
      // Ensure database is closed if it was partially opened
      try {
        if (database != null) await database.close();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> close(ProjectSession session) => session.close();
}
