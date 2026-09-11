import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_move_service.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/persistence/project_recovery_service.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/projects/domain/project_model.dart';
import 'package:void_scriptor/features/projects/presentation/widgets/project_card.dart';

/// Wiring sprint Task 3 (BUG-7 contract "both halves ship together"): the
/// move trigger UI. The recovery half (roll-forward + registry repoint) is
/// already wired in registry load (cron ce28d9a); this slice adds the first
/// production caller of [ProjectMoveService.movePackage] and proves the
/// registry entry is repointed to the new location on a successful move,
/// and that a failed move leaves everything untouched.
void main() {
  Future<(Directory, ProjectRegistryService, ProjectModel)> seed(
    String name,
  ) async {
    final root = await Directory.systemTemp.createTemp('move-ui-$name-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Move Me $name');
    final registry = ProjectRegistryService(paths: paths);
    final model = ProjectModel(
      id: package.projectId,
      name: 'Move Me $name',
      description: 'seed',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastOpenedAt: DateTime.now(),
      localPath: package.root.path,
      version: '1',
    );
    await registry.upsert(model);
    return (root, registry, model);
  }

  test(
    'relocateProject moves the package and repoints the registry entry',
    () async {
      final (root, registry, model) = await seed('ok');
      final destinationRoot = Directory(
        '${root.path}${Platform.pathSeparator} elsewhere',
      );
      await destinationRoot.create();

      final service = ProjectRelocationService(registry: registry);
      final moved = await service.relocateProject(
        projectId: model.id,
        destinationRoot: destinationRoot,
      );

      final package = Directory(
        '${destinationRoot.path}${Platform.pathSeparator}${model.id}.voidproject',
      );
      expect(await package.exists(), isTrue, reason: 'package pindah fisik');
      expect(moved.path, package.path);

      final entry = (await registry.load()).firstWhere((p) => p.id == model.id);
      expect(entry.localPath, package.path, reason: 'registry entry repointed');

      // The moved location is loadable again. The registry load itself has
      // no path-existence re-check (bug-hunt vs-hunt-20260911 BUG-7: an
      // earlier comment falsely claimed stale localPaths are dropped or
      // tombstoned on load) — this re-read proves the repointed entry is
      // durable and stable across loads, which is exactly what BUG-3's
      // durability-first ordering guarantees at the crash window.
      final reloaded = (await registry.load()).where((p) => p.id == model.id);
      expect(reloaded, isNotEmpty);
    },
  );

  test(
    'a failed move consumes the journal and keeps the registry untouched',
    () async {
      final (root, registry, model) = await seed('fail');
      // Occupy the destination so the rename fails (Directory.rename cannot
      // replace an existing directory on Windows).
      final destinationRoot = Directory(
        '${root.path}${Platform.pathSeparator}else',
      );
      await destinationRoot.create();
      final occupied = Directory(
        '${destinationRoot.path}${Platform.pathSeparator}${model.id}.voidproject',
      );
      await occupied.create();
      // bug-hunt vs-hunt-20260911 BUG-6: the obstacle must be NON-empty.
      // POSIX rename(2) happily replaces an existing *empty* directory,
      // so an empty obstacle only fails the rename on Windows — the
      // unfiltered Linux CI job (ci.yml) would see no exception at all.
      // A file inside makes rename fail on every platform.
      await File(
        '${occupied.path}${Platform.pathSeparator}obstacle.txt',
      ).writeAsString('occupied', flush: true);

      final service = ProjectRelocationService(registry: registry);
      await expectLater(
        service.relocateProject(
          projectId: model.id,
          destinationRoot: destinationRoot,
        ),
        throwsA(isA<FileSystemException>()),
      );

      final entry = (await registry.load()).firstWhere((p) => p.id == model.id);
      expect(
        entry.localPath,
        model.localPath,
        reason: 'kegagalan move tidak boleh menggeser entry',
      );
      // No stale journal: the service consumed the move-pending marker.
      final marker = File(
        '${model.localPath}${Platform.pathSeparator}${ProjectRecoveryService.movePendingMarkerName}',
      );
      expect(await marker.exists(), isFalse);
    },
  );

  testWidgets('project card exposes Move Project… in the actions menu', (
    tester,
  ) async {
    ProjectModel? requested;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectCard(
            project: ProjectModel(
              id: 'p1',
              name: 'Demo',
              description: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              lastOpenedAt: DateTime.now(),
              localPath: '/tmp/p1.voidproject',
              version: '1',
            ),
            onDelete: () {},
            onMove: (model) => requested = model,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Project actions for Demo'));
    await tester.pumpAndSettle();
    expect(find.text('Move Project…'), findsOneWidget);

    await tester.tap(find.text('Move Project…'));
    await tester.pumpAndSettle();
    expect(requested?.id, 'p1');
  });
}
