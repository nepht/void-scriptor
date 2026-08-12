import '../../../database/project/project_database.dart';
import '../domain/weapon_model.dart';
import '../domain/weapon_repository.dart';

class WeaponRepositoryImpl implements WeaponRepository {
  WeaponRepositoryImpl({required this.database, required this.projectId});

  final ProjectDatabase database;
  final String projectId;

  @override
  Future<List<WeaponModel>> getWeapons() async =>
      (await database.weaponDao.getWeapons(projectId)).map(_map).toList();

  @override
  Future<WeaponModel?> getWeapon(String assetId) async {
    final row = await database.weaponDao.getWeapon(assetId);
    return row == null ? null : _map(row);
  }

  WeaponModel _map(Weapon row) => WeaponModel(
    assetId: row.assetId,
    projectId: row.projectId,
    name: row.name,
    weaponType: row.weaponType,
    description: row.description,
    primaryMaterial: row.primaryMaterial,
    secondaryMaterial: row.secondaryMaterial,
    energyType: row.energyType,
    coreType: row.coreType,
    lengthMm: row.lengthMm,
    weightKg: row.weightKg,
    notes: row.notes,
  );
}
