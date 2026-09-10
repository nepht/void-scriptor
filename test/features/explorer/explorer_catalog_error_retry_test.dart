import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/environment/domain/environment_model.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// BUG-8 (void-scriptor-hunt-run171, Referee REAL BUG Medium):
/// katalog yang gagal pada load pertama menyandera intent typed
/// (story/environment): baris error grup Explorer hanyalah teks `$error`
/// tanpa aksi retry, dan recovery hanya menunggu katalog re-emit yang
/// tidak pernah terjadi (FutureProvider tidak auto-retry setelah error).
/// Kontrak (prioritas pengguna 2026-09-04 #2 - pemulihan pilihan saat
/// katalog gagal):
/// 1. baris error grup story/environment menawarkan tombol "Coba lagi"
///    yang me-retry katalog (invalidate provider);
/// 2. katalog sehat tidak merender tombol retry;
/// 3. setelah backend pulih dan retry ditekan, intent typed terstranding
///    dipulihkan oleh recovery tanpa navigasi ulang pengguna.
void main() {
  late Directory root;
  late String projectId;
  late ProviderContainer container;
  // Failure-injection flag: true = katalog berikutnya melempar error
  // (mensimulasikan kegagalan DB/IO transien), false = katalog sehat
  // membaca data proyek uji. Dibaca dengan ref.read agar perubahan flag
  // tidak otomatis meng-invalidate provider - retry tombol-lah yang
  // menjadi mekanisme pemulihan.
  final storyFailFlag = StateProvider<bool>((ref) => false);
  final environmentFailFlag = StateProvider<bool>((ref) => false);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('void-bug8-retry-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Bug8 Retry');
    projectId = package.projectId;
    container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(
          ProjectPaths(rootDirectory: root),
        ),
        storyExplorerProvider.overrideWith((ref, arg) async {
          if (ref.read(storyFailFlag)) {
            throw StateError('katalog story tidak tersedia (uji)');
          }
          final session = ref.watch(projectSessionProvider).valueOrNull;
          if (session == null || session.manifest.id != arg) {
            return const [];
          }
          return (await session.database.assetDao.getAllAssets())
              .where((asset) => asset.projectId == arg && asset.type == 'story')
              .toList(growable: false);
        }),
        environmentExplorerProvider.overrideWith((ref, arg) async {
          if (ref.read(environmentFailFlag)) {
            throw StateError('katalog environment tidak tersedia (uji)');
          }
          return <EnvironmentModel>[
            EnvironmentModel(
              assetId: 'env-fixture',
              projectId: arg,
              name: 'Gunung Uji',
            ),
          ];
        }),
      ],
    );
    await container.read(projectSessionProvider.future);
    await container
        .read(projectSessionProvider.notifier)
        .openProject(projectId);
    final session = container.read(projectSessionProvider).value!;
    await session.database
        .into(session.database.assets)
        .insert(
          AssetsCompanion.insert(
            id: 'story-fixture',
            projectId: projectId,
            name: 'Naskah Uji',
            type: 'story',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
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
        child: const MaterialApp(home: Scaffold(body: ExplorerPanel())),
      ),
    );
    await tester.pumpAndSettle();
    // Production shells keep the autoDispose intent provider alive.
    container.listen(workspaceIntentProvider, (_, _) {});
  }

  testWidgets(
    'failed story catalog offers a retry that lets recovery restore the typed intent',
    (tester) async {
      // Inject failure BEFORE the first catalog load so the error state
      // carries no previous data (the stranding mechanism of BUG-8).
      container.read(storyFailFlag.notifier).state = true;
      await pumpShell(tester);

      // Navigate to the novel workspace while the catalog is broken.
      final novelHeader = find.text('Novel Workspace');
      await tester.ensureVisible(novelHeader);
      await tester.tap(novelHeader);
      await tester.pumpAndSettle();
      expect(container.read(workspaceIntentProvider)?.$2, AssetType.story);

      // BUG-8 RED: the failed catalog renders a bare error line only,
      // with no retry affordance anywhere in the Explorer.
      expect(
        find.textContaining('katalog story tidak tersedia'),
        findsOneWidget,
      );
      // The retry affordance is an IconButton with a tooltip label.
      expect(find.byTooltip('Coba lagi'), findsOneWidget);

      // Retry while still failing: the row stays honest, no crash.
      await tester.tap(find.byTooltip('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Coba lagi'), findsOneWidget);

      // Backend heals; retry re-runs the catalog and the recovery
      // provider restores the stranded typed intent without re-navigation.
      container.read(storyFailFlag.notifier).state = false;
      await tester.tap(find.byTooltip('Coba lagi'));
      await tester.pumpAndSettle();
      expect(container.read(selectionProvider)?.assetType, AssetType.story);
      expect(container.read(selectionProvider)?.assetId, 'story-fixture');
    },
  );

  testWidgets(
    'failed environment catalog offers a retry that lets recovery restore the typed intent',
    (tester) async {
      container.read(environmentFailFlag.notifier).state = true;
      await pumpShell(tester);

      final envHeader = find.text('Environments');
      await tester.ensureVisible(envHeader);
      await tester.tap(envHeader);
      await tester.pumpAndSettle();
      expect(
        container.read(workspaceIntentProvider)?.$2,
        AssetType.environment,
      );
      // The first header tap focuses but collapses the initially-expanded
      // tile; re-expand to reach the error row (as a real user would).
      await tester.tap(envHeader);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('katalog environment tidak tersedia'),
        findsOneWidget,
      );
      expect(find.byTooltip('Coba lagi'), findsOneWidget);

      await tester.tap(find.byTooltip('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Coba lagi'), findsOneWidget);

      container.read(environmentFailFlag.notifier).state = false;
      await tester.tap(find.byTooltip('Coba lagi'));
      await tester.pumpAndSettle();
      expect(
        container.read(selectionProvider)?.assetType,
        AssetType.environment,
      );
      expect(container.read(selectionProvider)?.assetId, 'env-fixture');
    },
  );

  testWidgets('healthy catalogs never render a retry button', (tester) async {
    await pumpShell(tester);
    final novelHeader = find.text('Novel Workspace');
    await tester.ensureVisible(novelHeader);
    await tester.tap(novelHeader);
    await tester.pumpAndSettle();
    expect(container.read(workspaceIntentProvider)?.$2, AssetType.story);
    // Recovery restores the selection from the healthy catalog directly.
    expect(container.read(selectionProvider)?.assetId, 'story-fixture');
    expect(find.byTooltip('Coba lagi'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
