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

  test(
    'a readWrite session satisfies a readOnly request instead of re-opening under its owner',
    () async {
      // vs-hunt-20260913-projects BUG-2 (Medium): before the fix a readOnly
      // request against a live readWrite session failed the mode check and
      // re-opened the project, closing the database the readWrite caller was
      // actively using.
      final root = await Directory.systemTemp.createTemp(
        'hermes-mode-upgrade-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Mode Project');
      final container = ProviderContainer(
        overrides: [
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: root),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(currentProjectSessionProvider.notifier);
      final writeSession = await controller.openProject(package.projectId);
      final readSession = await controller.openProject(
        package.projectId,
        mode: ProjectOpenMode.readOnly,
      );

      expect(
        identical(readSession, writeSession),
        isTrue,
        reason: 'readWrite is a superset of readOnly: reuse, never re-open',
      );
      // The write session must still be live for its original owner.
      await writeSession.save();
      // Deterministic teardown: await the close before deleting the root.
      await controller.closeProject();
    },
  );

  test(
    'concurrent openProject requests converge on the shared readWrite session',
    () async {
      // The hunter's exact interleaving: two simultaneous requests with
      // differing modes must both receive the one live session, not race a
      // close/re-open cycle (vs-hunt-20260913-projects BUG-2).
      final root = await Directory.systemTemp.createTemp('hermes-mode-race-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Race Project');
      final container = ProviderContainer(
        overrides: [
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: root),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(currentProjectSessionProvider.notifier);
      final sessions = await Future.wait([
        controller.openProject(package.projectId),
        controller.openProject(
          package.projectId,
          mode: ProjectOpenMode.readOnly,
        ),
      ]);

      expect(identical(sessions[0], sessions[1]), isTrue);
      expect(sessions[0].mode, ProjectOpenMode.readWrite);
      await sessions[0].save();
      // Deterministic teardown: await the close before deleting the root.
      await controller.closeProject();
    },
  );

  test(
    'a readOnly session is upgraded to a fresh readWrite session on request',
    () async {
      // Regression lock for the legitimate re-open direction: write access
      // cannot be granted by reusing a read-only session.
      final root = await Directory.systemTemp.createTemp(
        'hermes-mode-downgrade-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Upgrade Project');
      final container = ProviderContainer(
        overrides: [
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: root),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(currentProjectSessionProvider.notifier);
      final readSession = await controller.openProject(
        package.projectId,
        mode: ProjectOpenMode.readOnly,
      );
      final writeSession = await controller.openProject(package.projectId);

      expect(writeSession.mode, ProjectOpenMode.readWrite);
      expect(identical(writeSession, readSession), isFalse);
      await writeSession.save();
      // Close before teardown: the provider-dispose close is unawaited and
      // races root deletion on Windows (preserved lifecycle, not a bug).
      await controller.closeProject();
    },
  );
}
