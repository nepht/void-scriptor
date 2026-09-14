import '../domain/wardrobe_model.dart';
import '../domain/wardrobe_workspace_data.dart';

abstract interface class WardrobeRepository {
  Future<List<WardrobeModel>> getWardrobes();
  Future<WardrobeModel?> getWardrobe(String assetId);

  /// Persisted child rows (components/colors/variants/references) resolved
  /// for the workspace detail cards (vs-hunt-20260914-wardrobe-weapon WBUG-5).
  Future<WardrobeWorkspaceData> getWorkspaceData(String assetId);

  Future<void> deleteWardrobe(String assetId);
}
