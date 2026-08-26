import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

void main() {
  test(
    'persists and reloads a novel-character link after database reopen',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's109-link-persistence-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      const projectId = 'project-1';
      final databasePath = (await paths.database(projectId)).path;
      final databaseService = ProjectDatabaseService();
      await databaseService.create(databasePath);

      var database = await databaseService.open(databasePath);
      final repository = NovelCharacterLinkRepository(
        database: database,
        projectId: projectId,
      );
      final created = await repository.create(
        NovelCharacterLink.create(
          linkId: 'link-1',
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'character-1',
          characterId: 'character-entity-1',
          role: 'protagonist',
          visibility: 'visible',
          mode: LinkMode.reference,
          now: DateTime.utc(2026, 8, 22, 10, 30),
        ),
      );
      expect(created.linkId, 'link-1');
      await database.close();

      database = await databaseService.open(databasePath);
      final reopened = NovelCharacterLinkRepository(
        database: database,
        projectId: projectId,
      );
      addTearDown(database.close);
      final links = await reopened.listForNovel('novel-1');

      expect(links, hasLength(1));
      expect(links.single.mode, LinkMode.reference);
      expect(links.single.characterId, 'character-entity-1');
      expect(links.single.createdAt, DateTime.utc(2026, 8, 22, 10, 30));
    },
  );
}
