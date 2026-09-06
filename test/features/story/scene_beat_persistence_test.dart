import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';

void main() {
  test('scene beats can be reordered and deleted', () async {
    final root = await Directory.systemTemp.createTemp('s15-beats-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final path = (await paths.database('p')).path;
    final service = ProjectDatabaseService();
    await service.create(path);
    final db = await service.open(path);
    addTearDown(db.close);
    final story = CreateStoryService(database: db, paths: paths);
    final sid = await story.createStory(projectId: 'p', title: 'Story');
    final cid = await story.createChapter(
      storyId: sid,
      title: 'Chapter',
      chapterNumber: 1,
    );
    final scene = await story.createScene(
      storyId: sid,
      chapterId: cid,
      title: 'Scene',
      sceneNumber: 1,
    );
    final first = await story.addBeat(sceneId: scene, content: 'First');
    final second = await story.addBeat(sceneId: scene, content: 'Second');
    await story.reorderBeats(sceneId: scene, orderedIds: [second, first]);
    expect((await db.storyDao.getSceneBeats(scene)).map((b) => b.id).toList(), [
      second,
      first,
    ]);
    await story.deleteBeat(second);
    expect((await db.storyDao.getSceneBeats(scene)).map((b) => b.id).toList(), [
      first,
    ]);
  });

  test('scene beat order survives database restart', () async {
    final root = Directory(
      '${Directory.systemTemp.path}/s15-reorder-${DateTime.now().microsecondsSinceEpoch}',
    );
    await root.create(recursive: true);
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final path = (await paths.database('p')).path;
    final service = ProjectDatabaseService();
    await service.create(path);
    final firstDb = await service.open(path);
    final story = CreateStoryService(database: firstDb, paths: paths);
    final storyId = await story.createStory(projectId: 'p', title: 'Story');
    final chapterId = await story.createChapter(
      storyId: storyId,
      title: 'Chapter',
      chapterNumber: 1,
    );
    final sceneId = await story.createScene(
      storyId: storyId,
      chapterId: chapterId,
      title: 'Scene',
      sceneNumber: 1,
    );
    final first = await story.addBeat(sceneId: sceneId, content: 'First');
    final second = await story.addBeat(sceneId: sceneId, content: 'Second');
    await story.reorderBeats(sceneId: sceneId, orderedIds: [second, first]);
    await firstDb.close();

    final secondDb = await service.open(path);
    addTearDown(secondDb.close);
    final beats = await secondDb.storyDao.getSceneBeats(sceneId);
    expect(beats.map((beat) => beat.id).toList(), [second, first]);
  });
}
