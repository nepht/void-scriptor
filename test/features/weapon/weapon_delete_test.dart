import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/weapon/application/create_weapon_service.dart';
import 'package:void_scriptor/features/weapon/data/weapon_repository_impl.dart';

void main() {
  test(
    'weapon repository deletes technical data, universal asset, and folder',
    () async {
      final root = await Directory.systemTemp.createTemp('s12-weapon-delete-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final databasePath = (await paths.database('project-1')).path;
      await ProjectDatabaseService().create(databasePath);
      final database = await ProjectDatabaseService().open(databasePath);
      addTearDown(database.close);

      final id = await CreateWeaponService(database: database, paths: paths)
          .create(
            projectId: 'project-1',
            name: 'Void Dual Dagger',
            weaponType: 'Dual Dagger',
          );
      final repository = WeaponRepositoryImpl(
        database: database,
        projectId: 'project-1',
        paths: paths,
      );
      await repository.deleteWeapon(id);

      expect(await database.assetDao.getById(id), isNull);
      expect(await database.weaponDao.getWeapon(id), isNull);
      expect(await database.weaponDao.getVariants(id), isEmpty);
      expect(
        await Directory(
          '${(await paths.project('project-1')).path}${Platform.pathSeparator}assets${Platform.pathSeparator}weapons${Platform.pathSeparator}$id',
        ).exists(),
        isFalse,
      );
    },
  );
}
