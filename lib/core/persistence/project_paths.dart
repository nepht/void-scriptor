import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'custom_storage_location.dart';

/// Why [ProjectPaths.root] fell back away from the configured custom
/// storage location (core-hunt-20260906 BUG-12).
enum StorageFallbackReason { missingDrive, degraded }

/// Typed signal emitted when the effective project root differs from the
/// configured custom storage location. The fallback itself is a codified
/// contract (wiring tests); this makes it observable instead of silent.
class StorageFallbackNotice {
  const StorageFallbackNotice({
    required this.reason,
    required this.requestedLocation,
    required this.effectiveRoot,
  });

  final StorageFallbackReason reason;
  final String? requestedLocation;
  final Directory effectiveRoot;
}

final class ProjectPaths {
  ProjectPaths({
    Directory? rootDirectory,
    Future<String> Function()? documentsPath,
    Future<String?> Function()? supportPath,
    CustomStorageLocationStore? customStorageStore,
    Directory? fallbackRootDirectory,
  }) : _rootOverride = rootDirectory,
       _documentsPathOverride = documentsPath,
       _supportPathOverride = supportPath,
       _storageStore = customStorageStore,
       _fallbackRoot = fallbackRootDirectory;

  final Directory? _rootOverride;
  final Future<String> Function()? _documentsPathOverride;
  final Future<String?> Function()? _supportPathOverride;
  final CustomStorageLocationStore? _storageStore;
  final Directory? _fallbackRoot;

  /// core-hunt-20260906 BUG-12: the missingDrive→Documents fallback is a
  /// codified contract, but it used to be silent. This exposes the most
  /// recent fallback away from the configured custom storage location so
  /// consumers (status bar / settings surface) can surface a visible
  /// warning: "projects are currently written to <fallback> because the
  /// configured drive is missing". Cleared whenever a subsequent [root]
  /// call uses the configured location, and null when no custom store is
  /// configured at all.
  StorageFallbackNotice? lastFallbackNotice;

  /// Exposes the effective custom storage root (healthy active location) or
  /// null when no custom location is configured. Used by wiring tests and the
  /// settings surface to show the active storage home.
  String? get rootOverride {
    final store = _storageStore;
    if (store == null) return null;
    final state = store.cachedState;
    if (state == null) return null;
    if (state.status != StorageLocationStatus.healthy) return null;
    return state.activeLocation;
  }

  Future<Directory> root() async {
    final override = _rootOverride;
    if (override != null) {
      await override.create(recursive: true);
      return override;
    }

    final store = _storageStore;
    if (store != null) {
      final state = await store.load();
      final active = state.activeLocation;
      if (active != null && state.status == StorageLocationStatus.healthy) {
        final custom = Directory(active);
        await custom.create(recursive: true);
        lastFallbackNotice = null;
        return custom;
      }
      // core-hunt-20260906 BUG-12: the fallback is intentional (codified
      // wiring contract) but must not be silent. Record a typed notice for
      // consumers; the status surface can show a visible warning.
      lastFallbackNotice = StorageFallbackNotice(
        reason: StorageFallbackReason.missingDrive,
        requestedLocation: active,
        effectiveRoot:
            _fallbackRoot ??
            Directory(
              p.join(await _documentsPath(), 'VoidScriptor', 'Projects'),
            ),
      );
    }

    final fallback = _fallbackRoot;
    if (fallback != null) {
      await fallback.create(recursive: true);
      return fallback;
    }

    final candidates = <String?>[
      await _documentsPath(),
      await _supportPath(),
      p.join(Directory.systemTemp.path, 'VoidScriptor', 'Projects'),
    ];
    Object? lastError;
    for (final candidate in candidates) {
      if (candidate == null || candidate.isEmpty) continue;
      final directory = Directory(
        p.join(candidate, 'VoidScriptor', 'Projects'),
      );
      try {
        await directory.create(recursive: true);
        return directory;
      } on FileSystemException catch (error) {
        lastError = error;
      }
    }
    throw StateError('Unable to create a writable project root: $lastError');
  }

  Future<String> _documentsPath() async {
    final override = _documentsPathOverride;
    if (override != null) return override();
    try {
      return (await getApplicationDocumentsDirectory()).path;
    } catch (_) {
      return '';
    }
  }

  Future<String?> _supportPath() async {
    final override = _supportPathOverride;
    if (override != null) return override();
    try {
      return (await getApplicationSupportDirectory()).path;
    } catch (_) {
      return null;
    }
  }

  Future<Directory> project(String projectId) async =>
      Directory(p.join((await root()).path, '$projectId.voidproject'));

  /// Host file next to the effective root: beside the custom storage
  /// location when active, otherwise beside the default Projects folder.
  /// Used for machine-local wiring records such as storage_locations.json.
  Future<File> rootDirectoryFile(String fileName) async {
    final store = _storageStore;
    if (store != null) {
      final state = await store.load();
      final active = state.activeLocation;
      if (active != null && state.status == StorageLocationStatus.healthy) {
        return File(p.join(active, fileName));
      }
    }
    final override = _rootOverride;
    if (override != null) {
      return File(p.join(override.path, fileName));
    }
    return File(p.join((await root()).parent.path, fileName));
  }

  Future<File> manifest(String projectId) async =>
      File(p.join((await project(projectId)).path, 'manifest', 'project.json'));

  Future<File> database(String projectId) async =>
      File(p.join((await project(projectId)).path, 'database', 'project.db'));

  Future<File> registry() async => File(
    p.join(
      _rootOverride == null ? (await root()).parent.path : (await root()).path,
      'projects.json',
    ),
  );
}
