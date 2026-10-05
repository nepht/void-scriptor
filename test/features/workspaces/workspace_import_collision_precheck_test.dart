import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_import_service.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

/// vs-hunt-20260912n BUG-07 + BUG-20 (Referee REAL, Medium):
/// restoreNovel threw a hard StateError whenever `expectedWorkspaceId` was
/// set and the target already existed — BEFORE reading the archive and
/// regardless of `collisionChoice`. That made the documented `skip`
/// (return skipped:true, leave the target untouched) and
/// `adoptExistingLinks` (insert only missing links) unreachable whenever the
/// caller supplied an explicit workspace ID, and it let a collision error
/// mask a corrupt-archive error on those non-fail choices.
void main() {
  Future<
    ({
      ProjectPackage package,
      NovelCharacterLinkRepository links,
      ProjectDatabaseServiceCloser closer,
    })
  >
  makePackage(Directory root, String name) async {
    final package = await ProjectPackageService(
      rootDirectory: Directory('${root.path}/$name'),
    ).create(name: name);
    final db = await ProjectDatabaseService().open(package.databaseFile.path);
    addTearDown(db.close);
    return (
      package: package,
      links: NovelCharacterLinkRepository(
        database: db,
        projectId: package.projectId,
      ),
      closer: db.close,
    );
  }

  Future<File> exportNovel(
    Directory destination,
    ProjectPackage package,
    NovelCharacterLinkRepository links,
    String novelId,
  ) async {
    await WorkspaceFileNamespace(package)
        .createNovelFile(novelId, 'drafts/chapter.md')
        .then((file) => file.writeAsString('# Chapter $novelId'));
    return WorkspaceExportService(
      package: package,
      links: links,
    ).exportNovel(novelId, destination: destination);
  }

  Future<void> seedLink(
    NovelCharacterLinkRepository links, {
    required String linkId,
    required String novelId,
    required String characterId,
  }) async {
    await links.create(
      NovelCharacterLink.create(
        linkId: linkId,
        novelWorkspaceId: novelId,
        characterWorkspaceId: characterId,
        characterId: characterId,
        role: 'protagonist',
        visibility: 'visible',
        mode: LinkMode.reference,
        now: DateTime.utc(2026, 9, 12),
      ),
    );
  }

  test(
    'skip + expectedWorkspaceId returns a skipped result instead of throwing',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-precheck-skip-');
      addTearDown(() => root.delete(recursive: true));
      final source = await makePackage(root, 'source');
      await seedLink(
        source.links,
        linkId: 'link-1',
        novelId: 'novel-7',
        characterId: 'character-1',
      );
      final archive = await exportNovel(
        root,
        source.package,
        source.links,
        'novel-7',
      );

      final target = await makePackage(root, 'target');
      await WorkspaceImportService(
        package: target.package,
        links: target.links,
      ).restoreNovel(archive);
      final localFile = await WorkspaceFileNamespace(
        target.package,
      ).createNovelFile('novel-7', 'drafts/local.md');
      await localFile.writeAsString('# Local edit');

      final result =
          await WorkspaceImportService(
            package: target.package,
            links: target.links,
          ).restoreNovel(
            archive,
            expectedWorkspaceId: 'novel-7',
            collisionChoice: WorkspaceImportCollisionChoice.skip,
          );

      expect(result.skipped, isTrue);
      expect(result.workspaceId, 'novel-7');
      expect(result.restoredLinkCount, 0);
      expect(await localFile.readAsString(), '# Local edit');
      expect(await target.links.listForNovel('novel-7'), hasLength(1));
    },
  );

  test(
    'adoptExistingLinks + expectedWorkspaceId stays reachable and idempotent',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-precheck-adopt-');
      addTearDown(() => root.delete(recursive: true));
      final source = await makePackage(root, 'source');
      await seedLink(
        source.links,
        linkId: 'link-1',
        novelId: 'novel-7',
        characterId: 'character-1',
      );
      final archive = await exportNovel(
        root,
        source.package,
        source.links,
        'novel-7',
      );

      final target = await makePackage(root, 'target');
      await WorkspaceImportService(
        package: target.package,
        links: target.links,
      ).restoreNovel(archive);
      final localFile = await WorkspaceFileNamespace(
        target.package,
      ).createNovelFile('novel-7', 'drafts/local.md');
      await localFile.writeAsString('# Local edit');

      // Same archive, same link IDs: adopting must be a no-op on links and
      // must never overwrite the local file — and it must not throw.
      final result =
          await WorkspaceImportService(
            package: target.package,
            links: target.links,
          ).restoreNovel(
            archive,
            expectedWorkspaceId: 'novel-7',
            collisionChoice: WorkspaceImportCollisionChoice.adoptExistingLinks,
          );

      expect(result.skipped, isFalse);
      expect(result.restoredLinkCount, 0);
      expect(await localFile.readAsString(), '# Local edit');
      expect(await target.links.listForNovel('novel-7'), hasLength(1));
    },
  );

  test('skip + expectedWorkspaceId surfaces a corrupt-archive error, '
      'not a masked skip', () async {
    final root = await Directory.systemTemp.createTemp('ws-precheck-corrupt-');
    addTearDown(() => root.delete(recursive: true));
    final target = await makePackage(root, 'target');
    // Target workspace already exists.
    final existing = await WorkspaceFileNamespace(
      target.package,
    ).createNovelFile('novel-7', 'drafts/chapter.md');
    await existing.writeAsString('# Existing');
    // Archive is garbage bytes, not a zip.
    final bogus = File('${root.path}/bogus.voidworkspace');
    await bogus.writeAsBytes(<int>[0, 1, 2, 3, 4, 5, 6, 7]);

    await expectLater(
      WorkspaceImportService(
        package: target.package,
        links: target.links,
      ).restoreNovel(
        bogus,
        expectedWorkspaceId: 'novel-7',
        collisionChoice: WorkspaceImportCollisionChoice.skip,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(await existing.readAsString(), '# Existing');
  });

  test('documented fail contract is preserved: missing archive + existing '
      'target still raises the collision StateError', () async {
    // This is the intentional ordering the old comment protected, and the
    // contract of workspace_import_service_test.dart:92. It must survive
    // the BUG-07 fix: the early throw belongs to `fail` only.
    final root = await Directory.systemTemp.createTemp('ws-precheck-fail-');
    addTearDown(() => root.delete(recursive: true));
    final target = await makePackage(root, 'target');
    final existing = await WorkspaceFileNamespace(
      target.package,
    ).createNovelFile('novel-1', 'existing.txt');
    await existing.writeAsString('preserve');
    final archive = File('${root.path}/missing.voidworkspace');

    await expectLater(
      WorkspaceImportService(
        package: target.package,
        links: target.links,
      ).restoreNovel(archive, expectedWorkspaceId: 'novel-1'),
      throwsA(isA<StateError>()),
    );
    expect(await existing.readAsString(), 'preserve');
  });
}

/// Alias so the record type above stays readable; db.close is `Future<void>`.
typedef ProjectDatabaseServiceCloser = Future<void> Function();
