import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart'
    hide NovelCharacterLink;
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_import_service.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

// vs-hunt-20260912n BUG-03: adoptExistingLinks must never materialize
// embedded character payloads. Its documented contract is "keep existing
// files untouched and insert only link-manifest entries whose link ID does
// not exist yet". Before the fix the embedded block ran before the adopting
// flag was respected, so an adopt either aborted on an existing canonical
// character (hard StateError) or inserted payload characters as ghosts.
void main() {
  void registerDb(Future<void> Function() close) {
    addTearDown(close);
  }

  Future<
    ({
      ProjectPackage package,
      ProjectDatabase db,
      NovelCharacterLinkRepository links,
    })
  >
  makePackage(Directory root, String name) async {
    final package = await ProjectPackageService(
      rootDirectory: Directory('${root.path}/$name'),
    ).create(name: name);
    final db = await ProjectDatabaseService().open(package.databaseFile.path);
    registerDb(db.close);
    return (
      package: package,
      db: db,
      links: NovelCharacterLinkRepository(
        database: db,
        projectId: package.projectId,
      ),
    );
  }

  Future<void> seedCharacter(
    ProjectDatabase db, {
    required String assetId,
    required String displayName,
  }) async {
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            assetId: assetId,
            projectId: 'seed',
            displayName: displayName,
          ),
        );
  }

  Future<void> seedEmbeddedLink(
    NovelCharacterLinkRepository links, {
    required String linkId,
    required String characterId,
  }) async {
    await links.create(
      NovelCharacterLink.create(
        linkId: linkId,
        novelWorkspaceId: 'novel-1',
        characterWorkspaceId: 'ws-$characterId',
        characterId: characterId,
        role: 'protagonist',
        visibility: 'visible',
        mode: LinkMode.snapshot,
        now: DateTime.utc(2026, 9, 12),
      ),
    );
  }

  Future<File> exportEmbeddedNovel(
    Directory destination,
    ({
      ProjectPackage package,
      ProjectDatabase db,
      NovelCharacterLinkRepository links,
    })
    source,
  ) async {
    await WorkspaceFileNamespace(source.package)
        .createNovelFile('novel-1', 'drafts/chapter.md')
        .then((file) => file.writeAsString('# Chapter novel-1'));
    return WorkspaceExportService(
      package: source.package,
      links: source.links,
      database: source.db,
    ).exportNovel(
      'novel-1',
      destination: destination,
      characterRepresentation:
          WorkspaceCharacterRepresentation.embeddedSnapshot,
    );
  }

  test(
    'adopt of an embedded archive whose characters already exist completes instead of aborting',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-adopt-exist-');
      addTearDown(() => root.delete(recursive: true));
      final source = await makePackage(root, 'source');
      await seedCharacter(source.db, assetId: 'char-1', displayName: 'Rara');
      await seedEmbeddedLink(
        source.links,
        linkId: 'link-1',
        characterId: 'char-1',
      );
      final archive = await exportEmbeddedNovel(root, source);

      final target = await makePackage(root, 'target');
      await WorkspaceImportService(
        package: target.package,
        links: target.links,
        database: target.db,
      ).restoreNovel(archive);
      // The first restore already materialized char-1 into the target, so
      // re-importing the same archive with adopt must be link-only work:
      // link-1 exists, nothing is inserted, and nothing throws.
      final result =
          await WorkspaceImportService(
            package: target.package,
            links: target.links,
            database: target.db,
          ).restoreNovel(
            archive,
            collisionChoice: WorkspaceImportCollisionChoice.adoptExistingLinks,
          );

      expect(result.skipped, isFalse);
      expect(result.restoredLinkCount, 0);
      final row = await (target.db.select(
        target.db.characters,
      )..where((tbl) => tbl.assetId.equals('char-1'))).getSingle();
      // Existing canonical row survives untouched (no overwrite, no abort).
      expect(row.displayName, 'Rara');
    },
  );

  test(
    'adopt inserts only missing links and never materializes embedded payload characters',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-adopt-ghost-');
      addTearDown(() => root.delete(recursive: true));
      final first = await makePackage(root, 'first');
      await seedCharacter(first.db, assetId: 'char-1', displayName: 'Rara');
      await seedEmbeddedLink(
        first.links,
        linkId: 'link-1',
        characterId: 'char-1',
      );
      final firstArchive = await exportEmbeddedNovel(root, first);

      final target = await makePackage(root, 'target');
      await WorkspaceImportService(
        package: target.package,
        links: target.links,
        database: target.db,
      ).restoreNovel(firstArchive);

      // A second source carries char-2 ONLY as an embedded payload.
      final second = await makePackage(root, 'second');
      await seedCharacter(second.db, assetId: 'char-2', displayName: 'Kian');
      await seedEmbeddedLink(
        second.links,
        linkId: 'link-2',
        characterId: 'char-2',
      );
      final secondArchive = await exportEmbeddedNovel(root, second);

      final result =
          await WorkspaceImportService(
            package: target.package,
            links: target.links,
            database: target.db,
          ).restoreNovel(
            secondArchive,
            collisionChoice: WorkspaceImportCollisionChoice.adoptExistingLinks,
          );

      expect(result.restoredLinkCount, 1);
      final adopted = await target.links.listForNovel('novel-1');
      expect(adopted.map((l) => l.linkId), containsAll(['link-1', 'link-2']));
      // The adopt contract is link-only: char-2's embedded payload must NOT
      // be materialized into the canonical store.
      final ghost = await (target.db.select(
        target.db.characters,
      )..where((tbl) => tbl.assetId.equals('char-2'))).get();
      expect(ghost, isEmpty);
    },
  );
}
