import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart' as data;
import '../domain/novel_character_link.dart' as domain;

class NovelCharacterLinkRepository {
  NovelCharacterLinkRepository({
    required this.database,
    required this.projectId,
  });

  final data.ProjectDatabase database;
  final String projectId;

  /// BUG-1 (vs-hunt-20260914-workspaces): exposes the Drift transaction
  /// boundary so callers (the workspace migration runner) can commit a whole
  /// link set atomically. Every [create]/[unlink] issued inside [action]
  /// participates in the same SQLite transaction and rolls back together.
  Future<R> transaction<R>(Future<R> Function() action) =>
      database.transaction(action);

  Future<domain.NovelCharacterLink> create(
    domain.NovelCharacterLink link,
  ) async {
    await database
        .into(database.novelCharacterLinks)
        .insert(
          data.NovelCharacterLinksCompanion.insert(
            linkId: link.linkId,
            projectId: projectId,
            novelWorkspaceId: link.novelWorkspaceId,
            characterWorkspaceId: link.characterWorkspaceId,
            characterId: link.characterId,
            linkMode: _modeValue(link.mode),
            role: link.role,
            visibility: link.visibility,
            createdAt: link.createdAt,
            updatedAt: link.updatedAt,
          ),
        );
    return link;
  }

  Future<List<domain.NovelCharacterLink>> listForNovel(
    String novelWorkspaceId,
  ) async {
    final rows =
        await (database.select(database.novelCharacterLinks)
              ..where(
                (row) =>
                    row.projectId.equals(projectId) &
                    row.novelWorkspaceId.equals(novelWorkspaceId),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
            .get();
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<List<domain.NovelCharacterLink>> listForCharacter(
    String characterWorkspaceId,
  ) async {
    final rows =
        await (database.select(database.novelCharacterLinks)
              ..where(
                (row) =>
                    row.projectId.equals(projectId) &
                    row.characterWorkspaceId.equals(characterWorkspaceId),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
            .get();
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<bool> unlink(String linkId) async {
    final deleted =
        await (database.delete(database.novelCharacterLinks)..where(
              (row) =>
                  row.projectId.equals(projectId) & row.linkId.equals(linkId),
            ))
            .go();
    return deleted == 1;
  }

  domain.NovelCharacterLink _fromRow(data.NovelCharacterLink row) =>
      domain.NovelCharacterLink(
        linkId: row.linkId,
        novelWorkspaceId: row.novelWorkspaceId,
        characterWorkspaceId: row.characterWorkspaceId,
        characterId: row.characterId,
        mode: _modeFromValue(row.linkMode),
        role: row.role,
        visibility: row.visibility,
        createdAt: row.createdAt.toUtc(),
        updatedAt: row.updatedAt.toUtc(),
      );

  static String _modeValue(domain.LinkMode mode) => switch (mode) {
    domain.LinkMode.reference => 'reference',
    domain.LinkMode.snapshot => 'snapshot',
    domain.LinkMode.fork => 'fork',
  };

  static domain.LinkMode _modeFromValue(String value) => switch (value) {
    'reference' => domain.LinkMode.reference,
    'snapshot' => domain.LinkMode.snapshot,
    'fork' => domain.LinkMode.fork,
    _ => throw StateError('Unsupported persisted link mode: $value'),
  };
}
