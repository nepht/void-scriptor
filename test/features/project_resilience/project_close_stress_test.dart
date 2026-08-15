import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/daos/asset_dao.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-s26-close-'),
  );
  tearDown(() => root.delete(recursive: true));

  test(
    'closing project A releases its database before opening project B',
    () async {
      final service = ProjectPackageService(rootDirectory: root);
      final packageA = await service.create(name: 'Project A');
      final packageB = await service.create(name: 'Project B');

      final manager = ProjectSessionManager();

      // Open A, write a marker asset, then close.
      final sessionA = await manager.open(packageA);
      final now = DateTime.now().toUtc();
      await sessionA.database
          .into(sessionA.database.assets)
          .insert(
            AssetsCompanion.insert(
              id: 'asset-from-A',
              projectId: packageA.projectId,
              name: 'asset-from-A',
              type: 'reference',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await sessionA.close();

      // Open B and confirm no cross-project data.
      final sessionB = await manager.open(packageB);
      addTearDown(sessionB.close);

      final assetsInB = await AssetDao(sessionB.database).getAllAssets();
      expect(assetsInB.map((a) => a.name), isNot(contains('asset-from-A')));
    },
  );
}
