import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/custom_storage_location.dart';
import '../../../core/persistence/project_paths.dart';
import '../../../core/persistence/project_registry_service.dart';
import '../../../core/project_package/project_package.dart';
import '../../project_resilience/application/project_session_manager.dart';
import '../data/project_local_data_source.dart';
import '../data/project_repository_impl.dart';

/// Custom storage location store backed by a JSON file next to the default
/// project registry root. The paths provider consults this store so an
/// activated custom location (C:/D:/USB) becomes the project home.
final customStorageStoreProvider = FutureProvider<CustomStorageLocationStore>((
  ref,
) async {
  final registryFile = await ProjectPaths().rootDirectoryFile(
    'storage_locations.json',
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
    state = const AsyncLoading();
    await _session?.close();
    final root = await ref.read(projectPathsProvider).project(projectId);
    final session = await _manager.open(
      ProjectPackage(projectId: projectId, root: root),
      mode: mode,
    );
    _session = session;
    state = AsyncData(session);
    return session;
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
    await _session?.close();
    _session = null;
    state = const AsyncData(null);
  }
}
