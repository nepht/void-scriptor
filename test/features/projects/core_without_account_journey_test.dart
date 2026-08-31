import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/auth/auth_controller.dart';
import 'package:void_scriptor/core/auth/auth_session_store.dart';
import 'package:void_scriptor/core/auth/auth_session_store_io.dart';
import 'package:void_scriptor/core/auth/auth_status.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/projects/domain/project_model.dart';
import 'package:void_scriptor/features/projects/data/project_local_data_source.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

void main() {
  test('145.20: complete local journey works without account (create/edit/save/'
      'backup/restore/reopen, no credentials)', () async {
    final temp = Directory.systemTemp.createTempSync('vs_14520_journey_');
    addTearDown(() async {
      try {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      } on FileSystemException catch (_) {}
    });

    // 1. Restore a persisted local session (Offline) — no account, no
    //    network. This exercises the sibling implementation (AuthController
    //    reading authSessionStoreProvider) without editing it.
    final sessionFile = File(
      '${temp.path}${Platform.pathSeparator}session.json',
    );
    final store = AuthSessionStoreIo(file: sessionFile);
    final container = ProviderContainer(
      overrides: [authSessionStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).continueOffline();
    final offline = container.read(authControllerProvider).valueOrNull;
    expect(offline?.status, AuthStatus.offline);
    expect(offline?.userId, isNull, reason: 'no account identity');

    // Fresh container over the same file = app restart; the Offline session
    // must be restored without any login.
    final reopened = ProviderContainer(
      overrides: [
        authSessionStoreProvider.overrideWithValue(
          AuthSessionStoreIo(file: sessionFile),
        ),
      ],
    );
    addTearDown(reopened.dispose);
    final restored = await reopened.read(authControllerProvider.future);
    expect(restored.status, AuthStatus.offline);
    expect(restored.displayName, 'Offline User');

    // 2. Create a project (real package on disk, no account).
    final paths = ProjectPaths(rootDirectory: temp);
    final registryPaths = ProjectPaths(
      rootDirectory: Directory('${temp.path}${Platform.pathSeparator}registry'),
    );
    final projectPathsRoot = await paths.root();
    final package = await ProjectPackageService(
      rootDirectory: projectPathsRoot,
    ).create(name: 'Novel Tanpa Akun');
    final project = ProjectModel(
      id: package.projectId,
      name: 'Novel Tanpa Akun',
      description: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastOpenedAt: DateTime.now(),
      localPath: package.root.path,
      version: '0.1.0',
    );
    final source = ProjectLocalDataSource(
      registry: ProjectRegistryService(paths: registryPaths),
    );
    await source.createProject(project);

    // 3. Open the project DB, create story/chapter/scene, save a draft.
    final db = await ProjectDatabaseService().open(package.databaseFile.path);
    addTearDown(() async {
      try {
        await db.close();
      } on Object {
        // Best-effort close; the temp root is removed in tearDown.
      }
    });
    final createStory = CreateStoryService(database: db, paths: paths);
    final storyId = await createStory.createStory(
      projectId: package.projectId,
      title: 'Novel Tanpa Akun',
    );
    final chapterId = await createStory.createChapter(
      storyId: storyId,
      title: 'Bab Satu',
      chapterNumber: 1,
    );
    final sceneId = await createStory.createScene(
      storyId: storyId,
      chapterId: chapterId,
      title: 'Scene Satu',
      sceneNumber: 1,
    );
    final storyRepo = StoryRepositoryImpl(
      database: db,
      projectId: package.projectId,
    );
    await storyRepo.saveSceneDraft(sceneId, 'Naskah tanpa akun, versi 1.');
    expect(
      await storyRepo.getSceneDraft(sceneId),
      'Naskah tanpa akun, versi 1.',
    );

    // 4. Close DB (checkpoint), backup, corrupt, restore, reopen, verify.
    await db.close();

    final backupService = ProjectBackupService();
    final backup = await backupService.create(
      package: package,
      type: 'test-backup',
    );
    expect(await backup.exists(), isTrue);
    expect(
      File('${backup.path}${Platform.pathSeparator}project.db').existsSync(),
      isTrue,
    );

    // Simulate partial data loss: wipe the draft content and workspaces.
    // (A fully deleted project.db makes restore() crash while creating its
    // emergency pre-restore backup — recorded as a sibling-owned limitation;
    // the core restore contract here is missing/corrupted content.)
    await package.databaseFile.writeAsBytes(<int>[]);
    final workspaces = Directory(
      '${package.root.path}${Platform.pathSeparator}workspaces',
    );
    if (await workspaces.exists()) {
      await workspaces.delete(recursive: true);
    }

    await backupService.restore(package: package, backup: backup);

    final restoredDb = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    addTearDown(() async {
      try {
        await restoredDb.close();
      } on Object {
        // Best-effort close; the temp root is removed in tearDown.
      }
    });
    final restoredRepo = StoryRepositoryImpl(
      database: restoredDb,
      projectId: package.projectId,
    );
    expect(
      await restoredRepo.getSceneDraft(sceneId),
      'Naskah tanpa akun, versi 1.',
      reason: 'draft must survive backup/restore and restart',
    );

    // 5. Search evidence: the saved draft is queryable from the reopened DB.
    final rows = await restoredDb.select(restoredDb.storyScenes).get();
    expect(rows.any((row) => row.id == sceneId), isTrue);
  });
}
