import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_memory_snapshot.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/character/domain/character_model.dart';
import 'package:void_scriptor/features/character/presentation/character_controller.dart';
import 'package:void_scriptor/features/creatures/domain/creature_model.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// vs-hunt-20260914-explorer-selection (Referee on-disk = otoritas verdict;
/// head_at_verdict fea57ba):
/// - BUG-2 Medium: explorerCatalogRecoveryProvider mencampur katalog kosong
///   SUKSES (ids.isEmpty) dengan loading/error (ids == null) lalu return
///   tanpa menyelesaikan memori. Saat aset terakhir workspace terhapus, id
///   yang diingat (sudah mati) bertahan di memori sesi +
///   cache/selection_memory.json dan navigasi typed tersandera. Kontrak
///   (instruksi prioritas pengguna 2026-09-04 #2) menuntut kasus empty
///   catalog + aset terhapus ditangani: SelectionController.selectWorkspace
///   sudah punya percabangan empty yang benar (hapus kunci + clear), tapi
///   recovery tidak pernah meneruskan katalog-empty-sukses ke sana.
/// - BUG-3 + BUG-4 Medium: baris error catalog character dan creature
///   hanyalah teks tanpa aksi retry — preseden BUG-8 (hunt-run171) hanya
///   melengkapi grup story/environment. Inkonsistensi ini menyandera typed
///   intent setelah kegagalan transien.
void main() {
  group('BUG-2 empty-catalog recovery (recovery provider, unit)', () {
    late Directory root;
    late String projectId;
    late File memoryFile;
    late ProviderContainer container;
    // Katalog dikendalikan lewat variabel mode + invalidasi manual:
    // perubahan mode TIDAK otomatis meng-invalidate provider.
    late String catalogMode;
    late Completer<void> holdLoading;

    Future<void> makeContainer() async {
      root = await Directory.systemTemp.createTemp('void-bug2-empty-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Bug2 Empty');
      projectId = package.projectId;
      catalogMode = 'one';
      holdLoading = Completer<void>();
      container = ProviderContainer(
        overrides: [
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: root),
          ),
          characterControllerProvider.overrideWith((ref, arg) async {
            switch (catalogMode) {
              case 'loading':
                await holdLoading.future;
                return const <CharacterModel>[];
              case 'empty':
                return const <CharacterModel>[];
              default:
                return const [
                  CharacterModel(
                    assetId: 'char-fixture',
                    projectId: 'fixture',
                    displayName: 'Arka',
                  ),
                ];
            }
          }),
        ],
      );
      await container.read(projectSessionProvider.future);
      await container
          .read(projectSessionProvider.notifier)
          .openProject(projectId);
      memoryFile = selectionMemoryFileFor(
        container.read(projectSessionProvider).value!.package,
      );
      // Jaga wiring autoDispose recovery + persistence tetap hidup,
      // meniru shell (ExplorerPanel.build me-watch keduanya).
      container.listen(explorerCatalogRecoveryProvider, (_, _) {});
      container.listen(selectionMemoryPersistenceProvider, (_, _) {});
      container.listen(workspaceIntentProvider, (_, _) {});
    }

    setUp(makeContainer);

    tearDown(() async {
      container.dispose();
      try {
        await root.delete(recursive: true);
      } catch (_) {}
    });

    test(
      'successful empty catalog discards the remembered deleted selection',
      () async {
        // 1. Katalog sehat; pengguna memilih karakter -> entri memori
        //    (projectId, character) tercatat dan terpersist.
        final controller = container.read(selectionProvider.notifier);
        controller.select(
          SelectionModel(
            assetId: 'char-fixture',
            assetType: AssetType.character,
            projectId: projectId,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(
          loadSelectionMemorySnapshotSync(memoryFile)[(
            projectId,
            AssetType.character,
          )],
          'char-fixture',
          reason: 'prasyarat: file memori memuat entri karakter',
        );

        // 2. Karakter terakhir dihapus: katalog SUKSES menjadi kosong, dan
        //    selection dibuang (perilaku pasca-deletion di production).
        catalogMode = 'empty';
        controller.clear();
        container.invalidate(characterControllerProvider(projectId));

        // 3. Recovery wajib konvergen: seleksi null DAN id terhapus hilang
        //    dari memori sesi. (File ikut bersih pada tulis berikutnya —
        //    snapshot di-scope per proyek — jadi kontrak inti = memori
        //    sesi tidak lagi menghidupkan id mati saat restart/hidrasi.)
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(container.read(selectionProvider), isNull);
        expect(
          controller.workspaceMemorySnapshot(projectId: projectId)[(
            projectId,
            AssetType.character,
          )],
          isNull,
          reason:
              'memori aset-terhapus harus dibuang saat katalog sukses '
              'melaporkan workspace kosong',
        );
      },
    );

    test('loading catalog still keeps memory (no premature discard)', () async {
      // Kontrak lama yang wajib dipertahankan fix BUG-2: selama katalog
      // MEMUAT, id yang diingat tidak boleh dibuang.
      final controller = container.read(selectionProvider.notifier);
      controller.select(
        SelectionModel(
          assetId: 'char-fixture',
          assetType: AssetType.character,
          projectId: projectId,
        ),
      );
      catalogMode = 'loading';
      controller.clear();
      container.invalidate(characterControllerProvider(projectId));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(
        controller.workspaceMemorySnapshot(projectId: projectId)[(
          projectId,
          AssetType.character,
        )],
        'char-fixture',
        reason: 'selama katalog memuat, memori tetap disimpan',
      );
      holdLoading.complete();
    });
  });

  group('BUG-3/BUG-4 error-row retry parity (ExplorerPanel shell)', () {
    // Injeksi kegagalan dibaca via ref.read agar perubahan flag tidak
    // otomatis meng-invalidate provider — tombol retry-lah mekanisme
    // pemulihnya (pola persis explorer_catalog_error_retry_test.dart
    // preseden BUG-8 run171).
    late StateProvider<bool> characterFailFlag;
    late StateProvider<bool> creatureFailFlag;
    late Directory root;
    late String projectId;
    late ProviderContainer container;

    setUp(() async {
      characterFailFlag = StateProvider<bool>((ref) => false);
      creatureFailFlag = StateProvider<bool>((ref) => false);
      root = await Directory.systemTemp.createTemp('void-bug34-retry-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Bug34 Retry');
      projectId = package.projectId;
      container = ProviderContainer(
        overrides: [
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: root),
          ),
          characterControllerProvider.overrideWith((ref, arg) async {
            if (ref.read(characterFailFlag)) {
              throw StateError('katalog character tidak tersedia (uji)');
            }
            return const [
              CharacterModel(
                assetId: 'char-fixture',
                projectId: 'fixture',
                displayName: 'Arka',
              ),
            ];
          }),
          creatureExplorerProvider.overrideWith((ref, arg) async {
            if (ref.read(creatureFailFlag)) {
              throw StateError('katalog creature tidak tersedia (uji)');
            }
            return const [
              CreatureModel(
                assetId: 'creature-fixture',
                projectId: 'fixture',
                name: 'Naga Uji',
                category: CreatureCategory.dragon,
              ),
            ];
          }),
        ],
      );
      await container.read(projectSessionProvider.future);
      await container
          .read(projectSessionProvider.notifier)
          .openProject(projectId);
    });

    tearDown(() async {
      container.dispose();
      try {
        await root.delete(recursive: true);
      } catch (_) {}
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
      container.listen(workspaceIntentProvider, (_, _) {});
    }

    /// Tap header grup dua kali bila perlu: tap pertama pada tile yang
    /// semula-expanded me-collapse (sekalian men-stamp intent lewat
    /// onFocused); tap kedua memperluas baris error seperti pengguna nyata.
    Future<void> focusAndExpand(WidgetTester tester, Finder header) async {
      await tester.ensureVisible(header);
      await tester.tap(header);
      await tester.pumpAndSettle();
      await tester.tap(header);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'failed character catalog offers a retry that lets recovery restore the typed intent',
      (tester) async {
        container.read(characterFailFlag.notifier).state = true;
        await pumpShell(tester);
        container.invalidate(characterControllerProvider(projectId));
        await tester.pumpAndSettle();

        await focusAndExpand(tester, find.text('Characters'));
        expect(
          container.read(workspaceIntentProvider)?.$2,
          AssetType.character,
        );
        expect(
          find.textContaining('katalog character tidak tersedia'),
          findsOneWidget,
        );
        // BUG-4 RED: baris error karakter hanya teks — tanpa affordance retry.
        expect(find.byTooltip('Coba lagi'), findsOneWidget);

        // Retry saat masih gagal: baris tetap jujur, tanpa crash.
        await tester.tap(find.byTooltip('Coba lagi'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Coba lagi'), findsOneWidget);

        // Backend pulih; retry menjalankan ulang katalog lalu recovery
        // memulihkan typed intent yang tersandera tanpa navigasi ulang.
        container.read(characterFailFlag.notifier).state = false;
        await tester.tap(find.byTooltip('Coba lagi'));
        await tester.pumpAndSettle();
        expect(
          container.read(selectionProvider)?.assetType,
          AssetType.character,
        );
        expect(container.read(selectionProvider)?.assetId, 'char-fixture');
      },
    );

    testWidgets(
      'failed creature catalog offers a retry that lets recovery restore the typed intent',
      (tester) async {
        container.read(creatureFailFlag.notifier).state = true;
        await pumpShell(tester);
        container.invalidate(creatureExplorerProvider(projectId));
        await tester.pumpAndSettle();

        await focusAndExpand(tester, find.text('Creatures & Companions'));
        expect(container.read(workspaceIntentProvider)?.$2, AssetType.creature);
        expect(
          find.textContaining('katalog creature tidak tersedia'),
          findsOneWidget,
        );
        // BUG-3 RED: baris error creature tanpa affordance retry.
        expect(find.byTooltip('Coba lagi'), findsOneWidget);

        await tester.tap(find.byTooltip('Coba lagi'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Coba lagi'), findsOneWidget);

        container.read(creatureFailFlag.notifier).state = false;
        await tester.tap(find.byTooltip('Coba lagi'));
        await tester.pumpAndSettle();
        expect(
          container.read(selectionProvider)?.assetType,
          AssetType.creature,
        );
        expect(container.read(selectionProvider)?.assetId, 'creature-fixture');
      },
    );

    testWidgets('healthy catalogs never render a retry button', (tester) async {
      await pumpShell(tester);
      await focusAndExpand(tester, find.text('Characters'));
      expect(container.read(selectionProvider)?.assetId, 'char-fixture');
      expect(find.byTooltip('Coba lagi'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
