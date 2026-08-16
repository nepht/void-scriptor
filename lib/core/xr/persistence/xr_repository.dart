import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';

/// Persists XR sessions and spatial anchors (Step 41.15).
class XrRepository {
  XrRepository({required this.database});

  final ProjectDatabase database;

  Future<void> saveSession({required String id, required String state}) async {
    await database
        .into(database.xrSessions)
        .insertOnConflictUpdate(
          XrSessionsCompanion.insert(
            id: id,
            state: state,
            startedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<List<XrSession>> listSessions() async =>
      database.select(database.xrSessions).get();

  Future<void> saveAnchor({
    required String id,
    required String sessionId,
    required String contentId,
    required double x,
    required double y,
    required double z,
  }) async {
    await database
        .into(database.spatialAnchors)
        .insertOnConflictUpdate(
          SpatialAnchorsCompanion.insert(
            id: id,
            sessionId: sessionId,
            contentId: contentId,
            x: x,
            y: y,
            z: z,
          ),
        );
  }

  Future<List<SpatialAnchor>> listAnchors(String sessionId) async {
    final query = database.select(database.spatialAnchors)
      ..where((row) => row.sessionId.equals(sessionId));
    return query.get();
  }
}
