import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';
import 'package:void_scriptor/features/relations/application/create_relation_service.dart';
import 'package:void_scriptor/features/relations/data/relation_repository_impl.dart';
import 'package:void_scriptor/features/weapon/application/create_weapon_service.dart';

void main() {
  test('weapon and uses relation survive database restart', () async {
    final root = await Directory.systemTemp.createTemp('s12-relation-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databasePath = (await paths.database('project-1')).path;
    final service = ProjectDatabaseService();
    await service.create(databasePath);

    final first = await service.open(databasePath);
    final weaponId = await CreateWeaponService(database: first, paths: paths)
        .create(
          projectId: 'project-1',
          name: 'Void Dual Dagger',
          weaponType: 'Dual Dagger',
        );
    await first
        .into(first.assets)
        .insert(
          AssetsCompanion.insert(
            id: 'qowner',
            projectId: 'project-1',
            name: 'Qowner',
            type: 'character',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
    final repository = RelationRepositoryImpl(database: first);
    await CreateRelationService(repository)(
      projectId: 'project-1',
      sourceId: 'qowner',
      targetId: weaponId,
      type: AssetRelationType.uses,
    );
    await first.close();

    final second = await service.open(databasePath);
    addTearDown(second.close);
    expect(second.schemaVersion, 35);
    expect(
      (await second.weaponDao.getWeapon(weaponId))?.name,
      'Void Dual Dagger',
    );
    final incoming = await second.relationDao.getIncomingRelations(weaponId);
    expect(incoming, hasLength(1));
    expect(incoming.single.sourceAssetId, 'qowner');
    expect(incoming.single.relationType, 'uses');
  });
}
