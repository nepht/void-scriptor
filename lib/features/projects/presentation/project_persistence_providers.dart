import 'package:flutter_riverpod/flutter_riverpod.dart';

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
