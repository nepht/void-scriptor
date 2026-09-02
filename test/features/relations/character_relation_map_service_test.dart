import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';
import 'package:void_scriptor/features/character/application/create_character_service.dart';
import 'package:void_scriptor/features/relations/application/character_relation_map_service.dart';
import 'package:void_scriptor/features/relations/application/create_relation_service.dart';
import 'package:void_scriptor/features/relations/data/relation_repository_impl.dart';

void main() {
  Future<(ProjectDatabase, ProjectPaths)> openDb(Directory root) async {
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final db = await service.open(dbPath);
    return (db, ProjectPaths(rootDirectory: root));
  }

  Future<String> seedCharacter(
    ProjectDatabase db,
    ProjectPaths paths,
    String projectId,
    String name,
  ) async {
    return CreateCharacterService(
      database: db,
      paths: paths,
    ).create(projectId: projectId, name: name);
  }

  test('map is empty when the project has no relations', () async {
    final root = await Directory.systemTemp.createTemp('relmap-empty-');
    addTearDown(() => root.delete(recursive: true));
    final (db, _) = await openDb(root);
    addTearDown(db.close);

    final map = await const CharacterRelationMapService().mapForProject(
      db,
      projectId: 'project-1',
    );
    expect(map, isEmpty);
  });

  test(
    'character-to-character relation resolves both endpoint names',
    () async {
      final root = await Directory.systemTemp.createTemp('relmap-resolve-');
      addTearDown(() => root.delete(recursive: true));
      final (db, paths) = await openDb(root);
      addTearDown(db.close);

      final raka = await seedCharacter(db, paths, 'project-1', 'Raka');
      final sinta = await seedCharacter(db, paths, 'project-1', 'Sinta');
      await CreateRelationService(RelationRepositoryImpl(database: db)).call(
        projectId: 'project-1',
        sourceId: raka,
        targetId: sinta,
        type: AssetRelationType.companionOf,
      );

      final map = await const CharacterRelationMapService().mapForProject(
        db,
        projectId: 'project-1',
      );
      expect(map, hasLength(1));
      expect(map.first.sourceName, 'Raka');
      expect(map.first.targetName, 'Sinta');
      expect(map.first.typeLabel, 'companion_of');
      expect(map.first.sourceAssetId, raka);
      expect(map.first.targetAssetId, sinta);
      expect(map.first.relationId, isNotEmpty);
    },
  );

  test('map rows survive project database close and reopen', () async {
    final root = await Directory.systemTemp.createTemp('relmap-restart-');
    addTearDown(() => root.delete(recursive: true));
    final (db, paths) = await openDb(root);
    final raka = await seedCharacter(db, paths, 'project-1', 'Raka');
    final sinta = await seedCharacter(db, paths, 'project-1', 'Sinta');
    await CreateRelationService(RelationRepositoryImpl(database: db)).call(
      projectId: 'project-1',
      sourceId: raka,
      targetId: sinta,
      type: AssetRelationType.enemyOf,
    );
    await db.close();

    final service = ProjectDatabaseService();
    final reopened = await service.open('${root.path}/project.db');
    addTearDown(reopened.close);

    final map = await const CharacterRelationMapService().mapForProject(
      reopened,
      projectId: 'project-1',
    );
    expect(map, hasLength(1));
    expect(map.first.sourceName, 'Raka');
    expect(map.first.targetName, 'Sinta');
    expect(map.first.typeLabel, 'enemy_of');
  });
}
