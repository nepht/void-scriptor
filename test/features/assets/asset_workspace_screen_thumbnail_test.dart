import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/application/asset_thumbnail_importer.dart';
import 'package:void_scriptor/features/assets/presentation/supporting_asset_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/wardrobe/presentation/wardrobe_workspace_screen.dart';
import 'package:void_scriptor/features/weapon/presentation/weapon_workspace_screen.dart';

/// Screen wiring parity (run233 follow-up, Choirudin: "berlaku juga untuk
/// accessory wardrobe dan item"): the wardrobe Product View and weapon
/// Technical View sections must surface the SAME package-owned thumbnail the
/// character portrait uses whenever a project session exists. Real session +
/// real imported image; Windows-only like the other session-backed tests.
class _BoundSession extends ProjectSessionController {
  _BoundSession(this.session);

  final ProjectSession session;

  @override
  Future<ProjectSession?> build() async => session;
}

void main() {
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  Future<ProjectSession> seed(
    WidgetTester tester,
    String name,
    String assetType,
  ) async {
    late ProjectSession session;
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('ws-thumb-$name-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'WS Thumb $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final now = DateTime.now();
      await session.database
          .into(session.database.assets)
          .insert(
            AssetsCompanion.insert(
              id: 'asset-first',
              projectId: session.manifest.id,
              name: 'Void Coat',
              type: assetType,
              createdAt: now,
              updatedAt: now,
            ),
          );
      final source = File(p.join(root.path, 'design.png'));
      await source.writeAsBytes(pngBytes);
      await AssetThumbnailImporter(
        database: session.database,
        assetsDirectory: session.package.assetsDirectory,
      ).importFromFile(assetId: 'asset-first', sourcePath: source.path);
    });
    return session;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    ProjectSession session,
    Widget screen,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _BoundSession(session)),
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: session.package.root.parent),
          ),
        ],
        child: MaterialApp(home: Scaffold(body: screen)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'wardrobe Product View section renders the bound package image and import action',
    (tester) async {
      final session = await seed(tester, 'wardrobe', 'wardrobe');
      await pumpScreen(
        tester,
        session,
        const WardrobeWorkspaceScreen(wardrobeId: 'asset-first'),
      );

      expect(find.text('Product View'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image).first);
      expect(
        (image.image as FileImage).file.path,
        contains('asset_thumbnails'),
      );
      expect(find.text('Add Image'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'weapon Technical View section renders the bound package image and import action',
    (tester) async {
      final session = await seed(tester, 'weapon', 'weapon');
      await pumpScreen(
        tester,
        session,
        const WeaponWorkspaceScreen(weaponId: 'asset-first'),
      );

      expect(find.text('Technical View'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image).first);
      expect(
        (image.image as FileImage).file.path,
        contains('asset_thumbnails'),
      );
      expect(find.text('Add Image'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'supporting asset (accessory) Design View renders the bound package image and import action',
    (tester) async {
      final session = await seed(tester, 'accessory', 'accessory');
      await pumpScreen(
        tester,
        session,
        const SupportingAssetWorkspaceScreen(assetId: 'asset-first'),
      );

      expect(find.text('Design View'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image).first);
      expect(
        (image.image as FileImage).file.path,
        contains('asset_thumbnails'),
      );
      expect(find.text('Add Image'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );
}
