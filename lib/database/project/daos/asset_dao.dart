import 'package:drift/drift.dart';

import '../project_database.dart';
import '../tables/asset_collections.dart';
import '../tables/asset_relations.dart';
import '../tables/asset_tags.dart';
import '../tables/assets.dart';
import '../tables/tags.dart';

part 'asset_dao.g.dart';

@DriftAccessor(
  tables: [
    Assets,
    AssetTags,
    AssetRelations,
    Tags,
    AssetTagLinks,
    AssetCollections,
    AssetCollectionItems,
  ],
)
class AssetDao extends DatabaseAccessor<ProjectDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  Future<List<Asset>> getAllAssets() => select(assets).get();
  Future<Asset?> getById(String id) =>
      (select(assets)..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<void> createStandaloneCharacterAsset({
    required String id,
    required String projectId,
    required String name,
    required String type,
    String description = '',
    required DateTime now,
  }) => createStandaloneAsset(
    id: id,
    projectId: projectId,
    name: name,
    type: type,
    description: description,
    now: now,
  );

  /// Stand-alone types per product contract (2026-09-06): wardrobe, weapon,
  /// armor, accessory, prop, creature, vehicle.
  Future<void> createStandaloneAsset({
    required String id,
    required String projectId,
    required String name,
    required String type,
    String description = '',
    required DateTime now,
  }) async {
    const standaloneTypes = <String>{
      'wardrobe',
      'weapon',
      'armor',
      'accessory',
      'hair_variant',
      'prop',
      'creature',
      'vehicle',
    };
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) throw ArgumentError('Name must not be empty');
    if (!standaloneTypes.contains(type)) {
      throw ArgumentError('Type is not a stand-alone asset type: $type');
    }
    await into(assets).insert(
      AssetsCompanion.insert(
        id: id,
        projectId: projectId,
        name: normalizedName,
        description: Value(description.trim()),
        type: type,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<List<String>> getTags(String assetId) async {
    final normalized = await (select(
      assetTagLinks,
    )..where((row) => row.assetId.equals(assetId))).get();
    if (normalized.isNotEmpty) {
      final ids = normalized.map((row) => row.tagId).toSet();
      final rows = await (select(tags)..where((row) => row.id.isIn(ids))).get();
      return rows.map((row) => row.name).toList(growable: false);
    }
    final legacy = await (select(
      assetTags,
    )..where((row) => row.assetId.equals(assetId))).get();
    return legacy.map((row) => row.tag).toList(growable: false);
  }

  Future<void> replaceTags(String assetId, Iterable<String> values) async {
    final normalized = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    await transaction(() async {
      await (delete(
        assetTagLinks,
      )..where((row) => row.assetId.equals(assetId))).go();
      for (final name in normalized) {
        final id = '${assetId}_tag_$name';
        await into(tags).insertOnConflictUpdate(
          TagsCompanion.insert(
            id: id,
            projectId: (await getById(assetId))?.projectId ?? '',
            name: name,
          ),
        );
        await into(
          assetTagLinks,
        ).insert(AssetTagLinksCompanion.insert(assetId: assetId, tagId: id));
      }
    });
  }

  Future<void> setFavorite(String assetId, bool value) =>
      (update(assets)..where((row) => row.id.equals(assetId))).write(
        AssetsCompanion(favorite: Value(value)),
      );

  /// 145.44: writes the asset thumbnail reference. The schema column has
  /// existed since the asset browser, but nothing produced it until the
  /// thumbnail importer landed; the browser renders it at read time.
  Future<void> setThumbnail(String assetId, String? path) =>
      (update(assets)..where((row) => row.id.equals(assetId))).write(
        AssetsCompanion(thumbnailPath: Value(path)),
      );
  Future<void> markOpened(String assetId, DateTime at) =>
      (update(assets)..where((row) => row.id.equals(assetId))).write(
        AssetsCompanion(lastOpenedAt: Value(at)),
      );

  Future<void> addTagToAssets(Iterable<String> assetIds, String tag) async {
    final normalized = tag.trim().toLowerCase();
    if (normalized.isEmpty) return;
    await transaction(() async {
      for (final id in assetIds) {
        final existing = await getTags(id);
        await replaceTags(id, [...existing, normalized]);
      }
    });
  }

  Future<void> addToCollection(
    String collectionId,
    String assetId, {
    int sortOrder = 0,
  }) => into(assetCollectionItems).insertOnConflictUpdate(
    AssetCollectionItemsCompanion.insert(
      collectionId: collectionId,
      assetId: assetId,
      sortOrder: Value(sortOrder),
    ),
  );

  Future<void> addRelation({
    required String id,
    required String sourceAssetId,
    required String targetAssetId,
    required String relationType,
  }) => into(assetRelations).insert(
    AssetRelationsCompanion.insert(
      id: id,
      sourceAssetId: sourceAssetId,
      targetAssetId: targetAssetId,
      relationType: relationType,
    ),
  );

  Future<void> removeAssetData(String assetId) async {
    await (delete(assetTags)..where((row) => row.assetId.equals(assetId))).go();
    await (delete(
      assetTagLinks,
    )..where((row) => row.assetId.equals(assetId))).go();
    await (delete(
      assetCollectionItems,
    )..where((row) => row.assetId.equals(assetId))).go();
    await (delete(assetRelations)..where(
          (row) =>
              row.sourceAssetId.equals(assetId) |
              row.targetAssetId.equals(assetId),
        ))
        .go();
  }
}
