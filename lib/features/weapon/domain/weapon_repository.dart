import '../domain/weapon_model.dart';

abstract interface class WeaponRepository {
  Future<List<WeaponModel>> getWeapons();
  Future<WeaponModel?> getWeapon(String assetId);
  Future<void> deleteWeapon(String assetId);
}
