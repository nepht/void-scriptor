import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';

/// Persists animation tracks and keyframes (Step 33.14).
class AnimationRepository {
  AnimationRepository({required this.database});

  final ProjectDatabase database;

  Future<void> saveTrack({
    required String clipId,
    required String id,
    required String name,
    required String targetProperty,
    required String interpolation,
    required double durationSeconds,
  }) async {
    await database
        .into(database.animationTracks)
        .insertOnConflictUpdate(
          AnimationTracksCompanion.insert(
            id: id,
            clipId: clipId,
            name: name,
            targetProperty: targetProperty,
            interpolation: interpolation,
            durationSeconds: durationSeconds,
          ),
        );
  }

  Future<List<AnimationTrack>> listTracks(String clipId) async {
    final query = database.select(database.animationTracks)
      ..where((row) => row.clipId.equals(clipId));
    return query.get();
  }

  Future<void> saveKeyframe({
    required String id,
    required String trackId,
    required double timeSeconds,
    required double value,
  }) async {
    await database
        .into(database.animationKeyframes)
        .insertOnConflictUpdate(
          AnimationKeyframesCompanion.insert(
            id: id,
            trackId: trackId,
            timeSeconds: timeSeconds,
            value: value,
          ),
        );
  }

  Future<List<AnimationKeyframe>> listKeyframes(String trackId) async {
    final query = database.select(database.animationKeyframes)
      ..where((row) => row.trackId.equals(trackId))
      ..orderBy([(row) => OrderingTerm.asc(row.timeSeconds)]);
    return query.get();
  }
}
