import '../../assets/domain/asset_relation_type.dart';

class AssetRelation {
  const AssetRelation({
    required this.id,
    required this.projectId,
    required this.sourceAssetId,
    required this.targetAssetId,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String sourceAssetId;
  final String targetAssetId;
  final AssetRelationType type;
  final DateTime createdAt;
}
