import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/project_model.dart';
import 'project_recovery_service.dart';
import 'project_registry_service.dart';

/// Moves a project package between directories of one volume behind a
/// durable journal so an interrupted rename (process kill / power loss) is
/// recoverable instead of silently losing the package (145.42).
///
/// The journal (`move-pending.marker`) is written and flushed BEFORE the
/// rename opens the crash window. Recovery contract:
/// - rename completed  -> [movePackage] returns the destination WITH the
///   journal still inside it. The caller must persist the registry repoint
///   FIRST and only then drain the stale journal — bug-hunt
///   vs-hunt-20260911 BUG-3 reversed the old consume-before-upsert order
///   (durability first, the registry's own rule). If the caller crashes
///   before draining, the journal is stale state the registry consumes
///   once its entry points at the new location (landed-marker sweep), or
///   it survives as recovery evidence when the entry was never repointed;
/// - rename never ran  -> [ProjectRecoveryService.recoverInterruptedMoves]
///   rolls the package forward to the recorded destination;
/// - rename failed     -> the package is still at the source, the journal
///   is consumed, and the error surfaces to the caller.
/// Same-volume moves use `Directory.rename` (atomic, journal travels inside
/// the package). Cross-volume moves — the primary 145.42 case, "Move
/// Project" onto a USB drive — cannot rename (Windows errno 17 / POSIX
/// EXDEV 18) and fall back to a staged copy-verify-place-delete on the
/// destination volume, keeping the same journal contract: the marker is
/// copied into the package before it is placed, so a crash at any step
/// before the registry repoint stays recoverable, and a failed attempt
/// leaves the source untouched with its journal consumed.
class ProjectMoveService {
  const ProjectMoveService({this.renameOverride});

  /// Test seam for the rename step; production leaves it null. The USB-real
  /// session (2026-09-14) proved the cross-device branch cannot be reached
  /// on CI without a second volume, so the rename error is injectable.
  final Future<Directory> Function(String from, String to)? renameOverride;

  /// `ERROR_NOT_SAME_DEVICE` on Windows; EXDEV (18) on POSIX.
  static bool _isCrossDeviceError(FileSystemException error) {
    final code = error.osError?.errorCode;
    return code == 17 || code == 18;
  }

  Future<Directory> movePackage({
    required Directory package,
    required Directory destinationRoot,
  }) async {
    final name = p.basename(package.path);
    final destination = p.join(destinationRoot.path, name);
    await destinationRoot.create(recursive: true);
    final marker = File(
      p.join(package.path, ProjectRecoveryService.movePendingMarkerName),
    );
    final projectId = name.endsWith('.voidproject')
        ? name.substring(0, name.length - '.voidproject'.length)
        : name;
    await marker.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'projectId': projectId,
        'source': package.path,
        'destination': destination,
        'writtenAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
    try {
      final renamed = renameOverride == null
          ? await package.rename(destination)
          : await renameOverride!(package.path, destination);
      // The marker travelled with the package into the destination: the
      // move itself is complete, but the journal stays on disk. The caller
      // (ProjectRelocationService) must first make the registry repoint
      // durable — bug-hunt vs-hunt-20260911 BUG-3: consuming the journal
      // BEFORE the entry is repointed left a crash window where a healthy
      // package had zero journal and a stale entry, invisible to every
      // documented safety net. The relocation service drains it right
      // after the upsert; the registry's landed-marker sweep remains the
      // safety net for an un-drained stale journal.
      return renamed;
    } on FileSystemException catch (error) {
      if (_isCrossDeviceError(error)) {
        // 145.42 USB: rename cannot cross volume boundaries; stage a
        // copy-verify-place-delete so moving to a flash drive works.
        return _copyMovePackage(
          package: package,
          destination: destination,
          marker: marker,
        );
      }
      // The rename failed: the package never left the source. Consume the
      // journal so a later scan cannot roll a move that must not happen.
      try {
        await marker.delete();
      } on FileSystemException {
        // Best effort: recovery treats an unmoveable source+occupied
        // destination as untouched state and leaves the journal in place.
      }
      rethrow;
    }
  }

  /// Cross-volume fallback (145.42 USB real-hardware finding): copy the
  /// whole package into a staging directory on the destination volume,
  /// verify the copy, publish it to its final place, and only then delete
  /// the source. The journal marker is copied with the package, so every
  /// crash point between copy-completion and the registry repoint leaves
  /// recoverable state: the destination holds a journaled package and
  /// [ProjectRecoveryService.recoverInterruptedMoves] rolls a surviving
  /// source forward. Any failure at or before publishing drops staging and
  /// consumes the journal — the source stays intact.
  Future<Directory> _copyMovePackage({
    required Directory package,
    required String destination,
    required File marker,
  }) async {
    final staging = Directory('$destination.xvol-staging');
    if (await Directory(destination).exists()) {
      // Same guard the rename path inherits from the OS: never overwrite an
      // occupied destination. Consume the journal and fail like a refused
      // rename would.
      try {
        await marker.delete();
      } on FileSystemException {
        // Best effort, mirrors the rename-failure branch above.
      }
      throw FileSystemException(
        'Move destination already exists',
        destination,
        const OSError(
          'Cannot create a file when that file already exists',
          183,
        ),
      );
    }
    try {
      await _copyTree(package, staging);
      await _verifyTree(package, staging);
      await staging.rename(destination);
      await _publishFlush(Directory(destination));
      await package.delete(recursive: true);
    } on Object {
      try {
        if (await staging.exists()) await staging.delete(recursive: true);
      } on FileSystemException {
        // Best effort.
      }
      try {
        if (await marker.exists()) await marker.delete();
      } on FileSystemException {
        // Best effort: recovery treats an unmoveable source+occupied
        // destination as untouched state and leaves the journal in place.
      }
      rethrow;
    }
    return Directory(destination);
  }

  Future<void> _copyTree(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list(recursive: true)) {
      final relative = p.relative(entity.path, from: from.path);
      final target = p.join(to.path, relative);
      if (entity is Directory) {
        await Directory(target).create(recursive: true);
      } else if (entity is File) {
        await Directory(p.dirname(target)).create(recursive: true);
        await entity.copy(target);
      } else if (entity is Link) {
        // Project packages do not contain symlinks; refuse rather than
        // silently drop one from the copy.
        throw FileSystemException(
          'Cross-volume move does not support symlinks',
          entity.path,
        );
      }
    }
  }

  Future<void> _verifyTree(Directory source, Directory staged) async {
    final sourceFiles = <String, int>{};
    await for (final entity in source.list(recursive: true)) {
      if (entity is File) {
        sourceFiles[p.relative(entity.path, from: source.path)] = await entity
            .length();
      }
    }
    final stagedFiles = <String, int>{};
    await for (final entity in staged.list(recursive: true)) {
      if (entity is File) {
        stagedFiles[p.relative(entity.path, from: staged.path)] = await entity
            .length();
      }
    }
    final problems = <String>[];
    for (final entry in sourceFiles.entries) {
      final stagedLength = stagedFiles[entry.key];
      if (stagedLength == null) {
        problems.add('missing ${entry.key}');
      } else if (stagedLength != entry.value) {
        problems.add('size ${entry.key} $stagedLength != ${entry.value}');
      }
    }
    for (final key in stagedFiles.keys) {
      if (!sourceFiles.containsKey(key)) problems.add('extra $key');
    }
    if (problems.isNotEmpty) {
      throw FileSystemException(
        'Cross-volume copy verification failed: ${problems.join('; ')}',
        staged.path,
      );
    }
  }

  Future<void> _publishFlush(Directory published) async {
    // FAT32/exFAT USB: a rename is metadata-only; reopen the journal marker
    // for append and close it so the filesystem pushes the directory entry
    // out of its write cache before the source gets deleted.
    try {
      final raf = await File(
        p.join(published.path, ProjectRecoveryService.movePendingMarkerName),
      ).open(mode: FileMode.append);
      await raf.close();
    } on FileSystemException {
      // Best effort: a marker we cannot reopen is still on disk; recovery
      // treats a package whose journal is un-drainable as untouched state.
    }
  }
}

/// Wiring sprint Task 3 (bug-hunt run197 BUG-7 "both halves ship together"):
/// first production caller of [ProjectMoveService.movePackage]. A successful
/// move is followed immediately by repointing the registry entry
/// (`localPath`) to the new package location, and only after that repoint
/// is durable is the travelled journal drained — bug-hunt vs-hunt-20260911
/// BUG-3: the old order consumed the journal BEFORE the upsert, leaving a
/// crash window where a healthy package had no journal and a stale entry
/// (the registry has no path-existence re-check on load, so nothing
/// self-healed it). The registry's roll-forward scan only reaches owner
/// directories one level deep, so a journal left on a nested destination is
/// drained here or by the registry's landed-marker sweep once the entry
/// points at the package.
class ProjectRelocationService {
  const ProjectRelocationService({
    required this.registry,
    this.moveService = const ProjectMoveService(),
  });

  final ProjectRegistryService registry;
  final ProjectMoveService moveService;

  /// Returns the moved package directory. Throws the original
  /// [FileSystemException] when the rename fails; the registry entry is then
  /// untouched and the journal consumed by [ProjectMoveService] itself.
  Future<Directory> relocateProject({
    required String projectId,
    required Directory destinationRoot,
  }) async {
    final entries = await registry.load();
    ProjectModel? entry;
    for (final project in entries) {
      if (project.id == projectId) {
        entry = project;
        break;
      }
    }
    if (entry == null) {
      throw StateError('Project $projectId is not registered');
    }
    final moved = await moveService.movePackage(
      package: Directory(entry.localPath),
      destinationRoot: destinationRoot,
    );
    await registry.upsert(entry.copyWith(localPath: moved.path));
    // Durability first (bug-hunt vs-hunt-20260911 BUG-3, same rule the
    // registry applies to rolled-forward journals): the travelled marker
    // may only be consumed AFTER the repointed entry is durable. A crash
    // between the upsert and this drain leaves a stale journal on a
    // package the registry already points at — harmless state that the
    // registry's landed-marker sweep drains on the next load. Drain
    // best-effort: a transient delete failure (errno 32/5) must not
    // report a completed move as failed.
    final journal = File(
      p.join(moved.path, ProjectRecoveryService.movePendingMarkerName),
    );
    try {
      if (await journal.exists()) await journal.delete();
    } on FileSystemException {
      // Left for the registry's next load to consume.
    }
    return moved;
  }
}
