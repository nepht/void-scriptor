// Regression test for void-scriptor-hunt-20260910 BUG-02 (Referee REAL BUG
// Medium): a faction hit in the global search sheet never navigates because
// neither production callsite wires `onSelectFaction` - the sheet pops and the
// faction callback is a no-op. Production contract: selecting a faction hit
// must write a typed faction SelectionModel into the shared selectionProvider
// (the same production path Explorer and the resolver's faction branch use),
// and the resolver must then resolve it into WorldbuildingBody. Also covers
// null-type rows generally: rows whose storage type cannot map to AssetType
// (e.g. legacy hair_variant) must not hit the faction callback either - the
// launcher excludes them from results per the documented search contract.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/features/bible/application/create_faction_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/application/global_search_launcher.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

void main() {
  testWidgets(
    'BUG-02: faction hit in production resolver search navigates to faction '
    'workspace without any explicit callback',
    (tester) async {
      late final Directory root;
      late final ProjectSession session;
      late final String factionId;

      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('gs-bug02-');
        final package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'BUG02 Faction Nav');
        session = await ProjectSessionManager().open(package);
        final faction = await const CreateFactionService().create(
          session.database,
          projectId: package.projectId,
          name: 'Polar Council',
        );
        factionId = faction.assetId;
      });
      addTearDown(() => root.delete(recursive: true));
      addTearDown(session.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(
              () => _FakeProjectSessionController(session),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
        ),
      );
      await tester.pumpAndSettle();

      // Open the production global search entry from the overview.
      expect(find.text('Cari di Proyek'), findsOneWidget);
      await tester.tap(find.text('Cari di Proyek'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'polar');
      await tester.tap(find.text('Cari'));
      await tester.pumpAndSettle();

      // The faction row is listed and selectable.
      expect(find.text('Polar Council'), findsOneWidget);
      await tester.tap(find.text('Polar Council'));
      await tester.pumpAndSettle();

      // Typed faction selection must be written to the shared provider and
      // resolved into the Worldbuilding body (faction branch), not dropped.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkspaceResolver)),
      );
      final selection = container.read(selectionProvider);
      expect(selection?.assetId, factionId);
      expect(selection?.assetType, AssetType.faction);
      expect(selection?.projectId, session.manifest.id);
      expect(find.byType(WorldbuildingBody), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'BUG-02: unmappable storage rows (hair_variant) are excluded from results '
    'instead of dead-ending on the faction callback',
    () async {
      final root = await Directory.systemTemp.createTemp('gs-bug02b-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'BUG02 Hair Variant');
      final session = await ProjectSessionManager().open(package);
      var sessionClosed = false;
      addTearDown(() async {
        if (!sessionClosed) await session.close();
      });
      final db = session.database;
      final projectId = package.projectId;

      await db.assetDao.createStandaloneAsset(
        id: 'hair-1',
        projectId: projectId,
        name: 'Silver Braid',
        type: 'hair_variant',
        now: DateTime.fromMillisecondsSinceEpoch(0),
      );
      await const CreateFactionService().create(
        db,
        projectId: projectId,
        name: 'Polar Council',
      );

      final launcher = GlobalSearchLauncher(database: db);

      final hits = await launcher.search('silver', projectId: projectId);
      expect(hits, isEmpty, reason: 'hair_variant rows have no typed route');
    },
  );
}
