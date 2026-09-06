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
import 'package:void_scriptor/features/workspaces/presentation/workspace_export_actions.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_export_options_dialog.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_import_service.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_import_actions.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_import_options_dialog.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

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

  Map<String, Object?> readManifest(File archive) {
    final decoded = ZipDecoder().decodeBytes(
      archive.readAsBytesSync(),
      verify: true,
    );
    return jsonDecode(
          utf8.decode(decoded.find('workspace.export.json')!.readBytes()!),
        )
        as Map<String, Object?>;
  }

  test(
    'export actions carry the dialog choice into the service manifest',
    () async {
      final temp = await Directory.systemTemp.createTemp('ws-actions-export-');
      try {
        final source = await makePackage(temp, 'source-project');

        await source.db
            .into(source.db.characters)
            .insert(
              CharactersCompanion.insert(
                assetId: 'char-1',
                projectId: source.package.projectId,
                displayName: 'Rara',
              ),
            );
        await WorkspaceFileNamespace(
          source.package,
        ).createNovelFile('novel-1', 'drafts/chapter.md');
        await source.links.create(
          NovelCharacterLink.create(
            linkId: 'link-1',
            novelWorkspaceId: 'novel-1',
            characterWorkspaceId: 'char-1',
            characterId: 'char-1',
            role: 'protagonist',
            visibility: 'visible',
            mode: LinkMode.reference,
            now: DateTime.utc(2026, 8, 23),
          ),
        );

        // The exact object the export dialog pops with.
        const chosen = WorkspaceExportOptions(
          characterRepresentation:
              WorkspaceCharacterRepresentation.embeddedSnapshot,
        );

        final archive = await WorkspaceExportActions(
          package: source.package,
          links: source.links,
        ).run('novel-1', chosen, destination: temp);

        expect(archive.existsSync(), isTrue);
        final manifest = readManifest(archive);
        expect(manifest['characterRepresentation'], 'embedded_snapshot');

        final decoded = ZipDecoder().decodeBytes(
          archive.readAsBytesSync(),
          verify: true,
        );
        // Embedded files travel under the workspace/ namespace.
        expect(decoded.find('workspace/characters/char-1.json'), isNotNull);
      } finally {
        await closeOpenDatabases();
        if (await temp.exists()) await temp.delete(recursive: true);
      }
    },
  );

  test(
    'import actions surface the archive representation before any mutation',
    () async {
      final temp = await Directory.systemTemp.createTemp('ws-actions-import-');
      try {
        final source = await makePackage(temp, 'source-project');

        await WorkspaceFileNamespace(
          source.package,
        ).createNovelFile('novel-9', 'drafts/chapter.md');
        final exported = await WorkspaceExportService(
          package: source.package,
          links: source.links,
        ).exportNovel('novel-9', destination: temp);

        // Import only needs the completed archive. Release the source
        // connection before opening the target so two ProjectDatabase
        // instances never overlap in this single-project runtime fixture.
        await source.db.close();
        openClosers.removeLast();

        final target = await makePackage(temp, 'target-project');

        final actions = WorkspaceImportActions(
          package: target.package,
          links: target.links,
        );
        expect(
          await actions.peekCharacterRepresentation(exported),
          // Default exports always declare their representation (ADR).
          'reference_manifest',
        );

        final result = await actions.run(
          exported,
          const WorkspaceImportOptions(
            collisionChoice: WorkspaceImportCollisionChoice.fail,
          ),
          expectedWorkspaceId: 'novel-9',
        );
        expect(result.restoredLinkCount, 0);
        expect(result.skipped, isFalse);
      } finally {
        await closeOpenDatabases();
        if (await temp.exists()) await temp.delete(recursive: true);
      }
    },
  );
}
