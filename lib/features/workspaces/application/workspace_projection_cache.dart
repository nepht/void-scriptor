import '../domain/novel_character_link.dart';

typedef WorkspaceProjectionLoader =
    Future<List<NovelCharacterLink>> Function(String novelWorkspaceId);

final class WorkspaceProjection {
  const WorkspaceProjection({
    required this.novelWorkspaceId,
    required this.links,
  });

  final String novelWorkspaceId;
  final List<NovelCharacterLink> links;
}

final class WorkspaceProjectionCache {
  factory WorkspaceProjectionCache({
    required WorkspaceProjectionLoader loader,
  }) => WorkspaceProjectionCache._(loader);

  WorkspaceProjectionCache._(this._loader);

  final WorkspaceProjectionLoader _loader;
  final Map<String, Future<WorkspaceProjection>> _entries = {};

  Future<WorkspaceProjection> forNovel(String novelWorkspaceId) {
    return _entries.putIfAbsent(novelWorkspaceId, () async {
      final links = await _loader(novelWorkspaceId);
      return WorkspaceProjection(
        novelWorkspaceId: novelWorkspaceId,
        links: List<NovelCharacterLink>.unmodifiable(links),
      );
    });
  }

  void invalidate(String novelWorkspaceId) {
    _entries.remove(novelWorkspaceId);
  }

  void clear() {
    _entries.clear();
  }
}
