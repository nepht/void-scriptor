import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/bible/application/bible_timeline_repository.dart';
import 'package:void_scriptor/features/bible/application/timeline_era_image_importer.dart';
import 'package:void_scriptor/features/bible/domain/timeline_era.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

/// run236 (Choi: "terapkan juga untuk world building dan timeline"): era
/// timeline terpilih harus punya kartu gambar nyata dengan aksi import ke
/// namespace paket, bukan ikon mati; dan memilih era dari daftar harus
/// nyata mengubah selection (sebelumnya baris era tidak punya onTap sama
/// sekali).
class _BoundSession extends ProjectSessionController {
  _BoundSession(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

class _RecordingSelection extends SelectionController {
  _RecordingSelection(this._initial);
  final SelectionModel _initial;
  SelectionModel? current;
  @override
  SelectionModel? build() {
    current = _initial;
    return _initial;
  }

  @override
  void select(SelectionModel selection) {
    current = selection;
    state = selection;
  }
}

void main() {
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  Future<ProjectSession> seed(WidgetTester tester, String tag) async {
    late ProjectSession session;
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('era-ui-$tag-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Era UI');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      await BibleTimelineRepository(session.database).saveEra(
        TimelineEraModel(
          id: 'era-screen',
          projectId: session.manifest.id,
          name: 'Age of Echoes',
          orderIndex: 0,
          description: 'First age',
        ),
      );
    });
    return session;
  }

  /// Binds a real package-owned image via the production importer.
  Future<void> bindImage(ProjectSession session, Directory root) async {
    final source = File(p.join(root.path, 'era.png'))
      ..writeAsBytesSync(pngBytes);
    await TimelineEraImageImporter(
      database: session.database,
      assetsDirectory: session.package.assetsDirectory,
    ).importFromFile(eraId: 'era-screen', sourcePath: source.path);
  }

  Future<void> pump(
    WidgetTester tester,
    ProjectSession session,
    SelectionModel selection,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _BoundSession(session)),
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: session.package.root.parent),
          ),
          selectionProvider.overrideWith(() => _RecordingSelection(selection)),
        ],
        child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
      ),
    );
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Timeline').evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
    'selected era renders ERA IMAGE card with the bound package image and import action',
    (tester) async {
      final session = await seed(tester, 'card');
      await tester.runAsync(() => bindImage(session, session.package.root));
      await pump(
        tester,
        session,
        SelectionModel(
          assetId: 'era-screen',
          assetType: AssetType.timeline,
          projectId: session.manifest.id,
        ),
      );

      expect(find.text('ERA IMAGE'), findsOneWidget);
      // Body worldbuilding hanya me-render satu Image.file (kartu era ini),
      // jadi finder langsung jujur tanpa bergantung pada tipe VoidCard.
      final image = tester.widget<Image>(find.byType(Image).first);
      expect((image.image as FileImage).file.path, contains('era_images'));
      expect(find.text('Add Image'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'era row in the Timeline section carries a real onTap that selects the era',
    (tester) async {
      final session = await seed(tester, 'row');
      final controller = _RecordingSelection(
        SelectionModel(
          assetId: 'novel-1',
          assetType: AssetType.story,
          projectId: session.manifest.id,
        ),
      );
      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _BoundSession(session)),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: session.package.root.parent),
            ),
            selectionProvider.overrideWith(() => controller),
          ],
          child: const MaterialApp(home: Scaffold(body: WorldbuildingBody())),
        ),
      );
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Age of Echoes').evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();
      expect(find.text('Age of Echoes'), findsWidgets);

      await tester.tap(find.text('Age of Echoes').first);
      await tester.pumpAndSettle();
      expect(controller.current?.assetId, 'era-screen');
      expect(controller.current?.assetType, AssetType.timeline);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );
}
