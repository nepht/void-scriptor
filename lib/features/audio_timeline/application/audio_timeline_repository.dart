import 'package:drift/drift.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/tables/audio_timeline.dart';
import '../domain/audio_timeline_models.dart' as domain;
part 'audio_timeline_repository.g.dart';

@DriftAccessor(tables: [AudioTimelineClips, AudioAutomationKeyframes])
class AudioTimelineRepository extends DatabaseAccessor<ProjectDatabase>
    with _$AudioTimelineRepositoryMixin {
  AudioTimelineRepository(super.db);
  Future<void> saveClip(domain.AudioTimelineClipModel v) =>
      into(audioTimelineClips).insertOnConflictUpdate(
        AudioTimelineClipsCompanion.insert(
          id: v.id,
          timelineId: v.timelineId,
          trackType: v.trackType.name,
          audioFileId: v.audioFileId,
          startSeconds: v.startSeconds,
          durationSeconds: v.durationSeconds,
          fadeInSeconds: Value(v.fadeInSeconds),
          fadeOutSeconds: Value(v.fadeOutSeconds),
          gainDb: Value(v.gainDb),
          pan: Value(v.pan),
          intent: Value(v.intent?.name),
        ),
      );
  Future<List<domain.AudioTimelineClipModel>> clipsForTimeline(
    String id,
  ) async {
    final rows =
        await (select(audioTimelineClips)
              ..where((x) => x.timelineId.equals(id))
              ..orderBy([(x) => OrderingTerm.asc(x.startSeconds)]))
            .get();
    return [
      for (final r in rows)
        domain.AudioTimelineClipModel(
          id: r.id,
          timelineId: r.timelineId,
          trackType: domain.AudioTrackType.values.byName(r.trackType),
          audioFileId: r.audioFileId,
          startSeconds: r.startSeconds,
          durationSeconds: r.durationSeconds,
          fadeInSeconds: r.fadeInSeconds,
          fadeOutSeconds: r.fadeOutSeconds,
          gainDb: r.gainDb,
          pan: r.pan,
          intent: r.intent == null
              ? null
              : domain.MusicIntent.values.byName(r.intent!),
        ),
    ];
  }

  Future<void> saveAutomation(
    List<domain.AudioAutomationKeyframeModel> values,
  ) => batch(
    (b) => b.insertAllOnConflictUpdate(audioAutomationKeyframes, [
      for (final v in values)
        AudioAutomationKeyframesCompanion.insert(
          id: v.id,
          clipId: v.clipId,
          timeSeconds: v.timeSeconds,
          parameter: v.parameter,
          value: v.value,
        ),
    ]),
  );
  Future<List<domain.AudioAutomationKeyframeModel>> automationFor(
    String id,
  ) async {
    final rows =
        await (select(audioAutomationKeyframes)
              ..where((x) => x.clipId.equals(id))
              ..orderBy([(x) => OrderingTerm.asc(x.timeSeconds)]))
            .get();
    return [
      for (final r in rows)
        domain.AudioAutomationKeyframeModel(
          id: r.id,
          clipId: r.clipId,
          timeSeconds: r.timeSeconds,
          parameter: r.parameter,
          value: r.value,
        ),
    ];
  }
}
