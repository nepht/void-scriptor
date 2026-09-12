import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';

void main() {
  test('Novel export never follows symlinks out of the workspace '
      '(vs-hunt-20260912n BUG-04)', () async {
    final root = await Directory.systemTemp.createTemp(
      'workspace-export-symlink-',
    );
    addTearDown(() => root.delete(recursive: true));

    // Payload living OUTSIDE the project package that must never travel
    // inside a project export.
    final externalDir = await Directory(p.join(root.path, 'external')).create();
    final externalFile = File(p.join(externalDir.path, 'secret.txt'));
    await externalFile.writeAsString('EXTERNAL-PAYLOAD');

    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Symlink Export');
    final files = WorkspaceFileNamespace(package);
    final novelFile = await files.createNovelFile(
      'novel-1',
      'drafts/chapter-1.md',
    );
    await novelFile.writeAsString('# Chapter 1');
    final novelDir = files.novelDirectory('novel-1');
    await Link(p.join(novelDir.path, 'link.txt')).create(externalFile.path);
    await Link(p.join(novelDir.path, 'dirlink')).create(externalDir.path);

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
    ).exportNovel('novel-1', destination: root);
    final archive = ZipDecoder().decodeBytes(
      await output.readAsBytes(),
      verify: true,
    );

    // Real workspace content must still export.
    expect(archive.find('workspace/drafts/chapter-1.md'), isNotNull);
    // Symlinked file and symlinked directory content must not.
    expect(archive.find('workspace/link.txt'), isNull);
    expect(archive.find('workspace/dirlink/secret.txt'), isNull);
    final leaked = archive
        .where((e) {
          if (!e.isFile) return false;
          final bytes = e.readBytes();
          return bytes != null &&
              utf8
                  .decode(bytes, allowMalformed: true)
                  .contains('EXTERNAL-PAYLOAD');
        })
        .map((e) => e.name)
        .toList();
    expect(leaked, isEmpty);
  });

  test('Character export never follows symlinks out of the workspace '
      '(vs-hunt-20260912n BUG-04)', () async {
    final root = await Directory.systemTemp.createTemp(
      'workspace-character-export-symlink-',
    );
    addTearDown(() => root.delete(recursive: true));
    final externalFile = File(p.join(root.path, 'secret.txt'));
    await externalFile.writeAsString('EXTERNAL-PAYLOAD');

    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Character Symlink Export');
    final files = WorkspaceFileNamespace(package);
    final characterFile = await files.createCharacterFile(
      'character-1',
      'profile/identity.json',
    );
    await characterFile.writeAsString('{"name":"Qowner"}');
    await Link(
      p.join(files.characterDirectory('character-1').path, 'link.txt'),
    ).create(externalFile.path);

    final database = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    addTearDown(database.close);

    final output = await WorkspaceExportService(
      package: package,
      links: NovelCharacterLinkRepository(
        database: database,
        projectId: package.projectId,
      ),
    ).exportCharacter('character-1', destination: root);
    final archive = ZipDecoder().decodeBytes(
      await output.readAsBytes(),
      verify: true,
    );

    expect(archive.find('workspace/profile/identity.json'), isNotNull);
    expect(archive.find('workspace/link.txt'), isNull);
    final leaked = archive
        .where((e) {
          if (!e.isFile) return false;
          final bytes = e.readBytes();
          return bytes != null &&
              utf8
                  .decode(bytes, allowMalformed: true)
                  .contains('EXTERNAL-PAYLOAD');
        })
        .map((e) => e.name)
        .toList();
    expect(leaked, isEmpty);
  });
}
