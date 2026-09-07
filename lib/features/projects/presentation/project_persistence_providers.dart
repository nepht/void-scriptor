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
  final store = ref.watch(customStorageStoreProvider).valueOrNull;
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
        if (session.mode == mode) return session;
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
    if (active?.package.projectId == projectId && active?.mode == mode) {
      return active!;
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

  Future<ProjectSession> _openProject(
    String projectId,
    ProjectOpenMode mode,
  ) async {
    _releaseForeignSelection(projectId);
    state = const AsyncLoading();
    try {
      await _session?.close();
      _session = null;
      final root = await ref.read(projectPathsProvider).project(projectId);
      final session = await _manager.open(
        ProjectPackage(projectId: projectId, root: root),
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
