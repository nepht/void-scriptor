// UI journey proof for step 145.27 cross-workspace search: the resolver's
// "Cari di Proyek" entry opens a live-session sheet; typing and selecting a
// character writes a typed SelectionModel into the shared selectionProvider
// (the same provider Explorer writes) and the resolver opens the Character
// workspace; selecting a faction invokes the navigation callback.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/features/bible/application/create_faction_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/global_search_sheet.dart';
import 'package:void_scriptor/features/workspace/application/global_search_launcher.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

void main() {
  testWidgets('global search journey: character select opens typed workspace', (
    tester,
  ) async {
    late final Directory root;
    late final ProjectSession session;
    late final String characterId;

    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('s27-gs-journey-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'GS Journey');
      session = await ProjectSessionManager().open(package);
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: root.parent),
      );
      final character = await repo.createCharacter(name: 'Qowner');
      characterId = character.assetId;
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

    // No selection yet: the overview shows the global search entry.
    expect(find.text('Novel Workspace'), findsOneWidget);
    expect(find.text('Cari di Proyek'), findsOneWidget);

    // Open the sheet and run a live query.
    await tester.tap(find.text('Cari di Proyek'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'qowner');
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();

    // The live character row is selectable.
    expect(find.text('Qowner'), findsOneWidget);
    await tester.tap(find.text('Qowner'));
    await tester.pumpAndSettle();

    // Typed selection resolved into the live Character workspace.
    expect(find.byType(CharacterWorkspaceScreen), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CharacterWorkspaceScreen)),
    );
    expect(container.read(selectionProvider)?.assetId, characterId);
    expect(tester.takeException(), isNull);
  });

  testWidgets('global search journey: faction select invokes nav callback', (
    tester,
  ) async {
    late final Directory root;
    late final ProjectSession session;

    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('s27-gs-journey2-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'GS Journey 2');
      session = await ProjectSessionManager().open(package);
      await const CreateFactionService().create(
        session.database,
        projectId: package.projectId,
        name: 'Polar Council',
      );
    });
    addTearDown(() => root.delete(recursive: true));
    addTearDown(session.close);

    String? selectedFactionId;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _FakeProjectSessionController(session),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showGlobalSearchSheet(
                    context,
                    launcher: GlobalSearchLauncher(database: session.database),
                    projectId: session.manifest.id,
                    onSelectFaction: (id, name) => selectedFactionId = id,
                  ),
                  child: const Text('Open Search'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'polar');
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();
    expect(find.text('Polar Council'), findsOneWidget);
    await tester.tap(find.text('Polar Council'));
    await tester.pumpAndSettle();
    expect(selectedFactionId, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
