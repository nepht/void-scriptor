import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/projects/domain/project_model.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// vs-hunt-20260911 BUG-2 (High): the open path resolved package roots with
/// ProjectPaths.project(id) — a pure join against the (possibly custom)
/// root — and never consulted the registry entry's localPath. A package
/// moved via "Move Project..." became listed-but-unopenable while the
/// relocation snackbar claimed success. This test pins the contract: the
/// open path resolves the package root from the registry entry first and
/// falls back to the root join only when no entry exists.
void main() {
  test(
    'openProject and unlockAndOpen resolve a moved package via registry localPath '
    '(vs-hunt-20260911 BUG-2)',
    skip: !Platform.isWindows,
    () async {
      final defaultRoot = await Directory.systemTemp.createTemp('bug2-root-');
      addTearDown(() => defaultRoot.delete(recursive: true));
      final movedParent = await Directory.systemTemp.createTemp('bug2-moved-');
      addTearDown(() => movedParent.delete(recursive: true));

      // Create a real package at the default root.
      final package = await ProjectPackageService(
        rootDirectory: defaultRoot,
      ).create(name: 'Moved Project');
      final originalRoot = package.root.path;

      // Move the directory away and repoint the registry entry.
      final movedDir = Directory(
        '${movedParent.path}${Platform.pathSeparator}'
        '${package.projectId}.voidproject',
      );
      await package.root.rename(movedDir.path);
      expect(
        await Directory(originalRoot).exists(),
        isFalse,
        reason: 'paket benar-benar pindah — root join tak mungkin berhasil',
      );

      final registry = ProjectRegistryService(rootDirectory: defaultRoot);
      await registry.upsert(
        ProjectModel(
          id: package.projectId,
          name: 'Moved Project',
          description: 'moved',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastOpenedAt: DateTime.now(),
          localPath: movedDir.path,
          version: '1',
        ),
      );

      // The ProjectPaths instance used by the controller still joins the
      // default root, so without the fix the opens below fail.
      final container = ProviderContainer(
        overrides: [
          projectPathsProvider.overrideWith(
            (ref) => ProjectPaths(rootDirectory: defaultRoot),
          ),
          projectRegistryServiceProvider.overrideWith((ref) => registry),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(projectSessionProvider.notifier);

      final session = await controller.openProject(package.projectId);
      addTearDown(session.close);
      expect(
        session.package.root.path,
        movedDir.path,
        reason: 'open path resolved from registry localPath',
      );

      // The unlock probe shares the resolution: a wrong passphrase on the
      // moved package returns false (probe reached the database); with a
      // root-join probe it would throw PathAccessException instead.
      final unlocked = await controller.unlockAndOpen(
        package.projectId,
        'wrong-passphrase',
      );
      expect(unlocked, isFalse);
    },
  );
}
