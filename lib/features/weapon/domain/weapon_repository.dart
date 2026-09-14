import '../domain/weapon_model.dart';
import '../domain/weapon_workspace_data.dart';

abstract interface class WeaponRepository {
  Future<List<WeaponModel>> getWeapons();
  Future<WeaponModel?> getWeapon(String assetId);

  /// Persisted child rows (components/measurements/energy/variants/
  /// references) resolved for the workspace detail cards
  /// (vs-hunt-20260914-wardrobe-weapon WBUG-6).
  Future<WeaponWorkspaceData> getWorkspaceData(String assetId);

  Future<void> deleteWeapon(String assetId);
}
