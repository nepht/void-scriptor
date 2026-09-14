import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/project_package/project_package.dart';
import '../domain/novel_character_link.dart';
import 'novel_character_link_repository.dart';
import 'workspace_file_namespace.dart';
import 'workspace_projection_cache.dart';

final class CharacterNovelAssignment {
  const CharacterNovelAssignment({
    required this.characterId,
    required this.novelWorkspaceId,
  });

  final String characterId;
  final String novelWorkspaceId;
}

/// BUG-1 + BUG-5 (vs-hunt-20260914-workspaces): a migration that cannot
/// complete leaves no partial state. Every stage that mutates data runs
/// inside one database transaction with filesystem compensation, so a
/// failure is always reported through this type rather than as a raw
/// IO/SQLite error or — worse — a success-shaped report.
final class WorkspaceMigrationFailure implements Exception {
  const WorkspaceMigrationFailure({
    required this.stage,
    required this.message,
    required this.compensated,
    this.compensationErrors = const [],
    this.cause,
  });

  /// 'backup' | 'copy' | 'verification' | 'database'.
  final String stage;
  final String message;

  /// True when every installed filesystem artifact was rolled back. When
  /// false, [compensationErrors] names what is still on disk.
  final bool compensated;
  final List<String> compensationErrors;
  final Object? cause;

  @override
  String toString() =>
      'WorkspaceMigrationFailure(stage: $stage, message: $message, '
      'compensated: $compensated'
      '${compensationErrors.isEmpty ? '' : ', compensationErrors: $compensationErrors'}'
      ')';
}

final class WorkspaceMigrationReport {
  const WorkspaceMigrationReport({
    required this.backupCreated,
    required this.inventoriedStories,
    required this.inventoriedCharacters,
    required this.copiedStoryFiles,
    required this.copiedCharacterFiles,
    required this.createdLinks,
    required this.validatedCounts,
    required this.projectionRebuilt,
    required this.rollbackDrillPassed,
  });

  final bool backupCreated;
  final List<String> inventoriedStories;
  final List<String> inventoriedCharacters;
  final int copiedStoryFiles;
  final int copiedCharacterFiles;
  final int createdLinks;
  final bool validatedCounts;
  final bool projectionRebuilt;
  final bool rollbackDrillPassed;
}

final class WorkspaceMigrationRunner {
  WorkspaceMigrationRunner({
    required this.package,
    required this.links,
    required this.backups,
    required this.projections,
  }) : _files = WorkspaceFileNamespace(package);

  final ProjectPackage package;
  final NovelCharacterLinkRepository links;
  final dynamic backups;
  final WorkspaceProjectionCache projections;
  final WorkspaceFileNamespace _files;

  Future<WorkspaceMigrationReport> migrate({
    required Map<String, String> storyWorkspaceIds,
    required List<CharacterNovelAssignment> characterAssignments,
  }) async {
    // Phase 1: validate everything before mutating anything.
    for (final entry in storyWorkspaceIds.entries) {
      if (!WorkspaceFileNamespace.isValidWorkspaceIdentifier(entry.key)) {
        throw ArgumentError.value(entry.key, 'storyWorkspaceIds key');
      }
      if (!WorkspaceFileNamespace.isValidWorkspaceIdentifier(entry.value)) {
        throw ArgumentError.value(entry.value, 'storyWorkspaceIds value');
      }
    }
    // BUG-4 (vs-hunt-20260914-workspaces): one target Novel workspace fed by
    // two legacy story IDs would merge two independent directories into the
    // same typed namespace. Merging needs an explicit policy, so refuse.
    final uniqueTargets = storyWorkspaceIds.values.toSet();
    if (uniqueTargets.length != storyWorkspaceIds.length) {
      throw ArgumentError.value(
        storyWorkspaceIds.values.toList(),
        'storyWorkspaceIds',
        'duplicate target novel workspace',
      );
    }
    final seenPairs = <String>{};
    final seenLinkIds = <String>{};
    for (final assignment in characterAssignments) {
      if (!WorkspaceFileNamespace.isValidWorkspaceIdentifier(
        assignment.characterId,
      )) {
        throw ArgumentError.value(assignment.characterId, 'characterId');
      }
      // A Character assignment names the TARGET novel workspace (the same
      // identifier links and projections use), not the legacy story id.
      if (!uniqueTargets.contains(assignment.novelWorkspaceId)) {
        throw ArgumentError.value(
          assignment.novelWorkspaceId,
          'novelWorkspaceId',
          'not a mapped Story workspace',
        );
      }
      // BUG-3 (vs-hunt-20260914-workspaces): one character may legitimately
      // be assigned to several novels; only the exact pair is a duplicate.
      final pairKey =
          '${assignment.novelWorkspaceId}\u0000${assignment.characterId}';
      if (!seenPairs.add(pairKey)) {
        throw ArgumentError.value(
          assignment.characterId,
          'characterId',
          'duplicated assignment',
        );
      }
      // BUG-4 (vs-hunt-20260914-workspaces): link ids join dash-containing
      // identifiers, so 'a-b'+'c' and 'a'+'b-c' collide; preflight uniqueness.
      final linkId =
          'migration-${assignment.novelWorkspaceId}-${assignment.characterId}';
      if (!seenLinkIds.add(linkId)) {
        throw ArgumentError.value(
          linkId,
          'characterAssignments',
          'duplicate deterministic link id',
        );
      }
    }
    // BUG-2 (vs-hunt-20260914-workspaces): a legacy tree with symlinked
    // content could pull bytes from outside the package into migrated
    // workspaces. Refuse before any backup or mutation.
    final storiesRoot = Directory(
      p.join(package.assetsDirectory.path, 'stories'),
    );
    final charactersRoot = Directory(
      p.join(package.assetsDirectory.path, 'characters'),
    );
    for (final legacyStoryId in storyWorkspaceIds.keys) {
      await _assertNoSymlinkedContent(
        Directory(p.join(storiesRoot.path, legacyStoryId)),
      );
    }
    for (final assignment in characterAssignments) {
      await _assertNoSymlinkedContent(
        Directory(p.join(charactersRoot.path, assignment.characterId)),
      );
    }

    // BUG-1 (vs-hunt-20260914-workspaces): every artifact this run installs
    // is tracked, and any later failure compensates exactly those artifacts —
    // pre-existing content is never deleted. Database link writes run in one
    // transaction so no link survives without its full set.
    final installedFiles = <File>[];
    final installedDirectories = <({Directory directory, bool fresh})>[];
    Future<Directory> trackWorkspace(Directory directory) async {
      final fresh = !await directory.exists();
      await directory.create(recursive: true);
      installedDirectories.add((directory: directory, fresh: fresh));
      return directory;
    }

    Future<WorkspaceMigrationFailure> compensate(
      String stage,
      String message,
      Object cause,
      StackTrace trace,
    ) async {
      final compensationErrors = <String>[];
      for (final file in installedFiles.reversed) {
        try {
          if (await file.exists()) await file.delete();
        } catch (error) {
          compensationErrors.add('${file.path}: $error');
        }
      }
      for (final entry in installedDirectories.reversed) {
        if (!entry.fresh) continue;
        try {
          if (await entry.directory.exists()) {
            await entry.directory.delete(recursive: true);
          }
        } catch (error) {
          compensationErrors.add('${entry.directory.path}: $error');
        }
      }
      final failure = WorkspaceMigrationFailure(
        stage: stage,
        message: message,
        compensated: compensationErrors.isEmpty,
        compensationErrors: compensationErrors,
        cause: cause,
      );
      Error.throwWithStackTrace(failure, trace);
    }

    // Phase 2: pre-migration backup (manifest + db + assets + workspaces).
    // BUG-6 (vs-hunt-20260914-workspaces): capture the exact backup identity;
    // re-discovering one by lexicographic path order can pick an unrelated
    // UUID-named backup taken by someone else.
    final Directory preMigrationBackup;
    try {
      preMigrationBackup = await backups.create(
        package: package,
        type: 'pre-workspace-migration',
        note: 'Automatic backup before ADR-WS-001 mixed-storage migration',
      );
    } catch (error) {
      // The backup precedes every mutation: nothing was changed, but the
      // runner must still refuse to proceed (BUG-1 fail-closed contract).
      throw WorkspaceMigrationFailure(
        stage: 'backup',
        message: 'pre-migration backup failed; no data was changed',
        compensated: true,
        cause: error,
      );
    }

    // Phase 3: inventory legacy mixed storage from disk.
    // (storiesRoot / charactersRoot were resolved during Phase 1 validation.)
    final inventoriedStories = await _listChildDirectories(storiesRoot);
    final inventoriedCharacters = await _listChildDirectories(charactersRoot);
    for (final assignment in characterAssignments) {
      if (!inventoriedCharacters.contains(assignment.characterId)) {
        throw ArgumentError.value(
          assignment.characterId,
          'characterId',
          'no legacy Character directory',
        );
      }
    }

    // Phase 4: copy into typed namespaces without deleting legacy sources.
    var copiedStoryFiles = 0;
    for (final entry in storyWorkspaceIds.entries) {
      final source = Directory(p.join(storiesRoot.path, entry.key));
      try {
        // DB-only packages keep an empty legacy scaffold; the migrated Novel
        // still needs its home on disk for later exports.
        final target = await trackWorkspace(_files.novelDirectory(entry.value));
        copiedStoryFiles += await _copyInto(source, target, installedFiles);
      } catch (error, trace) {
        await compensate(
          'copy',
          'failed copying legacy story ${entry.key}',
          error,
          trace,
        );
      }
    }
    var copiedCharacterFiles = 0;
    // One character may be linked to several novels; its legacy directory is
    // copied once into its typed Character workspace.
    for (final characterId
        in characterAssignments.map((a) => a.characterId).toSet()) {
      final source = Directory(p.join(charactersRoot.path, characterId));
      try {
        final target = await trackWorkspace(
          _files.characterDirectory(characterId),
        );
        copiedCharacterFiles += await _copyInto(source, target, installedFiles);
      } catch (error, trace) {
        await compensate(
          'copy',
          'failed copying legacy character $characterId',
          error,
          trace,
        );
      }
    }

    // Phase 5 (BUG-5, vs-hunt-20260914-workspaces): validate the copy BEFORE
    // any database write. A mismatch is a failure that aborts the migration
    // — it never degrades into a success-shaped report.
    for (final entry in storyWorkspaceIds.entries) {
      final verified = await _verifyCopy(
        Directory(p.join(storiesRoot.path, entry.key)),
        _files.novelDirectory(entry.value),
      );
      if (!verified) {
        await compensate(
          'verification',
          'story copy verification failed for ${entry.key} -> '
              '${entry.value}',
          StateError('checksum/count mismatch'),
          StackTrace.current,
        );
      }
    }
    for (final assignment in characterAssignments) {
      final verified = await _verifyCopy(
        Directory(p.join(charactersRoot.path, assignment.characterId)),
        _files.characterDirectory(assignment.characterId),
      );
      if (!verified) {
        await compensate(
          'verification',
          'character copy verification failed for '
              '${assignment.characterId}',
          StateError('checksum/count mismatch'),
          StackTrace.current,
        );
      }
    }

    // Phase 6: explicit links only, deterministic IDs, reference mode.
    // BUG-1: one database transaction — a conflict on any link rolls the
    // whole link set back, then filesystem output is compensated too.
    var createdLinks = 0;
    try {
      await links.transaction(() async {
        for (final assignment in characterAssignments) {
          await links.create(
            NovelCharacterLink.create(
              linkId:
                  'migration-${assignment.novelWorkspaceId}-${assignment.characterId}',
              novelWorkspaceId: assignment.novelWorkspaceId,
              characterWorkspaceId: assignment.characterId,
              characterId: assignment.characterId,
              role: 'migrated',
              visibility: 'visible',
            ),
          );
          createdLinks++;
        }
      });
    } catch (error, trace) {
      await compensate(
        'database',
        'link transaction failed; database rolled back',
        error,
        trace,
      );
    }

    // Phase 7: rebuild projections for migrated Novels.
    for (final novelWorkspaceId in storyWorkspaceIds.values.toSet()) {
      projections.invalidate(novelWorkspaceId);
    }

    // Phase 8: rollback drill on a disposable copy using backup contents.
    // A drill failure never reverts a committed migration (the drill is
    // diagnostic only — run310 contract): it is surfaced as
    // rollbackDrillPassed == false while the compensation ledger stays clean.
    var rollbackDrillPassed = false;
    try {
      rollbackDrillPassed = await _runRollbackDrill(preMigrationBackup);
    } catch (_) {
      rollbackDrillPassed = false;
    }

    return WorkspaceMigrationReport(
      backupCreated: true,
      inventoriedStories: inventoriedStories,
      inventoriedCharacters: inventoriedCharacters,
      copiedStoryFiles: copiedStoryFiles,
      copiedCharacterFiles: copiedCharacterFiles,
      createdLinks: createdLinks,
      validatedCounts: true,
      projectionRebuilt: true,
      rollbackDrillPassed: rollbackDrillPassed,
    );
  }

  Future<void> _assertNoSymlinkedContent(Directory? root) async {
    if (root == null || !await root.exists()) return;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is Link) {
        throw ArgumentError.value(
          entity.path,
          'legacy content',
          'workspace migration refuses symlinked content',
        );
      }
    }
  }

  Future<List<String>> _listChildDirectories(Directory? parent) async {
    if (parent == null || !await parent.exists()) return const [];
    final names = <String>[];
    await for (final entity in parent.list()) {
      if (entity is Directory) names.add(p.basename(entity.path));
    }
    names.sort();
    return names;
  }

  Future<int> _copyInto(
    Directory? source,
    Directory target, [
    List<File>? installedFiles,
  ]) async {
    if (source == null || !await source.exists()) return 0;
    var count = 0;
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      // Never import link-resolved bytes; the preflight already refuses
      // symlinked trees, this keeps the copy loop safe against races.
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: source.path);
      final destination = File(p.join(target.path, 'legacy', relative));
      final alreadyPresent = await destination.exists();
      await destination.parent.create(recursive: true);
      await entity.copy(destination.path);
      // BUG-1: compensation removes only files this run actually installed;
      // content that was already at the destination is never deleted.
      if (!alreadyPresent) installedFiles?.add(destination);
      count++;
    }
    return count;
  }

  Future<bool> _verifyCopy(Directory source, Directory target) async {
    if (!await source.exists()) return true;
    var expected = 0;
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      expected++;
      final relative = p.relative(entity.path, from: source.path);
      final copied = File(p.join(target.path, 'legacy', relative));
      if (!await copied.exists()) return false;
      final sourceDigest = sha256
          .convert(await entity.readAsBytes())
          .toString();
      final copiedDigest = sha256
          .convert(await copied.readAsBytes())
          .toString();
      if (sourceDigest != copiedDigest) return false;
    }
    var actual = 0;
    final legacy = Directory(p.join(target.path, 'legacy'));
    if (await legacy.exists()) {
      await for (final entity in legacy.list(recursive: true)) {
        if (entity is File) actual++;
      }
    }
    return actual == expected;
  }

  Future<bool> _runRollbackDrill(Directory backup) async {
    // BUG-6 (vs-hunt-20260914-workspaces): operate on the exact backup this
    // migration created. A vanished backup fails the drill; it must never
    // fall back to whichever UUID-named directory sorts last on disk.
    if (!await backup.exists()) return false;
    final metadata = File(p.join(backup.path, 'backup.json'));
    if (await metadata.exists()) {
      final decoded = jsonDecode(await metadata.readAsString());
      if (decoded is! Map<String, dynamic> ||
          decoded['projectId'] != package.projectId) {
        return false;
      }
    }
    final drill = await Directory.systemTemp.createTemp('ws-migration-drill-');
    try {
      final drillPackage = ProjectPackage(
        projectId: package.projectId,
        root: Directory(p.join(drill.path, 'drill-package')),
      );
      await _copyTree(
        package.manifestDirectory,
        drillPackage.manifestDirectory,
      );
      await File(
        p.join(drillPackage.databaseDirectory.path, 'project.db'),
      ).parent.create(recursive: true);
      if (await package.databaseFile.exists()) {
        await package.databaseFile.copy(
          p.join(drillPackage.databaseDirectory.path, 'project.db'),
        );
      }
      await _copyTree(package.assetsDirectory, drillPackage.assetsDirectory);

      // Apply the same mutation shape on the copy.
      final mutatedWorkspaces = Directory(
        p.join(drill.path, 'mutated-workspaces'),
      );
      await _copyTree(
        Directory(p.join(package.root.path, 'workspaces')),
        Directory(p.join(mutatedWorkspaces.path, 'workspaces')),
      );

      // Restore from the captured pre-migration backup onto the drill copy.
      final restoredWorkspaces = Directory(
        p.join(mutatedWorkspaces.path, 'workspaces'),
      );
      if (await restoredWorkspaces.exists()) {
        await restoredWorkspaces.delete(recursive: true);
      }
      await _copyTree(
        Directory(p.join(backup.path, 'workspaces')),
        restoredWorkspaces,
      );
      final remaining = <File>[];
      if (await restoredWorkspaces.exists()) {
        await for (final entity in restoredWorkspaces.list(recursive: true)) {
          if (entity is File) remaining.add(entity);
        }
      }
      return remaining.isEmpty;
    } finally {
      if (await drill.exists()) await drill.delete(recursive: true);
    }
  }

  Future<void> _copyTree(Directory? source, Directory target) async {
    if (source == null || !await source.exists()) return;
    await for (final entity in source.list(recursive: true)) {
      final relative = p.relative(entity.path, from: source.path);
      if (entity is Directory) {
        await Directory(p.join(target.path, relative)).create(recursive: true);
      } else if (entity is File) {
        final destination = File(p.join(target.path, relative));
        await destination.parent.create(recursive: true);
        await entity.copy(destination.path);
      }
    }
  }
}
