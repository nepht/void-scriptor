import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/commands/command_type_registry.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_mutation_runtime.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/timeline/application/create_timeline_service.dart';
import 'package:void_scriptor/features/timeline/application/move_timeline_clip_command.dart';

void main() {
  test('timeline drag is one durable undoable command', () async {
    final root = await Directory.systemTemp.createTemp('s25-timeline-command-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databaseService = ProjectDatabaseService();
    final dbPath = (await paths.database('project-1')).path;
    await databaseService.create(dbPath);
    final database = await databaseService.open(dbPath);
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
      estimatedDurationSeconds: 10,
    );
    await story.addBeat(
      sceneId: sceneId,
      content: 'Descend',
      startSecond: 0,
      durationSeconds: 2,
    );
    final timeline = CreateTimelineService(database: database);
    final timelineId = await timeline.ensureTimelineForScene(
      projectId: 'project-1',
      sceneId: sceneId,
    );
    final clip = (await timeline.getClips(timelineId)).single;
    final runtime = await ProjectMutationRuntime.open(
      database: database,
      projectId: 'project-1',
    );
    await runtime.bus.execute(
      MoveTimelineClipCommand(
        id: 'move-1',
        projectId: 'project-1',
        timelineService: timeline,
        clipId: clip.id,
        oldStartSeconds: 0,
        newStartSeconds: 3,
        durationSeconds: 2,
      ),
    );
    expect((await timeline.getClips(timelineId)).single.startSeconds, 3);
    expect(await runtime.historyRepository.list('project-1'), hasLength(1));
    await runtime.bus.undo();
    expect((await timeline.getClips(timelineId)).single.startSeconds, 0);
    await runtime.bus.redo();
    expect((await timeline.getClips(timelineId)).single.startSeconds, 3);

    final registry = CommandTypeRegistry()
      ..register('timeline.clip.move', (record) {
        return MoveTimelineClipCommand.fromRecord(record, timeline);
      });
    final reopened = await ProjectMutationRuntime.open(
      database: database,
      projectId: 'project-1',
      registry: registry,
    );
    expect(reopened.bus.canUndo, isTrue);
  });
}
