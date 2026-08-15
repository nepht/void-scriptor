import '../../assets/domain/asset_type.dart';

/// A single workspace tab (Step 27.2).
class WorkspaceTab {
  const WorkspaceTab({
    required this.id,
    required this.assetId,
    required this.assetType,
    required this.title,
  });

  final String id;
  final String assetId;
  final AssetType assetType;
  final String title;

  @override
  bool operator ==(Object other) => other is WorkspaceTab && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
