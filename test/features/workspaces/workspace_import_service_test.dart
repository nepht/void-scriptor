import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_import_service.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

void main() {
  test(
    'restores Novel files and link provenance into an empty target',
    () async {
      final root = await Directory.systemTemp.createTemp('workspace-restore-');
      addTearDown(() => root.delete(recursive: true));
      final source = await ProjectPackageService(
        rootDirectory: Directory('${root.path}/source'),
      ).create(name: 'Source');
      final sourceFile = await WorkspaceFileNamespace(
        source,
      ).createNovelFile('novel-1', 'drafts/chapter.md');
      await sourceFile.writeAsString('# Chapter');
      final sourceDb = await ProjectDatabaseService().open(
        source.databaseFile.path,
      );
      final sourceLinks = NovelCharacterLinkRepository(
        database: sourceDb,
        projectId: source.projectId,
      );
      await sourceLinks.create(
        NovelCharacterLink.create(
          linkId: 'link-1',
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'character-1',
          characterId: 'character-1',
          role: 'protagonist',
          visibility: 'visible',
          mode: LinkMode.snapshot,
          now: DateTime.utc(2026, 8, 22),
        ),
      );
      final archive = await WorkspaceExportService(
        package: source,
        links: sourceLinks,
      ).exportNovel('novel-1', destination: root);
      await sourceDb.close();

      final target = await ProjectPackageService(
        rootDirectory: Directory('${root.path}/target'),
      ).create(name: 'Target');
      final targetDb = await ProjectDatabaseService().open(
        target.databaseFile.path,
      );
      addTearDown(targetDb.close);
      final targetLinks = NovelCharacterLinkRepository(
        database: targetDb,
        projectId: target.projectId,
      );

      final result = await WorkspaceImportService(
        package: target,
        links: targetLinks,
      ).restoreNovel(archive);

      expect(result.workspaceId, 'novel-1');
      expect(
        await WorkspaceFileNamespace(
          target,
        ).novelFile('novel-1', 'drafts/chapter.md').readAsString(),
        '# Chapter',
      );
      final restored = (await targetLinks.listForNovel('novel-1')).single;
      expect(restored.mode, LinkMode.snapshot);
      expect(restored.createdAt, DateTime.utc(2026, 8, 22));
      expect(restored.characterWorkspaceId, 'character-1');
    },
  );

  test('refuses to overwrite an existing Novel namespace', () async {
    final root = await Directory.systemTemp.createTemp('workspace-collision-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Collision');
    final database = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    addTearDown(database.close);
    final links = NovelCharacterLinkRepository(
      database: database,
      projectId: package.projectId,
    );
    final existing = await WorkspaceFileNamespace(
      package,
    ).createNovelFile('novel-1', 'existing.txt');
    await existing.writeAsString('preserve');
    final archive = File('${root.path}/missing.voidworkspace');

    await expectLater(
      WorkspaceImportService(
        package: package,
        links: links,
      ).restoreNovel(archive, expectedWorkspaceId: 'novel-1'),
      throwsA(isA<StateError>()),
    );
    expect(await existing.readAsString(), 'preserve');
  });

  test(
    'rejects traversal entries without leaving a partial Novel workspace',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'workspace-restore-traversal-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Traversal Target');
      final database = await ProjectDatabaseService().open(
        package.databaseFile.path,
      );
      addTearDown(database.close);
      final links = NovelCharacterLinkRepository(
        database: database,
        projectId: package.projectId,
      );
      final archiveFile = File('${root.path}/malicious.voidworkspace');
      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'workspace.export.json',
            '{"format":"void-workspace-export","version":1,'
                '"workspaceType":"novel","workspaceId":"novel-escape",'
                '"characterRepresentation":"reference_manifest","links":[]}',
          ),
        )
        ..addFile(ArchiveFile.string('workspace/../../escape.txt', 'unsafe'));
      await archiveFile.writeAsBytes(ZipEncoder().encode(archive));

      await expectLater(
        WorkspaceImportService(
          package: package,
          links: links,
        ).restoreNovel(archiveFile),
        throwsA(isA<FormatException>()),
      );
      expect(
        await WorkspaceFileNamespace(
          package,
        ).novelDirectory('novel-escape').exists(),
        isFalse,
      );
      expect(await File('${root.path}/escape.txt').exists(), isFalse);
    },
  );
}
