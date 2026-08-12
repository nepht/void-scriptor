import 'package:uuid/uuid.dart';

import '../../assets/domain/asset_relation_type.dart';
import '../domain/asset_relation.dart';
import '../domain/relation_repository.dart';

class CreateRelationService {
  CreateRelationService(this.repository);
  final RelationRepository repository;

  Future<void> call({
    required String projectId,
    required String sourceId,
    required String targetId,
    required AssetRelationType type,
  }) async {
    if (sourceId == targetId) {
      throw ArgumentError('An asset cannot relate to itself.');
    }
    await repository.create(
      AssetRelation(
        id: const Uuid().v4(),
        projectId: projectId,
        sourceAssetId: sourceId,
        targetAssetId: targetId,
        type: type,
        createdAt: DateTime.now(),
      ),
    );
  }
}
