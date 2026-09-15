import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../database/project/project_database.dart';
import '../domain/timeline_model.dart';

class CreateTimelineService {
  CreateTimelineService({required this.database});
  final ProjectDatabase database;
  static const _defaultTracks = [
    TimelineTrackType.character,
    TimelineTrackType.creature,
    TimelineTrackType.vehicle,
    TimelineTrackType.camera,
    TimelineTrackType.action,
    TimelineTrackType.dialogue,
    TimelineTrackType.prop,
    TimelineTrackType.vfx,
    TimelineTrackType.audio,
    TimelineTrackType.environment,
    TimelineTrackType.continuity,
  ];

  Future<String> ensureTimelineForScene({
    required String projectId,
    required String sceneId,
  }) async {
    final existing = await database.timelineDao.getTimelineForScene(sceneId);
    if (existing != null) {
      await _reconcileSceneBeats(timelineId: existing.id, sceneId: sceneId);
      return existing.id;
    }
    final scene = await database.storyDao.getScene(sceneId);
    if (scene == null) throw StateError('Scene not found');
    final timelineId = const Uuid().v4();
    final now = DateTime.now();
    await database.transaction(() async {
      await database
          .into(database.timelines)
          .insert(
            TimelinesCompanion.insert(
              id: timelineId,
              projectId: projectId,
              sceneId: sceneId,
              durationSeconds: scene.estimatedDurationSeconds ?? 10,
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (var index = 0; index < _defaultTracks.length; index++) {
        final type = _defaultTracks[index];
        await database
            .into(database.timelineTracks)
            .insert(
              TimelineTracksCompanion.insert(
                id: const Uuid().v4(),
                timelineId: timelineId,
                trackType: type.name,
                name: _label(type),
                sortOrder: Value(index),
              ),
            );
      }
      final actionTrack =
          await (database.select(database.timelineTracks)..where(
                (row) =>
                    row.timelineId.equals(timelineId) &
                    row.trackType.equals(TimelineTrackType.action.name),
              ))
              .getSingle();
      final beats = await database.storyDao.getSceneBeats(sceneId);
      for (var index = 0; index < beats.length; index++) {
        final beat = beats[index];
        await database
            .into(database.timelineClips)
            .insert(
              TimelineClipsCompanion.insert(
                id: const Uuid().v4(),
                timelineId: timelineId,
                trackId: actionTrack.id,
                clipType: beat.beatType,
                label: beat.content,
                startSeconds: beat.startSecond ?? 0,
                durationSeconds: beat.durationSeconds ?? 1,
                sourceId: Value(beat.id),
                sortOrder: Value(index),
              ),
            );
      }
    });
    return timelineId;
  }

  Future<void> _reconcileSceneBeats({
    required String timelineId,
    required String sceneId,
  }) async {
    await database.transaction(() async {
      final actionTrack =
          await (database.select(database.timelineTracks)..where(
                (row) =>
                    row.timelineId.equals(timelineId) &
                    row.trackType.equals(TimelineTrackType.action.name),
              ))
              .getSingle();
      final beats = await database.storyDao.getSceneBeats(sceneId);
      final clips = await database.timelineDao.getClips(timelineId);
      final clipsBySource = <String, TimelineClip>{
        for (final clip in clips)
          if (clip.sourceId != null) clip.sourceId!: clip,
      };

      for (var index = 0; index < beats.length; index++) {
        final beat = beats[index];
        final clip = clipsBySource[beat.id];
        if (clip == null) {
          await database
              .into(database.timelineClips)
              .insert(
                TimelineClipsCompanion.insert(
                  id: const Uuid().v4(),
                  timelineId: timelineId,
                  trackId: actionTrack.id,
                  clipType: beat.beatType,
                  label: beat.content,
                  startSeconds: beat.startSecond ?? 0,
                  durationSeconds: beat.durationSeconds ?? 1,
                  sourceId: Value(beat.id),
                  sortOrder: Value(index),
                ),
              );
          continue;
        }
        await (database.update(
          database.timelineClips,
        )..where((row) => row.id.equals(clip.id))).write(
          TimelineClipsCompanion(
            clipType: Value(beat.beatType),
            label: Value(beat.content),
            sortOrder: Value(index),
          ),
        );
      }
    });
  }

  Future<List<TimelineTrack>> getTracks(String timelineId) =>
      database.timelineDao.getTracks(timelineId);
  Future<List<TimelineClip>> getClips(String timelineId) =>
      database.timelineDao.getClips(timelineId);
  Future<void> updateClipTiming(
    String clipId, {
    required double startSeconds,
    required double durationSeconds,
  }) => database.timelineDao.updateClip(
    clipId,
    startSeconds: startSeconds,
    durationSeconds: durationSeconds,
  );
  static String _label(TimelineTrackType type) => switch (type) {
    TimelineTrackType.character => 'Character',
    TimelineTrackType.creature => 'Creature',
    TimelineTrackType.vehicle => 'Vehicle',
    TimelineTrackType.camera => 'Camera',
    TimelineTrackType.action => 'Action',
    TimelineTrackType.dialogue => 'Dialogue',
    TimelineTrackType.prop => 'Prop',
    TimelineTrackType.vfx => 'VFX',
    TimelineTrackType.audio => 'Audio',
    TimelineTrackType.environment => 'Environment',
    TimelineTrackType.continuity => 'Continuity',
  };
}
