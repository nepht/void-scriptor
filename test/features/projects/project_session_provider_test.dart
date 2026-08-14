import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  test('current project provider owns open save close lifecycle', () async {
    final root = await Directory.systemTemp.createTemp('hermes-s24-provider-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Provider Project');
    final container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(
          ProjectPaths(rootDirectory: root),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(currentProjectSessionProvider.notifier);
    final session = await controller.open(package.projectId);
    expect(session.mode, ProjectOpenMode.readWrite);
    expect(
      container.read(currentProjectSessionProvider).value?.package.projectId,
      package.projectId,
    );
    await controller.save();
    await controller.closeProject();
    expect(container.read(currentProjectSessionProvider).value, isNull);
  });
}
