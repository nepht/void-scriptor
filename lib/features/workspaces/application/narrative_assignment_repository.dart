import 'package:drift/drift.dart' hide isNull;

import '../../../database/project/project_database.dart' as data;
import '../domain/narrative_assignment.dart' as domain;

/// Storage-backed repository for backlog `phase_one` narrative assignment and
/// support relationships (canonical mapping: steps 145.25/145.26). One
/// character keeps a single profile; assignments are keyed per (project,
/// novel, character) so the same character holds independent roles in
/// different novels without cross-contamination. Enum values persist as the
/// domain wire tokens; unknown tokens fail loudly via `fromWire`.
class NarrativeAssignmentRepository {
  NarrativeAssignmentRepository({
    required this.database,
    required this.projectId,
  });

  final data.ProjectDatabase database;

  final String projectId;

  Future<domain.NarrativeAssignment?> getAssignment({
    required String novelWorkspaceId,
    required String characterId,
  }) async {
    final query = database.select(database.characterNarrativeAssignments)
      ..where(
        (row) =>
            row.projectId.equals(projectId) &
            row.novelWorkspaceId.equals(novelWorkspaceId) &
            row.characterId.equals(characterId),
      );
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _assignmentFromRow(row);
  }

  Future<void> saveAssignment(domain.NarrativeAssignment assignment) async {
    await database
        .into(database.characterNarrativeAssignments)
        .insertOnConflictUpdate(_assignmentTarget(assignment));
  }

  Future<void> removeAssignment({
    required String novelWorkspaceId,
    required String characterId,
  }) async {
    await (database.delete(database.characterNarrativeAssignments)..where(
          (row) =>
              row.projectId.equals(projectId) &
              row.novelWorkspaceId.equals(novelWorkspaceId) &
              row.characterId.equals(characterId),
        ))
        .go();
  }

  Future<List<domain.SupportRelationship>> listSupports(
    String sourceCharacterId,
  ) async {
    final rows =
        await (database.select(database.characterSupportRelationships)
              ..where(
                (row) =>
                    row.projectId.equals(projectId) &
                    row.sourceCharacterId.equals(sourceCharacterId),
              )
              ..orderBy([
                (row) => OrderingTerm.asc(row.storyNovelWorkspaceId),
                (row) => OrderingTerm.asc(row.supportedId),
              ]))
            .get();
    return rows.map(_supportFromRow).toList(growable: false);
  }

  Future<List<domain.SupportRelationship>> listSupportsFor(
    String supportedId,
  ) async {
    final rows =
        await (database.select(database.characterSupportRelationships)..where(
              (row) =>
                  row.projectId.equals(projectId) &
                  row.supportedId.equals(supportedId),
            ))
            .get();
    return rows.map(_supportFromRow).toList(growable: false);
  }

  /// Insert-or-replace keyed so that editing one relationship (e.g. changing
  /// its duration) overwrites exactly that (source, supported, story) row
  /// and cannot touch any other relationship or the assignment's
  /// importance/POV.
  Future<void> saveSupport(domain.SupportRelationship support) async {
    final companion = _supportTarget(support);
    await database
        .into(database.characterSupportRelationships)
        .insertOnConflictUpdate(companion);
  }

  Future<void> removeSupport({
    required String sourceCharacterId,
    required String supportedId,
    required String storyNovelWorkspaceId,
  }) async {
    await (database.delete(database.characterSupportRelationships)..where(
          (row) =>
              row.projectId.equals(projectId) &
              row.sourceCharacterId.equals(sourceCharacterId) &
              row.supportedId.equals(supportedId) &
              row.storyNovelWorkspaceId.equals(storyNovelWorkspaceId),
        ))
        .go();
  }

  /// Removes all narrative rows of one character (assignments keyed on the
  /// character and support rows where the character is the source or the
  /// supported target). Used by character deletion cleanup; relation removal
  /// never deletes character data itself (acceptance: removal does not
  /// delete character data).
  Future<void> deleteForCharacter(String characterId) async {
    await (database.delete(database.characterNarrativeAssignments)..where(
          (row) =>
              row.projectId.equals(projectId) &
              row.characterId.equals(characterId),
        ))
        .go();
    await (database.delete(database.characterSupportRelationships)..where(
          (row) =>
              row.projectId.equals(projectId) &
              (row.sourceCharacterId.equals(characterId) |
                  row.supportedId.equals(characterId)),
        ))
        .go();
  }

  data.CharacterNarrativeAssignmentsCompanion _assignmentTarget(
    domain.NarrativeAssignment assignment,
  ) => data.CharacterNarrativeAssignmentsCompanion.insert(
    projectId: projectId,
    novelWorkspaceId: assignment.novelWorkspaceId,
    characterId: assignment.characterId,
    roles: Value(
      rowSetToken(assignment.roles.map((role) => role.wireName).toSet()),
    ),
    importance: Value(
      assignment.importance == domain.NarrativeImportance.unspecified
          ? null
          : assignment.importance.wireName,
    ),
    pov: Value(
      assignment.pov == domain.NarrativePov.unspecified
          ? null
          : assignment.pov.wireName,
    ),
  );

  data.CharacterSupportRelationshipsCompanion _supportTarget(
    domain.SupportRelationship support,
  ) => data.CharacterSupportRelationshipsCompanion.insert(
    projectId: projectId,
    sourceCharacterId: support.sourceCharacterId,
    supportedId: support.supportedId,
    storyNovelWorkspaceId: support.storyNovelWorkspaceId,
    type: support.type.wireName,
    duration: Value(support.duration.wireName),
    status: Value(support.status.wireName),
    purpose: Value(support.purpose),
    separationReason: Value(support.separationReason),
  );

  domain.NarrativeAssignment _assignmentFromRow(
    data.CharacterNarrativeAssignment row,
  ) {
    final roleTokens = (row.roles ?? '')
        .split(',')
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .map(domain.NarrativeRole.fromWire)
        .toSet();
    return domain.NarrativeAssignment(
      novelWorkspaceId: row.novelWorkspaceId,
      characterId: row.characterId,
      roles: roleTokens,
      importance: row.importance == null
          ? domain.NarrativeImportance.unspecified
          : domain.NarrativeImportance.fromWire(row.importance!),
      pov: row.pov == null
          ? domain.NarrativePov.unspecified
          : domain.NarrativePov.fromWire(row.pov!),
    );
  }

  domain.SupportRelationship _supportFromRow(
    data.CharacterSupportRelationship row,
  ) => domain.SupportRelationship(
    sourceCharacterId: row.sourceCharacterId,
    supportedId: row.supportedId,
    storyNovelWorkspaceId: row.storyNovelWorkspaceId,
    type: domain.SupportType.fromWire(row.type),
    duration: domain.SupportDuration.fromWire(row.duration),
    status: domain.SupportStatus.fromWire(row.status),
    purpose: row.purpose,
    separationReason: row.separationReason,
  );

  static String? rowSetToken(Set<String> tokens) =>
      tokens.isEmpty ? null : tokens.join(',');
}

Set<domain.NarrativeRole> roleTokensToRoles(Set<String> roleTokens) =>
    roleTokens.map(domain.NarrativeRole.fromWire).toSet();
