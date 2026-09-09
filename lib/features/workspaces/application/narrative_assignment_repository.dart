import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/foundation.dart' show debugPrint;

import '../../../database/project/project_database.dart' as data;
import '../domain/narrative_assignment.dart' as domain;

/// Storage-backed repository for backlog `phase_one` narrative assignment and
/// support relationships (canonical mapping: steps 145.25/145.26). One
/// character keeps a single profile; assignments are keyed per (project,
/// novel, character) so the same character holds independent roles in
/// different novels without cross-contamination. Enum values persist as the
/// domain wire tokens; `fromWire` itself stays strict, but row decoding here
/// is tolerant per token: an unknown token (the realistic vector is a
/// version-skewed portable import or a manual DB edit — hunt-20260909
/// BUG-06) is skipped with a warning instead of failing the whole list.
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

  /// Every narrative assignment of this project (all novels, all characters).
  /// Used by the explorer character-list filter; rows are project-scoped so
  /// assignments of other projects never leak in.
  Future<List<domain.NarrativeAssignment>> listAssignments() async {
    final rows = await (database.select(
      database.characterNarrativeAssignments,
    )..where((row) => row.projectId.equals(projectId))).get();
    return rows.map(_assignmentFromRow).toList(growable: false);
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
        await (database.select(database.characterSupportRelationships)
              ..where(
                (row) =>
                    row.projectId.equals(projectId) &
                    row.supportedId.equals(supportedId),
              )
              // BUG-13 (hunt-run157): mirror listSupports' deterministic
              // (story, supported) ordering so consumers cannot observe raw
              // insertion order.
              ..orderBy([
                (row) => OrderingTerm.asc(row.storyNovelWorkspaceId),
                (row) => OrderingTerm.asc(row.supportedId),
              ]))
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

  /// Replaces a support relationship whose coordinates changed (defensive
  /// picker-locked edit) in ONE database transaction: the previous row is
  /// removed and the updated row is written together, so a failure at any
  /// point rolls back and the original relationship survives (hunt-run157
  /// BUG-03 — the old remove-then-save lost the row when the save failed).
  Future<void> replaceSupport({
    required domain.SupportRelationship previous,
    required domain.SupportRelationship updated,
  }) async {
    await database.transaction(() async {
      await (database.delete(database.characterSupportRelationships)..where(
            (row) =>
                row.projectId.equals(projectId) &
                row.sourceCharacterId.equals(previous.sourceCharacterId) &
                row.supportedId.equals(previous.supportedId) &
                row.storyNovelWorkspaceId.equals(
                  previous.storyNovelWorkspaceId,
                ),
          ))
          .go();
      await database
          .into(database.characterSupportRelationships)
          .insertOnConflictUpdate(_supportTarget(updated));
    });
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
    final roleTokens = <domain.NarrativeRole>{};
    for (final rawToken in (row.roles ?? '').split(',')) {
      final token = rawToken.trim();
      if (token.isEmpty) continue;
      try {
        roleTokens.add(domain.NarrativeRole.fromWire(token));
      } on ArgumentError {
        debugPrint(
          'NarrativeAssignmentRepository: skipping unknown role token '
          '"$token" in assignment (novel=${row.novelWorkspaceId}, '
          'character=${row.characterId})',
        );
      }
    }
    return domain.NarrativeAssignment(
      novelWorkspaceId: row.novelWorkspaceId,
      characterId: row.characterId,
      roles: roleTokens,
      importance: row.importance == null
          ? domain.NarrativeImportance.unspecified
          : _tolerantWire(
              row.importance!,
              domain.NarrativeImportance.fromWire,
              domain.NarrativeImportance.unspecified,
              row,
            ),
      pov: row.pov == null
          ? domain.NarrativePov.unspecified
          : _tolerantWire(
              row.pov!,
              domain.NarrativePov.fromWire,
              domain.NarrativePov.unspecified,
              row,
            ),
    );
  }

  /// Tolerant scalar decode: an unknown token falls back to [fallback]
  /// instead of aborting the whole assignment list (hunt BUG-06); the
  /// fallback values mean "no explicit value" in the filter semantics.
  T _tolerantWire<T>(
    String value,
    T Function(String) fromWire,
    T fallback,
    data.CharacterNarrativeAssignment row,
  ) {
    try {
      return fromWire(value);
    } on ArgumentError {
      debugPrint(
        'NarrativeAssignmentRepository: unknown wire token "$value" decoded '
        'as ${fallback.toString().toLowerCase()} (novel='
        '${row.novelWorkspaceId}, character=${row.characterId})',
      );
      return fallback;
    }
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
