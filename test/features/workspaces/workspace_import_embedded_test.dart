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

  Future<File> exportEmbeddedNovel(
    Directory root,
    ProjectPackage package,
    NovelCharacterLinkRepository links,
    ProjectDatabase db,
    String novelId,
  ) async {
    await WorkspaceFileNamespace(package)
        .createNovelFile(novelId, 'drafts/chapter.md')
        .then((file) => file.writeAsString('# Chapter $novelId'));
    return WorkspaceExportService(
      package: package,
      links: links,
      database: db,
    ).exportNovel(
      novelId,
      destination: root,
      characterRepresentation:
          WorkspaceCharacterRepresentation.embeddedSnapshot,
    );
  }

  test(
    'restoring an embedded snapshot materializes canonical characters in the target',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-import-snap-');
      addTearDown(() => root.delete(recursive: true));
      final source = await makePackage(root, 'source');
      await seedCharacter(source.db, assetId: 'char-1', displayName: 'Rara');
      await source.links.create(
        NovelCharacterLink.create(
          linkId: 'link-1',
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'ws-char-1',
          characterId: 'char-1',
          role: 'protagonist',
          visibility: 'visible',
          mode: LinkMode.snapshot,
          now: DateTime.utc(2026, 8, 22),
        ),
      );
      final archive = await exportEmbeddedNovel(
        root,
        source.package,
        source.links,
        source.db,
        'novel-1',
      );

      final target = await makePackage(root, 'target');
      await WorkspaceImportService(
        package: target.package,
        links: target.links,
        database: target.db,
      ).restoreNovel(archive);

      final row = await (target.db.select(
        target.db.characters,
      )..where((tbl) => tbl.assetId.equals('char-1'))).getSingleOrNull();
      expect(row, isNotNull);
      expect(row!.displayName, 'Rara');
      expect(row.projectId, target.package.projectId);
    },
  );

  test('restore never overwrites an existing canonical character', () async {
    final root = await Directory.systemTemp.createTemp('ws-import-coll-');
    addTearDown(() => root.delete(recursive: true));
    final source = await makePackage(root, 'source');
    await seedCharacter(source.db, assetId: 'char-1', displayName: 'Rara');
    await source.links.create(
      NovelCharacterLink.create(
        linkId: 'link-1',
        novelWorkspaceId: 'novel-1',
        characterWorkspaceId: 'ws-char-1',
        characterId: 'char-1',
        role: 'protagonist',
        visibility: 'visible',
        mode: LinkMode.snapshot,
        now: DateTime.utc(2026, 8, 22),
      ),
    );
    final archive = await exportEmbeddedNovel(
      root,
      source.package,
      source.links,
      source.db,
      'novel-1',
    );

    final target = await makePackage(root, 'target');
    await seedCharacter(
      target.db,
      assetId: 'char-1',
      displayName: 'Existing',
      projectId: target.package.projectId,
    );

    await expectLater(
      WorkspaceImportService(
        package: target.package,
        links: target.links,
        database: target.db,
      ).restoreNovel(archive),
      throwsA(isA<StateError>()),
    );
    final row = await (target.db.select(
      target.db.characters,
    )..where((tbl) => tbl.assetId.equals('char-1'))).getSingle();
    expect(row.displayName, 'Existing');
  });

  test(
    'reference manifest restore leaves the canonical store untouched',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-import-refm-');
      addTearDown(() => root.delete(recursive: true));
      final source = await makePackage(root, 'source');
      await seedCharacter(source.db, assetId: 'char-1', displayName: 'Rara');
      await source.links.create(
        NovelCharacterLink.create(
          linkId: 'link-1',
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'ws-char-1',
          characterId: 'char-1',
          role: 'protagonist',
          visibility: 'visible',
          mode: LinkMode.reference,
          now: DateTime.utc(2026, 8, 22),
        ),
      );
      await WorkspaceFileNamespace(source.package)
          .createNovelFile('novel-1', 'drafts/chapter.md')
          .then((file) => file.writeAsString('# Chapter novel-1'));
      final archive = await WorkspaceExportService(
        package: source.package,
        links: source.links,
        database: source.db,
      ).exportNovel('novel-1', destination: root);

      final target = await makePackage(root, 'target');
      await WorkspaceImportService(
        package: target.package,
        links: target.links,
        database: target.db,
      ).restoreNovel(archive);

      final count = await (target.db.select(
        target.db.characters,
      )..where((tbl) => tbl.assetId.equals('char-1'))).get();
      expect(count, isEmpty);
    },
  );
}
