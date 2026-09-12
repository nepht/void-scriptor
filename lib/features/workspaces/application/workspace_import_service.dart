import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../../../core/project_package/project_package.dart';
import 'package:drift/drift.dart' show Value;
import '../../../database/project/project_database.dart' as data;
import '../domain/novel_character_link.dart';
import 'novel_character_link_repository.dart';
import 'workspace_file_namespace.dart';

/// Explicit decision for importing a Novel workspace whose target already
/// exists.
///
/// `snapshot` and `fork` are deliberately absent: no such transform exists
/// yet, so offering them would fabricate behavior.
enum WorkspaceImportCollisionChoice {
  /// Default. Reject the import when the target Novel already exists.
  fail,

  /// Leave the existing workspace completely untouched.
  skip,

  /// Keep existing files untouched and insert only link-manifest entries
  /// whose link ID does not exist yet.
  adoptExistingLinks,
}

final class WorkspaceRestoreResult {
  const WorkspaceRestoreResult({
    required this.workspaceId,
    required this.restoredLinkCount,
    this.skipped = false,
  });

  final String workspaceId;
  final int restoredLinkCount;

  /// True when a collision was met and
  /// [WorkspaceImportCollisionChoice.skip] left the target untouched.
  final bool skipped;
}

final class WorkspaceImportService {
  WorkspaceImportService({
    required this.package,
    required this.links,
    data.ProjectDatabase? database,
  }) : database = database ?? links.database,
       files = WorkspaceFileNamespace(package);

  final ProjectPackage package;
  final NovelCharacterLinkRepository links;

  /// Canonical character store used to materialize embedded snapshot/fork
  /// exports. Defaults to the link repository's own database.
  final data.ProjectDatabase database;
  final WorkspaceFileNamespace files;

  Future<WorkspaceRestoreResult> restoreNovel(
    File archive, {
    String? expectedWorkspaceId,
    WorkspaceImportCollisionChoice collisionChoice =
        WorkspaceImportCollisionChoice.fail,
  }) async {
    // Collision pre-checks run BEFORE reading the archive: a missing or
    // corrupt archive must not change which error an existing target raises.
    if (expectedWorkspaceId != null) {
      final expectedTarget = files.novelDirectory(expectedWorkspaceId);
      if (await expectedTarget.exists()) {
        throw StateError(
          'Novel workspace already exists; collision decision is required.',
        );
      }
    }
    final probeId = expectedWorkspaceId ?? await _peekWorkspaceId(archive);
    final target = files.novelDirectory(probeId);
    final hasCollision = await target.exists();
    if (hasCollision &&
        collisionChoice == WorkspaceImportCollisionChoice.skip) {
      return WorkspaceRestoreResult(
        workspaceId: probeId,
        restoredLinkCount: 0,
        skipped: true,
      );
    }

    final decoded = ZipDecoder().decodeBytes(
      await archive.readAsBytes(),
      verify: true,
    );
    final manifestEntry = decoded.find('workspace.export.json');
    if (manifestEntry == null || !manifestEntry.isFile) {
      throw const FormatException('Missing workspace export manifest');
    }
    final manifest =
        jsonDecode(utf8.decode(manifestEntry.readBytes()!))
            as Map<String, dynamic>;
    if (manifest['format'] != 'void-workspace-export' ||
        manifest['workspaceType'] != 'novel') {
      throw const FormatException('Archive is not a Novel workspace export');
    }
    final workspaceId = manifest['workspaceId'] as String?;
    if (workspaceId == null || workspaceId.trim().isEmpty) {
      throw const FormatException('Missing Novel workspace ID');
    }
    if (expectedWorkspaceId != null && expectedWorkspaceId != workspaceId) {
      throw const FormatException('Workspace ID does not match expectation');
    }

    // Validate BEFORE any mutation.
    final rawLinks = manifest['links'];
    if (rawLinks is! List<dynamic>) {
      throw const FormatException('Novel export requires a link manifest');
    }
    final restoredLinks = rawLinks
        .map(
          (value) => NovelCharacterLink.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList(growable: false);
    if (restoredLinks.any((link) => link.novelWorkspaceId != workspaceId)) {
      throw const FormatException('Link provenance targets another Novel');
    }

    if (hasCollision &&
        collisionChoice == WorkspaceImportCollisionChoice.fail) {
      throw StateError(
        'Novel workspace already exists; collision decision is required.',
      );
    }

    final adopting =
        hasCollision &&
        collisionChoice == WorkspaceImportCollisionChoice.adoptExistingLinks;

    // ADR-WS-001 restore_collision: never overwrite. An embedded snapshot /
    // fork export materializes its canonical characters into the target
    // store; an existing character is a hard stop, not a silent overwrite.
    final representation = manifest['characterRepresentation'] as String?;
    if (representation != null && representation != 'reference_manifest') {
      final embeddedPayloads = <String, Map<String, dynamic>>{};
      const embeddedPrefix = 'workspace/characters/';
      for (final entry in decoded) {
        if (!entry.isFile) continue;
        final normalized = p.posix.normalize(entry.name);
        if (!normalized.startsWith(embeddedPrefix) ||
            !normalized.endsWith('.json')) {
          continue;
        }
        final payload =
            jsonDecode(utf8.decode(entry.readBytes()!)) as Map<String, dynamic>;
        embeddedPayloads[normalized.substring(
              embeddedPrefix.length,
              normalized.length - '.json'.length,
            )] =
            payload;
      }
      final insertedCharacterIds = <String>[];
      try {
        for (final link in restoredLinks) {
          final existing =
              await (database.select(database.characters)
                    ..where((tbl) => tbl.assetId.equals(link.characterId)))
                  .getSingleOrNull();
          if (existing != null) {
            throw StateError(
              'Canonical character ${link.characterId} already exists; '
              'embedded snapshot/fork restore must not overwrite.',
            );
          }
        }
        for (final link in restoredLinks) {
          final payload = embeddedPayloads[link.characterId];
          if (payload == null) {
            // vs-hunt-20260912n BUG-05: a missing embedded payload must
            // reject the archive before any mutation. Falling back to an
            // empty map used to silently insert a blank canonical
            // character (displayName = raw ID).
            throw FormatException(
              'Missing embedded character payload for ${link.characterId}',
            );
          }
          // Columns with schema defaults are constructor params typed
          // Value<T>; Value.absent() lets the database default apply.
          T? read<T>(String key) => payload[key] as T?;
          await database
              .into(database.characters)
              .insert(
                data.CharactersCompanion.insert(
                  assetId: link.characterId,
                  projectId: package.projectId,
                  displayName: read<String>('displayName') ?? link.characterId,
                  alias: read<String>('alias') != null
                      ? Value(read<String>('alias')!)
                      : const Value.absent(),
                  biography: read<String>('biography') != null
                      ? Value(read<String>('biography')!)
                      : const Value.absent(),
                  personality: read<String>('personality') != null
                      ? Value(read<String>('personality')!)
                      : const Value.absent(),
                  gender: read<String>('gender') != null
                      ? Value(read<String>('gender')!)
                      : const Value.absent(),
                  age: read<int>('age') != null
                      ? Value(read<int>('age')!)
                      : const Value.absent(),
                  heightCm: read<num>('heightCm') != null
                      ? Value(read<num>('heightCm')!.toDouble())
                      : const Value.absent(),
                  hair: read<String>('hair') != null
                      ? Value(read<String>('hair')!)
                      : const Value.absent(),
                  eyes: read<String>('eyes') != null
                      ? Value(read<String>('eyes')!)
                      : const Value.absent(),
                  skin: read<String>('skin') != null
                      ? Value(read<String>('skin')!)
                      : const Value.absent(),
                ),
              );
          insertedCharacterIds.add(link.characterId);
        }
      } catch (_) {
        for (final characterId in insertedCharacterIds.reversed) {
          await (database.delete(
            database.characters,
          )..where((tbl) => tbl.assetId.equals(characterId))).go();
        }
        rethrow;
      }
    }

    final staging = await Directory.systemTemp.createTemp(
      'void-workspace-restore-',
    );
    var movedIntoPlace = false;
    final insertedLinkIds = <String>[];
    try {
      if (!adopting) {
        for (final entry in decoded) {
          if (!entry.isFile || entry.name == 'workspace.export.json') continue;
          final normalized = p.posix.normalize(entry.name);
          if (!normalized.startsWith('workspace/') ||
              p.posix.isAbsolute(normalized)) {
            throw const FormatException('Archive entry escapes workspace');
          }
          final relative = normalized.substring('workspace/'.length);
          if (relative.isEmpty ||
              relative == '..' ||
              relative.startsWith('../')) {
            throw const FormatException('Archive entry escapes workspace');
          }
          final output = File(p.join(staging.path, relative));
          final resolved = p.normalize(p.absolute(output.path));
          final stagingRoot = p.normalize(p.absolute(staging.path));
          final fromRoot = p.relative(resolved, from: stagingRoot);
          if (fromRoot == '..' || fromRoot.startsWith('..${p.separator}')) {
            throw const FormatException('Archive entry escapes workspace');
          }
          await output.parent.create(recursive: true);
          await output.writeAsBytes(entry.readBytes()!);
        }

        await target.parent.create(recursive: true);
        await staging.rename(target.path);
        movedIntoPlace = true;
      }

      final existingLinkIds = adopting
          ? (await links.listForNovel(
              workspaceId,
            )).map((link) => link.linkId).toSet()
          : const <String>{};
      for (final link in restoredLinks) {
        if (adopting && existingLinkIds.contains(link.linkId)) continue;
        await links.create(link);
        insertedLinkIds.add(link.linkId);
      }
      return WorkspaceRestoreResult(
        workspaceId: workspaceId,
        restoredLinkCount: insertedLinkIds.length,
        skipped: false,
      );
    } catch (_) {
      for (final linkId in insertedLinkIds.reversed) {
        await links.unlink(linkId);
      }
      if (movedIntoPlace && await target.exists()) {
        await target.delete(recursive: true);
      }
      rethrow;
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  /// Reads the archive manifest without touching any workspace directory.
  /// Used by import actions to surface the declared character representation
  /// before the user commits to a collision decision.
  static Future<Map<String, dynamic>> peekManifest(File archive) async {
    final decoded = ZipDecoder().decodeBytes(
      await archive.readAsBytes(),
      verify: true,
    );
    final entry = decoded.find('workspace.export.json');
    if (entry == null || !entry.isFile) {
      throw const FormatException('Missing workspace export manifest');
    }
    return jsonDecode(utf8.decode(entry.readBytes()!)) as Map<String, dynamic>;
  }

  /// Reads only the manifest entry to learn the workspace ID before any
  /// mutation. Corrupt archives raise here; that is acceptable because the
  /// default choice (`fail`) must reject collisions regardless.
  Future<String> _peekWorkspaceId(File archive) async {
    final decoded = ZipDecoder().decodeBytes(
      await archive.readAsBytes(),
      verify: true,
    );
    final entry = decoded.find('workspace.export.json');
    if (entry == null || !entry.isFile) {
      throw const FormatException('Missing workspace export manifest');
    }
    final manifest =
        jsonDecode(utf8.decode(entry.readBytes()!)) as Map<String, dynamic>;
    final id = manifest['workspaceId'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Missing Novel workspace ID');
    }
    return id;
  }
}
