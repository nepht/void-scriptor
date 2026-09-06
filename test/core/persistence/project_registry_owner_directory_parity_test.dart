import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_recovery_service.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-bug16-');
  });

  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  File markerOf(Directory packageRoot) => File(
    '${packageRoot.path}${Platform.pathSeparator}'
    '${ProjectRecoveryService.creationMarkerName}',
  );

  group('bug-hunt run94 BUG-16 owner-directory parity', () {
    test(
      'crash-window package in the legacy <root>/Projects layout is admitted',
      () async {
        final legacyProjects = await Directory(
          '${tempRoot.path}${Platform.pathSeparator}Projects',
        ).create(recursive: true);
        final package = await ProjectPackageService(
          rootDirectory: legacyProjects,
        ).create(name: 'Legacy Home');

        // The package carries an explicit creation marker, but admission
        // must scan the same directory set stash recovery scans.
        expect(markerOf(package.root).existsSync(), isTrue);

        final registry = ProjectRegistryService(rootDirectory: tempRoot);
        final projects = await registry.load();

        expect(projects, hasLength(1));
        expect(projects.single.id, package.projectId);
        expect(projects.single.name, 'Legacy Home');
        expect(projects.single.localPath, package.root.path);

        // Admission is durable before the marker is consumed.
        expect(markerOf(package.root).existsSync(), isFalse);
        expect(await registry.load(), hasLength(1));
      },
    );

    test(
      'interrupted-import stash in the legacy layout is still restored',
      () async {
        final legacyProjects = await Directory(
          '${tempRoot.path}${Platform.pathSeparator}Projects',
        ).create(recursive: true);
        final package = await ProjectPackageService(
          rootDirectory: legacyProjects,
        ).create(name: 'Stashed Legacy');

        final legacyRegistry = ProjectRegistryService(
          rootDirectory: legacyProjects,
        );
        await legacyRegistry.upsert((await legacyRegistry.load()).first);

        // Simulate the pre-import stash: the canonical package moves aside.
        final stashPath =
            '${legacyProjects.path}${Platform.pathSeparator}'
            '.${package.projectId}.voidproject.import-backup-legacy';
        await package.root.rename(stashPath);
        await legacyRegistry.remove(package.projectId);

        final home = ProjectRegistryService(rootDirectory: tempRoot);
        await home.load();

        expect(
          Directory(
            '${legacyProjects.path}${Platform.pathSeparator}'
            '${package.projectId}.voidproject',
          ).existsSync(),
          isTrue,
        );
      },
    );
  });
}
