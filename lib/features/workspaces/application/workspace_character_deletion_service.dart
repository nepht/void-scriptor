import 'novel_character_link_repository.dart';
import 'workspace_projection_cache.dart';

enum CharacterDeletionDecision { unlink }

final class CharacterDeletionReview {
  const CharacterDeletionReview({
    required this.characterWorkspaceId,
    required this.affectedNovelWorkspaceIds,
    required this.availableDecisions,
  });

  final String characterWorkspaceId;
  final List<String> affectedNovelWorkspaceIds;
  final Set<CharacterDeletionDecision> availableDecisions;
}

typedef CharacterSourceDeleter =
    Future<void> Function(String characterWorkspaceId);

final class WorkspaceCharacterDeletionService {
  const WorkspaceCharacterDeletionService({
    required this.links,
    required this.projections,
    required this.deleteCharacterSource,
  });

  final NovelCharacterLinkRepository links;
  final WorkspaceProjectionCache projections;
  final CharacterSourceDeleter deleteCharacterSource;

  Future<CharacterDeletionReview> review(String characterWorkspaceId) async {
    final affectedLinks = await links.listForCharacter(characterWorkspaceId);
    final affectedNovelIds =
        affectedLinks
            .map((link) => link.novelWorkspaceId)
            .toSet()
            .toList(growable: false)
          ..sort();
    return CharacterDeletionReview(
      characterWorkspaceId: characterWorkspaceId,
      affectedNovelWorkspaceIds: List<String>.unmodifiable(affectedNovelIds),
      availableDecisions: const {CharacterDeletionDecision.unlink},
    );
  }

  Future<void> deleteCharacterWorkspace(
    String characterWorkspaceId, {
    CharacterDeletionDecision? decision,
  }) async {
    if (decision == null) {
      throw StateError(
        'Character deletion requires an explicit affected-Novel decision.',
      );
    }

    final affectedLinks = await links.listForCharacter(characterWorkspaceId);
    switch (decision) {
      case CharacterDeletionDecision.unlink:
        for (final link in affectedLinks) {
          await links.unlink(link.linkId);
          projections.invalidate(link.novelWorkspaceId);
        }
    }
    await deleteCharacterSource(characterWorkspaceId);
  }
}
