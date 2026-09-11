import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/project_model.dart';
import 'async_mutex.dart';
import 'project_recovery_service.dart';
import 'project_paths.dart';

/// The project registry at [registryPath] cannot be parsed into a usable
/// project list. [cause] is the underlying parse/type failure; the corrupt
/// file is preserved on disk for manual inspection.
class ProjectRegistryUnreadableException implements Exception {
  ProjectRegistryUnreadableException(this.registryPath, this.cause);

  final String registryPath;

  /// The underlying content failure (JSON syntax, registry shape, or the
  /// type error of a field-corrupt entry).
  final Object cause;

  @override
  String toString() =>
      'ProjectRegistryUnreadableException: registry at $registryPath '
      'is not a readable project registry ($cause)';
}

class ProjectRegistryService {
  ProjectRegistryService({Directory? rootDirectory, this.paths})
    : file = rootDirectory == null
          ? null
          : File('${rootDirectory.path}${Platform.pathSeparator}projects.json');

  final File? file;
  final ProjectPaths? paths;
  final ProjectRecoveryService _recovery = const ProjectRecoveryService();
  final AsyncMutex _mutex = AsyncMutex();

  Future<File> get _registryFile async {
    final configuredPaths = paths;
    final configuredFile = file;
    if (configuredPaths != null) return configuredPaths.registry();
    if (configuredFile != null) return configuredFile;
    throw StateError('ProjectRegistryService requires rootDirectory or paths');
  }

  Future<List<ProjectModel>> load() => _mutex.run(_loadUnlocked);

  /// Bug-hunt run197 BUG-19: tombstone file next to the registry recording
  /// project ids the user explicitly removed. `.bak` recovery restores the
  /// PRE-remove registry content, so without durable deletion intent an
  /// unrelated corruption/power-loss event silently resurrects removed
  /// projects. Written by [remove] BEFORE the registry rewrite, consulted
  /// only on backup-restored listings, and cleared whenever a persisted
  /// listing contains the id again (re-registering is a newer decision).
  static const String removedSuffix = '.removed.json';

  Future<File> _tombstoneFile() async =>
      File('${(await _registryFile).path}$removedSuffix');

  Future<Set<String>> _readTombstones(File tombstone) async {
    try {
      if (!await tombstone.exists()) return const {};
      final decoded = jsonDecode(await tombstone.readAsString());
      if (decoded is! List<dynamic>) return const {};
      return decoded.whereType<String>().toSet();
    } on Object {
      // The tombstone is best-effort hardening: a corrupt one must never
      // block project listing (same posture as marker consumption).
      return const {};
    }
  }

  Future<List<ProjectModel>> _loadUnlocked() async {
    final file = await _registryFile;
    // run197 BUG-19: a registry that materializes from `.bak` during the
    // power-loss roll-forward below carries the same stale-content risk as
    // a corrupt-registry restore, so both legs are backup-derived.
    final existedBeforeRecovery = await file.exists();
    // 145.42 power-loss window: pulihkan registry dari .bak sebelum
    // melaporkan daftar proyek kosong.
    await _recovery.recoverIfInterrupted(file);
    // 145.42 interrupted-import window: pulihkan package asli yang
    // terkubur di stash `.import-backup-*` sebelum daftar proyek
    // dilaporkan.
    await _recoverImportStashes();
    final (registered, restoredFromBackup) =
        await _decodeProjectsWithBackupRecovery(file);
    final isBackupDerived = restoredFromBackup || !existedBeforeRecovery;
    if (isBackupDerived) {
      // run197 BUG-19: content that came from `.bak` may predate an
      // explicit removal. Filter it against durable deletion intent and
      // persist the filtered (healed) listing so the decision sticks.
      final removed = await _readTombstones(await _tombstoneFile());
      if (removed.isNotEmpty) {
        final filtered = registered
            .where((project) => !removed.contains(project.id))
            .toList();
        if (filtered.length != registered.length) {
          await _saveUnlocked(filtered);
          return filtered;
        }
      }
    }
    // 145.42 interrupted-move window: consume move journals that
    // landed inside this listing root before the marker delete ran.
    await _consumeLandedMoveMarkers(registered);
    // 145.42 crash window: a finished package whose registry entry never
    // landed (process kill / power loss between create() and upsert) is
    // admitted so a complete project never becomes invisible. Only an
    // explicit creation marker admits; folders without one are
    // deliberately unregistered state and are never touched.
    final knownIds = registered.map((project) => project.id).toSet();
    final admitted = <ProjectModel>[];
    for (final owner in await _ownerDirectories()) {
      admitted.addAll(await _recovery.admitMarkedCreations(owner, knownIds));
    }
    if (admitted.isEmpty) return registered;
    final merged = [...registered, ...admitted];
    // Durability first: persist the admission, then consume the markers.
    // A crash in between leaves the marker in place, but the id is now
    // registered so the next load consumes it without duplicating.
    await _saveUnlocked(merged);
    for (final project in admitted) {
      // bug-hunt run197 BUG-1: marker consumption is best-effort. The
      // admission is already durable; a transient fresh-file delete
      // failure (errno 32/5) must not throw the listing. A stale marker
      // is harmless: the id is registered, so the next load consumes it
      // without duplicating.
      await _recovery.consumeCreationMarkerQuietly(
        File(
          p.join(project.localPath, ProjectRecoveryService.creationMarkerName),
        ),
      );
    }
    return merged;
  }

  /// Bug-hunt run94 BUG-04: corrupt registry CONTENT is not a power-loss
  /// window ([ProjectRecoveryService.recoverIfInterrupted] only handles a
  /// MISSING target). The last durable copy in `.bak` is restored to the
  /// target before the failure is reported; without a `.bak` the corrupt
  /// file is preserved for inspection and the typed unreadable exception
  /// propagates (remove()/upsert() compose on this, so they fail loudly
  /// instead of silently diverging registry from disk).
  ///
  /// Returns whether the listing was restored from the `.bak` copy. That
  /// content may predate explicit removals (run197 BUG-19), so callers
  /// reconcile it against deletion tombstones.
  Future<(List<ProjectModel>, bool)> _decodeProjectsWithBackupRecovery(
    File file,
  ) async {
    try {
      return (await _decodeProjects(file), false);
    } on ProjectRegistryUnreadableException {
      final restored = await _recovery.restoreBackup(file);
      if (!restored) rethrow;
      return (await _decodeProjects(file), true);
    }
  }

  /// Corrupt content (unparsable JSON, wrong shape, field-level type
  /// failures) is reported as [ProjectRegistryUnreadableException]. Two
  /// deliberate non-corruption contracts are preserved raw:
  /// 1. file-level I/O failures (missing/unreadable registry) propagate as
  ///    FileSystemException, exactly as before this slice;
  /// 2. an interpretable registry whose schema is newer than 1 keeps the
  ///    raw FormatException compatibility rejection (an app-update artifact
  ///    is an actionable "upgrade required" signal, not corruption).
  Future<List<ProjectModel>> _decodeProjects(File registryFile) async {
    if (!await registryFile.exists()) return const [];
    final Object decoded;
    try {
      decoded = jsonDecode(await registryFile.readAsString());
    } on FileSystemException {
      rethrow;
    } on Object catch (cause) {
      throw ProjectRegistryUnreadableException(registryFile.path, cause);
    }
    if (decoded is! Map<String, dynamic>) {
      throw ProjectRegistryUnreadableException(
        registryFile.path,
        const FormatException('Project registry must be a JSON object'),
      );
    }
    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion != 1) {
      // Compatibility rejection stays raw: an app-update artifact is an
      // actionable "upgrade required" signal, not corruption.
      throw FormatException(
        'Unsupported project registry schema version: $schemaVersion',
      );
    }
    final List<dynamic> entries;
    try {
      entries = decoded['projects'] as List<dynamic>? ?? const [];
    } on Object catch (cause) {
      throw ProjectRegistryUnreadableException(registryFile.path, cause);
    }
    try {
      return entries
          .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on Object catch (cause) {
      throw ProjectRegistryUnreadableException(registryFile.path, cause);
    }
  }

  /// Bug-hunt run94 BUG-16: admission and stash recovery must iterate the
  /// SAME owner-directory set. The rootDirectory (file-branch) wiring
  /// scans the registry directory plus its legacy `Projects`
  /// subdirectory, so a creation-marked package one level down is found
  /// by stash recovery but was never admitted.
  Future<List<Directory>> _ownerDirectories() async {
    final configuredPaths = paths;
    if (configuredPaths != null) return [await configuredPaths.root()];
    final configuredFile = file;
    if (configuredFile != null) {
      return [
        configuredFile.parent,
        Directory(p.join(configuredFile.parent.path, 'Projects')),
      ];
    }
    throw StateError('ProjectRegistryService requires rootDirectory or paths');
  }

  Future<void> save(List<ProjectModel> projects) =>
      _mutex.run(() => _saveUnlocked(projects));

  Future<void> _saveUnlocked(List<ProjectModel> projects) async {
    final file = await _registryFile;
    await file.parent.create(recursive: true);
    final json = {
      'schemaVersion': 1,
      'projects': projects.map((project) => project.toJson()).toList(),
    };
    await _recovery.atomicWrite(
      target: file,
      content: '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );
    // run197 BUG-19: a persisted listing that still contains a previously
    // removed id supersedes the deletion intent (re-creating under the same
    // id is a newer decision). Best-effort: a stale tombstone only filters
    // future backup-restored listings, never the live one.
    final tombstone = await _tombstoneFile();
    if (await tombstone.exists()) {
      try {
        final removed = await _readTombstones(tombstone);
        final stillPresent = projects.map((project) => project.id).toSet();
        final remaining = removed.difference(stillPresent).toList()..sort();
        if (remaining.isEmpty) {
          await tombstone.delete();
        } else if (remaining.length != removed.length) {
          await tombstone.writeAsString(
            '${const JsonEncoder.withIndent('  ').convert(remaining)}\n',
            flush: true,
          );
        }
      } on FileSystemException {
        // Keep the stale tombstone rather than throwing from a save.
      }
    }
  }

  Future<void> upsert(ProjectModel project) => _mutex.run(() async {
    final projects = [...await _loadUnlocked()];
    final index = projects.indexWhere((item) => item.id == project.id);
    if (index == -1) {
      projects.add(project);
    } else {
      projects[index] = project;
    }
    await _saveUnlocked(projects);
    // The crash window (package finished, registration pending) closes
    // here: only after the registration is durable is the creation
    // marker consumed. A crash before the save leaves the marker for
    // the next load to admit and consume.
    // bug-hunt run197 BUG-1 (Critical): consumption must be best-effort.
    // The registration above is durable; a transient fresh-file delete
    // failure (errno 32/5) used to propagate into
    // ProjectController.createProject's catch, which deleted the COMPLETE
    // package while the registry entry dangled. A stale marker is
    // harmless (admitMarkedCreations treats known ids as registered) and
    // is retried by the next load.
    await _recovery.consumeCreationMarkerQuietly(
      File(
        p.join(project.localPath, ProjectRecoveryService.creationMarkerName),
      ),
    );
  });

  /// Removes [projectId] from the registry.
  ///
  /// run197 BUG-19: deletion intent is recorded durably BEFORE the registry
  /// rewrite. `atomicWrite` archives the PRE-remove content as `.bak`, and
  /// backup recovery restores that copy verbatim; without the tombstone a
  /// later corruption/power-loss event would silently resurrect the removed
  /// project. Tombstone write failure aborts the removal loudly (the user's
  /// decision must be representable before the registry forgets it).
  Future<void> remove(String projectId) => _mutex.run(() async {
    final tombstone = await _tombstoneFile();
    final removed = (await _readTombstones(tombstone)).toList()..sort();
    if (!removed.contains(projectId)) removed.add(projectId);
    await tombstone.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(removed)}\n',
      flush: true,
    );
    try {
      await _saveUnlocked(
        (await _loadUnlocked()).where((item) => item.id != projectId).toList(),
      );
    } on Object {
      // The registry rewrite failed loudly; do not leave a tombstone that
      // hides a project the registry still lists. The compensation itself
      // is best-effort: the ORIGINAL failure must always propagate.
      try {
        final stillListed = (await _loadUnlocked())
            .map((item) => item.id)
            .toSet();
        if (stillListed.contains(projectId)) {
          final remaining = (await _readTombstones(tombstone)).toList()
            ..remove(projectId)
            ..sort();
          await tombstone.writeAsString(
            '${const JsonEncoder.withIndent('  ').convert(remaining)}\n',
            flush: true,
          );
        }
      } on Object {
        // Cannot prove the registry still lists the id; keep the tombstone
        // (it only ever filters backup-restored listings, never the live
        // decode) and surface the original failure below.
      }
      rethrow;
    }
  });

  /// Best-effort consumption of landed move journals (145.42): a
  /// `move-pending.marker` inside the directory of a registered
  /// project means its move completed but the marker delete never
  /// ran. The marker is stale state; consuming it must never block
  /// project listing.
  Future<void> _consumeLandedMoveMarkers(List<ProjectModel> projects) async {
    for (final project in projects) {
      final marker = File(
        p.join(project.localPath, ProjectRecoveryService.movePendingMarkerName),
      );
      try {
        if (await marker.exists()) await marker.delete();
      } on FileSystemException {
        continue;
      }
    }
  }

  /// Best-effort recovery of interrupted-import stashes. Only
  /// [FileSystemException] is swallowed so an unavailable storage root
  /// never blocks listing projects; programming errors still surface.
  Future<void> _recoverImportStashes() async {
    for (final owner in await _ownerDirectories()) {
      try {
        await _recovery.recoverInterruptedImportStashes(owner);
      } on FileSystemException {
        continue;
      }
    }
  }
}
