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
    String projectId = 'seed',
  }) async {
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            assetId: assetId,
            projectId: projectId,
            displayName: displayName,
          ),
        );
  }

  Future<void> addSnapshotLink(
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
        now: DateTime.utc(2026, 8, 22),
      ),
    );
  }

  test('vs-hunt-20260912n BUG-01: embedded restore that fails mid-import '
      'rolls back every canonical character row, not just the links', () async {
    final root = await Directory.systemTemp.createTemp('ws-import-atomic-');
    addTearDown(() => root.delete(recursive: true));

    final source = await makePackage(root, 'source');
    await seedCharacter(source.db, assetId: 'char-1', displayName: 'Rara');
    await seedCharacter(source.db, assetId: 'char-2', displayName: 'Bagas');
    await addSnapshotLink(
      source.links,
      linkId: 'link-1',
      characterId: 'char-1',
    );
    await addSnapshotLink(
      source.links,
      linkId: 'link-2',
      characterId: 'char-2',
    );
    await WorkspaceFileNamespace(source.package)
        .createNovelFile('novel-1', 'drafts/chapter.md')
        .then((file) => file.writeAsString('# Chapter novel-1'));
    final archive =
        await WorkspaceExportService(
          package: source.package,
          links: source.links,
          database: source.db,
        ).exportNovel(
          'novel-1',
          destination: root,
          characterRepresentation:
              WorkspaceCharacterRepresentation.embeddedSnapshot,
        );

    // An unrelated pre-existing link row squats the archive's second link
    // ID, so link insertion fails AFTER both embedded characters were
    // materialized. Without a transaction the characters stay as ghosts.
    final target = await makePackage(root, 'target');
    await target.db
        .into(target.db.novelCharacterLinks)
        .insert(
          NovelCharacterLinksCompanion.insert(
            linkId: 'link-2',
            projectId: 'other-project',
            novelWorkspaceId: 'other-novel',
            characterWorkspaceId: 'ws-other',
            characterId: 'char-other',
            linkMode: 'reference',
            role: 'extra',
            visibility: 'visible',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );

    await expectLater(
      WorkspaceImportService(
        package: target.package,
        links: target.links,
        database: target.db,
      ).restoreNovel(archive),
      throwsA(isA<Object>()),
    );

    final ghostCharacters = await (target.db.select(
      target.db.characters,
    )..where((tbl) => tbl.assetId.isIn(const ['char-1', 'char-2']))).get();
    expect(
      ghostCharacters.map((row) => row.assetId).toList(),
      isEmpty,
      reason: 'a partially failed embedded import must leave no characters',
    );
    final halfLinks = await (target.db.select(
      target.db.novelCharacterLinks,
    )..where((tbl) => tbl.novelWorkspaceId.equals('novel-1'))).get();
    expect(halfLinks, isEmpty);
    // The unrelated squatting row must survive the rollback untouched.
    final squatRows = await (target.db.select(
      target.db.novelCharacterLinks,
    )..where((tbl) => tbl.linkId.equals('link-2'))).get();
    expect(squatRows, hasLength(1));
    expect(squatRows.single.novelWorkspaceId, 'other-novel');
    // The failed import must not leave the novel workspace directory behind.
    expect(
      await WorkspaceFileNamespace(
        target.package,
      ).novelDirectory('novel-1').exists(),
      isFalse,
    );
  });
}
