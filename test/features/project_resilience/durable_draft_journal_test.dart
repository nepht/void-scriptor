import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

void main() {
  test(
    'durable draft journal survives a simulated crash and replays unsaved content',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-s30-journal-');
      addTearDown(() => root.delete(recursive: true));
      final dir = Directory('${root.path}/novel-1');
      await dir.create(recursive: true);
      final journal = DurableDraftJournal(dir: dir);

      await journal.stage(sceneId: 'scene-a', content: 'Draf belum autosave.');

      // Simulasi crash: langsung buat instance baru tanpa flush/close.
      final recovered = DurableDraftJournal(dir: dir);
      final pending = await recovered.pendingEntries();

      expect(pending, hasLength(1));
      expect(pending.single.sceneId, 'scene-a');
      expect(pending.single.content, 'Draf belum autosave.');

      await recovered.acknowledge(pending.single.sceneId);
      expect(await recovered.pendingEntries(), isEmpty);
    },
  );

  test('durable draft journal is durable across close and reopen', () async {
    final root = await Directory.systemTemp.createTemp('hermes-s30-journal2-');
    addTearDown(() => root.delete(recursive: true));
    final dir = Directory('${root.path}/novel-2');
    await dir.create(recursive: true);
    final journal = DurableDraftJournal(dir: dir);

    await journal.stage(sceneId: 'scene-b', content: 'Isi draf 2');
    await journal.close();

    final reopened = DurableDraftJournal(dir: dir);
    final pending = await reopened.pendingEntries();
    expect(pending, hasLength(1));
    expect(pending.single.content, 'Isi draf 2');
  });

  test(
    'durable draft journal reject blank content and duplicate scene staging',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hermes-s30-journal3-',
      );
      addTearDown(() => root.delete(recursive: true));
      final dir = Directory('${root.path}/novel-3');
      await dir.create(recursive: true);
      final journal = DurableDraftJournal(dir: dir);

      expect(
        () => journal.stage(sceneId: 'scene-c', content: '   '),
        throwsArgumentError,
      );

      await journal.stage(sceneId: 'scene-c', content: 'versi 1');
      await journal.stage(sceneId: 'scene-c', content: 'versi 2');
      final pending = await journal.pendingEntries();
      expect(pending, hasLength(1));
      expect(pending.single.content, 'versi 2');
    },
  );
  test(
    'no silent loss: unsaved screen edit survives simulated crash',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-s30-journey-');
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
        title: 'Crash Recovery',
      );
      final chapterId = await storyService.createChapter(
        storyId: storyId,
        title: 'Bab',
        chapterNumber: 1,
      );
      final sceneId = await storyService.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Scene',
        sceneNumber: 1,
      );

      final journalDir = Directory('${root.path}/recovery/draft-journal');
      final journal = DurableDraftJournal(dir: journalDir);
      final repository = StoryRepositoryImpl(
        database: database,
        projectId: 'project-1',
      );

      // Pengguna mengetik TAPI autosave belum jalan (crash sebelum debounce).
      await journal.stage(
        sceneId: sceneId,
        content: 'Suntingan terakhir sebelum aplikasi mati paksa.',
      );
      // Jalur autosave normal belum pernah menyimpan scene ini.
      expect(await repository.getSceneDraft(sceneId), isNull);

      // Crash: tanpa close database pun, journal file sudah durable.
      final recoveredJournal = DurableDraftJournal(dir: journalDir);
      final pending = await recoveredJournal.pendingEntries();
      expect(pending, hasLength(1));
      expect(pending.single.sceneId, sceneId);
      expect(
        pending.single.content,
        'Suntingan terakhir sebelum aplikasi mati paksa.',
      );

      // Pemulihan yang dikendalikan pengguna: replay ke repository.
      for (final entry in pending) {
        await repository.saveSceneDraft(entry.sceneId, entry.content);
        await recoveredJournal.acknowledge(entry.sceneId);
      }
      expect(
        await repository.getSceneDraft(sceneId),
        'Suntingan terakhir sebelum aplikasi mati paksa.',
      );
      expect(await recoveredJournal.pendingEntries(), isEmpty);
    },
  );
}
