import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart'
    hide NovelCharacterLink;
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_import_service.dart';

/// vs-hunt-20260912n BUG-02 (Referee REAL, Medium): restoreNovel validated
/// `format` and `workspaceType` but never asserted the manifest `version`,
/// so a future (or hand-tampered) archive with `version: 2` — or no version
/// at all — was processed with version-1 semantics. The import side must
/// reject unsupported versions BEFORE any mutation.
void main() {
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
    addTearDown(db.close);
    return (
      package: package,
      db: db,
      links: NovelCharacterLinkRepository(
        database: db,
        projectId: package.projectId,
      ),
    );
  }

  Future<File> archiveWithManifest(
    Directory root,
    String fileName,
    String manifestJson,
  ) async {
    final archive = Archive()
      ..addFile(ArchiveFile.string('workspace.export.json', manifestJson));
    final out = File('${root.path}/$fileName');
    await out.writeAsBytes(ZipEncoder().encode(archive));
    return out;
  }

  String manifestWithVersion(String versionField) =>
      '{"format":"void-workspace-export",$versionField'
      '"workspaceType":"novel","workspaceId":"novel-versioned",'
      '"characterRepresentation":"reference_manifest","links":[]}';

  Future<void> expectRejectedWithoutTrace(
    Directory root,
    String fileName,
    String manifestJson,
  ) async {
    final archiveFile = await archiveWithManifest(root, fileName, manifestJson);
    final target = await makePackage(root, 'target-$fileName');
    await expectLater(
      WorkspaceImportService(
        package: target.package,
        links: target.links,
        database: target.db,
      ).restoreNovel(archiveFile, expectedWorkspaceId: 'novel-versioned'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported Novel workspace export version'),
        ),
      ),
    );
    // Rejection happens before materialization: no novel directory is created.
    final namespace = WorkspaceFileNamespace(target.package);
    expect(
      await namespace.novelDirectory('novel-versioned').exists(),
      isFalse,
      reason: 'a rejected archive must not create the target workspace',
    );
    expect(await target.links.listForNovel('novel-versioned'), isEmpty);
  }

  test(
    'restore rejects an archive declaring a future manifest version',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-import-version-');
      addTearDown(() => root.delete(recursive: true));
      await expectRejectedWithoutTrace(
        root,
        'v2.voidworkspace',
        manifestWithVersion('"version":2,'),
      );
    },
  );

  test('restore rejects an archive with no manifest version at all', () async {
    final root = await Directory.systemTemp.createTemp('ws-import-noversion-');
    addTearDown(() => root.delete(recursive: true));
    await expectRejectedWithoutTrace(
      root,
      'missing.voidworkspace',
      manifestWithVersion(''),
    );
  });
}
