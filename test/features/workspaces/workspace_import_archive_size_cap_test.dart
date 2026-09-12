import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
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

/// vs-hunt-20260912n BUG-12 (Referee REAL, Medium): both archive read points
/// (`restoreNovel` and `peekManifest`) did `readAsBytes()` + a full decode
/// with no size bound, so an oversized or zip-bomb file could exhaust memory
/// before any validation ran. The contract now: reject a file larger than the
/// configured cap BEFORE reading its bytes into memory — at both entry
/// points — while files under the cap restore unchanged.
void main() {
  // Same open-after-create pattern as workspace_import_missing_payload_test:
  // ProjectPackageService.create seeds a db that ProjectDatabaseService.open
  // replaces; the drift multi-instance warning is expected here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

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

  /// A real production export of Novel 'novel-1' with a body of [fillerBytes]
  /// so the archive size is controllable.
  Future<File> exportArchiveWithSize(
    Directory root, {
    required int fillerBytes,
  }) async {
    final source = await makePackage(root, 'source');
    await WorkspaceFileNamespace(source.package)
        .createNovelFile('novel-1', 'drafts/chapter.md')
        .then(
          (file) =>
              file.writeAsString('# Chapter novel-1\n${'x' * fillerBytes}'),
        );
    await source.links.create(
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
    return WorkspaceExportService(
      package: source.package,
      links: source.links,
    ).exportNovel('novel-1', destination: root);
  }

  test(
    'restoreNovel rejects an archive above the size cap before decode',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-size-cap-');
      addTearDown(() => root.delete(recursive: true));
      final archive = await exportArchiveWithSize(root, fillerBytes: 8192);
      expect(await archive.length(), greaterThan(128));
      final target = await makePackage(root, 'target');
      final service = WorkspaceImportService(
        package: target.package,
        links: target.links,
        database: target.db,
        maxArchiveBytes: 128,
      );
      await expectLater(
        service.restoreNovel(archive),
        throwsA(
          isA<WorkspaceArchiveTooLargeException>().having(
            (e) => e.maxAllowedBytes,
            'maxAllowedBytes',
            128,
          ),
        ),
      );
      // Rejected before decode: the target workspace directory was never made.
      expect(
        await WorkspaceFileNamespace(
          target.package,
        ).novelDirectory('novel-1').exists(),
        isFalse,
      );
    },
  );

  test('restoreNovel accepts the same archive under a generous cap', () async {
    final root = await Directory.systemTemp.createTemp('ws-size-ok-');
    addTearDown(() => root.delete(recursive: true));
    final archive = await exportArchiveWithSize(root, fillerBytes: 64);
    final target = await makePackage(root, 'target');
    final service = WorkspaceImportService(
      package: target.package,
      links: target.links,
      database: target.db,
      maxArchiveBytes: WorkspaceImportService.defaultMaxArchiveBytes,
    );
    final result = await service.restoreNovel(archive);
    expect(result.workspaceId, 'novel-1');
    expect(result.restoredLinkCount, 1);
  });

  test(
    'peekManifest enforces the size cap too (it runs before restore)',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-size-peek-');
      addTearDown(() => root.delete(recursive: true));
      final archive = await exportArchiveWithSize(root, fillerBytes: 8192);
      await expectLater(
        WorkspaceImportService.peekManifest(archive, maxArchiveBytes: 128),
        throwsA(isA<WorkspaceArchiveTooLargeException>()),
      );
      // Under the cap, peek still behaves normally.
      final manifest = await WorkspaceImportService.peekManifest(
        archive,
        maxArchiveBytes: WorkspaceImportService.defaultMaxArchiveBytes,
      );
      expect(manifest['workspaceId'], 'novel-1');
    },
  );

  test('a non-positive size cap is rejected, it would disable the guard', () {
    expect(
      () => WorkspaceImportService.validateMaxArchiveBytes(0),
      throwsArgumentError,
    );
    expect(
      () => WorkspaceImportService.validateMaxArchiveBytes(-1),
      throwsArgumentError,
    );
    // The default cap passes its own validation.
    WorkspaceImportService.validateMaxArchiveBytes(
      WorkspaceImportService.defaultMaxArchiveBytes,
    );
  });
}
