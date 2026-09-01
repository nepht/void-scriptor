import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

void main() {
  test('scene draft snapshots persist across database restart', () async {
    final root = await Directory.systemTemp.createTemp('novel-snapshot-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databaseService = ProjectDatabaseService();
    final dbPath = (await paths.database('project-1')).path;
    await databaseService.create(dbPath);
    final firstDatabase = await databaseService.open(dbPath);
    final storyService = CreateStoryService(
      database: firstDatabase,
      paths: paths,
    );
    final storyId = await storyService.createStory(
      projectId: 'project-1',
      title: 'Novel Snapshotted',
    );
    final chapterId = await storyService.createChapter(
      storyId: storyId,
      title: 'Bab Satu',
      chapterNumber: 1,
    );
    final sceneId = await storyService.createScene(
      storyId: storyId,
      chapterId: chapterId,
      title: 'Scene Pertama',
      sceneNumber: 1,
    );
    final repository = StoryRepositoryImpl(
      database: firstDatabase,
      projectId: 'project-1',
    );
    await repository.saveSceneDraft(sceneId, 'Draf asli sebelum snapshot.');
    final snapshotId = await repository.captureSceneDraftSnapshot(
      sceneId,
      label: 'checkpoint bab satu',
    );
    expect(snapshotId, isNotEmpty);

    await firstDatabase.close();
    final reopenedDatabase = await databaseService.open(dbPath);
    addTearDown(reopenedDatabase.close);
    final reopenedRepository = StoryRepositoryImpl(
      database: reopenedDatabase,
      projectId: 'project-1',
    );

    final snapshots = await reopenedRepository.getSceneDraftSnapshots(sceneId);
    expect(snapshots, hasLength(1));
    expect(snapshots.single.label, 'checkpoint bab satu');
    expect(snapshots.single.content, 'Draf asli sebelum snapshot.');
    expect(snapshots.single.kind, 'manual');
  });

  test(
    'snapshot restore backs up current draft and preserves original',
    () async {
      final root = await Directory.systemTemp.createTemp('novel-restore-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final databaseService = ProjectDatabaseService();
      final dbPath = (await paths.database('project-1')).path;
      await databaseService.create(dbPath);
      final database = await databaseService.open(dbPath);
      addTearDown(database.close);
      final storyService = CreateStoryService(database: database, paths: paths);
      final storyId = await storyService.createStory(
        projectId: 'project-1',
        title: 'Novel Restored',
      );
      final chapterId = await storyService.createChapter(
        storyId: storyId,
        title: 'Bab Satu',
        chapterNumber: 1,
      );
      final sceneId = await storyService.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Scene Pertama',
        sceneNumber: 1,
      );
      final repository = StoryRepositoryImpl(
        database: database,
        projectId: 'project-1',
      );
      await repository.saveSceneDraft(sceneId, 'Teks pertama.');
      final snapshotId = await repository.captureSceneDraftSnapshot(
        sceneId,
        label: 'titik aman',
      );
      await repository.saveSceneDraft(sceneId, 'Teks revisi berat.');

      final restored = await repository.restoreSceneDraftSnapshot(
        sceneId,
        snapshotId: snapshotId,
      );

      expect(restored, 'Teks pertama.');
      final draft = await repository.getSceneDraft(sceneId);
      expect(draft, 'Teks pertama.');
      final backups = await repository.getSceneDraftSnapshots(sceneId);
      final backupEntries = backups
          .where((s) => s.kind == 'restoreBackup')
          .toList();
      expect(backupEntries, hasLength(1));
      expect(backupEntries.single.content, 'Teks revisi berat.');
      final originals = await repository.getSceneDraftSnapshots(sceneId);
      expect(originals.where((s) => s.kind == 'manual'), hasLength(1));
    },
  );

  test('retention limit trims oldest snapshots', () async {
    final root = await Directory.systemTemp.createTemp('novel-retention-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databaseService = ProjectDatabaseService();
    final dbPath = (await paths.database('project-1')).path;
    await databaseService.create(dbPath);
    final database = await databaseService.open(dbPath);
    addTearDown(database.close);
    final storyService = CreateStoryService(database: database, paths: paths);
    final storyId = await storyService.createStory(
      projectId: 'project-1',
      title: 'Novel Retention',
    );
    final chapterId = await storyService.createChapter(
      storyId: storyId,
      title: 'Bab Satu',
      chapterNumber: 1,
    );
    final sceneId = await storyService.createScene(
      storyId: storyId,
      chapterId: chapterId,
      title: 'Scene Pertama',
      sceneNumber: 1,
    );
    final repository = StoryRepositoryImpl(
      database: database,
      projectId: 'project-1',
    );
    await repository.saveSceneDraft(sceneId, 'Draf untuk retensi.');
    await repository.setDraftSnapshotRetention(sceneId, maxSnapshots: 2);
    final first = await repository.captureSceneDraftSnapshot(
      sceneId,
      label: 'a',
    );
    final second = await repository.captureSceneDraftSnapshot(
      sceneId,
      label: 'b',
    );
    await repository.captureSceneDraftSnapshot(sceneId, label: 'c');

    final snapshots = await repository.getSceneDraftSnapshots(sceneId);
    expect(snapshots.map((s) => s.label), ['b', 'c']);
    final stillThere = await repository.getSceneDraftSnapshots(
      sceneId,
      snapshotId: second,
    );
    expect(stillThere, hasLength(1));
    final trimmed = await repository.getSceneDraftSnapshots(
      sceneId,
      snapshotId: first,
    );
    expect(trimmed, isEmpty);
  });
}
