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

void main() {
  final openClosers = <Future<void> Function()>[];

  void registerDb(Future<void> Function() close) {
    openClosers.add(close);
  }

  tearDown(() async {
    for (final close in openClosers.reversed) {
      await close();
    }
    openClosers.clear();
  });

  Future<({ProjectPackage package, NovelCharacterLinkRepository links})>
  makePackage(Directory root, String name) async {
    final package = await ProjectPackageService(
      rootDirectory: Directory('${root.path}/$name'),
    ).create(name: name);
    final db = await ProjectDatabaseService().open(package.databaseFile.path);
    registerDb(db.close);
    return (
      package: package,
      links: NovelCharacterLinkRepository(
        database: db,
        projectId: package.projectId,
      ),
    );
  }

  Future<void> seedLink(
    NovelCharacterLinkRepository links, {
    required String linkId,
    required String novelId,
    required String characterId,
    DateTime? createdAt,
  }) async {
    await links.create(
      NovelCharacterLink.create(
        linkId: linkId,
        novelWorkspaceId: novelId,
        characterWorkspaceId: characterId,
        characterId: characterId,
        role: 'protagonist',
        visibility: 'visible',
        mode: LinkMode.snapshot,
        now: createdAt ?? DateTime.utc(2026, 8, 22),
      ),
    );
  }

  Future<File> exportNovel(
    Directory root,
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
    ).exportNovel(novelId, destination: root);
  }

  test('fail choice rejects importing over an existing Novel', () async {
    final root = await Directory.systemTemp.createTemp('ws-import-fail-');
    addTearDown(() => root.delete(recursive: true));
    final source = await makePackage(root, 'source');
    final archive = await exportNovel(
      root,
      source.package,
      source.links,
      'novel-1',
    );

    final target = await makePackage(root, 'target');
    await WorkspaceImportService(
      package: target.package,
      links: target.links,
    ).restoreNovel(archive);

    expect(
      () => WorkspaceImportService(package: target.package, links: target.links)
          .restoreNovel(
            archive,
            collisionChoice: WorkspaceImportCollisionChoice.fail,
          ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'Novel workspace already exists; collision decision is required.',
        ),
      ),
    );
  });

  test('skip choice leaves an existing Novel completely untouched', () async {
    final root = await Directory.systemTemp.createTemp('ws-import-skip-');
    addTearDown(() => root.delete(recursive: true));
    final source = await makePackage(root, 'source');
    await seedLink(
      source.links,
      linkId: 'link-1',
      novelId: 'novel-1',
      characterId: 'character-1',
    );
    final archive = await exportNovel(
      root,
      source.package,
      source.links,
      'novel-1',
    );

    final target = await makePackage(root, 'target');
    await WorkspaceImportService(
      package: target.package,
      links: target.links,
    ).restoreNovel(archive);

    final localFile = await WorkspaceFileNamespace(
      target.package,
    ).createNovelFile('novel-1', 'drafts/local.md');
    await localFile.writeAsString('# Local edit');

    final result =
        await WorkspaceImportService(
          package: target.package,
          links: target.links,
        ).restoreNovel(
          archive,
          collisionChoice: WorkspaceImportCollisionChoice.skip,
        );

    expect(result.workspaceId, 'novel-1');
    expect(result.skipped, isTrue);
    expect(result.restoredLinkCount, 0);
    expect(await localFile.readAsString(), '# Local edit');
    expect(await target.links.listForNovel('novel-1'), hasLength(1));
  });

  test('adopt choice preserves files and inserts only missing links', () async {
    final root = await Directory.systemTemp.createTemp('ws-import-adopt-');
    addTearDown(() => root.delete(recursive: true));

    final firstSource = await makePackage(root, 'first-source');
    await seedLink(
      firstSource.links,
      linkId: 'link-1',
      novelId: 'novel-1',
      characterId: 'character-1',
      createdAt: DateTime.utc(2026, 8, 22),
    );
    final firstOut = Directory('${root.path}/out1')
      ..createSync(recursive: true);
    final firstArchive = await exportNovel(
      firstOut,
      firstSource.package,
      firstSource.links,
      'novel-1',
    );

    final secondSource = await makePackage(root, 'second-source');
    await seedLink(
      secondSource.links,
      linkId: 'link-1',
      novelId: 'novel-1',
      characterId: 'character-1',
      createdAt: DateTime.utc(2027, 1, 1),
    );
    await seedLink(
      secondSource.links,
      linkId: 'link-2',
      novelId: 'novel-1',
      characterId: 'character-2',
      createdAt: DateTime.utc(2027, 1, 2),
    );
    final secondArchive = await exportNovel(
      root,
      secondSource.package,
      secondSource.links,
      'novel-1',
    );

    final target = await makePackage(root, 'target');
    await WorkspaceImportService(
      package: target.package,
      links: target.links,
    ).restoreNovel(firstArchive);
    final localFile = await WorkspaceFileNamespace(
      target.package,
    ).createNovelFile('novel-1', 'drafts/chapter.md');
    await localFile.writeAsString('# Local edit');

    final result =
        await WorkspaceImportService(
          package: target.package,
          links: target.links,
        ).restoreNovel(
          secondArchive,
          collisionChoice: WorkspaceImportCollisionChoice.adoptExistingLinks,
        );

    expect(result.workspaceId, 'novel-1');
    expect(result.skipped, isFalse);
    expect(result.restoredLinkCount, 1);
    expect(await localFile.readAsString(), '# Local edit');

    final adopted = await target.links.listForNovel('novel-1');
    expect(adopted, hasLength(2));
    final kept = adopted.singleWhere((l) => l.linkId == 'link-1');
    expect(kept.createdAt, DateTime.utc(2026, 8, 22));
    expect(
      adopted.map((l) => l.characterWorkspaceId),
      containsAll(<String>['character-1', 'character-2']),
    );
  });

  test('skip falls back to a normal restore without a collision', () async {
    final root = await Directory.systemTemp.createTemp('ws-import-empty-');
    addTearDown(() => root.delete(recursive: true));
    final source = await makePackage(root, 'source');
    await seedLink(
      source.links,
      linkId: 'link-1',
      novelId: 'novel-1',
      characterId: 'character-1',
    );
    final archive = await exportNovel(
      root,
      source.package,
      source.links,
      'novel-1',
    );
    final target = await makePackage(root, 'target');

    final result =
        await WorkspaceImportService(
          package: target.package,
          links: target.links,
        ).restoreNovel(
          archive,
          collisionChoice: WorkspaceImportCollisionChoice.skip,
        );

    expect(result.skipped, isFalse);
    expect(result.restoredLinkCount, 1);
    expect(
      await WorkspaceFileNamespace(
        target.package,
      ).novelFile('novel-1', 'drafts/chapter.md').readAsString(),
      '# Chapter novel-1',
    );
  });
}
