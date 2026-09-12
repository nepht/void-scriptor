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
import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_import_service.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

/// vs-hunt-20260912n BUG-05 (Referee REAL, Medium): an embedded snapshot /
/// fork archive that declares a character link but omits its
/// `workspace/characters/<id>.json` payload used to silently insert a blank
/// canonical character (displayName fell back to the raw ID). The export side
/// fails hard on a missing character; the import side must enforce the same
/// contract: reject the archive BEFORE mutating anything.
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

  Future<File> exportEmbeddedArchive(Directory root) async {
    final source = await makePackage(root, 'source');
    await source.db
        .into(source.db.characters)
        .insert(
          CharactersCompanion.insert(
            assetId: 'char-1',
            projectId: 'seed',
            displayName: 'Rara',
          ),
        );
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
    await WorkspaceFileNamespace(source.package)
        .createNovelFile('novel-1', 'drafts/chapter.md')
        .then((file) => file.writeAsString('# Chapter novel-1'));
    return WorkspaceExportService(
      package: source.package,
      links: source.links,
      database: source.db,
    ).exportNovel(
      'novel-1',
      destination: root,
      characterRepresentation:
          WorkspaceCharacterRepresentation.embeddedSnapshot,
    );
  }

  /// Re-encode the real archive WITHOUT the embedded character payload file.
  Future<File> stripCharacterPayload(Directory root, File archive) async {
    final decoded = ZipDecoder().decodeBytes(await archive.readAsBytes());
    final stripped = Archive();
    for (final entry in decoded) {
      if (!entry.isFile) continue;
      if (entry.name == 'workspace/characters/char-1.json') continue;
      final bytes = entry.readBytes()!;
      stripped.addFile(ArchiveFile(entry.name, bytes.length, bytes));
    }
    final out = File('${root.path}/stripped.voidworkspace');
    await out.writeAsBytes(ZipEncoder().encode(stripped));
    return out;
  }

  test('restore rejects an embedded archive missing a character payload '
      'and does not create a blank canonical character', () async {
    final root = await Directory.systemTemp.createTemp(
      'ws-import-missing-payload-',
    );
    addTearDown(() => root.delete(recursive: true));
    final archive = await exportEmbeddedArchive(root);
    final tampered = await stripCharacterPayload(root, archive);

    final target = await makePackage(root, 'target');

    await expectLater(
      WorkspaceImportService(
        package: target.package,
        links: target.links,
        database: target.db,
      ).restoreNovel(tampered),
      throwsA(isA<FormatException>()),
    );

    // Nothing may survive the rejected import: no ghost character row.
    final rows = await (target.db.select(
      target.db.characters,
    )..where((tbl) => tbl.assetId.equals('char-1'))).get();
    expect(rows, isEmpty);
  });
}
