import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/wardrobe/application/create_wardrobe_service.dart';
import 'package:void_scriptor/features/wardrobe/data/wardrobe_repository_impl.dart';

void main() {
  test(
    'wardrobe repository deletes technical data, universal asset, and folder',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's11-wardrobe-delete-',
      );
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
      final repository = WardrobeRepositoryImpl(
        database: database,
        projectId: 'project-1',
        paths: paths,
      );
      await repository.deleteWardrobe(id);

      expect(await database.assetDao.getById(id), isNull);
      expect(await database.wardrobeDao.getWardrobe(id), isNull);
      expect(await database.wardrobeDao.getVariants(id), isEmpty);
      expect(
        await Directory(
          '${(await paths.project('project-1')).path}${Platform.pathSeparator}assets${Platform.pathSeparator}wardrobe${Platform.pathSeparator}$id',
        ).exists(),
        isFalse,
      );
    },
  );
}
