import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart'
    hide NovelCharacterLink;
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';
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

  Future<File> exportNovel(
    Directory root,
    ProjectPackage package,
    NovelCharacterLinkRepository links,
    String novelId, {
    WorkspaceCharacterRepresentation representation =
        WorkspaceCharacterRepresentation.referenceManifest,
    ProjectDatabase? database,
  }) async {
    await WorkspaceFileNamespace(package)
        .createNovelFile(novelId, 'drafts/chapter.md')
        .then((file) => file.writeAsString('# Chapter $novelId'));
    return WorkspaceExportService(
      package: package,
      links: links,
      database: database,
    ).exportNovel(
      novelId,
      destination: root,
      characterRepresentation: representation,
    );
  }

  Map<String, Object?> readManifest(File archive) {
    final decoded = ZipDecoder().decodeBytes(
      archive.readAsBytesSync(),
      verify: true,
    );
    return jsonDecode(
          utf8.decode(
            decoded.find('workspace.export.json')!.content as List<int>,
          ),
        )
        as Map<String, Object?>;
  }

  bool archiveContains(File archive, String entryName) {
    final decoded = ZipDecoder().decodeBytes(
      archive.readAsBytesSync(),
      verify: true,
    );
    return decoded.find(entryName) != null;
  }

  test(
    'default export stays reference_manifest without embedded files',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-export-ref-');
      addTearDown(() => root.delete(recursive: true));
      final source = await makePackage(root, 'source');
      await source.links.create(
        NovelCharacterLink.create(
          linkId: 'link-1',
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'char-ws-1',
          characterId: 'char-1',
          role: 'protagonist',
          visibility: 'visible',
          mode: LinkMode.reference,
          now: DateTime.utc(2026, 8, 22),
        ),
      );

      final archive = await exportNovel(
        root,
        source.package,
        source.links,
        'novel-1',
      );
      final manifest = readManifest(archive);

      expect(manifest['characterRepresentation'], 'reference_manifest');
      expect(
        archiveContains(archive, 'workspace/characters/char-1.json'),
        isFalse,
      );
    },
  );

  test('embedded snapshot embeds every linked canonical character', () async {
    final root = await Directory.systemTemp.createTemp('ws-export-snap-');
    addTearDown(() => root.delete(recursive: true));
    final source = await makePackage(root, 'source');
    await seedCharacter(source.db, assetId: 'char-1', displayName: 'Rara');
    await seedCharacter(source.db, assetId: 'char-2', displayName: 'Bayu');
    for (final (linkId, charId) in [
      ('link-1', 'char-1'),
      ('link-2', 'char-2'),
    ]) {
      await source.links.create(
        NovelCharacterLink.create(
          linkId: linkId,
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'ws-$charId',
          characterId: charId,
          role: 'support',
          visibility: 'visible',
          mode: LinkMode.snapshot,
          now: DateTime.utc(2026, 8, 22),
        ),
      );
    }

    final archive = await exportNovel(
      root,
      source.package,
      source.links,
      'novel-1',
      representation: WorkspaceCharacterRepresentation.embeddedSnapshot,
      database: source.db,
    );
    final manifest = readManifest(archive);

    expect(manifest['characterRepresentation'], 'embedded_snapshot');
    expect(
      archiveContains(archive, 'workspace/characters/char-1.json'),
      isTrue,
    );
    expect(
      archiveContains(archive, 'workspace/characters/char-2.json'),
      isTrue,
    );
  });

  test(
    'embedded snapshot payload carries provenance of its source character',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-export-prov-');
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

      final archive = await exportNovel(
        root,
        source.package,
        source.links,
        'novel-1',
        representation: WorkspaceCharacterRepresentation.embeddedSnapshot,
        database: source.db,
      );
      final decoded = ZipDecoder().decodeBytes(
        archive.readAsBytesSync(),
        verify: true,
      );
      final payload =
          jsonDecode(
                utf8.decode(
                  decoded.find('workspace/characters/char-1.json')!.content
                      as List<int>,
                ),
              )
              as Map<String, Object?>;

      expect(payload['displayName'], 'Rara');
      expect(payload['provenance'], isNotNull);
    },
  );

  test('fork representation declares fork in the manifest', () async {
    final root = await Directory.systemTemp.createTemp('ws-export-fork-');
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
        mode: LinkMode.fork,
        now: DateTime.utc(2026, 8, 22),
      ),
    );

    final archive = await exportNovel(
      root,
      source.package,
      source.links,
      'novel-1',
      representation: WorkspaceCharacterRepresentation.fork,
      database: source.db,
    );
    final manifest = readManifest(archive);

    expect(manifest['characterRepresentation'], 'fork');
    expect(
      archiveContains(archive, 'workspace/characters/char-1.json'),
      isTrue,
    );
  });

  test('embedding fails honestly when a linked character is missing', () async {
    final root = await Directory.systemTemp.createTemp('ws-export-miss-');
    addTearDown(() => root.delete(recursive: true));
    final source = await makePackage(root, 'source');
    await source.links.create(
      NovelCharacterLink.create(
        linkId: 'link-1',
        novelWorkspaceId: 'novel-1',
        characterWorkspaceId: 'ws-char-x',
        characterId: 'char-x',
        role: 'support',
        visibility: 'visible',
        mode: LinkMode.snapshot,
        now: DateTime.utc(2026, 8, 22),
      ),
    );

    await expectLater(
      exportNovel(
        root,
        source.package,
        source.links,
        'novel-1',
        representation: WorkspaceCharacterRepresentation.embeddedSnapshot,
        database: source.db,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
