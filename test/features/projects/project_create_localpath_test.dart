// vs-hunt-20260913-projects PRJ-BUG-02 (Referee: REAL BUG, Low).
// createProject menerima parameter `localPath` yang REQUIRED tetapi selama ini
// diabaikan diam-diam: body selalu memakai paths.root(). Parameter yang berjanji
// menentukan lokasi tetapi tidak pernah dipakai = contract trap kelas BUG-7:
// caller berikutnya yang meneruskan direktori pilihan pengguna akan menghasilkan
// paket proyek di lokasi SALAH tanpa error.
//
// Kontrak perbaikan: localPath non-kosong dipakai sebagai root paket; localPath
// kosong mempertahankan perilaku default paths.root() (kontrak web-guard test
// yang sudah ada: localPath: '' -> root terkelola, tidak pernah gagal).
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/features/projects/data/project_local_data_source.dart';
import 'package:void_scriptor/features/projects/data/project_repository_impl.dart';
import 'package:void_scriptor/features/projects/presentation/project_controller.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

ProviderContainer _container(Directory managedRoot) {
  final paths = ProjectPaths(rootDirectory: managedRoot);
  final registry = ProjectRegistryService(paths: paths);
  return ProviderContainer(
    overrides: [
      projectPathsProvider.overrideWithValue(paths),
      projectRegistryServiceProvider.overrideWithValue(registry),
      projectLocalDataSourceProvider.overrideWithValue(
        ProjectLocalDataSource(registry: registry),
      ),
      projectRepositoryProvider.overrideWith(
        (ref) =>
            ProjectRepositoryImpl(ref.watch(projectLocalDataSourceProvider)),
      ),
    ],
  );
}

void main() {
  test(
    'createProject honors a non-empty localPath as the package root',
    () async {
      final managedRoot = await Directory.systemTemp.createTemp(
        'ws-create-honored-managed-',
      );
      final chosenRoot = await Directory.systemTemp.createTemp(
        'ws-create-honored-chosen-',
      );
      addTearDown(() => managedRoot.delete(recursive: true));
      addTearDown(() => chosenRoot.delete(recursive: true));

      final container = _container(managedRoot);
      addTearDown(container.dispose);

      final project = await container
          .read(projectControllerProvider.notifier)
          .createProject(
            name: 'Lokasi Dipilih',
            description: '',
            localPath: chosenRoot.path,
          );

      // RED target: paket HARUS berada di dalam root yang diminta pemanggil,
      // bukan diam-diam jatuh ke root terkelola.
      expect(project.localPath, startsWith(chosenRoot.path));
      expect(Directory(project.localPath).existsSync(), isTrue);
      expect(
        Directory(
          managedRoot.path,
        ).listSync().where((e) => e.path.endsWith('.voidproject')),
        isEmpty,
        reason:
            'root terkelola tidak boleh menampung paket yang lokasinya '
            'dieksplisitkan pemanggil',
      );
    },
  );

  test(
    'createProject with empty localPath keeps the managed-root default',
    () async {
      final managedRoot = await Directory.systemTemp.createTemp(
        'ws-create-empty-fallback-',
      );
      addTearDown(() => managedRoot.delete(recursive: true));

      final container = _container(managedRoot);
      addTearDown(container.dispose);

      final project = await container
          .read(projectControllerProvider.notifier)
          .createProject(name: 'Default', description: '', localPath: '');

      expect(project.localPath.startsWith(managedRoot.path), isTrue);
      expect(Directory(project.localPath).existsSync(), isTrue);
    },
  );
}
