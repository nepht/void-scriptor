import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_character_deletion_service.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

void main() {
  test(
    'active project session exposes a project-scoped workspace file namespace',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's109-session-workspace-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Session Workspace');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);

      final file = await session.workspaceFiles.createFile(
        'novel-session',
        'exports/novel.json',
      );
      await file.writeAsString('{"id":"novel-session"}');

      expect(await file.exists(), isTrue);
      expect(
        p.isWithin(
          p.join(package.root.path, 'workspaces', 'novel-session'),
          file.path,
        ),
        isTrue,
      );
      expect(session.workspaceFiles.packageRoot, package.root.path);
    },
  );

  test(
    'session projection cache reloads persisted novel-character links',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's109-session-projection-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Session Projection');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);

      final first = await session.workspaceProjections.forNovel('novel-1');
      expect(first.links, isEmpty);

      await session.novelCharacterLinks.create(
        NovelCharacterLink.create(
          linkId: 'link-1',
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'character-workspace-1',
          characterId: 'character-1',
          role: 'protagonist',
          visibility: 'visible',
          now: DateTime.utc(2026, 8, 22),
        ),
      );
      expect(
        (await session.workspaceProjections.forNovel('novel-1')).links,
        isEmpty,
      );

      session.workspaceProjections.invalidate('novel-1');
      final refreshed = await session.workspaceProjections.forNovel('novel-1');
      expect(refreshed.links.single.linkId, 'link-1');
    },
  );

  test(
    'active session requires affected-Novel review before Character deletion',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's109-session-deletion-review-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Session Deletion Review');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);
      await session.novelCharacterLinks.create(
        NovelCharacterLink.create(
          linkId: 'delete-link-1',
          novelWorkspaceId: 'novel-delete-1',
          characterWorkspaceId: 'character-delete-1',
          characterId: 'character-delete-1',
          role: 'supporting',
          visibility: 'visible',
          now: DateTime.utc(2026, 8, 22),
        ),
      );

      final review = await session.characterDeletion.review(
        'character-delete-1',
      );

      expect(review.affectedNovelWorkspaceIds, ['novel-delete-1']);
      expect(review.availableDecisions, {CharacterDeletionDecision.unlink});
    },
  );
}
