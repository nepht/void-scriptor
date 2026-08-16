import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/audio_timeline/application/audio_timeline_repository.dart';
import 'package:void_scriptor/features/audio_timeline/domain/audio_timeline_models.dart';

void main() {
  test('audio clip automation and music intent survive restart', () async {
    final root = await Directory.systemTemp.createTemp('audio-timeline-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    await (await paths.project('project-timeline')).create(recursive: true);
    final dbPath = (await paths.database('project-timeline')).path;
    final service = ProjectDatabaseService();
    final database = await service.open(dbPath);
    final repository = AudioTimelineRepository(database);

    await repository.saveClip(
      const AudioTimelineClipModel(
        id: 'audio-clip-1',
        timelineId: 'timeline-scene-8',
        trackType: AudioTrackType.music,
        audioFileId: 'audio-qowner-theme',
        startSeconds: 48,
        durationSeconds: 42,
        fadeInSeconds: 2,
        fadeOutSeconds: 4,
        gainDb: -3,
        pan: -0.2,
        intent: MusicIntent.continueTheme,
      ),
    );
    await repository.saveAutomation(const [
      AudioAutomationKeyframeModel(
        id: 'gain-0',
        clipId: 'audio-clip-1',
        timeSeconds: 0,
        parameter: 'gainDb',
        value: -12,
      ),
      AudioAutomationKeyframeModel(
        id: 'gain-1',
        clipId: 'audio-clip-1',
        timeSeconds: 6,
        parameter: 'gainDb',
        value: -3,
      ),
    ]);
    await database.close();

    final second = await service.open(dbPath);
    addTearDown(second.close);
    final restored = AudioTimelineRepository(second);
    expect(second.schemaVersion, 44);
    expect(
      (await restored.clipsForTimeline(
        'timeline-scene-8',
      )).single.fadeOutSeconds,
      4,
    );
    expect(
      (await restored.clipsForTimeline('timeline-scene-8')).single.intent,
      MusicIntent.continueTheme,
    );
    expect(
      (await restored.automationFor(
        'audio-clip-1',
      )).map((keyframe) => keyframe.value),
      [-12, -3],
    );
  });
}
