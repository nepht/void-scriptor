import 'package:drift/drift.dart';

import '../project_database.dart';
import '../tables/asset_relations.dart';

part 'relation_dao.g.dart';

@DriftAccessor(tables: [AssetRelations])
class RelationDao extends DatabaseAccessor<ProjectDatabase>
    with _$RelationDaoMixin {
  RelationDao(super.db);

  Future<List<AssetRelation>> getOutgoingRelations(String assetId) => (select(
    assetRelations,
  )..where((row) => row.sourceAssetId.equals(assetId))).get();

  Future<List<AssetRelation>> getIncomingRelations(String assetId) => (select(
    assetRelations,
  )..where((row) => row.targetAssetId.equals(assetId))).get();

  Future<AssetRelation?> getRelation(String relationId) => (select(
    assetRelations,
  )..where((row) => row.id.equals(relationId))).getSingleOrNull();

  Future<void> createRelation(AssetRelationsCompanion relation) =>
      into(assetRelations).insert(relation);

  Future<void> deleteRelation(String relationId) =>
      (delete(assetRelations)..where((row) => row.id.equals(relationId))).go();
}
