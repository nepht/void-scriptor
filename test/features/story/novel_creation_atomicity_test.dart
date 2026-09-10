import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';

/// hunt-run171 BUG-9 (Referee REAL BUG Medium): "Create Novel" chains three
/// sequential inserts (story → chapter → scene) across two call sites
/// (workspace_resolver onCreateNovel, explorer_panel createExplorerAsset)
/// with no rollback. A failure after `createStory` (realistic vector: any
/// SQLite write error, staged here with a RAISE(ABORT) trigger on
/// story_scenes INSERT) leaves an orphaned story row — retry duplicates the
/// novel with a fresh UUID because createExplorerAsset is freely
/// re-runnable.
///
/// Contract under test:
/// 1. The service exposes one atomic creation operation; when any step
///    fails, NO story/chapter/scene row survives.
/// 2. The filesystem story folder created by createStory is removed on
///    rollback (createStory already cleans its own folder on failure —
///    the chained op must not leave it behind either).
///
/// Scoped to a disposable temp database; the trigger lives only there.
void main() {
  Future<ProjectDatabase> openDb(String dir) async {
    final service = ProjectDatabaseService();
    final dbPath = '$dir/project.db';
    await service.create(dbPath);
    return service.open(dbPath);
  }

  /// Stages a REAL SQLite write failure exactly at scene INSERT time:
  /// the trigger aborts every INSERT on story_scenes while story/chapter
  /// inserts still work — the old un-transactional chain therefore
  /// committed story + chapter rows before dying.
  Future<void> injectSceneInsertFailure(ProjectDatabase db) async {
    await db.customStatement(
      'CREATE TRIGGER story_scene_insert_abort '
      'BEFORE INSERT ON story_scenes '
      'BEGIN SELECT RAISE(ABORT, \'injected scene insert failure\'); END',
    );
  }

  test(
    'atomic story creation rolls back every row when the scene insert fails',
    () async {
      final dir = await Directory.systemTemp.createTemp('void-story-atomic-');
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      });

      final db = await openDb(dir.path);
      addTearDown(db.close);

      final service = CreateStoryService(
        database: db,
        paths: ProjectPaths(rootDirectory: dir),
      );
      await injectSceneInsertFailure(db);

      await expectLater(
        service.createNovelWithFirstChapter(
          projectId: 'project-1',
          title: 'Void Cube Novel',
        ),
        throwsA(isA<Exception>()),
      );

      final stories = await db.select(db.stories).get();
      final chapters = await db.select(db.storyChapters).get();
      final scenes = await db.select(db.storyScenes).get();
      expect(stories, isEmpty, reason: 'BUG-9: no orphaned story row');
      expect(chapters, isEmpty, reason: 'BUG-9: no orphaned chapter row');
      expect(scenes, isEmpty);

      final storiesRoot = Directory(
        '${dir.path}/project-1.voidproject/assets/stories',
      );
      final leftoverStoryFolders = storiesRoot.existsSync()
          ? storiesRoot.listSync().whereType<Directory>().toList()
          : const <Directory>[];
      expect(
        leftoverStoryFolders,
        isEmpty,
        reason:
            'BUG-9: rollback must remove the story folder createStory made '
            '(an empty assets/stories parent is legitimate shared state)',
      );
    },
  );

  test(
    'atomic story creation succeeds end to end when no failure is injected',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'void-story-atomic-ok-',
      );
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      });

      final db = await openDb(dir.path);
      addTearDown(db.close);

      final service = CreateStoryService(
        database: db,
        paths: ProjectPaths(rootDirectory: dir),
      );

      final storyId = await service.createNovelWithFirstChapter(
        projectId: 'project-1',
        title: 'Naskah Pertama',
      );

      final stories = await db.select(db.stories).get();
      final chapters = await db.select(db.storyChapters).get();
      final scenes = await db.select(db.storyScenes).get();
      expect(stories, hasLength(1));
      expect(chapters, hasLength(1));
      expect(scenes, hasLength(1));
      expect(chapters.single.storyId, storyId);
      expect(scenes.single.storyId, storyId);
      expect(
        Directory(
          '${dir.path}/project-1.voidproject/assets/stories/$storyId',
        ).existsSync(),
        isTrue,
      );
    },
  );
}
