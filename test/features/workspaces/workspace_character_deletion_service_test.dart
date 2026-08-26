import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_character_deletion_service.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

void main() {
  test(
    'reviews affected novels and requires an explicit deletion decision',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'workspace-delete-review-',
      );
      addTearDown(() => root.delete(recursive: true));
      final path = '${root.path}/project.db';
      final databaseService = ProjectDatabaseService();
      await databaseService.create(path);
      final database = await databaseService.open(path);
      addTearDown(database.close);
      final links = NovelCharacterLinkRepository(
        database: database,
        projectId: 'project-1',
      );
      await links.create(
        NovelCharacterLink.create(
          linkId: 'link-1',
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'character-1',
          characterId: 'character-1',
          role: 'protagonist',
          visibility: 'visible',
          now: DateTime.utc(2026, 8, 22),
        ),
      );
      var deleted = false;
      final service = WorkspaceCharacterDeletionService(
        links: links,
        projections: WorkspaceProjectionCache(loader: links.listForNovel),
        deleteCharacterSource: (_) async => deleted = true,
      );

      final review = await service.review('character-1');
      expect(review.affectedNovelWorkspaceIds, ['novel-1']);
      expect(
        review.availableDecisions,
        contains(CharacterDeletionDecision.unlink),
      );
      expect(
        () => service.deleteCharacterWorkspace('character-1'),
        throwsA(isA<StateError>()),
      );
      expect(deleted, isFalse);
    },
  );

  test(
    'explicit unlink removes links before deleting the character source',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'workspace-delete-unlink-',
      );
      addTearDown(() => root.delete(recursive: true));
      final path = '${root.path}/project.db';
      final databaseService = ProjectDatabaseService();
      await databaseService.create(path);
      final database = await databaseService.open(path);
      addTearDown(database.close);
      final links = NovelCharacterLinkRepository(
        database: database,
        projectId: 'project-1',
      );
      await links.create(
        NovelCharacterLink.create(
          linkId: 'link-1',
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'character-1',
          characterId: 'character-1',
          role: 'protagonist',
          visibility: 'visible',
          now: DateTime.utc(2026, 8, 22),
        ),
      );
      var deletedAfterUnlink = false;
      final service = WorkspaceCharacterDeletionService(
        links: links,
        projections: WorkspaceProjectionCache(loader: links.listForNovel),
        deleteCharacterSource: (_) async {
          deletedAfterUnlink = (await links.listForCharacter(
            'character-1',
          )).isEmpty;
        },
      );

      await service.deleteCharacterWorkspace(
        'character-1',
        decision: CharacterDeletionDecision.unlink,
      );

      expect(deletedAfterUnlink, isTrue);
      expect(await links.listForNovel('novel-1'), isEmpty);
    },
  );
}
