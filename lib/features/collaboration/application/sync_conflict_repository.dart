import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart';

/// Persists unresolved sync conflicts and their resolutions (Step 29.9).
class SyncConflictRepository {
  SyncConflictRepository(this.database);

  final ProjectDatabase database;
  static const _uuid = Uuid();

  Future<void> record({
    required String projectId,
    required String entityKey,
    required String baseJson,
    required String oursJson,
    required String theirsJson,
  }) async {
    await database
        .into(database.syncConflicts)
        .insert(
          SyncConflictsCompanion.insert(
            id: _uuid.v4(),
            projectId: projectId,
            entityKey: entityKey,
            baseJson: baseJson,
            oursJson: oursJson,
            theirsJson: theirsJson,
            resolution: const Value.absent(),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<List<SyncConflict>> forProject(String projectId) async {
    final query = database.select(database.syncConflicts)
      ..where((row) => row.projectId.equals(projectId))
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    return query.get();
  }

  Future<void> markResolved(String id, String resolution) async {
    await (database.update(database.syncConflicts)
          ..where((row) => row.id.equals(id)))
        .write(SyncConflictsCompanion(resolution: Value(resolution)));
  }
}
