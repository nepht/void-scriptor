import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
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

/// vs-hunt-20260912n BUG-17 (Referee REAL, Medium): `exportCharacter`
/// produced a `character-*.voidworkspace` archive that NO import path could
/// read — `restoreNovel` hard-rejects non-novel manifests, so the export was
/// a dead-end artifact. The contract now: a symmetric `restoreCharacter`
/// validates the same chain as the novel path (size cap BEFORE read,
/// manifest format/type/version, workspace ID, collision decision) and
/// restores the character file namespace without ever touching links or
/// canonical character rows.
void main() {
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

  /// A real production export of Character 'character-1' carrying one profile
  /// file and one notes file.
  Future<File> exportCharacterArchive(Directory root) async {
    final source = await makePackage(root, 'src');
    final files = WorkspaceFileNamespace(source.package);
    await (await files.createCharacterFile(
      'character-1',
      'profile/identity.json',
    )).writeAsString('{"name":"Qowner"}');
    await (await files.createCharacterFile(
      'character-1',
      'notes/voice.md',
    )).writeAsString('# Voice notes');
    return WorkspaceExportService(
      package: source.package,
      links: source.links,
    ).exportCharacter('character-1', destination: root);
  }

  WorkspaceImportService serviceFor(
    ({
      ProjectPackage package,
      ProjectDatabase db,
      NovelCharacterLinkRepository links,
    })
    target, {
    int? maxArchiveBytes,
  }) => WorkspaceImportService(
    package: target.package,
    links: target.links,
    database: target.db,
    maxArchiveBytes:
        maxArchiveBytes ?? WorkspaceImportService.defaultMaxArchiveBytes,
  );

  test(
    'a real character export round-trips through restoreCharacter',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-char-roundtrip-');
      addTearDown(() => root.delete(recursive: true));
      final archive = await exportCharacterArchive(root);
      final target = await makePackage(root, 'dst');
      final result = await serviceFor(target).restoreCharacter(archive);
      expect(result.workspaceId, 'character-1');
      expect(result.restoredLinkCount, 0);
      expect(result.skipped, isFalse);
      final dir = WorkspaceFileNamespace(
        target.package,
      ).characterDirectory('character-1');
      expect(await dir.exists(), isTrue);
      expect(
        await File('${dir.path}/profile/identity.json').readAsString(),
        '{"name":"Qowner"}',
      );
      expect(
        await File('${dir.path}/notes/voice.md').readAsString(),
        '# Voice notes',
      );
      // A character restore must never create novel rows or directories.
      expect(
        await WorkspaceFileNamespace(
          target.package,
        ).novelDirectory('character-1').exists(),
        isFalse,
      );
    },
  );

  test('restoreCharacter rejects a Novel archive by type', () async {
    final root = await Directory.systemTemp.createTemp('ws-char-type-');
    addTearDown(() => root.delete(recursive: true));
    final source = await makePackage(root, 'src');
    await (await WorkspaceFileNamespace(
      source.package,
    ).createNovelFile('novel-1', 'drafts/chapter.md')).writeAsString('x');
    final archive = await WorkspaceExportService(
      package: source.package,
      links: source.links,
    ).exportNovel('novel-1', destination: root);
    final target = await makePackage(root, 'dst');
    await expectLater(
      serviceFor(target).restoreCharacter(archive),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('not a Character workspace export'),
        ),
      ),
    );
    expect(
      await WorkspaceFileNamespace(
        target.package,
      ).characterDirectory('novel-1').exists(),
      isFalse,
    );
  });

  test('restoreCharacter rejects unsupported manifest versions', () async {
    final root = await Directory.systemTemp.createTemp('ws-char-version-');
    addTearDown(() => root.delete(recursive: true));
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'workspace.export.json',
          '{"format":"void-workspace-export","version":2,'
              '"workspaceType":"character","workspaceId":"character-v2"}',
        ),
      );
    final file = File('${root.path}/v2.voidworkspace');
    await file.writeAsBytes(ZipEncoder().encode(archive));
    final target = await makePackage(root, 'dst');
    await expectLater(
      serviceFor(target).restoreCharacter(file),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported Character workspace export version'),
        ),
      ),
    );
    expect(
      await WorkspaceFileNamespace(
        target.package,
      ).characterDirectory('character-v2').exists(),
      isFalse,
    );
  });

  test(
    'collision on fail throws; skip leaves the existing files untouched',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-char-collision-');
      addTearDown(() => root.delete(recursive: true));
      final archive = await exportCharacterArchive(root);
      final target = await makePackage(root, 'dst');
      final files = WorkspaceFileNamespace(target.package);
      await (await files.createCharacterFile(
        'character-1',
        'profile/identity.json',
      )).writeAsString('{"name":"Original"}');

      await expectLater(
        serviceFor(
          target,
        ).restoreCharacter(archive, expectedWorkspaceId: 'character-1'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Character workspace already exists'),
          ),
        ),
      );
      final skipResult = await serviceFor(target).restoreCharacter(
        archive,
        expectedWorkspaceId: 'character-1',
        collisionChoice: WorkspaceImportCollisionChoice.skip,
      );
      expect(skipResult.skipped, isTrue);
      expect(
        await File(
          '${files.characterDirectory('character-1').path}/profile/identity.json',
        ).readAsString(),
        '{"name":"Original"}',
        reason: 'skip must leave the existing workspace bytes untouched',
      );
    },
  );

  test(
    'restoreCharacter enforces the archive size cap before reading',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-char-cap-');
      addTearDown(() => root.delete(recursive: true));
      final archive = await exportCharacterArchive(root);
      expect(await archive.length(), greaterThan(128));
      final target = await makePackage(root, 'dst');
      await expectLater(
        serviceFor(target, maxArchiveBytes: 128).restoreCharacter(archive),
        throwsA(isA<WorkspaceArchiveTooLargeException>()),
      );
      expect(
        await WorkspaceFileNamespace(
          target.package,
        ).characterDirectory('character-1').exists(),
        isFalse,
      );
    },
  );

  test('adoptExistingLinks is rejected for character archives', () async {
    final root = await Directory.systemTemp.createTemp('ws-char-adopt-');
    addTearDown(() => root.delete(recursive: true));
    final archive = await exportCharacterArchive(root);
    final target = await makePackage(root, 'dst');
    await expectLater(
      serviceFor(target).restoreCharacter(
        archive,
        collisionChoice: WorkspaceImportCollisionChoice.adoptExistingLinks,
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('link manifest'),
        ),
      ),
    );
  });

  test('archive entries escaping the workspace root are refused', () async {
    final root = await Directory.systemTemp.createTemp('ws-char-escape-');
    addTearDown(() => root.delete(recursive: true));
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'workspace.export.json',
          '{"format":"void-workspace-export","version":1,'
              '"workspaceType":"character","workspaceId":"character-escape"}',
        ),
      )
      ..addFile(ArchiveFile.string('workspace/../evil.txt', 'payload'));
    final file = File('${root.path}/escape.voidworkspace');
    await file.writeAsBytes(ZipEncoder().encode(archive));
    final target = await makePackage(root, 'dst');
    await expectLater(
      serviceFor(target).restoreCharacter(file),
      throwsA(isA<FormatException>()),
    );
    expect(
      await File(
        '${WorkspaceFileNamespace(target.package).packageRoot}/evil.txt',
      ).exists(),
      isFalse,
    );
    expect(
      await WorkspaceFileNamespace(
        target.package,
      ).characterDirectory('character-escape').exists(),
      isFalse,
    );
  });

  test(
    'a mismatched expected workspace ID is refused before mutation',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-char-mismatch-');
      addTearDown(() => root.delete(recursive: true));
      final archive = await exportCharacterArchive(root);
      final target = await makePackage(root, 'dst');
      await expectLater(
        serviceFor(
          target,
        ).restoreCharacter(archive, expectedWorkspaceId: 'character-other'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('does not match expectation'),
          ),
        ),
      );
      expect(
        await WorkspaceFileNamespace(
          target.package,
        ).characterDirectory('character-1').exists(),
        isFalse,
      );
    },
  );
}
