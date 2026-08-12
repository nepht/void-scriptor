import 'package:drift/drift.dart';

import '../project_database.dart';
import '../tables/asset_tags.dart';
import '../tables/assets.dart';

part 'asset_dao.g.dart';

@DriftAccessor(tables: [Assets, AssetTags])
class AssetDao extends DatabaseAccessor<ProjectDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  Future<List<Asset>> getAllAssets() => select(assets).get();

  Future<Asset?> getById(String id) =>
      (select(assets)..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<List<String>> getTags(String assetId) async =>
      (select(assetTags)..where((row) => row.assetId.equals(assetId)))
          .get()
          .then((rows) => rows.map((row) => row.tag).toList(growable: false));
}
