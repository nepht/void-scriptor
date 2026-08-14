import '../domain/asset_relation.dart';

abstract interface class RelationRepository {
  Future<List<AssetRelation>> outgoing(String assetId);
  Future<List<AssetRelation>> incoming(String assetId);
  Future<void> create(AssetRelation relation);
  Future<void> delete(String relationId);
}

abstract interface class RelationSnapshotRepository {
  Future<AssetRelation?> getById(String relationId);
}
