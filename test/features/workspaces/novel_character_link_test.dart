import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_service.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

void main() {
  test('defaults a novel-character link to reference mode', () {
    final link = NovelCharacterLink.create(
      linkId: 'link-1',
      novelWorkspaceId: 'novel-1',
      characterWorkspaceId: 'character-1',
      characterId: 'character-entity-1',
      role: 'protagonist',
      visibility: 'visible',
    );

    expect(link.owner, WorkspaceType.novel);
    expect(link.mode, LinkMode.reference);
    expect(link.novelWorkspaceId, 'novel-1');
    expect(link.characterWorkspaceId, 'character-1');
  });

  test('rejects a link that crosses no workspace boundary', () {
    expect(
      () => NovelCharacterLink.create(
        linkId: 'link-1',
        novelWorkspaceId: 'same',
        characterWorkspaceId: 'same',
        characterId: 'character-entity-1',
        role: 'protagonist',
        visibility: 'visible',
      ),
      throwsArgumentError,
    );
  });

  test('rejects unsupported link values at the domain boundary', () {
    expect(
      () => NovelCharacterLink(
        linkId: 'link-1',
        novelWorkspaceId: 'novel-1',
        characterWorkspaceId: 'character-1',
        characterId: 'character-entity-1',
        mode: LinkMode.reference,
        role: '',
        visibility: 'visible',
        createdAt: DateTime.utc(2026, 8, 22),
        updatedAt: DateTime.utc(2026, 8, 22),
      ),
      throwsArgumentError,
    );
  });

  test('round-trips link mode and provenance fields through json', () {
    final link = NovelCharacterLink.create(
      linkId: 'link-2',
      novelWorkspaceId: 'novel-2',
      characterWorkspaceId: 'character-2',
      characterId: 'character-entity-2',
      role: 'mentor',
      visibility: 'private',
      mode: LinkMode.snapshot,
      now: DateTime.utc(2026, 8, 22, 10, 30),
    );

    final restored = NovelCharacterLink.fromJson(link.toJson());

    expect(restored.linkId, link.linkId);
    expect(restored.mode, LinkMode.snapshot);
    expect(restored.createdAt, link.createdAt);
    expect(restored.updatedAt, link.updatedAt);
    expect(restored.owner, WorkspaceType.novel);
  });

  test('creates, lists, and unlinks without deleting the character source', () {
    final service = NovelCharacterLinkService();
    final link = service.create(
      linkId: 'link-3',
      novelWorkspaceId: 'novel-3',
      characterWorkspaceId: 'character-3',
      characterId: 'character-entity-3',
      role: 'supporting',
      visibility: 'visible',
    );

    expect(service.listForNovel('novel-3'), [link]);
    expect(service.unlink('link-3'), isTrue);
    expect(service.listForNovel('novel-3'), isEmpty);
    expect(service.characterSourceStillExists('character-entity-3'), isTrue);
  });
}
