import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/creatures/application/create_creature_service.dart';
import 'package:void_scriptor/features/creatures/domain/creature_model.dart';
import 'package:void_scriptor/features/creatures/presentation/creature_workspace_screen.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

/// BUG-05 (void-scriptor-hunt-20260910, Referee REAL BUG Medium):
/// intent creature tanpa selection dirender sebagai WorldbuildingBody
/// generik (tanpa data creature) sementara header panel mengiklankan
/// "Creature Workspace", dan tidak ada jalur pemulihan selection creature.
/// Kontrak: creature intent harus pulih lewat katalog recovery (pola sama
/// dengan character/environment) dan empty-state-nya menawarkan aksi
/// create yang nyata, bukan surface worldbuilding yang menyesatkan.
void main() {
  late Directory root;
  late String projectId;
  late ProviderContainer container;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('void-creature-intent-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Creature Intent');
    projectId = package.projectId;
    container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(
          ProjectPaths(rootDirectory: root),
        ),
      ],
    );
    // Real async zone: session open runs here because widget test bodies
    // run under FakeAsync and cannot await real IO.
    await container.read(projectSessionProvider.future);
    await container
        .read(projectSessionProvider.notifier)
        .openProject(projectId);
  });

  tearDown(() async {
    await container.read(projectSessionProvider.notifier).closeProject();
    container.dispose();
    await root.delete(recursive: true);
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Column(
                children: [
                  TextButton(
                    onPressed: () =>
                        focusExplorerAsset(ref, AssetType.creature),
                    child: const Text('Creatures'),
                  ),
                  const Expanded(child: WorkspaceResolver()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'creature intent with an empty catalog shows a typed creature empty state, not WorldbuildingBody',
    (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Creatures'));
      await tester.pumpAndSettle();

      expect(container.read(workspaceIntentProvider)?.$2, AssetType.creature);
      // BUG-05 RED: sebelum patch, intent creature jatuh ke WorldbuildingBody.
      expect(find.byType(WorldbuildingBody), findsNothing);
      expect(find.text('Novel Workspace'), findsNothing);
      // Typed creature empty state: judul sesuai header panel + aksi create.
      expect(find.text('Creature Workspace'), findsOneWidget);
      expect(find.text('Buat Creature'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'creature selection released by a project switch is restored from catalog recovery',
    (tester) async {
      final session = container.read(projectSessionProvider).value!;
      // Real file IO must run through runAsync: the test body is FakeAsync
      // and directory creation never completes there (drift SQL is
      // synchronous, dart:io is not).
      final creatureId = await tester.runAsync(
        () =>
            CreateCreatureService(
              database: session.database,
              paths: ProjectPaths(rootDirectory: root),
            ).create(
              projectId: projectId,
              name: 'Nyx',
              category: CreatureCategory.monster,
            ),
      );

      await pumpShell(tester);

      // Simulate the strand: a live creature selection (intent stamped),
      // then the selection released the way a project switch releases it.
      final controller = container.read(selectionProvider.notifier);
      controller.select(
        SelectionModel(
          assetId: creatureId!,
          assetType: AssetType.creature,
          projectId: projectId,
        ),
      );
      controller.clear();
      expect(container.read(workspaceIntentProvider)?.$1, projectId);
      expect(container.read(workspaceIntentProvider)?.$2, AssetType.creature);
      expect(container.read(selectionProvider), isNull);

      // Re-enter the creature workspace; the catalog recovery must restore
      // the remembered creature without another explicit pick.
      await tester.tap(find.text('Creatures'));
      await tester.pumpAndSettle();
      // CreatureWorkspaceProvider loads through real IO; poll for the row.
      await tester.runAsync(() async {
        for (var i = 0; i < 50; i++) {
          if (find.text('Nyx').evaluate().isNotEmpty) return;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pumpAndSettle();

      expect(find.byType(CreatureWorkspaceScreen), findsOneWidget);
      expect(find.byType(WorldbuildingBody), findsNothing);
      expect(find.text('Nyx'), findsOneWidget);
      expect(container.read(selectionProvider)?.assetId, creatureId);
      expect(tester.takeException(), isNull);
    },
  );
}
