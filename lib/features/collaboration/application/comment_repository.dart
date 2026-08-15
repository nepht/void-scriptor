import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart';
import '../domain/collaborator.dart' as domain;

/// Persists comments attached to project entities (Step 29.12).
class CommentRepository {
  CommentRepository(this.database);

  final ProjectDatabase database;
  static const _uuid = Uuid();

  Future<void> add({
    required String projectId,
    required String authorId,
    required String targetType,
    required String targetId,
    required String body,
  }) async {
    await database
        .into(database.projectComments)
        .insert(
          ProjectCommentsCompanion.insert(
            id: _uuid.v4(),
            projectId: projectId,
            authorId: authorId,
            targetType: targetType,
            targetId: targetId,
            body: body,
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<List<domain.ProjectComment>> forTarget(
    String projectId,
    String targetType,
    String targetId,
  ) async {
    final query = database.select(database.projectComments)
      ..where(
        (row) =>
            row.projectId.equals(projectId) &
            row.targetType.equals(targetType) &
            row.targetId.equals(targetId),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]);
    final rows = await query.get();
    return rows
        .map(
          (row) => domain.ProjectComment(
            id: row.id,
            projectId: row.projectId,
            authorId: row.authorId,
            targetType: row.targetType,
            targetId: row.targetId,
            body: row.body,
            createdAt: row.createdAt,
          ),
        )
        .toList();
  }
}
