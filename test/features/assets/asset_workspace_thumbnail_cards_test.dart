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
import 'package:void_scriptor/features/assets/presentation/widgets/asset_thumbnail_card.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Test double that exposes one pre-opened session through the production
/// AsyncNotifier provider shape.
class _BoundSession extends ProjectSessionController {
  _BoundSession(this.session);

  final ProjectSession session;

  @override
  Future<ProjectSession?> build() async => session;
}

/// Asset thumbnail parity with the character portrait slice (run233): the
/// shared wardrobe/weapon/accessory card must render a package-owned image
/// bound through the [assetThumbnailProvider] (same [AssetThumbnailImporter]
/// the character portrait uses), and offer the import action whenever a
/// session exists. Ground truth = real session + real thumbnail file.
void main() {
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  Future<ProjectSession> seed(
    WidgetTester tester,
    String name, {
    required String imageName,
  }) async {
    late ProjectSession session;
    String thumbnailPath = '';
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('asset-thumb-$name-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Asset Thumb $name');
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
              type: 'wardrobe',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final source = File(p.join(root.path, imageName));
      await source.writeAsBytes(pngBytes);
      thumbnailPath = await AssetThumbnailImporter(
        database: session.database,
        assetsDirectory: session.package.assetsDirectory,
      ).importFromFile(assetId: 'asset-first', sourcePath: source.path);
    });
    assert(thumbnailPath.isNotEmpty);
    return session;
  }

  Future<void> pumpBound(WidgetTester tester, ProjectSession session) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _BoundSession(session)),
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: session.package.root.parent),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 560,
              child: AssetThumbnailCard(
                assetId: 'asset-first',
                title: 'Product View',
                placeholderIcon: Icons.checkroom_outlined,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders the package-owned thumbnail bound to the asset',
    (tester) async {
      final session = await seed(tester, 'bound', imageName: 'coat.png');
      await pumpBound(tester, session);

      final image = tester.widget<Image>(find.byType(Image).last);
      final boundPath = (image.image as FileImage).file.path;
      expect(boundPath, contains('asset_thumbnails'));
      expect(
        boundPath,
        (await session.database.assetDao.getById('asset-first'))!.thumbnailPath,
      );
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'shows the placeholder when the bound file was deleted',
    (tester) async {
      final session = await seed(tester, 'stale', imageName: 'coat2.png');
      final stale = await tester.runAsync(
        () async =>
            (await session.database.assetDao.getById('asset-first'))!
                .thumbnailPath!,
      );
      await tester.runAsync(() => File(stale!).delete());
      await pumpBound(tester, session);

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
      // The honest import path stays available, never a dead icon.
      expect(find.text('Add Image'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );
}
