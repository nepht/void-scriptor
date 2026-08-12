import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/environment/application/create_environment_service.dart';
import 'package:void_scriptor/features/environment/data/environment_repository_impl.dart';
import 'package:void_scriptor/features/environment/domain/environment_type.dart';

void main() {
  test('creates environment asset, profiles, physics, and folders', () async {
    final root = await Directory.systemTemp.createTemp('s14-environment-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databasePath = (await paths.database('project-1')).path;
    await ProjectDatabaseService().create(databasePath);
    final database = await ProjectDatabaseService().open(databasePath);
    addTearDown(database.close);

    final id = await CreateEnvironmentService(database: database, paths: paths)
        .create(
          projectId: 'project-1',
          name: 'Neo Futuristic Megacity',
          type: EnvironmentType.city,
        );

    expect((await database.assetDao.getById(id))?.type, 'environment');
    expect(
      (await database.environmentDao.getEnvironment(id))?.name,
      'Neo Futuristic Megacity',
    );
    expect(
      (await database.environmentDao.getWeatherProfiles(
        id,
      )).single.weatherPreset,
      'clear',
    );
    expect(
      (await database.environmentDao.getLightingProfiles(id)).single.timePreset,
      'noon',
    );
    expect(
      (await database.select(database.environmentPhysicsProfiles).get())
          .single
          .environmentId,
      id,
    );
    expect(
      await Directory(
        '${(await paths.project('project-1')).path}${Platform.pathSeparator}assets${Platform.pathSeparator}environments${Platform.pathSeparator}$id${Platform.pathSeparator}references${Platform.pathSeparator}lighting',
      ).exists(),
      isTrue,
    );

    final repository = EnvironmentRepositoryImpl(
      database: database,
      projectId: 'project-1',
      paths: paths,
    );
    expect((await repository.getEnvironments()).single.assetId, id);
    await repository.deleteEnvironment(id);
    expect(await database.assetDao.getById(id), isNull);
  });

  test('environment schema survives database restart', () async {
    final root = await Directory.systemTemp.createTemp('s14-restart-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databasePath = (await paths.database('project-1')).path;
    await ProjectDatabaseService().create(databasePath);
    final first = await ProjectDatabaseService().open(databasePath);
    final id = await CreateEnvironmentService(database: first, paths: paths)
        .create(
          projectId: 'project-1',
          name: 'Rooftop District',
          type: EnvironmentType.city,
        );
    await first.close();

    final second = await ProjectDatabaseService().open(databasePath);
    addTearDown(second.close);
    expect(second.schemaVersion, 10);
    expect(
      (await second.environmentDao.getEnvironment(id))?.name,
      'Rooftop District',
    );
    expect((await second.environmentDao.getWeatherProfiles(id)), hasLength(1));
  });
}
