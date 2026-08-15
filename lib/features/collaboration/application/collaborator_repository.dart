import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../domain/collaborator.dart';

/// Manages project collaborators and their roles (Step 29.10–29.11).
class CollaboratorRepository {
  CollaboratorRepository(this.database);

  final ProjectDatabase database;

  Future<void> add({
    required String projectId,
    required String userId,
    required CollaboratorRole role,
  }) async {
    await database
        .into(database.projectCollaborators)
        .insert(
          ProjectCollaboratorsCompanion.insert(
            projectId: projectId,
            userId: userId,
            role: role.name,
            invitedAt: DateTime.now().toUtc(),
            acceptedAt: const Value.absent(),
          ),
        );
  }

  Future<List<Collaborator>> forProject(String projectId) async {
    final query = database.select(database.projectCollaborators)
      ..where((row) => row.projectId.equals(projectId));
    final rows = await query.get();
    return rows
        .map(
          (row) => Collaborator(
            projectId: row.projectId,
            userId: row.userId,
            role: CollaboratorRole.values.byName(row.role),
            invitedAt: row.invitedAt,
            acceptedAt: row.acceptedAt,
          ),
        )
        .toList();
  }

  Future<void> acceptInvite(String projectId, String userId) async {
    await (database.update(database.projectCollaborators)..where(
          (row) => row.projectId.equals(projectId) & row.userId.equals(userId),
        ))
        .write(
          ProjectCollaboratorsCompanion(
            acceptedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }
}
