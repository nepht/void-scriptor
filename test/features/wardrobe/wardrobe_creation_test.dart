import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/wardrobe/application/create_wardrobe_service.dart';

void main() {
  test('creates wardrobe asset, default variant, and project folders', () async {
    final root = await Directory.systemTemp.createTemp('s11-wardrobe-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databasePath = (await paths.database('project-1')).path;
    await ProjectDatabaseService().create(databasePath);
    final database = await ProjectDatabaseService().open(databasePath);
    addTearDown(database.close);

    final id = await CreateWardrobeService(
      database: database,
      paths: paths,
    ).create(projectId: 'project-1', name: 'Void Coat');

    expect((await database.wardrobeDao.getWardrobe(id))?.name, 'Void Coat');
    expect((await database.wardrobeDao.getDefaultVariant(id))?.name, 'Normal');
    expect(
      await Directory(
        '${(await paths.project('project-1')).path}${Platform.pathSeparator}assets${Platform.pathSeparator}wardrobe${Platform.pathSeparator}$id${Platform.pathSeparator}references',
      ).exists(),
      isTrue,
    );
  });
}
