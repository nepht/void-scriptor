import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/features/platform/domain/platform_capability.dart';
import 'package:void_scriptor/features/platform/platform_capability_providers.dart';
import 'package:void_scriptor/features/projects/data/project_local_data_source.dart';
import 'package:void_scriptor/features/projects/data/project_repository_impl.dart';
import 'package:void_scriptor/features/projects/presentation/project_controller.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

ProviderContainer _container(Directory root, {required bool isWeb}) {
  final paths = ProjectPaths(rootDirectory: root);
  return ProviderContainer(
    overrides: [
      projectPathsProvider.overrideWithValue(paths),
      projectRegistryServiceProvider.overrideWithValue(
        ProjectRegistryService(paths: paths),
      ),
      projectLocalDataSourceProvider.overrideWithValue(
        ProjectLocalDataSource(registry: ProjectRegistryService(paths: paths)),
      ),
      projectRepositoryProvider.overrideWith(
        (ref) =>
            ProjectRepositoryImpl(ref.watch(projectLocalDataSourceProvider)),
      ),
      platformCapabilitiesProvider.overrideWithValue(
        resolvePlatformCapabilities(isWeb: isWeb),
      ),
    ],
  );
}

void main() {
  test('createProject refuses on Web with an actionable typed error', () async {
    final root = await Directory.systemTemp.createTemp('ws-web-guard-');
    addTearDown(() => root.delete(recursive: true));

    final container = _container(root, isWeb: true);
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(projectControllerProvider.notifier)
          .createProject(name: 'Web Attempt', description: '', localPath: ''),
      throwsA(
        isA<UnsupportedPlatformCapabilityError>().having(
          (e) => e.message,
          'message',
          allOf(contains('Membuat proyek baru'), contains('Web')),
        ),
      ),
    );

    // No package directory may be created on web.
    final created = root
        .listSync(recursive: true)
        .whereType<Directory>()
        .where((d) => d.path != root.path)
        .toList();
    expect(created, isEmpty, reason: 'web tidak boleh membuat paket proyek');
  });

  test(
    'createProject still works on native with explicit capabilities',
    () async {
      final root = await Directory.systemTemp.createTemp('ws-native-guard-');
      addTearDown(() => root.delete(recursive: true));

      final container = _container(root, isWeb: false);
      addTearDown(container.dispose);

      final project = await container
          .read(projectControllerProvider.notifier)
          .createProject(name: 'Native OK', description: '', localPath: '');
      expect(project.id, isNotEmpty);
      expect(Directory(project.localPath).existsSync(), isTrue);
    },
  );
}
