import 'package:uuid/uuid.dart';

import '../domain/novel_character_link.dart';
import 'novel_character_link_repository.dart';
import 'workspace_projection_cache.dart';

/// Step 145.43 friksi #1: aksi aplikasi tunggal untuk menghubungkan karakter
/// ke novel. Persist lewat [NovelCharacterLinkRepository] lalu invalidasi
/// [WorkspaceProjectionCache] per novel agar pembaca berikutnya (termasuk
/// kartu Linked Characters) memuat ulang dari database. Kegagalan persist
/// tidak pernah meng-invalidasi cache.
class CreateNovelCharacterLinkService {
  CreateNovelCharacterLinkService({
    required this.links,
    required this.projections,
  });

  final NovelCharacterLinkRepository links;
  final WorkspaceProjectionCache projections;

  Future<NovelCharacterLink> create({
    required String novelWorkspaceId,
    required String characterAssetId,
    String role = 'Character',
    String visibility = 'visible',
    LinkMode mode = LinkMode.reference,
  }) async {
    final link = NovelCharacterLink.create(
      linkId: const Uuid().v4(),
      novelWorkspaceId: novelWorkspaceId,
      characterWorkspaceId: characterAssetId,
      characterId: characterAssetId,
      role: role,
      visibility: visibility,
      mode: mode,
    );
    final created = await links.create(link);
    projections.invalidate(novelWorkspaceId);
    return created;
  }
}
