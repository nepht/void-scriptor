import 'dart:io';

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';
import '../domain/environment_model.dart';
import '../domain/environment_workspace_data.dart';

class EnvironmentRepositoryImpl {
  EnvironmentRepositoryImpl({
    required this.database,
    required this.projectId,
    ProjectPaths? paths,
  }) : paths = paths ?? ProjectPaths();

  final ProjectDatabase database;
  final String projectId;
  final ProjectPaths paths;

  Future<List<EnvironmentModel>> getEnvironments() async =>
      (await database.environmentDao.getEnvironments(
        projectId,
      )).map(_map).toList();

  Future<EnvironmentModel?> getEnvironment(String assetId) async {
    final row = await database.environmentDao.getEnvironment(assetId);
    return row == null ? null : _map(row);
  }

  /// Persisted profile data for the workspace cards (ENV-BUG-002): default
  /// weather profile, first lighting profile, ordered zone names, and the
  /// most recent continuity state — all read back from the project database
  /// instead of hardcoded stub values.
  Future<EnvironmentWorkspaceData> getWorkspaceData(String assetId) async {
    final weather = await database.environmentDao.getWeatherProfiles(assetId);
    final lighting = await database.environmentDao.getLightingProfiles(assetId);
    final zones = await database.environmentDao.getZones(assetId);
    final continuity = await database.environmentDao.getContinuityStates(
      assetId,
    );
    return EnvironmentWorkspaceData(
      weather: weather.isEmpty
          ? null
          : EnvironmentWeatherData(
              condition: weather.first.weatherPreset,
              intensity: weather.first.intensity,
              visibility: weather.first.visibility,
            ),
      lighting: lighting.isEmpty
          ? null
          : EnvironmentLightingData(
              time: lighting.first.timePreset,
              keyLight: lighting.first.keyLight,
              fogDensity: lighting.first.fogDensity,
            ),
      zones: [for (final zone in zones) zone.name],
      continuityStateName: continuity.isEmpty ? null : continuity.last.name,
    );
  }

  Future<void> deleteEnvironment(String assetId) async {
    await database.transaction(() async {
      await database.assetDao.removeAssetData(assetId);
      await database.environmentDao.removeEnvironmentData(assetId);
      await (database.delete(
        database.assets,
      )..where((row) => row.id.equals(assetId))).go();
    });
    final project = await paths.project(projectId);
    final directory = Directory(
      '${project.path}${Platform.pathSeparator}assets${Platform.pathSeparator}environments${Platform.pathSeparator}$assetId',
    );
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  EnvironmentModel _map(Environment row) => EnvironmentModel(
    assetId: row.assetId,
    projectId: row.projectId,
    name: row.name,
    environmentType: row.environmentType,
    description: row.description,
    location: row.location,
    architecture: row.architecture,
    terrain: row.terrain,
    notes: row.notes,
  );
}
