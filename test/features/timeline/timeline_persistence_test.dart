import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/timeline/application/create_timeline_service.dart';

void main() {
  test('timeline is generated from scene beats and survives restart', () async {
    final root = await Directory.systemTemp.createTemp('s16-timeline-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databaseService = ProjectDatabaseService();
    final dbPath = (await paths.database('project-1')).path;
    await databaseService.create(dbPath);
    final first = await databaseService.open(dbPath);
    final storyService = CreateStoryService(database: first, paths: paths);
    final storyId = await storyService.createStory(
      projectId: 'project-1',
      title: 'Rise',
    );
    final chapterId = await storyService.createChapter(
      storyId: storyId,
      title: 'Arrival',
      chapterNumber: 1,
    );
    final sceneId = await storyService.createScene(
      storyId: storyId,
      chapterId: chapterId,
      title: 'Landing',
      sceneNumber: 1,
      estimatedDurationSeconds: 10,
    );
    final beatId = await storyService.addBeat(
      sceneId: sceneId,
      content: 'Descend',
      startSecond: 0,
      durationSeconds: 2,
    );
    final timelineService = CreateTimelineService(database: first);
    final timelineId = await timelineService.ensureTimelineForScene(
      projectId: 'project-1',
      sceneId: sceneId,
    );
    final clips = await timelineService.getClips(timelineId);
    expect(clips.single.sourceId, beatId);
    expect(clips.single.startSeconds, 0);
    expect(clips.single.durationSeconds, 2);
    await first.close();
    final second = await databaseService.open(dbPath);
    addTearDown(second.close);
    final restarted = CreateTimelineService(database: second);
    expect((await restarted.getTracks(timelineId)).length, 8);
    expect((await restarted.getClips(timelineId)).single.label, 'Descend');
    expect(second.schemaVersion, 24);
  });
}
