import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/assets/application/asset_thumbnail_importer.dart';
import 'package:void_scriptor/features/environment/application/create_environment_service.dart';
import 'package:void_scriptor/features/environment/domain/environment_type.dart';
import 'package:void_scriptor/features/environment/presentation/environment_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Worldbuilding parity (run236): the Environment LOCATION PREVIEW must show
/// the package-owned image bound through assets.thumbnail_path and offer the
/// same Add Image action as wardrobe/weapon/accessory (Choi: "terapkan juga
/// untuk world building dan timeline"). Environments already create real
/// `assets` rows via CreateEnvironmentService, so zero migration is needed.
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

  Future<(ProjectSession, String)> seed(
    WidgetTester tester,
    String name,
  ) async {
    late ProjectSession session;
    late String environmentId;
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('env-thumb-$name-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Env Thumb $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      environmentId =
          await CreateEnvironmentService(
            database: session.database,
            paths: ProjectPaths(rootDirectory: package.root.parent),
          ).create(
            projectId: session.manifest.id,
            name: 'Kutub Es Selatan',
            type: EnvironmentType.landscape,
          );
      final source = File(p.join(root.path, 'map.png'));
      await source.writeAsBytes(pngBytes);
      await AssetThumbnailImporter(
        database: session.database,
        assetsDirectory: session.package.assetsDirectory,
      ).importFromFile(assetId: environmentId, sourcePath: source.path);
    });
    return (session, environmentId);
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    ProjectSession session,
    String environmentId,
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
        child: MaterialApp(
          home: Scaffold(
            body: EnvironmentWorkspaceScreen(environmentId: environmentId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'LOCATION PREVIEW renders the bound package image and import action',
    (tester) async {
      final (session, environmentId) = await seed(tester, 'bound');
      await pumpScreen(tester, session, environmentId);

      expect(find.text('LOCATION PREVIEW'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image).first);
      final bound = (image.image as FileImage).file.path;
      expect(bound, contains('asset_thumbnails'));
      expect(find.text('Add Image'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'LOCATION PREVIEW falls back to the placeholder when nothing is bound',
    (tester) async {
      final (session, environmentId) = await seed(tester, 'bound');
      final stale = await tester.runAsync(
        () async => (await session.database.assetDao.getById(
          environmentId,
        ))!.thumbnailPath!,
      );
      await tester.runAsync(() => File(stale!).delete());
      await pumpScreen(tester, session, environmentId);

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.landscape_outlined), findsWidgets);
      expect(find.text('Add Image'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );
}
