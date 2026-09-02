import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/custom_storage_location.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  late Directory tempRoot;
  late Directory customDrive;
  late File registryFile;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-14531-wiring-');
    customDrive = Directory(
      '${tempRoot.path}${Platform.pathSeparator}custom-drive',
    );
    await customDrive.create(recursive: true);
    registryFile = File(
      '${tempRoot.path}${Platform.pathSeparator}storage_locations.json',
    );
  });

  tearDown(() async {
    try {
      await tempRoot.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<CustomStorageLocationStore> activatedStore() async {
    final store = CustomStorageLocationStore(registryFile: registryFile);
    await store.setActiveLocation(customDrive.path);
    return store;
  }

  group('145.31 custom storage location wiring', () {
    test('ProjectPaths root follows active custom storage location', () async {
      final store = await activatedStore();
      final paths = ProjectPaths(
        customStorageStore: store,
        fallbackRootDirectory: tempRoot,
      );

      final root = await paths.root();

      expect(root.path, customDrive.path);
    });

    test(
      'package service and registry follow custom root without default projects folder',
      () async {
        final store = await activatedStore();
        final paths = ProjectPaths(
          customStorageStore: store,
          fallbackRootDirectory: tempRoot,
        );

        final package = await ProjectPackageService(
          rootDirectory: await paths.root(),
        ).create(name: 'Custom Home');

        expect(
          package.root.path,
          '${customDrive.path}${Platform.pathSeparator}'
          '${package.projectId}.voidproject',
        );
        expect(package.manifestFile.existsSync(), isTrue);
        expect(package.databaseFile.existsSync(), isTrue);

        final created = Directory(customDrive.path)
            .listSync()
            .whereType<Directory>()
            .where((entry) => entry.path.endsWith('.voidproject'))
            .toList();
        expect(created, hasLength(1));

        final container = ProviderContainer(
          overrides: [
            customStorageStoreProvider.overrideWith((ref) async => store),
            projectPathsProvider.overrideWithValue(paths),
          ],
        );
        addTearDown(container.dispose);
        expect(
          container.read(projectPathsProvider).rootOverride,
          customDrive.path,
        );
      },
    );

    test(
      'missing custom drive falls back to default root and marks location missing',
      () async {
        final store = await activatedStore();
        final paths = ProjectPaths(
          customStorageStore: store,
          fallbackRootDirectory: tempRoot,
        );
        await customDrive.delete(recursive: true);

        final root = await paths.root();

        expect(root.path, tempRoot.path);
        final state = await store.load();
        expect(state.status, StorageLocationStatus.missingDrive);
        expect(state.activeLocation, customDrive.path);
      },
    );

    test('no custom location keeps default Documents-style root', () async {
      final store = CustomStorageLocationStore(registryFile: registryFile);
      final paths = ProjectPaths(
        customStorageStore: store,
        documentsPath: () async => tempRoot.path,
      );

      final root = await paths.root();

      expect(
        root.path,
        '${tempRoot.path}${Platform.pathSeparator}VoidScriptor'
        '${Platform.pathSeparator}Projects',
      );
    });

    test(
      'custom location state round-trips schema and project binding',
      () async {
        final store = await activatedStore();
        await store.bindProject('proj-42');

        final state = await store.load();

        expect(state.schemaVersion, 1);
        expect(state.activeLocation, customDrive.path);
        expect(state.boundProjectId, 'proj-42');
        final encoded =
            jsonDecode(registryFile.readAsStringSync()) as Map<String, dynamic>;
        expect(encoded['schemaVersion'], 1);
        expect(encoded['activeLocation'], customDrive.path);
        expect(encoded['boundProjectId'], 'proj-42');
      },
    );
  });
}
