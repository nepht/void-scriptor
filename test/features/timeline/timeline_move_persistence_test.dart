import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/timeline/application/create_timeline_service.dart';

void main() {
  test('timeline move clip timing survives close/reopen database', () async {
    final root = await Directory.systemTemp.createTemp('s145-timeline-move-');
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
    await storyService.addBeat(
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

    // Move clip timing
    final clip = (await timelineService.getClips(timelineId)).single;
    await timelineService.updateClipTiming(
      clip.id,
      startSeconds: 3,
      durationSeconds: 2,
    );

    // Verify moved before close
    expect((await timelineService.getClips(timelineId)).single.startSeconds, 3);
    expect(
      (await timelineService.getClips(timelineId)).single.durationSeconds,
      2,
    );

    // Close and reopen
    await first.close();
    final second = await databaseService.open(dbPath);
    addTearDown(second.close);
    final restarted = CreateTimelineService(database: second);

    // Verify moved timing persists
    final reopenedClip = (await restarted.getClips(timelineId)).single;
    expect(reopenedClip.startSeconds, 3);
    expect(reopenedClip.durationSeconds, 2);
    expect(second.schemaVersion, 59);
  });
}
