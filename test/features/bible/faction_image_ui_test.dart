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
import 'package:void_scriptor/features/bible/application/create_faction_service.dart';
import 'package:void_scriptor/features/bible/application/faction_image_importer.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

/// run236 (Choi: "terapkan juga untuk world building dan timeline"): faksi
/// terpilih pada Worldbuilding body harus punya kartu gambar nyata dengan
/// import ke namespace paket — bukan diam tanpa visual sama sekali.
class _BoundSession extends ProjectSessionController {
  _BoundSession(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

class _FixedSelection extends SelectionController {
  _FixedSelection(this._initial);
  final SelectionModel _initial;
  @override
  SelectionModel? build() => _initial;
}

void main() {
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  testWidgets(
    'selected faction renders FACTION IMAGE card with the bound package image and import action',
    (tester) async {
      late ProjectSession session;
      late String factionId;
      late Directory root;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('faction-ui-');
        // Registered FIRST so the LIFO teardown runs it LAST — after the
        // database close below, releasing the sqlite handle (errno 32).
        addTearDown(() async {
          try {
            await root.delete(recursive: true);
          } catch (_) {}
        });
        final package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Faction Image');
        session = await ProjectSessionManager().open(package);
        addTearDown(session.database.close);
        final created = await const CreateFactionService().create(
          session.database,
          projectId: session.manifest.id,
          name: 'Guild of Echoes',
        );
        factionId = created.assetId;
        final source = File(p.join(root.path, 'sigil.png'))
          ..writeAsBytesSync(pngBytes);
        await FactionImageImporter(
          database: session.database,
          assetsDirectory: session.package.assetsDirectory,
        ).importFromFile(assetId: factionId, sourcePath: source.path);
      });

      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _BoundSession(session)),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: session.package.root.parent),
            ),
            selectionProvider.overrideWith(
              () => _FixedSelection(
                SelectionModel(
                  assetId: factionId,
                  assetType: AssetType.faction,
                  projectId: session.manifest.id,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
        ),
      );
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('FACTION IMAGE').evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();

      expect(find.text('FACTION IMAGE'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image).first);
      expect((image.image as FileImage).file.path, contains('faction_images'));
      expect(find.text('Add Image'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );
}
