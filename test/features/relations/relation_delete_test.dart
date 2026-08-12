import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';
import 'package:void_scriptor/features/relations/application/create_relation_service.dart';
import 'package:void_scriptor/features/relations/domain/asset_relation.dart';
import 'package:void_scriptor/features/relations/domain/relation_repository.dart';

class _Repository implements RelationRepository {
  final items = <AssetRelation>[];

  @override
  Future<void> create(AssetRelation relation) async => items.add(relation);

  @override
  Future<void> delete(String relationId) async =>
      items.removeWhere((item) => item.id == relationId);

  @override
  Future<List<AssetRelation>> incoming(String assetId) async =>
      items.where((item) => item.targetAssetId == assetId).toList();

  @override
  Future<List<AssetRelation>> outgoing(String assetId) async =>
      items.where((item) => item.sourceAssetId == assetId).toList();
}

void main() {
  test('relation service creates a relation that can be deleted', () async {
    final repository = _Repository();
    await CreateRelationService(repository)(
      projectId: 'project-1',
      sourceId: 'qowner',
      targetId: 'dagger',
      type: AssetRelationType.uses,
    );

    expect(repository.items, hasLength(1));
    final relationId = repository.items.single.id;
    await repository.delete(relationId);

    expect(repository.items, isEmpty);
  });
}
