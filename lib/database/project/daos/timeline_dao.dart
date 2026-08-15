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

  /// Returns only the clips intersecting the requested time window
  /// (with overscan), so render complexity depends on visible items rather
  /// than the total clip count (Step 26.36).
  Future<List<TimelineClip>> getVisibleClips({
    required String timelineId,
    required double startSeconds,
    required double endSeconds,
    double overscanSeconds = 0,
    String? trackId,
  }) {
    final queryStart = startSeconds - overscanSeconds;
    final queryEnd = endSeconds + overscanSeconds;
    final query = select(timelineClips)
      ..where(
        (row) =>
            row.timelineId.equals(timelineId) &
            row.startSeconds.isSmallerOrEqualValue(queryEnd) &
            (row.startSeconds + row.durationSeconds).isBiggerOrEqualValue(
              queryStart,
            ) &
            (trackId == null
                ? const Constant(true)
                : row.trackId.equals(trackId)),
      )
      ..orderBy([(row) => OrderingTerm(expression: row.startSeconds)]);
    return query.get();
  }

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
