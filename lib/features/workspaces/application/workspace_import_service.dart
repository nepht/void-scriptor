import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

/// vs-hunt-20260912n BUG-12: an archive file larger than the configured cap
/// is refused before any of its bytes are read into memory.
final class WorkspaceArchiveTooLargeException implements Exception {
  const WorkspaceArchiveTooLargeException({
    required this.archivePath,
    required this.archiveBytes,
    required this.maxAllowedBytes,
  });

  final String archivePath;
  final int archiveBytes;
  final int maxAllowedBytes;

  @override
  String toString() =>
      'Workspace archive exceeds the size cap: $archiveBytes bytes > '
      '$maxAllowedBytes bytes ($archivePath).';
}

final class WorkspaceImportService {
  /// Default cap for import archives. Novel workspace exports are text
  /// payloads (drafts, references, embedded character JSON); anything past
  /// this is either an accident or a hostile file, and the full archive is
  /// decoded in memory, so the cap must exist BEFORE reading.
  static const int defaultMaxArchiveBytes = 512 * 1024 * 1024; // 512 MiB

  /// Runtime check (not an assert): a non-positive cap would silently
  /// disable the guard in release builds.
  static void validateMaxArchiveBytes(int maxArchiveBytes) {
    if (maxArchiveBytes <= 0) {
      throw ArgumentError.value(
        maxArchiveBytes,
        'maxArchiveBytes',
        'must be a positive byte count',
      );
    }
  }

  WorkspaceImportService({
    required this.package,
    required this.links,
    data.ProjectDatabase? database,
    this.maxArchiveBytes = defaultMaxArchiveBytes,
  }) : database = database ?? links.database,
       files = WorkspaceFileNamespace(package) {
    validateMaxArchiveBytes(maxArchiveBytes);
  }

  final ProjectPackage package;
  final NovelCharacterLinkRepository links;

  /// vs-hunt-20260912n BUG-12: hard bound on archive size, checked against
  /// the file's length BEFORE `readAsBytes()` so an oversized file never
  /// reaches memory.
  final int maxArchiveBytes;

  /// Reads the whole archive only after its size clears [maxArchiveBytes].
  Future<Uint8List> readArchiveBytes(File archive) async {
    final size = await archive.length();
    if (size > maxArchiveBytes) {
      throw WorkspaceArchiveTooLargeException(
        archivePath: archive.path,
        archiveBytes: size,
        maxAllowedBytes: maxArchiveBytes,
      );
    }
    return archive.readAsBytes();
  }

  /// Shared gate for the static peek path: same bound as the instance guard.
  static Future<Uint8List> readArchiveBytesBounded(
    File archive, {
    required int maxArchiveBytes,
  }) async {
    validateMaxArchiveBytes(maxArchiveBytes);
    final size = await archive.length();
    if (size > maxArchiveBytes) {
      throw WorkspaceArchiveTooLargeException(
        archivePath: archive.path,
        archiveBytes: size,
        maxAllowedBytes: maxArchiveBytes,
      );
    }
    return archive.readAsBytes();
  }

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
    // vs-hunt-20260912n BUG-07/20: the pre-check belongs to the `fail`
    // contract only. For `fail` a missing or corrupt archive must not change
    // which error an existing target raises, so it still runs before reading
    // the archive. For `skip` and `adoptExistingLinks` the caller has already
    // decided an existing target is acceptable, so the archive must be
    // validated first and the collision handled below — an unconditional
    // early throw made both non-fail choices unreachable whenever the caller
    // supplied an expected workspace ID.
    if (expectedWorkspaceId != null &&
        collisionChoice == WorkspaceImportCollisionChoice.fail) {
      final expectedTarget = files.novelDirectory(expectedWorkspaceId);
      if (await expectedTarget.exists()) {
        throw StateError(
          'Novel workspace already exists; collision decision is required.',
        );
      }
    }
    // vs-hunt-20260912n BUG-12: the size cap gates the read itself, so an
    // oversized file is refused before its bytes enter memory.
    final decoded = ZipDecoder().decodeBytes(
      await readArchiveBytes(archive),
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
    // vs-hunt-20260912n BUG-02: only version-1 semantics are implemented.
    // An unknown or missing version must be rejected before any mutation,
    // not silently decoded with version-1 rules.
    if (manifest['version'] != 1) {
      throw const FormatException('Unsupported Novel workspace export version');
    }
    final workspaceId = manifest['workspaceId'] as String?;
    if (workspaceId == null || workspaceId.trim().isEmpty) {
      throw const FormatException('Missing Novel workspace ID');
    }
    if (expectedWorkspaceId != null && expectedWorkspaceId != workspaceId) {
      throw const FormatException('Workspace ID does not match expectation');
    }

    // vs-hunt-20260912n BUG-07/20: the collision decision is taken against
    // the archive's own validated workspace ID, AFTER the manifest proves the
    // archive is a readable Novel export. A corrupt archive now reports its
    // real error instead of being masked by a collision, and `skip` /
    // `adoptExistingLinks` stay reachable with an expected workspace ID.
    final target = files.novelDirectory(workspaceId);
    final hasCollision = await target.exists();
    if (hasCollision &&
        collisionChoice == WorkspaceImportCollisionChoice.skip) {
      return WorkspaceRestoreResult(
        workspaceId: workspaceId,
        restoredLinkCount: 0,
        skipped: true,
      );
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
    final embedded =
        representation != null && representation != 'reference_manifest';

    // vs-hunt-20260912n BUG-01: every mutation (character materialization,
    // directory move, link inserts) happens inside ONE transaction. The old
    // compensating-delete loops only covered the phase they ran in, so a
    // failure while inserting links left already-materialized canonical
    // characters behind as ghosts. Drift rolls the whole database back on
    // any throw; only the filesystem move needs manual undo.
    final staging = await Directory.systemTemp.createTemp(
      'void-workspace-restore-',
    );
    var movedIntoPlace = false;
    var restoredLinkCount = 0;
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
      }

      await database.transaction(() async {
        // vs-hunt-20260912n BUG-03: adoptExistingLinks is documented as
        // link-only ("insert only link-manifest entries whose link ID does
        // not exist yet"). Materializing embedded payloads during an adopt
        // either aborted the whole operation on an existing canonical
        // character or inserted payload characters as ghosts, so the
        // embedded block is skipped whenever adopting is true.
        if (embedded && !adopting) {
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
                jsonDecode(utf8.decode(entry.readBytes()!))
                    as Map<String, dynamic>;
            embeddedPayloads[normalized.substring(
                  embeddedPrefix.length,
                  normalized.length - '.json'.length,
                )] =
                payload;
          }
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
                    displayName:
                        read<String>('displayName') ?? link.characterId,
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
          }
        }

        if (!adopting) {
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
          restoredLinkCount++;
        }
      });

      return WorkspaceRestoreResult(
        workspaceId: workspaceId,
        restoredLinkCount: restoredLinkCount,
        skipped: false,
      );
    } catch (_) {
      if (movedIntoPlace && await target.exists()) {
        await target.delete(recursive: true);
      }
      rethrow;
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  /// vs-hunt-20260912n BUG-17: symmetric counterpart of
  /// [WorkspaceExportService.exportCharacter]. Before this, character
  /// archives were write-only artifacts — `restoreNovel` hard-rejects any
  /// non-novel manifest, so nothing could read them back.
  ///
  /// Scope contract: a character export carries ONLY workspace files. It has
  /// no link manifest and no embedded canonical rows, so restore touches
  /// neither `novel_character_links` nor the `characters` table; it validates
  /// the same chain as the novel path (size cap BEFORE read, format/type/
  /// version, workspace ID, collision decision) and then moves the extracted
  /// files into the character namespace atomically.
  Future<WorkspaceRestoreResult> restoreCharacter(
    File archive, {
    String? expectedWorkspaceId,
    WorkspaceImportCollisionChoice collisionChoice =
        WorkspaceImportCollisionChoice.fail,
  }) async {
    // Same ordering contract as restoreNovel (BUG-07/20): the early
    // collision pre-check belongs to the `fail` choice only, so a corrupt
    // archive reports its real error under `skip`.
    if (expectedWorkspaceId != null &&
        collisionChoice == WorkspaceImportCollisionChoice.fail) {
      final expectedTarget = files.characterDirectory(expectedWorkspaceId);
      if (await expectedTarget.exists()) {
        throw StateError(
          'Character workspace already exists; collision decision is '
          'required.',
        );
      }
    }
    // BUG-12's bound applies to every archive read, not just the novel path.
    final decoded = ZipDecoder().decodeBytes(
      await readArchiveBytes(archive),
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
        manifest['workspaceType'] != 'character') {
      throw const FormatException(
        'Archive is not a Character workspace export',
      );
    }
    if (manifest['version'] != 1) {
      throw const FormatException(
        'Unsupported Character workspace export version',
      );
    }
    final workspaceId = manifest['workspaceId'] as String?;
    if (workspaceId == null || workspaceId.trim().isEmpty) {
      throw const FormatException('Missing Character workspace ID');
    }
    if (expectedWorkspaceId != null && expectedWorkspaceId != workspaceId) {
      throw const FormatException('Workspace ID does not match expectation');
    }
    // adoptExistingLinks is a link-merging decision; a character archive
    // declares no links, so offering it would silently do nothing useful.
    if (collisionChoice == WorkspaceImportCollisionChoice.adoptExistingLinks) {
      throw StateError(
        'Character workspace exports have no link manifest; '
        'adoptExistingLinks is not supported.',
      );
    }
    final target = files.characterDirectory(workspaceId);
    final hasCollision = await target.exists();
    if (hasCollision &&
        collisionChoice == WorkspaceImportCollisionChoice.skip) {
      return WorkspaceRestoreResult(
        workspaceId: workspaceId,
        restoredLinkCount: 0,
        skipped: true,
      );
    }
    if (hasCollision) {
      throw StateError(
        'Character workspace already exists; collision decision is required.',
      );
    }

    final staging = await Directory.systemTemp.createTemp(
      'void-workspace-restore-character-',
    );
    var movedIntoPlace = false;
    try {
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
      return WorkspaceRestoreResult(
        workspaceId: workspaceId,
        restoredLinkCount: 0,
        skipped: false,
      );
    } catch (_) {
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
  ///
  /// vs-hunt-20260912n BUG-12: peek runs BEFORE restore in the production
  /// flow, so it enforces the same size cap — otherwise the guard would only
  /// exist on the second read of the file.
  static Future<Map<String, dynamic>> peekManifest(
    File archive, {
    int maxArchiveBytes = defaultMaxArchiveBytes,
  }) async {
    final decoded = ZipDecoder().decodeBytes(
      await readArchiveBytesBounded(archive, maxArchiveBytes: maxArchiveBytes),
      verify: true,
    );
    final entry = decoded.find('workspace.export.json');
    if (entry == null || !entry.isFile) {
      throw const FormatException('Missing workspace export manifest');
    }
    return jsonDecode(utf8.decode(entry.readBytes()!)) as Map<String, dynamic>;
  }
}
