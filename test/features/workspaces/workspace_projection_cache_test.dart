import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

void main() {
  test('caches a novel workspace projection until invalidated', () async {
    var loads = 0;
    final cache = WorkspaceProjectionCache(
      loader: (novelWorkspaceId) async {
        loads++;
        return [
          NovelCharacterLink.create(
            linkId: 'link-$loads',
            novelWorkspaceId: novelWorkspaceId,
            characterWorkspaceId: 'character-1',
            characterId: 'character-1',
            role: 'support',
            visibility: 'visible',
            now: DateTime.utc(2026, 8, 22),
          ),
        ];
      },
    );

    final first = await cache.forNovel('novel-1');
    final second = await cache.forNovel('novel-1');

    expect(loads, 1);
    expect(second, same(first));
    expect(first.links.single.linkId, 'link-1');

    cache.invalidate('novel-1');
    final refreshed = await cache.forNovel('novel-1');
    expect(loads, 2);
    expect(refreshed.links.single.linkId, 'link-2');
  });

  test('clear removes every cached workspace projection', () async {
    var loads = 0;
    final cache = WorkspaceProjectionCache(
      loader: (id) async {
        loads++;
        return <NovelCharacterLink>[];
      },
    );

    await cache.forNovel('novel-a');
    await cache.forNovel('novel-b');
    cache.clear();
    await cache.forNovel('novel-a');

    expect(loads, 3);
  });
}
