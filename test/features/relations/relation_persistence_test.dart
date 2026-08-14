import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';
import 'package:void_scriptor/features/relations/application/create_relation_service.dart';
import 'package:void_scriptor/features/relations/data/relation_repository_impl.dart';

void main() {
  test(
    'relation repository persists outgoing and incoming relations',
    () async {
      final root = await Directory.systemTemp.createTemp('s10-relation-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final databasePath = (await paths.database('project-1')).path;
      await ProjectDatabaseService().create(databasePath);
      final database = await ProjectDatabaseService().open(databasePath);
      addTearDown(database.close);

      final repository = RelationRepositoryImpl(database: database);
      await CreateRelationService(repository)(
        projectId: 'project-1',
        sourceId: 'qowner',
        targetId: 'void-coat',
        type: AssetRelationType.wears,
      );

      final outgoing = await repository.outgoing('qowner');
      final incoming = await repository.incoming('void-coat');
      expect(outgoing, hasLength(1));
      expect(outgoing.single.type, AssetRelationType.wears);
      expect(incoming.single.sourceAssetId, 'qowner');

      await repository.delete(outgoing.single.id);
      expect(await repository.outgoing('qowner'), isEmpty);
    },
  );

  test(
    'asset cleanup cascades relations without deleting the target asset',
    () async {
      final root = await Directory.systemTemp.createTemp('s10-cleanup-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final databasePath = (await paths.database('project-1')).path;
      await ProjectDatabaseService().create(databasePath);
      final database = await ProjectDatabaseService().open(databasePath);
      addTearDown(database.close);
      final createdAt = DateTime(2026);
      for (final asset in [
        ('source', 'Qowner', 'character'),
        ('target', 'Void Dual Dagger', 'weapon'),
      ]) {
        await database
            .into(database.assets)
            .insert(
              AssetsCompanion.insert(
                id: asset.$1,
                projectId: 'project-1',
                name: asset.$2,
                type: asset.$3,
                createdAt: createdAt,
                updatedAt: createdAt,
              ),
            );
      }
      final repository = RelationRepositoryImpl(database: database);
      await CreateRelationService(repository)(
        projectId: 'project-1',
        sourceId: 'source',
        targetId: 'target',
        type: AssetRelationType.uses,
      );

      await database.assetDao.removeAssetData('source');

      expect(await repository.outgoing('source'), isEmpty);
      expect(await repository.incoming('target'), isEmpty);
      expect(
        (await database.assetDao.getById('target'))?.name,
        'Void Dual Dagger',
      );
    },
  );
}
