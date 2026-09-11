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
/// Cross-volume moves are out of scope for this service: `Directory.rename`
/// does not cross volume boundaries.
class ProjectMoveService {
  const ProjectMoveService();

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
      await package.rename(destination);
    } on FileSystemException {
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
    // The marker travelled with the package into the destination: the
    // move itself is complete, but the journal stays on disk. The caller
    // (ProjectRelocationService) must first make the registry repoint
    // durable — bug-hunt vs-hunt-20260911 BUG-3: consuming the journal
    // BEFORE the entry is repointed left a crash window where a healthy
    // package had zero journal and a stale entry, invisible to every
    // documented safety net. The relocation service drains it right
    // after the upsert; the registry's landed-marker sweep remains the
    // safety net for an un-drained stale journal.
    return Directory(destination);
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
