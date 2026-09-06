import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  test('locked project publishes error instead of remaining loading', () async {
    final root = await Directory.systemTemp.createTemp('void-open-error-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Locked');
    await package.sessionFile.writeAsString('existing-session');
    final container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(
          ProjectPaths(rootDirectory: root),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(projectSessionProvider.future);
    await expectLater(
      container
          .read(projectSessionProvider.notifier)
          .openProject(package.projectId),
      throwsStateError,
    );
    expect(container.read(projectSessionProvider).hasError, isTrue);
    expect(container.read(projectSessionProvider).isLoading, isFalse);
    expect(await package.sessionFile.readAsString(), 'existing-session');
    // Simulate an explicit recovery on disposable test data, never auto-unlock.
    await package.sessionFile.delete();
    final controller = container.read(projectSessionProvider.notifier);
    await controller.openProject(package.projectId);
    expect(container.read(projectSessionProvider).hasError, isFalse);
    await controller.closeProject();
  });

  test('reopening active project reuses its session', () async {
    final root = await Directory.systemTemp.createTemp('void-open-repeat-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Repeat');
    final container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(
          ProjectPaths(rootDirectory: root),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(projectSessionProvider.future);
    final controller = container.read(projectSessionProvider.notifier);
    final first = await controller.openProject(package.projectId);
    final second = await controller.openProject(package.projectId);
    await controller.closeProject();
    expect(identical(first, second), isTrue);
  });

  test('simultaneous opens of the same project share one session', () async {
    final root = await Directory.systemTemp.createTemp('void-open-concurrent-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Concurrent');
    final container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(
          ProjectPaths(rootDirectory: root),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(projectSessionProvider.future);
    final controller = container.read(projectSessionProvider.notifier);
    final sessions = await Future.wait([
      controller.openProject(package.projectId),
      controller.openProject(package.projectId),
    ]);
    await controller.closeProject();
    expect(identical(sessions[0], sessions[1]), isTrue);
  });
}
