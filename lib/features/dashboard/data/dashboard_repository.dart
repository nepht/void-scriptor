import '../../../database/project/project_database.dart';
import '../domain/dashboard_snapshot.dart';

class DashboardRepository {
  const DashboardRepository();

  Future<DashboardSnapshot> loadProjectSnapshot(
    ProjectDatabase database,
    String projectId,
  ) async {
    final assetsFuture = database.assetDao.getAllAssets();
    final charactersFuture = database.characterDao.getAllCharacters(projectId);
    final wardrobesFuture = database.wardrobeDao.getWardrobes(projectId);
    final weaponsFuture = database.weaponDao.getWeapons(projectId);
    final environmentsFuture = database.environmentDao.getEnvironments(
      projectId,
    );

    final assets = await assetsFuture;
    final characters = await charactersFuture;
    final wardrobes = await wardrobesFuture;
    final weapons = await weaponsFuture;
    final environments = await environmentsFuture;

    return DashboardSnapshot(
      projects: 1,
      characters: characters.length,
      wardrobes: wardrobes.length,
      weapons: weapons.length,
      environments: environments.length,
      assets: assets.where((asset) => asset.projectId == projectId).length,
    );
  }
}
