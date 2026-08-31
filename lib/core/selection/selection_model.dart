import '../domain/asset_type.dart';

class SelectionModel {
  const SelectionModel({
    required this.assetId,
    required this.assetType,
    this.projectId,
  });

  final String assetId;
  final AssetType assetType;
  final String? projectId;

  @override
  bool operator ==(Object other) =>
      other is SelectionModel &&
      other.assetId == assetId &&
      other.assetType == assetType &&
      other.projectId == projectId;

  @override
  int get hashCode => Object.hash(assetId, assetType, projectId);
}
