import 'package:drift/drift.dart';
import '../project_database.dart';
import '../tables/timelines.dart';
import '../tables/timeline_tracks.dart';
import '../tables/timeline_clips.dart';

part 'timeline_dao.g.dart';

@DriftAccessor(tables: [Timelines, TimelineTracks, TimelineClips])
class TimelineDao extends DatabaseAccessor<ProjectDatabase>
    with _$TimelineDaoMixin {
  TimelineDao(super.db);

  Future<Timeline?> getTimeline(String id) =>
      (select(timelines)..where((row) => row.id.equals(id))).getSingleOrNull();
  Future<Timeline?> getTimelineForScene(String sceneId) => (select(
    timelines,
  )..where((row) => row.sceneId.equals(sceneId))).getSingleOrNull();
  Future<List<TimelineTrack>> getTracks(String timelineId) =>
      (select(timelineTracks)
            ..where((row) => row.timelineId.equals(timelineId))
            ..orderBy([(row) => OrderingTerm(expression: row.sortOrder)]))
          .get();
  Future<List<TimelineClip>> getClips(String timelineId) =>
      (select(timelineClips)
            ..where((row) => row.timelineId.equals(timelineId))
            ..orderBy([(row) => OrderingTerm(expression: row.sortOrder)]))
          .get();
  Future<void> updateClip(
    String id, {
    double? startSeconds,
    double? durationSeconds,
  }) async {
    await (update(timelineClips)..where((row) => row.id.equals(id))).write(
      TimelineClipsCompanion(
        startSeconds: startSeconds == null
            ? const Value.absent()
            : Value(startSeconds),
        durationSeconds: durationSeconds == null
            ? const Value.absent()
            : Value(durationSeconds),
      ),
    );
  }

  Future<void> replaceClips(
    String timelineId,
    List<TimelineClipsCompanion> rows,
  ) async {
    await transaction(() async {
      await (delete(
        timelineClips,
      )..where((row) => row.timelineId.equals(timelineId))).go();
      for (final row in rows) {
        await into(timelineClips).insert(row);
      }
    });
  }
}
