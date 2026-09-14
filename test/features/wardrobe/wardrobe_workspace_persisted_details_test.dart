import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/wardrobe/application/create_wardrobe_service.dart';
import 'package:void_scriptor/features/wardrobe/data/wardrobe_repository_impl.dart';
import 'package:void_scriptor/features/wardrobe/domain/wardrobe_model.dart';
import 'package:void_scriptor/features/wardrobe/domain/wardrobe_workspace_data.dart';
import 'package:void_scriptor/features/wardrobe/presentation/wardrobe_workspace_controller.dart';
import 'package:void_scriptor/features/wardrobe/presentation/wardrobe_workspace_screen.dart';

/// vs-hunt-20260914-wardrobe-weapon WBUG-5 (Referee: REAL BUG, Medium).
/// The production wardrobe workspace rendered const sample chips
/// ('Outer Coat', 'Void Black', 'Winter', ...) regardless of persisted
/// child rows. Fix mirrors the ENV-BUG-002 precedent (run271): cards are
/// data-driven from `WardrobeWorkspaceData` resolved through the repository,
/// and an empty database shows honest empty states instead of fake data.
void main() {
  const wardrobeId = 'wardrobe-1';

  const model = WardrobeModel(
    assetId: wardrobeId,
    projectId: 'project-1',
    name: 'Mantel Bulan Abu',
    category: 'Jubah Musim Hujan',
    primaryMaterial: 'Wool Berlapis Lilin',
    fabric: 'Kain Nafas',
    fit: 'Longgar Lapis',
    style: 'Petualang Sunyi',
  );

  const populated = WardrobeWorkspaceData(
    components: [
      WardrobeComponentInfo(
        name: 'Kerah Perak',
        componentType: 'collar',
        material: 'Perak Tempa',
        fabric: 'Lapis Suede',
      ),
      WardrobeComponentInfo(name: 'Ikat Pinggang Tenun', componentType: 'belt'),
    ],
    colors: [
      WardrobeColorInfo(name: 'Abu Bulan', hexValue: '#8899AA'),
      WardrobeColorInfo(name: 'Hitam Void', hexValue: '#050507'),
    ],
    variants: [
      WardrobeVariantInfo(name: 'Normal', isDefault: true),
      WardrobeVariantInfo(name: 'Edisi Basah', isDefault: false),
    ],
    references: [WardrobeReferenceInfo(referenceType: 'depan')],
  );

  Future<void> pumpWorkspace(
    WidgetTester tester, {
    required WardrobeWorkspaceData data,
    double width = 1280,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wardrobeWorkspaceProvider(
            wardrobeId,
          ).overrideWith((ref) async => model),
          wardrobeWorkspaceDetailsProvider(
            wardrobeId,
          ).overrideWith((ref) async => data),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WardrobeWorkspaceScreen(wardrobeId: wardrobeId)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('components/variants/references render persisted rows', (
    tester,
  ) async {
    await pumpWorkspace(tester, data: populated);
    expect(find.text('Kerah Perak'), findsOneWidget);
    expect(find.text('Ikat Pinggang Tenun'), findsOneWidget);
    expect(find.text('Edisi Basah'), findsOneWidget);
    expect(find.text('depan'), findsOneWidget);
    // The material card must draw from persisted component materials,
    // never the old fake 'Leather'/'Synthetic' chips.
    expect(find.text('Perak Tempa'), findsOneWidget);
    expect(find.text('Leather'), findsNothing);
    expect(find.text('Synthetic'), findsNothing);
    expect(find.text('Technical Fabric'), findsNothing);
    // The old fake sample chips must be gone.
    expect(find.text('Outer Coat'), findsNothing);
    expect(find.text('Inner Shirt'), findsNothing);
    expect(find.text('Winter'), findsNothing);
    expect(find.text('Damaged'), findsNothing);
    expect(
      find.textContaining('Front, Back, Side'),
      findsNothing,
      reason: 'references line was a hardcoded stub',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('color palette renders persisted swatches, not fake defaults', (
    tester,
  ) async {
    await pumpWorkspace(tester, data: populated);
    expect(find.text('Abu Bulan'), findsOneWidget);
    expect(find.text('Hitam Void'), findsOneWidget);
    expect(find.text('Void Violet'), findsNothing);
    expect(find.text('Electric Blue'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('specification card shows persisted scalars, dash when empty', (
    tester,
  ) async {
    await pumpWorkspace(tester, data: populated);
    expect(find.text('Jubah Musim Hujan'), findsWidgets);
    expect(find.text('Wool Berlapis Lilin'), findsOneWidget);
    expect(find.text('Kain Nafas'), findsOneWidget);
    expect(find.text('Longgar Lapis'), findsOneWidget);
    expect(find.text('Petualang Sunyi'), findsOneWidget);
    expect(find.text('Outerwear'), findsNothing);
    expect(find.text('Technical Synthetic'), findsNothing);
    expect(find.text('Waterproof Fabric'), findsNothing);
    expect(find.text('Oversized'), findsNothing);
    expect(find.text('Futuristic Tactical'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty database shows honest empty states, no fake rows', (
    tester,
  ) async {
    await pumpWorkspace(tester, data: const WardrobeWorkspaceData());
    expect(find.text('Belum ada komponen tersimpan.'), findsOneWidget);
    expect(find.text('Belum ada warna tersimpan.'), findsOneWidget);
    expect(find.text('Belum ada varian tersimpan.'), findsOneWidget);
    expect(find.text('Belum ada referensi tersimpan.'), findsOneWidget);
    expect(find.text('Outer Coat'), findsNothing);
    expect(find.text('Normal'), findsNothing);
    expect(find.text('Void Black'), findsNothing);
    expect(find.text('Leather'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow layout stays overflow-free with populated data', (
    tester,
  ) async {
    await pumpWorkspace(tester, data: populated, width: 390);
    expect(find.text('Kerah Perak'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'repository maps persisted child rows through real Drift tables',
    () async {
      final root = await Directory.systemTemp.createTemp('wbug5-repo-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final databasePath = (await paths.database('project-1')).path;
      await ProjectDatabaseService().create(databasePath);
      final db = await ProjectDatabaseService().open(databasePath);
      addTearDown(db.close);

      final id = await CreateWardrobeService(
        database: db,
        paths: paths,
      ).create(projectId: 'project-1', name: 'Mantel Uji');

      await db
          .into(db.wardrobeComponents)
          .insert(
            WardrobeComponentsCompanion.insert(
              id: 'comp-1',
              wardrobeId: id,
              name: 'Kancing Tulang',
              componentType: 'button',
            ),
          );
      await db
          .into(db.wardrobeColors)
          .insert(
            WardrobeColorsCompanion.insert(
              id: 'color-1',
              wardrobeId: id,
              name: 'Coklat Temaram',
              hexValue: '#4A3728',
            ),
          );

      final data = await WardrobeRepositoryImpl(
        database: db,
        projectId: 'project-1',
      ).getWorkspaceData(id);

      expect(data.components.map((c) => c.name), ['Kancing Tulang']);
      expect(data.colors.map((c) => c.name), ['Coklat Temaram']);
      expect(data.colors.single.hexValue, '#4A3728');
      // CreateWardrobeService seeds the default 'Normal' variant in the DB:
      // the workspace must show that persisted row, not four fake chips.
      expect(data.variants.map((v) => v.name), ['Normal']);
      expect(data.references, isEmpty);
      await db.close();
    },
  );
}
