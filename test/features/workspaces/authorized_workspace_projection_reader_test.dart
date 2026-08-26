import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspaces/application/authorized_workspace_projection_reader.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_permission_policy.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

void main() {
  final link = NovelCharacterLink.create(
    linkId: 'link-1',
    novelWorkspaceId: 'novel-1',
    characterWorkspaceId: 'character-1',
    characterId: 'character-1',
    role: 'protagonist',
    visibility: 'visible',
    now: DateTime.utc(2026, 8, 22),
  );

  test('filters projection when either workspace grant is missing', () async {
    final reader = AuthorizedWorkspaceProjectionReader(
      cache: WorkspaceProjectionCache(loader: (_) async => [link]),
      access: const WorkspaceAccess(readableNovelWorkspaceIds: {'novel-1'}),
    );

    expect((await reader.forNovel('novel-1')).links, isEmpty);
  });

  test('returns explicitly linked projection with both grants', () async {
    final reader = AuthorizedWorkspaceProjectionReader(
      cache: WorkspaceProjectionCache(loader: (_) async => [link]),
      access: const WorkspaceAccess(
        readableNovelWorkspaceIds: {'novel-1'},
        readableCharacterWorkspaceIds: {'character-1'},
      ),
    );

    expect((await reader.forNovel('novel-1')).links.single.linkId, 'link-1');
  });
}
