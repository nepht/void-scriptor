import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/security/application/project_lock_service.dart';
import '../../../core/security/crypto/encryption_cipher.dart';
import '../../../core/security/crypto/key_derivation.dart';
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
import '../../workspaces/application/novel_character_link_repository.dart';
import '../../workspaces/application/authorized_workspace_projection_reader.dart';
import '../../workspaces/application/workspace_permission_policy.dart';
import '../../workspaces/application/workspace_file_namespace.dart';
import '../../workspaces/application/workspace_character_deletion_service.dart';
import '../../workspaces/application/workspace_projection_cache.dart';
import '../../relations/application/relation_command.dart';
import '../../relations/data/relation_repository_impl.dart';
import 'project_integrity_service.dart';
import 'project_mutation_runtime.dart';
import 'project_version_control_service.dart';
import 'project_recovery_services.dart';

enum ProjectOpenMode { readWrite, readOnly }

typedef ProjectSchemaVersionReader = Future<int?> Function(String databasePath);

/// Thrown when [ProjectSessionManager.open] refuses to open a project whose
/// persisted passphrase lock is currently engaged. The caller (UI) should
/// prompt for the passphrase and retry; the partial session it started is
/// fully torn down before this propagates.
class ProjectLockedException implements Exception {
  ProjectLockedException(this.projectId);

  final String projectId;

  @override
  String toString() => 'ProjectLockedException(projectId: $projectId)';
}

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
    required this.novelCharacterLinks,
    required this.workspaceFiles,
    required this.workspaceProjections,
    required this.workspaceProjectionReader,
    required this.characterDeletion,
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
  final NovelCharacterLinkRepository novelCharacterLinks;
  final WorkspaceFileNamespace workspaceFiles;
  final WorkspaceProjectionCache workspaceProjections;
  final AuthorizedWorkspaceProjectionReader workspaceProjectionReader;
  final WorkspaceCharacterDeletionService characterDeletion;

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

  Future<void>? _closing;
  // run199 BUG-5: per-step completion flags. A mid-teardown failure must not
  // skip the remaining steps (a blocked session-marker release used to leave
  // the companion .project.lock behind) and must not replay already-finished
  // steps on a retry (double dispose throws). close() clears the memoized
  // future when a step fails so a later close() completes what is left.
  bool _projectionsCleared = false;
  bool _mutationRuntimeDisposed = false;
  bool _jobsDisposed = false;
  bool _databaseClosed = false;
  bool _lockReleased = false;

  // All callers share shutdown, including its failure; disposed resources must
  // never be disposed again by a concurrent exit or provider teardown.
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    Object? failure;
    void record(Object error) {
      // Keep the FIRST ORIGINAL error: the fail-closed type (e.g.
      // FileSystemException from lock.release) is part of the release
      // contract; later steps still run best-effort.
      failure ??= error;
    }

    if (!_projectionsCleared) {
      try {
        workspaceProjections.clear();
        _projectionsCleared = true;
      } on Object catch (e) {
        record(e);
      }
    }
    if (!_mutationRuntimeDisposed) {
      try {
        await mutationRuntime.dispose();
        _mutationRuntimeDisposed = true;
      } on Object catch (e) {
        record(e);
      }
    }
    if (!_jobsDisposed) {
      try {
        for (final task in jobs.jobs) {
          if (task.persistence == JobPersistence.transient) {
            await jobs.cancel(task.id);
          }
        }
        await jobs.dispose();
        _jobsDisposed = true;
      } on Object catch (e) {
        record(e);
      }
    }
    if (!_databaseClosed) {
      try {
        await database.close();
        _databaseClosed = true;
      } on Object catch (e) {
        record(e);
      }
    }
    if (mode == ProjectOpenMode.readWrite) {
      if (!_lockReleased) {
        try {
          await lock.release();
          _lockReleased = true;
        } on Object catch (e) {
          // Fail-closed release keeps its error, but the companion cleanup
          // below must still run instead of being skipped (BUG-5).
          record(e);
        }
      }
      try {
        if (await package.lockFile.exists()) {
          await package.lockFile.delete();
        }
      } on Object catch (e) {
        record(e);
      }
    }
    if (failure != null) {
      // Let a later close() retry the steps that did not complete.
      _closing = null;
      throw failure!;
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
        // 145.42 interrupted restore: a previous restore killed mid-crash-
        // window leaves '<final>.tmp' staging artifacts inside the package.
        // The session lock proves no other writer holds this project, so
        // heal them before any payload is opened. A read-only open never
        // mutates the package.
        await RestoreCrashRecovery.recover(package);
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
      if (companionWritten &&
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
      // core-hunt-20260906 BUG-21: the persisted passphrase lock was never
      // consulted on any open path. Check it now that the database is
      // open (the security row lives in this database, so there is no
      // chicken-and-egg); a locked project is refused before any
      // repository/runtime is built on top of it. No row at all means no
      // passphrase was ever set — that is not a lock. The throw re-enters
      // the catch below, which releases the session lock, deletes the
      // write companion, and closes the database.
      final lockRow =
          await (database.select(database.securitySettings)
                ..where((row) => row.projectId.equals(package.projectId)))
              .getSingleOrNull();
      if (lockRow != null && lockRow.passphraseHash != null && lockRow.locked) {
        throw ProjectLockedException(package.projectId);
      }
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
      final novelCharacterLinks = NovelCharacterLinkRepository(
        database: database,
        projectId: package.projectId,
      );
      final workspaceProjections = WorkspaceProjectionCache(
        loader: (novelWorkspaceId) =>
            novelCharacterLinks.listForNovel(novelWorkspaceId),
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
        novelCharacterLinks: novelCharacterLinks,
        workspaceFiles: WorkspaceFileNamespace(package),
        workspaceProjections: workspaceProjections,
        workspaceProjectionReader: AuthorizedWorkspaceProjectionReader(
          cache: workspaceProjections,
          access: const WorkspaceAccess(isLocalProjectOwner: true),
        ),
        characterDeletion: WorkspaceCharacterDeletionService(
          links: novelCharacterLinks,
          projections: workspaceProjections,
          deleteCharacterSource: characterRepository.deleteCharacter,
        ),
      );
    } catch (error) {
      // run199 BUG-6 (hunt run197): each cleanup step is individually
      // guarded and the database close runs FIRST, so a throw from the
      // marker release or companion delete can neither skip the close nor
      // replace the original open error rethrown below.
      try {
        if (database != null) await database.close();
      } on Object catch (_) {
        // Secondary to the original error; previously swallowed as well.
      }
      if (mode == ProjectOpenMode.readWrite) {
        try {
          await lock.release();
        } on Object catch (_) {
          // release() is fail-closed by design; a transient errno-32 hold
          // must not mask the original open failure or strand cleanup
          // (same family as BUG-1/run198).
        }
        try {
          if (companionWritten && await package.lockFile.exists()) {
            await package.lockFile.delete();
          }
        } on Object catch (_) {
          // Best-effort: the original error still propagates.
        }
      }
      rethrow;
    }
  }

  /// Wiring sprint Task 2 (bug-hunt run197 BUG-12): implements the
  /// `ProjectLockedException` doc promise — prompt for the passphrase and
  /// retry. Opens the project database WITHOUT taking the write companion or
  /// session lock (a passphrase check must never strand lock state if it
  /// fails), verifies the passphrase through [ProjectLockService.unlock]
  /// (which flips the persisted lock flag on success), then closes the probe
  /// connection so [open] can proceed normally afterwards. Returns false on
  /// a wrong passphrase; open-path failures propagate as the typed
  /// classification exceptions the shell already renders.
  Future<bool> unlockProject(ProjectPackage package, String passphrase) async {
    // bug-hunt vs-hunt-20260911 BUG-1: the probe below opens the database
    // read-write, so drift migrates an old-schema database during this open
    // exactly as it would in [open]. Every other writer path creates the
    // pre-migration backup first (see the guarded branch in [open]); the
    // probe must not bypass that guard, or unlocking a locked project
    // silently rewrites it with no backup — and the later guarded open can
    // never create one because the version already equals current.
    final existingVersion = await _schemaVersionReader(
      package.databaseFile.path,
    );
    if (existingVersion != null &&
        existingVersion < ProjectDatabase.currentSchemaVersion) {
      await ProjectBackupService().create(
        package: package,
        type: 'pre-migration',
        note:
            'Automatic backup before database migration '
            'v$existingVersion → v${ProjectDatabase.currentSchemaVersion}',
      );
    }
    final database = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    try {
      final lockService = ProjectLockService(
        database: database,
        deriver: const Pbkdf2KeyDeriver(),
        integrity: const HmacIntegrity(),
      );
      return await lockService.unlock(package.projectId, passphrase);
    } finally {
      try {
        await database.close();
      } on Object catch (_) {
        // Secondary to the unlock outcome; mirrors the guarded-close
        // convention in [ProjectSession._close].
      }
    }
  }

  Future<void> close(ProjectSession session) => session.close();
}
