import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/project_open_service.dart';
import '../../../core/persistence/project_paths.dart';
import '../../../core/persistence/project_registry_service.dart';
import '../data/project_local_data_source.dart';
import '../data/project_repository_impl.dart';

final projectPathsProvider = Provider<ProjectPaths>((ref) => ProjectPaths());

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
    AsyncNotifierProvider<ProjectSessionController, OpenProject?>(
      ProjectSessionController.new,
    );

class ProjectSessionController extends AsyncNotifier<OpenProject?> {
  OpenProject? _opened;

  @override
  Future<OpenProject?> build() async {
    ref.onDispose(() {
      _opened?.database.close();
      _opened = null;
    });
    return null;
  }

  Future<OpenProject> openProject(String projectId) async {
    state = const AsyncLoading();
    await _opened?.close();
    final opened = await ProjectOpenService(
      paths: ref.read(projectPathsProvider),
    ).open(projectId);
    _opened = opened;
    state = AsyncData(opened);
    return opened;
  }

  Future<void> closeProject() async {
    await _opened?.close();
    _opened = null;
    state = const AsyncData(null);
  }
}
