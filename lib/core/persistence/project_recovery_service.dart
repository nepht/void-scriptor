import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'async_mutex.dart';
import '../project_package/project_package.dart';

import 'project_manifest.dart';
import '../domain/project_model.dart';

/// Outcome accumulator for
/// [ProjectRecoveryService.recoverInterruptedMovesInto] (bug-hunt run197
/// BUG-7). The registry drives one sink per load and uses it to (a) repoint
/// registered entries whose package was rolled forward, (b) admit packages
/// that landed without their registry entry, and (c) spare journals the
/// scan deliberately left in place from the landed-marker consumption.
/// Path comparisons are canonicalized (case-insensitive on Windows) so a
/// drive-letter case difference cannot disarm the skip logic.
final class ProjectMoveRecoverySink {
  final List<({String id, Directory package})> _rolled = [];
  final Set<String> _rolledSources = {};
  final Set<String> _untouchedSources = {};
  final List<File> _travelledMarkers = [];

  void addRolled(String id, Directory destination, String sourcePath) {
    _rolled.add((id: id, package: destination));
    _rolledSources.add(p.canonicalize(sourcePath));
    // The marker travelled with the package into the destination. It is
    // NOT consumed here: durability first (the run197 BUG-1 rule) — the
    // journal must survive until the rolled-forward listing is durable,
    // or a crash in between leaves a moved package with no journal and no
    // registry entry (invisible forever). Callers drain explicitly.
    _travelledMarkers.add(
      File(
        p.join(destination.path, ProjectRecoveryService.movePendingMarkerName),
      ),
    );
  }

  void addUntouchedJournal(String sourcePath) =>
      _untouchedSources.add(p.canonicalize(sourcePath));

  bool hasUntouchedJournalAt(String packagePath) =>
      _untouchedSources.contains(p.canonicalize(packagePath));

  List<({String id, Directory package})> get rolled =>
      List.unmodifiable(_rolled);

  /// Consumes the travelled journals best-effort. The direct
  /// [ProjectRecoveryService.recoverInterruptedMoves] wrapper drains right
  /// after its scan completes (its documented contract); the registry
  /// drains only after the healed listing is persisted.
  Future<void> consumeTravelledMarkers(ProjectRecoveryService recovery) async {
    for (final marker in _travelledMarkers) {
      await recovery.consumeMoveMarkerQuietly(marker);
    }
    _travelledMarkers.clear();
  }
}

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
  ///
  /// Bug-hunt core-hunt-20260906 BUG-6: the marker is staged BEFORE the
  /// database and manifest are written, so a crash mid-creation leaves a
  /// marker-only (or db-only) folder. Admission therefore also requires
  /// package completeness: manifest file, database file, and an on-disk
  /// manifest whose projectId agrees with the folder name. Incomplete
  /// packages are skipped untouched for manual inspection, like corrupt
  /// markers.
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
      } on Object {
        // Bug-hunt core-hunt-20260906 BUG-02: a syntactically valid
        // marker whose manifest is type-corrupt throws TypeError, not
        // FormatException; letting it escape aborted the whole admission
        // scan for every sibling package. Corrupt markers are skipped
        // and left on disk for manual inspection, like every other
        // corrupt-marker path in this class.
        continue;
      }
      final id = name.substring(0, name.length - '.voidproject'.length);
      if (id != manifest.id) continue;
      // BUG-6: require package completeness before admission. The marker
      // is staged before the database and manifest are written, so its
      // presence alone does not prove the package finished assembling.
      final package = ProjectPackage(projectId: id, root: entity);
      if (!await package.manifestFile.exists()) continue;
      if (!await package.databaseFile.exists()) continue;
      String diskManifestJson;
      try {
        diskManifestJson = await package.manifestFile.readAsString();
      } on FileSystemException {
        continue;
      }
      Object? diskManifestDecoded;
      try {
        diskManifestDecoded = jsonDecode(diskManifestJson);
      } on Object {
        continue;
      }
      if (diskManifestDecoded is! Map<String, dynamic>) continue;
      final diskProjectId = diskManifestDecoded['projectId'];
      if (diskProjectId is! String || diskProjectId != id) continue;
      if (knownProjectIds.contains(id)) {
        await consumeCreationMarkerQuietly(marker);
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

  /// Best-effort consumption (bug-hunt run197 BUG-1): a transient
  /// fresh-file delete failure (errno 32/5) must never propagate once
  /// registry membership is durable. A stale marker is harmless —
  /// admitMarkedCreations treats known ids as registered — and the next
  /// load retries the delete.
  Future<void> consumeCreationMarkerQuietly(File marker) async {
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
    final sink = ProjectMoveRecoverySink();
    await recoverInterruptedMovesInto(sourceRoot, sink);
    // Direct callers (and the 145.42 interrupted-move contract) treat a
    // completed scan as the end of recovery: drain the travelled journals
    // now. The registry path drains only after the healed listing is
    // durable instead.
    await sink.consumeTravelledMarkers(this);
    return sink.rolled.length;
  }

  /// Same scan as [recoverInterruptedMoves], reporting each rolled-forward
  /// package (project id + destination) instead of only a count, so the
  /// registry can repoint its entries and admit packages that landed
  /// without their registry entry (bug-hunt run197 BUG-7: the roll-forward
  /// half of the move contract must be wired where the landed-marker half
  /// already runs).
  Future<void> recoverInterruptedMovesInto(
    Directory sourceRoot,
    ProjectMoveRecoverySink sink,
  ) async {
    if (!await sourceRoot.exists()) return;
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
        sink.addUntouchedJournal(entity.path);
        continue;
      }
      try {
        await entity.rename(destination);
      } on FileSystemException {
        continue;
      }
      final markerProjectId = decoded['projectId'];
      final id = markerProjectId is String && markerProjectId.isNotEmpty
          ? markerProjectId
          : p
                .basename(destination)
                .substring(
                  0,
                  p.basename(destination).length -
                      (p.basename(destination).endsWith('.voidproject')
                          ? '.voidproject'.length
                          : 0),
                );
      sink.addRolled(id, target, entity.path);
    }
  }

  /// Consumes a stale landed move marker best-effort: the registry's
  /// durability-first rule for creation markers applies here too
  /// (bug-hunt run197 BUG-1 pattern) — a transient fresh-file delete
  /// failure (errno 32/5) must never throw the recovery scan; a stale
  /// marker is harmless because the registry consumes it on next load.
  Future<void> consumeMoveMarkerQuietly(File marker) async {
    try {
      if (await marker.exists()) await marker.delete();
    } on FileSystemException {
      // Best effort: the registry load also consumes landed markers.
    }
  }

  /// Admits a rolled-forward move package after the same completeness
  /// gate as [admitMarkedCreations]: the on-disk manifest must exist and
  /// agree with the package folder identity, and the database file must
  /// exist — a partial package rolled forward from a journal is never
  /// surfaced (identity is never taken from the journal payload).
  ///
  /// Returns the admitted [ProjectModel], or null when the package fails
  /// the gate (left in place for inspection).
  Future<ProjectModel?> admitMarkedMovePackage(
    Directory destination,
    String id,
  ) async {
    final folderId = _projectIdFromFolder(p.basename(destination.path));
    if (folderId == null || folderId != id) return null;
    final package = ProjectPackage(projectId: folderId, root: destination);
    if (!await package.manifestFile.exists()) return null;
    if (!await package.databaseFile.exists()) return null;
    String diskManifestJson;
    try {
      diskManifestJson = await package.manifestFile.readAsString();
    } on FileSystemException {
      return null;
    }
    Object? diskManifestDecoded;
    try {
      diskManifestDecoded = jsonDecode(diskManifestJson);
    } on Object {
      return null;
    }
    if (diskManifestDecoded is! Map<String, dynamic>) return null;
    final diskProjectId = diskManifestDecoded['projectId'];
    if (diskProjectId is! String || diskProjectId != folderId) return null;
    ProjectManifest manifest;
    try {
      manifest = ProjectManifest.fromJson(diskManifestDecoded);
    } on Object {
      return null;
    }
    final now = DateTime.now().toUtc();
    return ProjectModel(
      id: folderId,
      name: manifest.name,
      description: manifest.description,
      createdAt: manifest.createdAt,
      updatedAt: now,
      lastOpenedAt: now,
      localPath: destination.path,
      version: manifest.projectVersion,
    );
  }

  /// The project id encoded in a `<projectId>.voidproject` folder name, or
  /// null when the name is not a package folder.
  static String? _projectIdFromFolder(String name) =>
      name.endsWith('.voidproject')
      ? name.substring(0, name.length - '.voidproject'.length)
      : null;

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
