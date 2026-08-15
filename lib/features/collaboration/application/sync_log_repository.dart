import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart';

/// Persists cloud sync operation logs (Step 29.6).
class SyncLogRepository {
  SyncLogRepository(this.database);

  final ProjectDatabase database;
  static const _uuid = Uuid();

  Future<void> record({
    required String projectId,
    required String kind,
    required String status,
    String? message,
  }) async {
    final now = DateTime.now().toUtc();
    await database
        .into(database.syncLogs)
        .insert(
          SyncLogsCompanion.insert(
            id: _uuid.v4(),
            projectId: projectId,
            kind: kind,
            status: status,
            message: Value(message),
            startedAt: now,
            finishedAt: Value(now),
          ),
        );
  }

  Future<List<SyncLog>> forProject(String projectId) async {
    final query = database.select(database.syncLogs)
      ..where((row) => row.projectId.equals(projectId))
      ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]);
    return query.get();
  }
}
