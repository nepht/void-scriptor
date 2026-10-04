import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/persistence/custom_storage_location.dart';
import '../../../core/persistence/project_paths.dart';
import '../../../core/persistence/project_registry_service.dart';
import '../../../core/persistence/storage_location_registry_resolver.dart';
import '../../../core/project_package/project_package.dart';
import '../../project_resilience/application/project_session_manager.dart';
import '../../../core/selection/selection_controller.dart';
import '../data/project_local_data_source.dart';
import '../data/project_repository_impl.dart';

/// Custom storage location store backed by a JSON file next to the default
/// project registry root. The paths provider consults this store so an
/// activated custom location (C:/D:/USB) becomes the project home.
final customStorageStoreProvider = FutureProvider<CustomStorageLocationStore>((
  ref,
) async {
  final legacyFile = await ProjectPaths().rootDirectoryFile(
    StorageLocationRegistryResolver.fileName,
  );
  final registryFile = await const StorageLocationRegistryResolver().resolve(
    applicationSupportDirectory: await getApplicationSupportDirectory(),
    legacyFile: legacyFile,
  );
  return CustomStorageLocationStore(registryFile: registryFile);
});

final projectPathsProvider = Provider<ProjectPaths>((ref) {
  final store = ref.watch(customStorageStoreProvider).value;
  return ProjectPaths(customStorageStore: store);
});

final projectRegistryServiceProvider = Provider<ProjectRegistryService>(
  (ref) => ProjectRegistryService(paths: ref.watch(projectPathsProvider)),
);

final projectLocalDataSourceProvider = Provider<ProjectLocalDataSource>(
  (ref) => ProjectLocalDataSource(
    registry: ref.watch(projectRegistryServiceProvider),
  ),
);

final projectRepositoryProvider = Provider<ProjectRepositoryImpl>(
  (ref) => ProjectRepositoryImpl(ref.watch(projectLocalDataSourceProvider)),
);

final projectSessionProvider =
    AsyncNotifierProvider<ProjectSessionController, ProjectSession?>(
      ProjectSessionController.new,
    );

final currentProjectSessionProvider = projectSessionProvider;

/// Stable project identity of the ACTIVE session, null when detached
/// (dashboard). The Inspector cross-project guard compares the selection's
/// projectId against this value instead of holding a full session.
final currentProjectIdProvider = Provider<String?>((ref) {
  return ref.watch(projectSessionProvider).value?.manifest.id;
});

class ProjectSessionController extends AsyncNotifier<ProjectSession?> {
  ProjectSession? _session;
  Future<ProjectSession>? _pendingOpen;
  String? _pendingProjectId;
  final ProjectSessionManager _manager = ProjectSessionManager();

  @override
  Future<ProjectSession?> build() async {
    ref.onDispose(() {
      final session = _session;
      if (session != null) {
        session.close();
      }
    });
    return null;
  }

  Future<ProjectSession> openProject(
    String projectId, {
    ProjectOpenMode mode = ProjectOpenMode.readWrite,
  }) async {
    final pending = _pendingOpen;
    if (pending != null) {
      if (_pendingProjectId == projectId) {
        final session = await pending;
        if (_modeSatisfies(sessionMode: session.mode, requestedMode: mode)) {
          return session;
        }
      } else {
        // Serialize project switches; never open two writers concurrently.
        try {
          await pending;
        } catch (_) {
          /* The caller receives its error. */
        }
      }
      return openProject(projectId, mode: mode);
    }
    final active = _session;
    // vs-hunt-20260913-projects BUG-2: a live readWrite session already
    // satisfies a readOnly request. Re-opening to "downgrade" the mode would
    // close the database out from under the readWrite caller, so the mode
    // check is a superset test, not an equality test.
    if (active != null &&
        active.package.projectId == projectId &&
        _modeSatisfies(sessionMode: active.mode, requestedMode: mode)) {
      return active;
    }
    _pendingProjectId = projectId;
    final operation = _openProject(projectId, mode);
    _pendingOpen = operation;
    try {
      return await operation;
    } finally {
      _pendingOpen = null;
      _pendingProjectId = null;
    }
  }

  /// vs-hunt-20260911 BUG-2 (High): the package root is resolved from the
  /// registry entry's localPath first, because a package can live anywhere
  /// after "Move Project..." (Task 3). The root join is only the fallback
  /// for projects without a registry entry (first-open-before-listing).
  Future<String> resolvePackageRoot(String projectId) async {
    try {
      final registry = ref.read(projectRegistryServiceProvider);
      final entries = await registry.load();
      for (final entry in entries) {
        if (entry.id == projectId && entry.localPath.isNotEmpty) {
          return entry.localPath;
        }
      }
    } catch (_) {
      // Registry unavailable (fresh profile, locked file): fall through to
      // the conventional root join instead of failing the open outright.
    }
    return (await ref.read(projectPathsProvider).project(projectId)).path;
  }

  Future<ProjectSession> _openProject(
    String projectId,
    ProjectOpenMode mode,
  ) async {
    _releaseForeignSelection(projectId);
    state = const AsyncLoading();
    try {
      await _session?.close();
      _session = null;
      // vs-hunt-20260911 BUG-2: resolve via registry localPath (moved
      // packages live outside the conventional root) with root-join
      // fallback.
      final rootPath = await resolvePackageRoot(projectId);
      final session = await _manager.open(
        ProjectPackage(projectId: projectId, root: Directory(rootPath)),
        mode: mode,
      );
      _session = session;
      state = AsyncData(session);
      return session;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      rethrow;
    }
  }

  Future<ProjectSession> open(
    String projectId, {
    ProjectOpenMode mode = ProjectOpenMode.readWrite,
  }) => openProject(projectId, mode: mode);

  /// A readWrite session is a superset of readOnly: it can serve reads
  /// without a destructive close/re-open cycle. The reverse never holds —
  /// write access always requires a fresh readWrite open.
  static bool _modeSatisfies({
    required ProjectOpenMode sessionMode,
    required ProjectOpenMode requestedMode,
  }) {
    if (sessionMode == requestedMode) return true;
    return sessionMode == ProjectOpenMode.readWrite &&
        requestedMode == ProjectOpenMode.readOnly;
  }

  /// Wiring sprint Task 2 (BUG-12): passphrase prompt-and-retry contract.
  /// Verifies the passphrase through [ProjectSessionManager.unlockProject]
  /// and, on success, re-runs [openProject] (which re-checks the persisted
  /// lock and now passes). Returns false on a wrong passphrase so the shell
  /// can keep the prompt up with an inline error; open failures propagate.
  Future<bool> unlockAndOpen(String projectId, String passphrase) async {
    // vs-hunt-20260911 BUG-2: same registry-first resolution as the open
    // path so the probe reaches the real (possibly moved) database.
    final rootPath = await resolvePackageRoot(projectId);
    final unlocked = await _manager.unlockProject(
      ProjectPackage(projectId: projectId, root: Directory(rootPath)),
      passphrase,
    );
    if (!unlocked) return false;
    await openProject(projectId);
    return true;
  }

  Future<void> save() async {
    final session = _session;
    if (session == null) return;
    await session.save();
    state = AsyncData(session);
  }

  Future<void> closeProject() async {
    final pending = _pendingOpen;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {
        /* Failed opens have no session. */
      }
    }
    await _session?.close();
    _session = null;
    ref.read(selectionProvider.notifier).clear();
    state = const AsyncData(null);
  }

  /// A selection created under a different project (or without a project)
  /// cannot be resolved against the newly opened database: releasing it
  /// prevents the Inspector from rendering a foreign asset id (observed as
  /// a stale character UUID after switching projects during 145.44).
  void _releaseForeignSelection(String projectId) {
    final selection = ref.read(selectionProvider);
    if (selection != null && selection.projectId != projectId) {
      ref.read(selectionProvider.notifier).clear();
    }
  }
}
