import '../../../database/project/project_database.dart';
import '../domain/dashboard_snapshot.dart';

class DashboardRepository {
  const DashboardRepository();

  Future<DashboardSnapshot> loadProjectSnapshot(
    ProjectDatabase database,
    String projectId,
  ) async {
    // vs-hunt-20260913-dashboard DB-BUG-01: asset count is computed in SQL
    // via assetDao.countByProject instead of loading the whole assets table
    // and filtering client-side.
    final charactersFuture = database.characterDao.getAllCharacters(projectId);
    final wardrobesFuture = database.wardrobeDao.getWardrobes(projectId);
    final weaponsFuture = database.weaponDao.getWeapons(projectId);
    final environmentsFuture = database.environmentDao.getEnvironments(
      projectId,
    );
    final assetsFuture = database.assetDao.countByProject(projectId);

    final characters = await charactersFuture;
    final wardrobes = await wardrobesFuture;
    final weapons = await weaponsFuture;
    final environments = await environmentsFuture;
    final assetCount = await assetsFuture;

    return DashboardSnapshot(
      projects: 1,
      characters: characters.length,
      wardrobes: wardrobes.length,
      weapons: weapons.length,
      environments: environments.length,
      assets: assetCount,
    );
  }
}
