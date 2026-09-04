import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/bible/application/create_faction_service.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

/// 145.27 prioritas #3: memisahkan body workspace per intent.
///
/// Kontrak: intent Worldbuilding (dan tipe worldbuilding lain) tidak boleh
/// jatuh ke fallback "Novel Workspace"; body harus menampilkan surface
/// worldbuilding nyata dengan data proyek.
void main() {
  Future<Directory> makeTemp(WidgetTester tester, String prefix) async {
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp(prefix),
    );
    return dir!;
  }

  Widget harness(
    ProjectSession session,
    Directory temp, {
    SelectionModel? selection,
  }) => ProviderScope(
    overrides: [
      projectSessionProvider.overrideWith(() => _FixedSession(session)),
      projectPathsProvider.overrideWithValue(
        ProjectPaths(rootDirectory: Directory('${temp.path}/data')),
      ),
      if (selection != null)
        selectionProvider.overrideWith(() => _FixedSelection(selection)),
    ],
    child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
  );

  testWidgets(
    'worldbuilding intent without selection opens worldbuilding body, not Novel fallback',
    (tester) async {
      final temp = await makeTemp(tester, 'wb-intent-');
      addTearDown(() {
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      });
      final session = await tester.runAsync(() async {
        final package = await ProjectPackageService(
          rootDirectory: Directory('${temp.path}/pkg'),
        ).create(name: 'Worldbuilding Intent');
        return ProjectSessionManager().open(package);
      });
      final liveSession = session!;
      addTearDown(liveSession.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(
              () => _FixedSession(liveSession),
            ),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: Directory('${temp.path}/data')),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => Column(
                  children: [
                    TextButton(
                      onPressed: () =>
                          focusExplorerAsset(ref, AssetType.faction),
                      child: const Text('Factions'),
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

      await tester.tap(find.text('Factions'));
      await tester.pumpAndSettle();

      // Tidak boleh jatuh ke fallback Novel.
      expect(find.text('Novel Workspace'), findsNothing);
      expect(find.text('Create Novel'), findsNothing);
      // Body worldbuilding nyata: aksi create + surface datanya ada.
      expect(find.text('Create Faction'), findsOneWidget);
      expect(find.byType(WorldbuildingBody), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selected faction renders worldbuilding body with project data, not Novel fallback',
    (tester) async {
      final temp = await makeTemp(tester, 'wb-faction-');
      addTearDown(() {
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      });
      final session = await tester.runAsync(() async {
        final package = await ProjectPackageService(
          rootDirectory: Directory('${temp.path}/pkg'),
        ).create(name: 'Worldbuilding Faction');
        return ProjectSessionManager().open(package);
      });
      final liveSession = session!;
      addTearDown(liveSession.close);

      final factionId = await tester.runAsync(
        () => const CreateFactionService().create(
          liveSession.database,
          projectId: liveSession.manifest.id,
          name: 'Guild of Echoes',
          ideology: 'Memory preservation',
        ),
      );

      await tester.pumpWidget(
        harness(
          liveSession,
          temp,
          selection: SelectionModel(
            assetId: factionId!.assetId,
            assetType: AssetType.faction,
            projectId: liveSession.manifest.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Data dimuat via IO async nyata; tunggu sampai katalog terlihat.
      await tester.runAsync(() async {
        for (var i = 0; i < 50; i++) {
          if (find.text('Guild of Echoes').evaluate().isNotEmpty) return;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('Novel Workspace'), findsNothing);
      expect(find.text('Create Novel'), findsNothing);
      // Nama faksi tampil di section Factions dan sekali lagi di katalog lore.
      expect(find.text('Guild of Echoes'), findsNWidgets(2));
      expect(find.byType(WorldbuildingBody), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this._session);

  final ProjectSession _session;

  @override
  Future<ProjectSession?> build() async => _session;
}

class _FixedSelection extends SelectionController {
  _FixedSelection(this._selection);

  final SelectionModel _selection;

  @override
  SelectionModel? build() => _selection;
}
