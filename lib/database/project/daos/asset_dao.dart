import 'package:drift/drift.dart';

import '../project_database.dart';
import '../tables/asset_tags.dart';
import '../tables/asset_relations.dart';
import '../tables/assets.dart';

part 'asset_dao.g.dart';

@DriftAccessor(tables: [Assets, AssetTags, AssetRelations])
class AssetDao extends DatabaseAccessor<ProjectDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  Future<List<Asset>> getAllAssets() => select(assets).get();

  Future<Asset?> getById(String id) =>
      (select(assets)..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<List<String>> getTags(String assetId) async =>
      (select(assetTags)..where((row) => row.assetId.equals(assetId)))
          .get()
          .then((rows) => rows.map((row) => row.tag).toList(growable: false));

  Future<void> replaceTags(String assetId, List<String> tags) async {
    await transaction(() async {
      await (delete(
        assetTags,
      )..where((row) => row.assetId.equals(assetId))).go();
      for (final tag
          in tags
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet()) {
        await into(
          assetTags,
        ).insert(AssetTagsCompanion.insert(assetId: assetId, tag: tag));
      }
    });
  }

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
    await (delete(assetRelations)..where(
          (row) =>
              row.sourceAssetId.equals(assetId) |
              row.targetAssetId.equals(assetId),
        ))
        .go();
  }
}
