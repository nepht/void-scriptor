import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../../../core/project_package/project_package.dart';
import '../../../database/project/project_database.dart' as data;
import 'novel_character_link_repository.dart';
import 'workspace_file_namespace.dart';

/// How a Novel export represents linked canonical characters.
///
/// ADR-WS-001 `backup_export_rules.portable_novel_export`: an export MUST
/// declare whether characters travel as a reference manifest, an embedded
/// snapshot, or a fork.
enum WorkspaceCharacterRepresentation {
  referenceManifest('reference_manifest'),
  embeddedSnapshot('embedded_snapshot'),
  fork('fork');

  const WorkspaceCharacterRepresentation(this.manifestValue);

  final String manifestValue;
}

final class WorkspaceExportService {
  WorkspaceExportService({
    required this.package,
    required this.links,
    data.ProjectDatabase? database,
  }) : database = database ?? links.database,
       files = WorkspaceFileNamespace(package);

  final ProjectPackage package;
  final NovelCharacterLinkRepository links;

  /// Canonical character store used for embedded snapshot/fork exports.
  /// Defaults to the link repository's own database.
  final data.ProjectDatabase database;
  final WorkspaceFileNamespace files;

  Future<File> exportNovel(
    String novelWorkspaceId, {
    required Directory destination,
    WorkspaceCharacterRepresentation characterRepresentation =
        WorkspaceCharacterRepresentation.referenceManifest,
    DateTime? exportedAt,
  }) async {
    final source = files.novelDirectory(novelWorkspaceId);
    final exportedLinks = await links.listForNovel(novelWorkspaceId);
    final manifest = <String, Object?>{
      'format': 'void-workspace-export',
      'version': 1,
      'workspaceType': 'novel',
      'workspaceId': novelWorkspaceId,
      'characterRepresentation':
          characterRepresentation.manifestValue, // ADR-WS-001
      'links': exportedLinks.map((link) => link.toJson()).toList(),
    };

    if (characterRepresentation ==
        WorkspaceCharacterRepresentation.referenceManifest) {
      return _export(
        source: source,
        destination: destination,
        filename: 'novel-$novelWorkspaceId.voidworkspace',
        manifest: manifest,
      );
    }

    // Embedded snapshot / fork: carry each linked canonical character file.
    // vs-hunt-20260912n BUG-13: provenance timestamps are truncated to whole
    // seconds (and can be pinned by the caller) so an export of unchanged
    // data is reproducible instead of embedding microsecond noise.
    final provenanceExportedAt = (exportedAt ?? DateTime.now().toUtc())
        .copyWith(microsecond: 0);
    final temp = await Directory.systemTemp.createTemp('void-workspace-embed-');
    try {
      final charactersDir = Directory(p.join(temp.path, 'characters'));
      await charactersDir.create(recursive: true);
      for (final link in exportedLinks) {
        final row =
            await (database.select(database.characters)
                  ..where((tbl) => tbl.assetId.equals(link.characterId)))
                .getSingleOrNull();
        if (row == null) {
          throw StateError(
            'Cannot embed character ${link.characterId}: not found in '
            'canonical store',
          );
        }
        await File(
          p.join(charactersDir.path, '${link.characterId}.json'),
        ).writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'assetId': row.assetId,
            'projectId': row.projectId,
            'displayName': row.displayName,
            'alias': row.alias,
            'biography': row.biography,
            'personality': row.personality,
            'gender': row.gender,
            'age': row.age,
            'heightCm': row.heightCm,
            'hair': row.hair,
            'eyes': row.eyes,
            'skin': row.skin,
            'provenance': {
              'sourceProjectId': package.projectId,
              'characterWorkspaceId': link.characterWorkspaceId,
              'linkMode': link.mode.name,
              'exportedAt': provenanceExportedAt.toIso8601String(),
              'representation': characterRepresentation.manifestValue,
            },
          }),
        );
      }
      // `return await` is REQUIRED here: a bare `return futureExpr` lets the
      // finally block delete `temp` before _export finishes copying it.
      return await _export(
        source: source,
        destination: destination,
        filename: 'novel-$novelWorkspaceId.voidworkspace',
        manifest: manifest,
        extraFiles: Directory(p.join(temp.path)),
      );
    } finally {
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  }

  Future<File> exportCharacter(
    String characterWorkspaceId, {
    required Directory destination,
  }) => _export(
    source: files.characterDirectory(characterWorkspaceId),
    destination: destination,
    filename: 'character-$characterWorkspaceId.voidworkspace',
    manifest: {
      'format': 'void-workspace-export',
      'version': 1,
      'workspaceType': 'character',
      'workspaceId': characterWorkspaceId,
    },
  );

  Future<File> _export({
    required Directory source,
    required Directory destination,
    required String filename,
    required Map<String, Object?> manifest,
    Directory? extraFiles,
  }) async {
    final temp = await Directory.systemTemp.createTemp(
      'void-workspace-export-',
    );
    try {
      if (await source.exists()) {
        await _copy(source, Directory(p.join(temp.path, 'workspace')));
      } else {
        await Directory(p.join(temp.path, 'workspace')).create(recursive: true);
      }
      if (extraFiles != null) {
        await _copy(extraFiles, Directory(p.join(temp.path, 'workspace')));
      }
      await File(
        p.join(temp.path, 'workspace.export.json'),
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
      await destination.create(recursive: true);
      final output = File(p.join(destination.path, filename));
      await ZipFileEncoder().zipDirectory(temp, filename: output.path);
      final decoded = ZipDecoder().decodeBytes(
        await output.readAsBytes(),
        verify: true,
      );
      if (decoded.find('workspace.export.json') == null) {
        throw StateError('Workspace export verification failed');
      }
      return output;
    } finally {
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  }

  Future<void> _copy(Directory source, Directory target) async {
    await target.create(recursive: true);
    // vs-hunt-20260912n BUG-04: list WITHOUT following links. A symlinked
    // file would archive content from outside the workspace (data leak) or
    // abort the export (dangling link); a symlinked directory would be
    // recursed into with the same result. Link entities are skipped entirely
    // — an export contains only real, workspace-owned bytes.
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is Link) continue;
      final relative = p.relative(entity.path, from: source.path);
      final targetPath = p.join(target.path, relative);
      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        await File(targetPath).parent.create(recursive: true);
        await entity.copy(targetPath);
      }
    }
  }
}
