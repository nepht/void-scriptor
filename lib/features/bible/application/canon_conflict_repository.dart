import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../../../database/project/tables/canon_conflicts.dart' as schema;
import '../domain/canon_conflict.dart' as domain;

part 'canon_conflict_repository.g.dart';

@DriftAccessor(tables: [schema.CanonConflicts, schema.CanonRuleExceptions])
class CanonConflictRepository extends DatabaseAccessor<ProjectDatabase>
    with _$CanonConflictRepositoryMixin {
  CanonConflictRepository(super.database);

  Future<void> save(domain.CanonConflict conflict) =>
      into(canonConflicts).insertOnConflictUpdate(
        CanonConflictsCompanion.insert(
          id: conflict.id,
          projectId: conflict.projectId,
          ruleId: conflict.ruleId,
          targetId: conflict.targetId,
          message: conflict.message,
          severity: conflict.severity.name,
          resolved: Value(conflict.resolved),
          resolutionNote: Value(conflict.resolutionNote),
          detectedAt: DateTime.now().toUtc(),
        ),
      );

  Future<void> resolve(String id, String note) =>
      (update(canonConflicts)..where((row) => row.id.equals(id))).write(
        CanonConflictsCompanion(
          resolved: const Value(true),
          resolutionNote: Value(note),
        ),
      );

  Future<List<domain.CanonConflict>> list(String projectId) async {
    final rows =
        await (select(canonConflicts)
              ..where((row) => row.projectId.equals(projectId))
              ..orderBy([(row) => OrderingTerm.desc(row.detectedAt)]))
            .get();
    return rows
        .map(
          (row) => domain.CanonConflict(
            id: row.id,
            projectId: row.projectId,
            ruleId: row.ruleId,
            targetId: row.targetId,
            message: row.message,
            severity: domain.CanonConflictSeverity.values.byName(row.severity),
            resolved: row.resolved,
            resolutionNote: row.resolutionNote,
          ),
        )
        .toList(growable: false);
  }
}
