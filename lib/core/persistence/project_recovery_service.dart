import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'async_mutex.dart';

import 'project_manifest.dart';
import '../domain/project_model.dart';

class ProjectRecoveryService {
  const ProjectRecoveryService();

  /// Bug-hunt run94 BUG-02: concurrent writers on one target shared a
  /// single `.tmp` name with no serialization, so the loser failed with
  /// a spurious exception and could transiently roll the winner back.
  /// Writes to the same target path are serialized (case-insensitive on
  /// Windows via canonicalize); different targets stay parallel.
  static final Map<String, AsyncMutex> _writeLocks = <String, AsyncMutex>{};

  /// Journal for an interrupted package move (145.42). Written and
  /// flushed by [ProjectMoveService.movePackage] BEFORE the rename opens
  /// the crash window; see [recoverInterruptedMoves] for the recovery
  /// contract.
  static const String movePendingMarkerName = 'move-pending.marker';

  /// Marker file written by package creation BEFORE the crash window opens
  /// (between a finished package on disk and its registry registration).
  /// Its presence is the only explicit admission signal: folders without it
  /// are deliberately unregistered state (deleted projects) and are never
  /// touched. The marker payload is the project manifest JSON.
  static const String creationMarkerName = 'creation-in-progress.marker';

  /// Admits interrupted package creations found under [ownerDirectory].
  ///
  /// A process kill / power loss between a finished
  /// `<projectId>.voidproject` package and its registry registration would
  /// otherwise orphan a complete, intact project forever: the registry is
  /// the only discovery mechanism. A folder carrying a parseable creation
  /// marker whose schema is supported and whose manifest id matches the
  /// folder name is therefore admitted as a [ProjectModel]. Ids already
  /// known to the caller are treated as registered: their stale marker is
  /// consumed and no duplicate is produced. Unsupported or corrupt markers
  /// are left untouched for manual inspection.
  Future<List<ProjectModel>> admitMarkedCreations(
    Directory ownerDirectory,
    Set<String> knownProjectIds,
  ) async {
    final admitted = <ProjectModel>[];
    if (!await ownerDirectory.exists()) return admitted;
    await for (final entity in ownerDirectory.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (!name.endsWith('.voidproject')) continue;
      final marker = File(p.join(entity.path, creationMarkerName));
      if (!await marker.exists()) continue;
      Object? decoded;
      try {
        decoded = jsonDecode(await marker.readAsString());
      } on Object {
        continue;
      }
      if (decoded is! Map<String, dynamic>) continue;
      ProjectManifest manifest;
      try {
        manifest = ProjectManifest.fromJson(decoded);
      } on FormatException {
        continue;
      }
      final id = name.substring(0, name.length - '.voidproject'.length);
      if (id != manifest.id) continue;
      if (knownProjectIds.contains(id)) {
        await _consumeQuietly(marker);
        continue;
      }
      final now = DateTime.now().toUtc();
      admitted.add(
        ProjectModel(
          id: id,
          name: manifest.name,
          description: manifest.description,
          createdAt: manifest.createdAt,
          updatedAt: now,
          lastOpenedAt: now,
          localPath: entity.path,
          version: manifest.projectVersion,
        ),
      );
    }
    return admitted;
  }

  /// Consumes the marker once the admission is durable in the registry.
  Future<void> consumeCreationMarker(File marker) async {
    if (await marker.exists()) await marker.delete();
  }

  Future<void> _consumeQuietly(File marker) async {
    try {
      await consumeCreationMarker(marker);
    } on FileSystemException {
      // A marker that cannot be removed must not break project listing;
      // registry membership already prevents duplicate admission.
    }
  }

  Future<void> atomicWrite({required File target, required String content}) {
    final lock = _writeLocks.putIfAbsent(
      p.canonicalize(target.path),
      AsyncMutex.new,
    );
    return lock.run(() => _atomicWriteLocked(target: target, content: content));
  }

  Future<void> _atomicWriteLocked({
    required File target,
    required String content,
  }) async {
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');

    await temporary.writeAsString(content, flush: true);
    if (await target.exists()) {
      if (await backup.exists()) await backup.delete();
      await target.rename(backup.path);
    }

    try {
      await temporary.rename(target.path);
    } catch (_) {
      if (await backup.exists() && !await target.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
  }

  /// Recovers a target left behind by an interrupted [atomicWrite].
  ///
  /// A process crash (power loss, kill, permission failure) between the
  /// `target -> .bak` rename and the `.tmp -> target` rename leaves the
  /// target missing while `.bak` (last durable content) and `.tmp` (new
  /// content, possibly truncated) still exist. The `.tmp` file is never
  /// trusted because it was never renamed into place; restoring `.bak`
  /// preserves the caller's previous durable state instead of silently
  /// reporting the record missing.
  Future<void> recoverIfInterrupted(File target) async {
    if (await target.exists()) return;
    final backup = File('${target.path}.bak');
    if (await backup.exists()) {
      await backup.rename(target.path);
    }
  }

  Future<bool> restoreBackup(File target) async {
    final backup = File('${target.path}.bak');
    if (!await backup.exists()) return false;
    if (await target.exists()) await target.delete();
    await backup.rename(target.path);
    return true;
  }

  /// Recovers a package move interrupted inside the rename crash window.
  ///
  /// [ProjectMoveService.movePackage] journals a `move-pending.marker`
  /// (source, destination) before renaming the package. When the process
  /// dies before the rename, the package and its journal stay at the
  /// source root while the destination never materializes: roll the
  /// package forward to the recorded destination. When the package is
  /// already gone from the source, the move had completed and a landed
  /// marker at the destination is consumed as stale journal state. A
  /// journal whose destination is occupied or whose source package is
  /// missing without a landed destination is never guessed around and is
  /// left untouched for inspection. Returns the number of rolled-forward
  /// packages.
  Future<int> recoverInterruptedMoves(Directory sourceRoot) async {
    if (!await sourceRoot.exists()) return 0;
    var rolledForward = 0;
    await for (final entity in sourceRoot.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final marker = File(p.join(entity.path, movePendingMarkerName));
      if (!await marker.exists()) continue;
      final Object? decoded;
      try {
        decoded = jsonDecode(await marker.readAsString());
      } on Object {
        continue;
      }
      if (decoded is! Map<String, dynamic>) continue;
      final destination = decoded['destination'];
      final source = decoded['source'];
      if (destination is! String || destination.isEmpty) continue;
      if (source is! String || source.isEmpty) continue;
      // The journal must describe THIS package: identity matches when the
      // scanned directory is the recorded source (crash before the rename)
      // or the recorded destination (marker landed with the package after
      // the rename completed). Any other payload is not trusted.
      final matchesSource =
          Directory(source).absolute.path ==
          Directory(entity.path).absolute.path;
      final matchesDestination =
          Directory(destination).absolute.path ==
          Directory(entity.path).absolute.path;
      if (matchesDestination) {
        // The move landed; this marker is stale journal state.
        await marker.delete();
        continue;
      }
      final target = Directory(destination);
      if (!matchesSource || await target.exists()) {
        // Destination occupied or unavailable: leave the journal and the
        // package untouched rather than guessing.
        continue;
      }
      try {
        await entity.rename(destination);
      } on FileSystemException {
        continue;
      }
      rolledForward++;
      // The marker travelled with the package; consume it at the
      // destination so the landed journal never survives recovery.
      final travelledMarker = File(p.join(destination, movePendingMarkerName));
      try {
        if (await travelledMarker.exists()) await travelledMarker.delete();
      } on FileSystemException {
        // The registry load also consumes landed markers (best effort).
      }
    }
    return rolledForward;
  }

  /// Recovers the destination-collision stash of an interrupted import.
  ///
  /// [PortableProjectImportCoordinator] renames an existing
  /// `<projectId>.voidproject` package into a hidden
  /// `.<projectId>.voidproject.import-backup-<uuid>` stash before an import
  /// reuses that project ID. A process death inside that window (kill /
  /// power loss) never runs the Dart rollback: the user's original package
  /// stays buried under the stash while the registry still points at the
  /// final path. For every stash in [ownerDirectory] whose canonical
  /// package directory no longer exists, this restores the stash to
  /// `<projectId>.voidproject`. When the canonical directory exists again
  /// (the import had already completed) the stash is left untouched:
  /// recovery must not guess between two complete copies. Returns the
  /// number of restored packages.
  Future<int> recoverInterruptedImportStashes(Directory ownerDirectory) async {
    if (!await ownerDirectory.exists()) return 0;
    final stashes = <Directory>[];
    await for (final entity in ownerDirectory.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith('.') ||
          !name.contains('.voidproject.import-backup-')) {
        continue;
      }
      stashes.add(entity);
    }
    var restored = 0;
    for (final stash in stashes) {
      final manifestFile = File(p.join(stash.path, 'manifest', 'project.json'));
      if (!await manifestFile.exists()) continue;
      final Object? decoded;
      try {
        decoded = jsonDecode(await manifestFile.readAsString());
      } on Object {
        continue;
      }
      if (decoded is! Map<String, dynamic>) continue;
      final ProjectManifest manifest;
      try {
        manifest = ProjectManifest.fromJson(decoded);
      } on Object {
        continue;
      }
      final canonical = Directory(
        p.join(ownerDirectory.path, '${manifest.id}.voidproject'),
      );
      if (await canonical.exists()) continue;
      await stash.rename(canonical.path);
      restored++;
    }
    return restored;
  }
}
