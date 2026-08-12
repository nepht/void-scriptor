import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';
import 'package:void_scriptor/features/relations/application/create_relation_service.dart';
import 'package:void_scriptor/features/relations/domain/asset_relation.dart';
import 'package:void_scriptor/features/relations/domain/relation_repository.dart';

class _MemoryRelationRepository implements RelationRepository {
  final List<AssetRelation> items = [];
  @override
  Future<List<AssetRelation>> outgoing(String id) async =>
      items.where((r) => r.sourceAssetId == id).toList();
  @override
  Future<List<AssetRelation>> incoming(String id) async =>
      items.where((r) => r.targetAssetId == id).toList();
  @override
  Future<void> create(AssetRelation relation) async => items.add(relation);
  @override
  Future<void> delete(String id) async => items.removeWhere((r) => r.id == id);
}

void main() {
  test(
    'create relation rejects self relation and stores typed relation',
    () async {
      final repository = _MemoryRelationRepository();
      final service = CreateRelationService(repository);

      await expectLater(
        service(
          projectId: 'project-1',
          sourceId: 'qowner',
          targetId: 'qowner',
          type: AssetRelationType.wears,
        ),
        throwsArgumentError,
      );

      await service(
        projectId: 'project-1',
        sourceId: 'qowner',
        targetId: 'coat',
        type: AssetRelationType.wears,
      );
      expect(repository.items.single.type, AssetRelationType.wears);
      expect(repository.items.single.projectId, 'project-1');
    },
  );
}
