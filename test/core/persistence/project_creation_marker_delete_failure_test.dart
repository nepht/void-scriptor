import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/persistence/project_recovery_service.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/projects/data/project_local_data_source.dart';
import 'package:void_scriptor/features/projects/data/project_repository_impl.dart';
import 'package:void_scriptor/features/projects/presentation/project_controller.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/platform/domain/platform_capability.dart';
import 'package:void_scriptor/features/platform/platform_capability_providers.dart';

// bug-hunt run197 BUG-1 (Critical, data-loss path):
// upsert() consumes the creation marker with an UNGUARDED delete right
// after the registry save is durable. A transient fresh-file error
// (errno 32/5, the class this repo documents in durable_draft_journal
// and ProjectLock) then propagates out of upsert, and
// ProjectController.createProject's catch deletes the COMPLETE package
// while the durable registry entry dangles. The same unguarded delete in
// _loadUnlocked turns a transient delete failure into a thrown project
// listing even though the admission is already durable.
//
// Trigger staging is deterministic and disposable, mirroring production
// errno classes without touching real drives:
//   Windows: `attrib +R` on the marker file -> File.delete throws
//     PathAccessException errno 5 (verified host probe).
//   POSIX: `chmod a-w` on the package root directory -> unlink of the
//     marker throws errno 13 (EACCES).
// Both surface as FileSystemException — the same class as the field
// documented errno-32 trigger. The container test stages the block via a
// registry subclass because the marker only exists after the controller's
// internal ProjectPackageService.create() call.
String _markerPath(String packageRoot) =>
    '$packageRoot${Platform.pathSeparator}'
    '${ProjectRecoveryService.creationMarkerName}';

Future<void> _blockMarkerDeletion(String packageRoot) async {
  if (Platform.isWindows) {
    final result = await Process.run('attrib', [
      '+R',
      _markerPath(packageRoot),
    ]);
    expect(result.exitCode, 0, reason: 'attrib +R must succeed to stage RED');
  } else {
    final result = await Process.run('chmod', ['a-w', packageRoot]);
    expect(result.exitCode, 0);
  }
}

Future<void> _clearMarkerDeletionBlock(String packageRoot) async {
  if (Platform.isWindows) {
    await Process.run('attrib', ['-R', _markerPath(packageRoot)]);
  } else {
    await Process.run('chmod', ['u+w', packageRoot]);
  }
}

/// Stages the transient marker-delete failure between the durable registry
/// save and the marker consumption inside the real production [upsert].
class _BlockingRegistryService extends ProjectRegistryService {
  _BlockingRegistryService({super.paths});

  @override
  Future<void> upsert(ProjectModel project) {
    return _blockAndCall(project, () => super.upsert(project));
  }

  Future<void> _blockAndCall(
    ProjectModel project,
    Future<void> Function() body,
  ) async {
    await _blockMarkerDeletion(project.localPath);
    await body();
  }
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vs-run197-bug1-');
  });

  tearDown(() async {
    if (await root.exists()) {
      // Release POSIX directory blocks so recursive cleanup succeeds.
      final dirs = root
          .listSync(recursive: true)
          .whereType<Directory>()
          .where((d) => d.path.endsWith('.voidproject'));
      for (final d in dirs) {
        await _clearMarkerDeletionBlock(d.path);
      }
      try {
        await root.delete(recursive: true);
      } on FileSystemException catch (_) {}
    }
  });

  test('transient marker-delete failure does not propagate out of upsert '
      'and keeps the durable registration', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Marker Blocked');
    // A package finished but never registered: the marker is still on
    // disk (the crash-window state). Registration happens below.
    expect(File(_markerPath(package.root.path)).existsSync(), isTrue);
    final paths = ProjectPaths(rootDirectory: root);
    final registry = ProjectRegistryService(paths: paths);
    final project = ProjectModel(
      id: package.projectId,
      name: 'Marker Blocked',
      description: '',
      createdAt: DateTime(2026, 9, 11),
      updatedAt: DateTime(2026, 9, 11),
      lastOpenedAt: DateTime(2026, 9, 11),
      localPath: package.root.path,
      version: '0.1.0',
    );

    await _blockMarkerDeletion(package.root.path);

    // RED on the old code: upsert's load admits the package, persists
    // the registration, then the UNGUARDED consumeCreationMarker delete
    // throws out of the whole call AFTER the registration is durable.
    await expectLater(registry.upsert(project), completes);

    // Registration survived and the package was never touched.
    await _clearMarkerDeletionBlock(package.root.path);
    final reloaded = await ProjectRegistryService(paths: paths).load();
    expect(reloaded.map((p) => p.id), contains(project.id));
    expect(await package.root.exists(), isTrue);
  });

  test('a stale creation marker with a registered id is harmless and is '
      'consumed on the next load once the block clears', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Stale Marker');
    final paths = ProjectPaths(rootDirectory: root);
    final registry = ProjectRegistryService(paths: paths);

    // Block BEFORE the first load: the crash-admission persists, but
    // its marker consumption fails transiently.
    await _blockMarkerDeletion(package.root.path);
    final first = await registry.load();
    expect(first, hasLength(1));
    expect(first.single.id, package.projectId);
    // Marker intentionally survives the failed consumption.
    expect(File(_markerPath(package.root.path)).existsSync(), isTrue);

    await _clearMarkerDeletionBlock(package.root.path);
    final afterRetry = await registry.load();
    expect(afterRetry, hasLength(1));
    expect(afterRetry.single.id, package.projectId);
    expect(File(_markerPath(package.root.path)).existsSync(), isFalse);
  });

  test('transient marker-delete failure during crash-admission does not '
      'break the project listing', () async {
    // Simulated process death before registration: package finished,
    // marker staged, registry never written.
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Admitted But Blocked');
    await _blockMarkerDeletion(package.root.path);

    final registry = ProjectRegistryService(rootDirectory: root);
    // RED on the old code: _loadUnlocked persists the admission, then
    // the unguarded marker-delete loop throws, so load() fails even
    // though the listing data is already durable.
    final projects = await registry.load();
    expect(projects.map((p) => p.id), contains(package.projectId));

    await _clearMarkerDeletionBlock(package.root.path);
    expect(await registry.load(), hasLength(1));
  });

  test('end-to-end: transient marker-delete failure during createProject '
      'does NOT destroy the complete package (data-loss path)', () async {
    final paths = ProjectPaths(rootDirectory: root);
    final registry = _BlockingRegistryService(paths: paths);
    final container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(paths),
        projectRegistryServiceProvider.overrideWithValue(registry),
        projectLocalDataSourceProvider.overrideWithValue(
          ProjectLocalDataSource(registry: registry),
        ),
        projectRepositoryProvider.overrideWithValue(
          ProjectRepositoryImpl(ProjectLocalDataSource(registry: registry)),
        ),
        platformCapabilitiesProvider.overrideWithValue(
          resolvePlatformCapabilities(isWeb: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    // GREEN contract: a transient failure consuming a HARMLESS marker
    // (registration is already durable) must not fail creation at all.
    final project = await container
        .read(projectControllerProvider.notifier)
        .createProject(
          name: 'Survivor',
          description: 'must not be wiped by marker errno',
          localPath: root.path,
        );

    final packageRoot = Directory(project.localPath);
    expect(
      await packageRoot.exists(),
      isTrue,
      reason:
          'BUG-1: the catch in ProjectController.createProject wiped '
          'the COMPLETE package after a marker-delete errno',
    );
    expect(
      File(
        '${project.localPath}${Platform.pathSeparator}manifest'
        '${Platform.pathSeparator}project.json',
      ).existsSync(),
      isTrue,
    );
    final listed = await registry.load();
    expect(listed.map((p) => p.id), contains(project.id));
  });
}
