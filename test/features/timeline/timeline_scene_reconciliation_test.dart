import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/timeline/application/create_timeline_service.dart';

void main() {
  test(
    'existing scene timeline imports new beats idempotently without overwriting user timing',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'scene-timeline-sync-',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final paths = ProjectPaths(rootDirectory: root);
      final databasePath = (await paths.database('project-1')).path;
      await ProjectDatabaseService().create(databasePath);
      final database = await ProjectDatabaseService().open(databasePath);
      addTearDown(database.close);
      final story = CreateStoryService(database: database, paths: paths);
      final storyId = await story.createStory(
        projectId: 'project-1',
        title: 'Rise',
      );
      final chapterId = await story.createChapter(
        storyId: storyId,
        title: 'Arrival',
        chapterNumber: 1,
      );
      final sceneId = await story.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Landing',
        sceneNumber: 1,
        estimatedDurationSeconds: 20,
      );
      final firstBeatId = await story.addBeat(
        sceneId: sceneId,
        content: 'Descend',
        beatType: 'action',
        startSecond: 0,
        durationSeconds: 2,
      );
      final timelines = CreateTimelineService(database: database);
      final timelineId = await timelines.ensureTimelineForScene(
        projectId: 'project-1',
        sceneId: sceneId,
      );
      final firstClip = (await timelines.getClips(timelineId)).single;
      await timelines.updateClipTiming(
        firstClip.id,
        startSeconds: 7,
        durationSeconds: 4,
      );

      await (database.update(
        database.sceneBeats,
      )..where((row) => row.id.equals(firstBeatId))).write(
        const SceneBeatsCompanion(
          beatType: Value('dialogue'),
          content: Value('Speak the warning'),
        ),
      );
      final secondBeatId = await story.addBeat(
        sceneId: sceneId,
        content: 'Raise shield',
        beatType: 'action',
        startSecond: 3,
        durationSeconds: 2,
      );

      expect(
        await timelines.ensureTimelineForScene(
          projectId: 'project-1',
          sceneId: sceneId,
        ),
        timelineId,
      );
      await timelines.ensureTimelineForScene(
        projectId: 'project-1',
        sceneId: sceneId,
      );

      final reconciled = await timelines.getClips(timelineId);
      expect(reconciled, hasLength(2));
      final updatedFirst = reconciled.singleWhere(
        (clip) => clip.sourceId == firstBeatId,
      );
      expect(updatedFirst.label, 'Speak the warning');
      expect(updatedFirst.clipType, 'dialogue');
      expect(updatedFirst.startSeconds, 7);
      expect(updatedFirst.durationSeconds, 4);
      expect(
        reconciled.where((clip) => clip.sourceId == secondBeatId),
        hasLength(1),
      );

      await story.deleteBeat(secondBeatId);
      await timelines.ensureTimelineForScene(
        projectId: 'project-1',
        sceneId: sceneId,
      );
      final afterBeatDeletion = await timelines.getClips(timelineId);
      expect(
        afterBeatDeletion.where((clip) => clip.sourceId == secondBeatId),
        hasLength(1),
        reason:
            'Timeline edits must not be deleted implicitly with a scene beat.',
      );
    },
  );
}
