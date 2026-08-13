import '../domain/asset_search_query.dart';

class AssetCollectionModel {
  const AssetCollectionModel({
    required this.id,
    required this.projectId,
    required this.name,
    this.description = '',
    this.query,
    this.isSmart = false,
    this.assetIds = const [],
  });
  final String id;
  final String projectId;
  final String name;
  final String description;
  final String? query;
  final bool isSmart;
  final List<String> assetIds;

  AssetCollectionModel copyWith({List<String>? assetIds}) =>
      AssetCollectionModel(
        id: id,
        projectId: projectId,
        name: name,
        description: description,
        query: query,
        isSmart: isSmart,
        assetIds: assetIds ?? this.assetIds,
      );
}

abstract interface class AssetRepository {
  Future<void> saveAsset(SearchableAsset asset);
  Future<SearchableAsset?> getAsset(String id);
  Future<void> replaceTags(String assetId, Iterable<String> tags);
  Future<List<String>> tagsFor(String assetId);
  Future<void> addTagToAssets(Iterable<String> assetIds, String tag);
  Future<void> setFavorite(String assetId, bool value);
  Future<void> markOpened(String assetId, DateTime at);
  Future<void> createCollection(AssetCollectionModel collection);
  Future<void> addToCollection(String collectionId, String assetId);
  Future<AssetCollectionModel?> getCollection(String id);
}

String normalizeAssetTag(String value) => value.trim().toLowerCase();

class InMemoryAssetRepository implements AssetRepository {
  final Map<String, SearchableAsset> _assets = {};
  final Map<String, List<String>> _tags = {};
  final Map<String, AssetCollectionModel> _collections = {};

  @override
  Future<void> saveAsset(SearchableAsset asset) async =>
      _assets[asset.id] = asset;

  @override
  Future<SearchableAsset?> getAsset(String id) async => _assets[id];

  @override
  Future<void> replaceTags(String assetId, Iterable<String> tags) async {
    _tags[assetId] = tags
        .map(normalizeAssetTag)
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  Future<List<String>> tagsFor(String assetId) async =>
      List.unmodifiable(_tags[assetId] ?? const []);

  @override
  Future<void> addTagToAssets(Iterable<String> assetIds, String tag) async {
    final normalized = normalizeAssetTag(tag);
    if (normalized.isEmpty) return;
    for (final assetId in assetIds) {
      final tags = _tags.putIfAbsent(assetId, () => []);
      if (!tags.contains(normalized)) tags.add(normalized);
    }
  }

  @override
  Future<void> setFavorite(String assetId, bool value) async {
    final asset = _assets[assetId];
    if (asset != null) _assets[assetId] = asset.copyWith(favorite: value);
  }

  @override
  Future<void> markOpened(String assetId, DateTime at) async {
    final asset = _assets[assetId];
    if (asset != null) _assets[assetId] = asset.copyWith(lastOpenedAt: at);
  }

  @override
  Future<void> createCollection(AssetCollectionModel collection) async =>
      _collections[collection.id] = collection;

  @override
  Future<void> addToCollection(String collectionId, String assetId) async {
    final collection = _collections[collectionId];
    if (collection == null) return;
    if (!collection.assetIds.contains(assetId)) {
      _collections[collectionId] = collection.copyWith(
        assetIds: [...collection.assetIds, assetId],
      );
    }
  }

  @override
  Future<AssetCollectionModel?> getCollection(String id) async =>
      _collections[id];
}
