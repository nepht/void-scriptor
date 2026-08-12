import 'dart:io';

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';
import '../domain/environment_model.dart';

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
