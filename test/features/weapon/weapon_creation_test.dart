import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/weapon/application/create_weapon_service.dart';

void main() {
  test(
    'creates weapon asset, defaults, preservation, and project folders',
    () async {
      final root = await Directory.systemTemp.createTemp('s12-weapon-');
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

      expect((await database.assetDao.getById(id))?.type, 'weapon');
      expect(
        (await database.weaponDao.getWeapon(id))?.name,
        'Void Dual Dagger',
      );
      expect((await database.weaponDao.getDefaultVariant(id))?.name, 'Normal');
      expect(
        (await database.weaponDao.getPreservationProfile(id))?.geometryLock,
        isTrue,
      );
      expect(
        await Directory(
          '${(await paths.project('project-1')).path}${Platform.pathSeparator}assets${Platform.pathSeparator}weapons${Platform.pathSeparator}$id${Platform.pathSeparator}references${Platform.pathSeparator}orthographic',
        ).exists(),
        isTrue,
      );

      await database.close();
      final reopened = await ProjectDatabaseService().open(databasePath);
      addTearDown(reopened.close);
      expect(
        (await reopened.weaponDao.getWeapon(id))?.name,
        'Void Dual Dagger',
      );
      expect((await reopened.weaponDao.getDefaultVariant(id))?.name, 'Normal');
      expect(
        (await reopened.weaponDao.getPreservationProfile(id))?.geometryLock,
        isTrue,
      );
    },
  );
}
