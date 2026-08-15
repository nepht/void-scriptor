import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart';
import '../domain/presence.dart' as domain;

/// Persists collaboration activity events (Step 29.14–29.15).
class ActivityRepository {
  ActivityRepository(this.database);

  final ProjectDatabase database;
  static const _uuid = Uuid();

  Future<void> record({
    required String projectId,
    required String actorId,
    required String kind,
    String? payload,
  }) async {
    await database
        .into(database.activityEvents)
        .insert(
          ActivityEventsCompanion.insert(
            id: _uuid.v4(),
            projectId: projectId,
            actorId: actorId,
            kind: kind,
            payload: Value(payload),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<List<domain.ActivityEvent>> forProject(String projectId) async {
    final query = database.select(database.activityEvents)
      ..where((row) => row.projectId.equals(projectId))
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    final rows = await query.get();
    return rows
        .map(
          (row) => domain.ActivityEvent(
            id: row.id,
            projectId: row.projectId,
            actorId: row.actorId,
            kind: row.kind,
            payload: row.payload,
            createdAt: row.createdAt,
          ),
        )
        .toList();
  }
}
