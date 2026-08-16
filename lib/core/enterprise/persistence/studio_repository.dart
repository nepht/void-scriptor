import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';

/// Persists studio members and audit events (Step 37.15).
class StudioRepository {
  StudioRepository({required this.database});

  final ProjectDatabase database;

  Future<void> saveMember({
    required String userId,
    required String studioId,
    required String role,
    required String status,
  }) async {
    await database
        .into(database.studioMembers)
        .insertOnConflictUpdate(
          StudioMembersCompanion.insert(
            userId: userId,
            studioId: studioId,
            role: role,
            status: status,
          ),
        );
  }

  Future<List<StudioMember>> listMembers(String studioId) async {
    final query = database.select(database.studioMembers)
      ..where((row) => row.studioId.equals(studioId));
    return query.get();
  }

  Future<void> appendEvent({
    required String id,
    required String actor,
    required String action,
    required String target,
  }) async {
    await database
        .into(database.auditEvents)
        .insert(
          AuditEventsCompanion.insert(
            id: id,
            actor: actor,
            action: action,
            target: target,
            timestamp: DateTime.now().toUtc(),
          ),
        );
  }

  Future<List<AuditEvent>> listEvents(String actor) async {
    final query = database.select(database.auditEvents)
      ..where((row) => row.actor.equals(actor))
      ..orderBy([(row) => OrderingTerm.desc(row.timestamp)]);
    return query.get();
  }
}
