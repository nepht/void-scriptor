import 'package:drift/drift.dart';
import 'package:void_scriptor/database/project/project_database.dart';

import '../domain/asset_search_query.dart';
import '../domain/asset_type.dart';
import 'asset_repository.dart';

class DriftAssetRepository implements AssetRepository {
  DriftAssetRepository(this.database);
  final ProjectDatabase database;

  @override
  Future<void> saveAsset(SearchableAsset asset) => database
      .into(database.assets)
      .insertOnConflictUpdate(
        AssetsCompanion.insert(
          id: asset.id,
          projectId: asset.projectId,
          name: asset.name,
          type: asset.type.name,
          description: Value(asset.description),
          favorite: Value(asset.favorite),
          lastOpenedAt: Value(asset.lastOpenedAt),
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

  @override
  Future<SearchableAsset?> getAsset(String id) async {
    final asset = await database.assetDao.getById(id);
    if (asset == null) return null;
    return SearchableAsset(
      id: asset.id,
      projectId: asset.projectId,
      name: asset.name,
      description: asset.description,
      type: _typeFromStorage(asset.type),
      favorite: asset.favorite,
      lastOpenedAt: asset.lastOpenedAt,
      tags: (await database.assetDao.getTags(id)).toSet(),
    );
  }

  @override
  Future<void> replaceTags(String assetId, Iterable<String> tags) =>
      database.assetDao.replaceTags(assetId, tags);

  @override
  Future<List<String>> tagsFor(String assetId) =>
      database.assetDao.getTags(assetId);

  @override
  Future<void> addTagToAssets(Iterable<String> assetIds, String tag) =>
      database.assetDao.addTagToAssets(assetIds, tag);

  @override
  Future<void> setFavorite(String assetId, bool value) =>
      database.assetDao.setFavorite(assetId, value);

  @override
  Future<void> markOpened(String assetId, DateTime at) =>
      database.assetDao.markOpened(assetId, at);

  @override
  Future<void> createCollection(AssetCollectionModel collection) => database
      .into(database.assetCollections)
      .insertOnConflictUpdate(
        AssetCollectionsCompanion.insert(
          id: collection.id,
          projectId: collection.projectId,
          name: collection.name,
          description: Value(collection.description),
          query: Value(collection.query),
          isSmart: Value(collection.isSmart),
          createdAt: DateTime.now().toUtc(),
        ),
      );

  @override
  Future<void> addToCollection(String collectionId, String assetId) =>
      database.assetDao.addToCollection(collectionId, assetId);

  @override
  Future<AssetCollectionModel?> getCollection(String id) async {
    final collection = await (database.select(
      database.assetCollections,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (collection == null) return null;
    final items = await (database.select(
      database.assetCollectionItems,
    )..where((row) => row.collectionId.equals(id))).get();
    return AssetCollectionModel(
      id: collection.id,
      projectId: collection.projectId,
      name: collection.name,
      description: collection.description,
      query: collection.query,
      isSmart: collection.isSmart,
      assetIds: items.map((item) => item.assetId).toList(growable: false),
    );
  }

  AssetType _typeFromStorage(String value) => AssetType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => AssetType.reference,
  );
}
