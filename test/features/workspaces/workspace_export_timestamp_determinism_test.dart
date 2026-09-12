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

// vs-hunt-20260912n BUG-13 (Low, determinism): the embedded character
// payload wrote provenance.exportedAt as a raw
// `DateTime.now().toUtc().toIso8601String()`. On the Windows Dart VM an
// in-the-now timestamp ALWAYS carries microsecond fractions, so two exports
// of identical bytes could never produce identical archives, and tests could
// not pin the provenance value at all. The contract now: exportNovel accepts
// an optional explicit `exportedAt`, and any timestamp written into an
// archive is truncated to whole seconds.

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

  Future<void> seedNovel(ProjectPackage package, String novelId) async {
    await WorkspaceFileNamespace(package)
        .createNovelFile(novelId, 'drafts/chapter.md')
        .then((file) => file.writeAsString('# Chapter $novelId'));
  }

  List<int> archiveBytes(File archive) => archive.readAsBytesSync();

  String embeddedCharacterJson(File archive, String characterId) {
    final decoded = ZipDecoder().decodeBytes(
      archiveBytes(archive),
      verify: true,
    );
    final entry = decoded.find('workspace/characters/$characterId.json');
    expect(entry, isNotNull, reason: 'embedded character payload missing');
    return utf8.decode(entry!.content as List<int>);
  }

  test(
    'explicit exportedAt is written verbatim into the embedded provenance',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-export-det-');
      addTearDown(() => root.delete(recursive: true));
      final source = await makePackage(root, 'source');
      await source.links.create(
        NovelCharacterLink.create(
          linkId: 'link-det-1',
          novelWorkspaceId: 'novel-det-1',
          characterWorkspaceId: 'char-ws-det-1',
          characterId: 'char-det-1',
          role: 'protagonist',
          visibility: 'visible',
          mode: LinkMode.reference,
          now: DateTime.utc(2026, 8, 22),
        ),
      );
      await seedCharacter(source.db, assetId: 'char-det-1', displayName: 'Det');
      await seedNovel(source.package, 'novel-det-1');

      final exportedAt = DateTime.utc(2026, 9, 12, 10, 47, 4);
      final archive =
          await WorkspaceExportService(
            package: source.package,
            links: source.links,
          ).exportNovel(
            'novel-det-1',
            destination: root,
            characterRepresentation:
                WorkspaceCharacterRepresentation.embeddedSnapshot,
            exportedAt: exportedAt,
          );

      final payload =
          jsonDecode(embeddedCharacterJson(archive, 'char-det-1'))
              as Map<String, Object?>;
      final provenance = payload['provenance']! as Map<String, Object?>;
      expect(provenance['exportedAt'], '2026-09-12T10:47:04.000Z');
    },
  );

  test('default exportedAt never carries fractional seconds', () async {
    final root = await Directory.systemTemp.createTemp('ws-export-det2-');
    addTearDown(() => root.delete(recursive: true));
    final source = await makePackage(root, 'source');
    await source.links.create(
      NovelCharacterLink.create(
        linkId: 'link-det-2',
        novelWorkspaceId: 'novel-det-2',
        characterWorkspaceId: 'char-ws-det-2',
        characterId: 'char-det-2',
        role: 'supporting',
        visibility: 'visible',
        mode: LinkMode.reference,
        now: DateTime.utc(2026, 8, 22),
      ),
    );
    await seedCharacter(source.db, assetId: 'char-det-2', displayName: 'Det2');
    await seedNovel(source.package, 'novel-det-2');

    final archive =
        await WorkspaceExportService(
          package: source.package,
          links: source.links,
        ).exportNovel(
          'novel-det-2',
          destination: root,
          characterRepresentation:
              WorkspaceCharacterRepresentation.embeddedSnapshot,
        );

    final payload =
        jsonDecode(embeddedCharacterJson(archive, 'char-det-2'))
            as Map<String, Object?>;
    final provenance = payload['provenance']! as Map<String, Object?>;
    final stamp = provenance['exportedAt']! as String;
    expect(
      RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$').hasMatch(stamp),
      isTrue,
      reason: 'exportedAt must be second-precision ISO-8601 UTC, got: $stamp',
    );
    expect(stamp, isNot(contains(RegExp(r'\.\d{4,}'))));
  });

  test(
    'two exports with the same exportedAt embed byte-identical payloads',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-export-det3-');
      addTearDown(() => root.delete(recursive: true));
      final source = await makePackage(root, 'source');
      await source.links.create(
        NovelCharacterLink.create(
          linkId: 'link-det-3',
          novelWorkspaceId: 'novel-det-3',
          characterWorkspaceId: 'char-ws-det-3',
          characterId: 'char-det-3',
          role: 'antagonist',
          visibility: 'visible',
          mode: LinkMode.reference,
          now: DateTime.utc(2026, 8, 22),
        ),
      );
      await seedCharacter(
        source.db,
        assetId: 'char-det-3',
        displayName: 'Det3',
      );
      await seedNovel(source.package, 'novel-det-3');

      final exportedAt = DateTime.utc(2026, 9, 12, 11, 2, 3);
      final service = WorkspaceExportService(
        package: source.package,
        links: source.links,
      );
      final first = await service.exportNovel(
        'novel-det-3',
        destination: root,
        characterRepresentation:
            WorkspaceCharacterRepresentation.embeddedSnapshot,
        exportedAt: exportedAt,
      );
      final firstJson = embeddedCharacterJson(first, 'char-det-3');
      final firstDir = Directory('${root.path}/out-a')
        ..createSync(recursive: true);
      final firstFile = await service.exportNovel(
        'novel-det-3',
        destination: firstDir,
        characterRepresentation:
            WorkspaceCharacterRepresentation.embeddedSnapshot,
        exportedAt: exportedAt,
      );
      final secondFile = await service.exportNovel(
        'novel-det-3',
        destination: Directory('${root.path}/out-b')
          ..createSync(recursive: true),
        characterRepresentation:
            WorkspaceCharacterRepresentation.embeddedSnapshot,
        exportedAt: exportedAt,
      );

      expect(firstFile.existsSync(), isTrue);
      expect(secondFile.existsSync(), isTrue);
      expect(
        embeddedCharacterJson(secondFile, 'char-det-3'),
        firstJson,
        reason: 'same exportedAt must produce the same embedded bytes',
      );
    },
  );
}
