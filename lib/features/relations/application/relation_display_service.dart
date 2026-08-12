import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';

String relationDisplayLabel({
  required AssetRelationType type,
  required bool incoming,
}) {
  if (!incoming) return type.value;
  return switch (type) {
    AssetRelationType.uses => 'used by',
    AssetRelationType.wears => 'worn by',
    AssetRelationType.owns => 'owned by',
    _ => type.value,
  };
}

class RelationDisplayItem {
  const RelationDisplayItem({
    required this.relationId,
    required this.label,
    required this.assetId,
    required this.assetName,
    required this.incoming,
  });

  final String relationId;
  final String label;
  final String assetId;
  final String assetName;
  final bool incoming;
}

class RelationDisplayService {
  RelationDisplayService(this.database);
  final ProjectDatabase database;

  Future<List<RelationDisplayItem>> forAsset(String assetId) async {
    final outgoing = await database.relationDao.getOutgoingRelations(assetId);
    final incoming = await database.relationDao.getIncomingRelations(assetId);
    final assets = await database.assetDao.getAllAssets();
    final names = {for (final asset in assets) asset.id: asset.name};
    return [
      ...outgoing.map(
        (relation) => RelationDisplayItem(
          relationId: relation.id,
          label: relationDisplayLabel(
            type: _type(relation.relationType),
            incoming: false,
          ),
          assetId: relation.targetAssetId,
          assetName: names[relation.targetAssetId] ?? relation.targetAssetId,
          incoming: false,
        ),
      ),
      ...incoming.map(
        (relation) => RelationDisplayItem(
          relationId: relation.id,
          label: relationDisplayLabel(
            type: _type(relation.relationType),
            incoming: true,
          ),
          assetId: relation.sourceAssetId,
          assetName: names[relation.sourceAssetId] ?? relation.sourceAssetId,
          incoming: true,
        ),
      ),
    ];
  }

  AssetRelationType _type(String value) => AssetRelationType.values.firstWhere(
    (type) => type.value == value,
    orElse: () => AssetRelationType.relatedTo,
  );
}
