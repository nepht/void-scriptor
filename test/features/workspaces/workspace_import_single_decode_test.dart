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
import 'package:void_scriptor/features/workspaces/application/workspace_import_service.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_import_actions.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_import_options_dialog.dart';

/// vs-hunt-20260912n BUG-10 (Referee REAL, Low, code-quality/robustness):
/// the production import flow decoded the whole archive twice — once via
/// `peekCharacterRepresentation` for the options dialog and again inside
/// `restoreNovel`. Two reads of a mutable file are also two different
/// snapshots: the bytes validated by the dialog were never the bytes the
/// restore actually used. The fix threads one bounded decode through both
/// steps via [WorkspaceArchivePreflight].
void main() {
  final openClosers = <Future<void> Function()>[];

  Future<void> closeOpenDatabases() async {
    for (final close in openClosers.reversed) {
      await close();
    }
    openClosers.clear();
  }

  tearDown(closeOpenDatabases);

  Future<
    ({
      Directory root,
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
    openClosers.add(db.close);
    return (
      root: root,
      package: package,
      db: db,
      links: NovelCharacterLinkRepository(
        database: db,
        projectId: package.projectId,
      ),
    );
  }

  Future<File> exportReferenceArchive(
    Directory temp, {
    required ProjectPackage package,
    required NovelCharacterLinkRepository links,
    required String novelId,
  }) {
    return WorkspaceExportService(
      package: package,
      links: links,
    ).exportNovel(novelId, destination: temp);
  }

  test(
    'preflight decodes once and exposes the declared representation',
    () async {
      final temp = await Directory.systemTemp.createTemp('ws-preflight-');
      try {
        final source = await makePackage(temp, 'source-project');
        await WorkspaceFileNamespace(
          source.package,
        ).createNovelFile('novel-a', 'drafts/chapter.md');
        final exported = await exportReferenceArchive(
          temp,
          package: source.package,
          links: source.links,
          novelId: 'novel-a',
        );
        await source.db.close();
        openClosers.removeLast();

        final preflight = await WorkspaceImportService.preflightArchive(
          exported,
        );
        expect(preflight.sourcePath, exported.path);
        expect(preflight.characterRepresentation, 'reference_manifest');
        expect(preflight.manifest['workspaceId'], 'novel-a');
        // The decoded snapshot is usable without touching the file again.
        expect(preflight.decoded.find('workspace.export.json'), isNotNull);
      } finally {
        await closeOpenDatabases();
        if (await temp.exists()) await temp.delete(recursive: true);
      }
    },
  );

  test('preflight enforces the size cap BEFORE reading the file', () async {
    final temp = await Directory.systemTemp.createTemp('ws-preflight-cap-');
    try {
      final source = await makePackage(temp, 'source-project');
      await WorkspaceFileNamespace(
        source.package,
      ).createNovelFile('novel-a', 'drafts/chapter.md');
      final exported = await exportReferenceArchive(
        temp,
        package: source.package,
        links: source.links,
        novelId: 'novel-a',
      );
      await source.db.close();
      openClosers.removeLast();

      expect(exported.lengthSync(), greaterThan(10));
      await expectLater(
        WorkspaceImportService.preflightArchive(exported, maxArchiveBytes: 10),
        throwsA(isA<WorkspaceArchiveTooLargeException>()),
      );
    } finally {
      await closeOpenDatabases();
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  });

  test('restore consumes the preflight snapshot: later file corruption cannot '
      'change what is restored', () async {
    final temp = await Directory.systemTemp.createTemp('ws-preflight-use-');
    try {
      final source = await makePackage(temp, 'source-project');
      await WorkspaceFileNamespace(
        source.package,
      ).createNovelFile('novel-a', 'drafts/chapter.md');
      final exported = await exportReferenceArchive(
        temp,
        package: source.package,
        links: source.links,
        novelId: 'novel-a',
      );
      await source.db.close();
      openClosers.removeLast();

      final target = await makePackage(temp, 'target-project');
      final actions = WorkspaceImportActions(
        package: target.package,
        links: target.links,
      );

      final preflight = await actions.preflightArchive(exported);
      expect(preflight.characterRepresentation, 'reference_manifest');

      // The old double-read bug would re-read the file here and hit garbage
      // instead of the snapshot the user actually confirmed in the dialog.
      await exported.writeAsBytes(List.filled(64, 0xFF));

      final result = await actions.run(
        exported,
        const WorkspaceImportOptions(
          collisionChoice: WorkspaceImportCollisionChoice.fail,
        ),
        preflight: preflight,
      );
      expect(result.workspaceId, 'novel-a');
      expect(result.skipped, isFalse);
      expect(
        await WorkspaceFileNamespace(
          target.package,
        ).novelDirectory('novel-a').exists(),
        isTrue,
      );
    } finally {
      await closeOpenDatabases();
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  });

  test('restore rejects a preflight bound to a different file', () async {
    final temp = await Directory.systemTemp.createTemp('ws-preflight-mix-');
    try {
      final source = await makePackage(temp, 'source-project');
      await WorkspaceFileNamespace(
        source.package,
      ).createNovelFile('novel-a', 'drafts/chapter.md');
      final exported = await exportReferenceArchive(
        temp,
        package: source.package,
        links: source.links,
        novelId: 'novel-a',
      );
      await source.db.close();
      openClosers.removeLast();

      final target = await makePackage(temp, 'target-project');
      final preflight = await WorkspaceImportService.preflightArchive(exported);
      final otherFile = File('${temp.path}/other.voidworkspace');
      await otherFile.writeAsBytes(exported.readAsBytesSync());

      await expectLater(
        WorkspaceImportService(
          package: target.package,
          links: target.links,
        ).restoreNovel(otherFile, preflight: preflight),
        throwsA(isA<ArgumentError>()),
      );
      // Rejection happened before any mutation: target has no novel dir.
      expect(
        await WorkspaceFileNamespace(
          target.package,
        ).novelDirectory('novel-a').exists(),
        isFalse,
      );
    } finally {
      await closeOpenDatabases();
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  });

  test('manifest validation still runs on the preflight path', () async {
    final temp = await Directory.systemTemp.createTemp('ws-preflight-bad-');
    try {
      final source = await makePackage(temp, 'source-project');
      await WorkspaceFileNamespace(
        source.package,
      ).createNovelFile('novel-a', 'drafts/chapter.md');
      await source.db.close();
      openClosers.removeLast();

      // A preflight built from bytes whose manifest claims a foreign
      // format must still be refused at restore time.
      final fakeBytes = ZipEncoder().encode(
        Archive()..add(
          ArchiveFile(
            'workspace.export.json',
            0,
            utf8.encode('{"format":"other","version":1}'),
          ),
        ),
      );
      final fakeFile = File('${temp.path}/fake.voidworkspace');
      await fakeFile.writeAsBytes(fakeBytes);

      final target = await makePackage(temp, 'target-project');
      final preflight = await WorkspaceImportService.preflightArchive(fakeFile);
      await expectLater(
        WorkspaceImportService(
          package: target.package,
          links: target.links,
        ).restoreNovel(fakeFile, preflight: preflight),
        throwsA(isA<FormatException>()),
      );
    } finally {
      await closeOpenDatabases();
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  });
}
