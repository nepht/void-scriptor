import 'package:drift/drift.dart';

import '../../../database/project/daos/relation_dao.dart';
import '../../../database/project/project_database.dart';
import '../../../features/assets/domain/asset_relation_type.dart';
import '../domain/asset_relation.dart' as domain;
import '../domain/relation_repository.dart';

class RelationRepositoryImpl
    implements RelationRepository, RelationSnapshotRepository {
  RelationRepositoryImpl({required ProjectDatabase database})
    : _dao = RelationDao(database);
  final RelationDao _dao;

  domain.AssetRelation _mapGenerated(AssetRelation row) => domain.AssetRelation(
    id: row.id,
    projectId: row.projectId,
    sourceAssetId: row.sourceAssetId,
    targetAssetId: row.targetAssetId,
    type: AssetRelationType.values.firstWhere(
      (type) => type.value == row.relationType,
      orElse: () => AssetRelationType.relatedTo,
    ),
    createdAt: row.createdAt,
  );

  @override
  Future<List<domain.AssetRelation>> outgoing(String assetId) async =>
      (await _dao.getOutgoingRelations(assetId)).map(_mapGenerated).toList();

  @override
  Future<List<domain.AssetRelation>> incoming(String assetId) async =>
      (await _dao.getIncomingRelations(assetId)).map(_mapGenerated).toList();

  @override
  Future<domain.AssetRelation?> getById(String relationId) async {
    final row = await _dao.getRelation(relationId);
    return row == null ? null : _mapGenerated(row);
  }

  @override
  Future<void> create(domain.AssetRelation relation) => _dao.createRelation(
    AssetRelationsCompanion.insert(
      id: relation.id,
      projectId: Value(relation.projectId),
      sourceAssetId: relation.sourceAssetId,
      targetAssetId: relation.targetAssetId,
      relationType: relation.type.value,
      createdAt: Value(relation.createdAt),
    ),
  );

  @override
  Future<void> delete(String relationId) => _dao.deleteRelation(relationId);
}
