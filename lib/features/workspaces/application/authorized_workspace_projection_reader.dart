import 'workspace_permission_policy.dart';
import 'workspace_projection_cache.dart';

final class AuthorizedWorkspaceProjectionReader {
  const AuthorizedWorkspaceProjectionReader({
    required this.cache,
    required this.access,
    this.policy = const WorkspacePermissionPolicy(),
  });

  final WorkspaceProjectionCache cache;
  final WorkspaceAccess access;
  final WorkspacePermissionPolicy policy;

  Future<WorkspaceProjection> forNovel(String novelWorkspaceId) async {
    final projection = await cache.forNovel(novelWorkspaceId);
    final authorized = projection.links
        .where(
          (link) => policy.canReadCharacterProjection(
            access: access,
            novelWorkspaceId: novelWorkspaceId,
            characterWorkspaceId: link.characterWorkspaceId,
            hasExplicitLink: true,
          ),
        )
        .toList(growable: false);
    return WorkspaceProjection(
      novelWorkspaceId: novelWorkspaceId,
      links: authorized,
    );
  }
}
