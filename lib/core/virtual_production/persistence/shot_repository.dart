import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';

/// Persists shots and takes (Step 35.14).
class ShotRepository {
  ShotRepository({required this.database});

  final ProjectDatabase database;

  Future<void> saveShot({
    required String id,
    required String name,
    required double startSeconds,
    required double durationSeconds,
    required String cameraId,
  }) async {
    await database
        .into(database.shots)
        .insertOnConflictUpdate(
          ShotsCompanion.insert(
            id: id,
            name: name,
            startSeconds: startSeconds,
            durationSeconds: durationSeconds,
            cameraId: cameraId,
          ),
        );
  }

  Future<List<Shot>> listShots() async {
    final query = database.select(database.shots)
      ..orderBy([(row) => OrderingTerm.asc(row.startSeconds)]);
    return query.get();
  }

  Future<void> saveTake({
    required String id,
    required String shotId,
    required int takeNumber,
    required String state,
    String notes = '',
  }) async {
    await database
        .into(database.takes)
        .insertOnConflictUpdate(
          TakesCompanion.insert(
            id: id,
            shotId: shotId,
            takeNumber: takeNumber,
            state: state,
            notes: Value(notes),
          ),
        );
  }

  Future<List<Take>> listTakes(String shotId) async {
    final query = database.select(database.takes)
      ..where((row) => row.shotId.equals(shotId))
      ..orderBy([(row) => OrderingTerm.asc(row.takeNumber)]);
    return query.get();
  }
}
