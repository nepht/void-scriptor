import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

void main() {
  test(
    'Novel export contains only Novel files and a provenance link manifest',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'workspace-novel-export-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Workspace Export');
      final files = WorkspaceFileNamespace(package);
      final novelFile = await files.createNovelFile(
        'novel-1',
        'drafts/chapter-1.md',
      );
      await novelFile.writeAsString('# Chapter 1');
      final characterFile = await files.createCharacterFile(
        'character-1',
        'profile/identity.json',
      );
      await characterFile.writeAsString('{"name":"Qowner"}');
      final database = await ProjectDatabaseService().open(
        package.databaseFile.path,
      );
      addTearDown(database.close);
      final links = NovelCharacterLinkRepository(
        database: database,
        projectId: package.projectId,
      );
      await links.create(
        NovelCharacterLink.create(
          linkId: 'link-1',
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'character-1',
          characterId: 'character-1',
          role: 'protagonist',
          visibility: 'visible',
          mode: LinkMode.reference,
          now: DateTime.utc(2026, 8, 22),
        ),
      );

      final output = await WorkspaceExportService(
        package: package,
        links: links,
      ).exportNovel('novel-1', destination: root);
      final archive = ZipDecoder().decodeBytes(
        await output.readAsBytes(),
        verify: true,
      );

      expect(archive.find('workspace/drafts/chapter-1.md'), isNotNull);
      expect(archive.find('workspace/profile/identity.json'), isNull);
      final manifest =
          jsonDecode(
                utf8.decode(
                  archive.find('workspace.export.json')!.readBytes()!,
                ),
              )
              as Map<String, dynamic>;
      expect(manifest['workspaceType'], 'novel');
      expect(manifest['workspaceId'], 'novel-1');
      expect(manifest['characterRepresentation'], 'reference_manifest');
      final exportedLinks = manifest['links'] as List<dynamic>;
      expect(exportedLinks.single['link_mode'], 'reference');
      expect(exportedLinks.single['character_workspace_id'], 'character-1');
      expect(exportedLinks.single['created_at'], '2026-08-22T00:00:00.000Z');
    },
  );

  test('Character export excludes Novel manuscripts', () async {
    final root = await Directory.systemTemp.createTemp(
      'workspace-character-export-',
    );
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Character Export');
    final files = WorkspaceFileNamespace(package);
    await (await files.createNovelFile(
      'novel-1',
      'drafts/chapter.md',
    )).writeAsString('novel');
    await (await files.createCharacterFile(
      'character-1',
      'profile/identity.json',
    )).writeAsString('{"name":"Qowner"}');
    final database = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    addTearDown(database.close);
    final links = NovelCharacterLinkRepository(
      database: database,
      projectId: package.projectId,
    );

    final output = await WorkspaceExportService(
      package: package,
      links: links,
    ).exportCharacter('character-1', destination: root);
    final archive = ZipDecoder().decodeBytes(await output.readAsBytes());

    expect(archive.find('workspace/profile/identity.json'), isNotNull);
    expect(archive.find('workspace/drafts/chapter.md'), isNull);
    final manifest =
        jsonDecode(
              utf8.decode(archive.find('workspace.export.json')!.readBytes()!),
            )
            as Map<String, dynamic>;
    expect(manifest['workspaceType'], 'character');
    expect(manifest['workspaceId'], 'character-1');
    expect(manifest['links'], isNull);
  });
}
