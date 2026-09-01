import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/bible/application/create_faction_service.dart';
import 'package:void_scriptor/features/bible/application/faction_repository.dart';
import 'package:void_scriptor/features/bible/presentation/project_bible_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;

  @override
  Future<ProjectSession?> build() async => session;
}

/// Step 145.27 Core Worldbuilding Reduction - Factions editor UI slice.
/// The Project Bible workspace must expose a Factions section that lists
/// live project factions, allows creating new ones through a dialog, and
/// surfaces duplicate-name rejection without crashing.
void main() {
  Future<ProjectSession> seed(WidgetTester tester, String name) async {
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    // Real IO (package create, session open, drift writes) must run in
    // tester.runAsync: the fake-async zone does not process real IO.
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('faction-ui-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Faction UI $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
    });
    return session;
  }

  Future<void> pumpBible(
    WidgetTester tester,
    ProjectSession session, {
    Size size = const Size(1280, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _FakeProjectSessionController(session),
          ),
        ],
        child: const MaterialApp(home: ProjectBibleWorkspaceScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Factions section lists seeded factions from the live session', (
    tester,
  ) async {
    final session = await seed(tester, 'list');
    await tester.runAsync(() async {
      await const CreateFactionService().create(
        session.database,
        projectId: session.manifest.id,
        name: 'Clan Kokuen',
        ideology: 'Preserve the Void',
        status: 'active',
        headquarters: 'Mountain Region',
      );
    });
    await pumpBible(tester, session);

    expect(find.widgetWithText(ChoiceChip, 'Factions'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Factions'));
    await tester.pumpAndSettle();

    expect(find.text('Clan Kokuen'), findsOneWidget);
    // Faction details render as a combined detail line inside the card.
    expect(find.textContaining('Preserve the Void'), findsOneWidget);
    expect(find.textContaining('Mountain Region'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a faction through the dialog persists and lists it', (
    tester,
  ) async {
    final session = await seed(tester, 'create');
    await pumpBible(tester, session);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Factions'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada faksi'), findsOneWidget);

    await tester.tap(find.text('Faksi Baru'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('faction_name')),
      'Void Legion',
    );
    await tester.enterText(
      find.byKey(const ValueKey('faction_ideology')),
      'Order over chaos',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Void Legion'), findsOneWidget);
    expect(find.textContaining('Order over chaos'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Persisted at the repository level after the dialog create.
    await tester.runAsync(() async {
      final factions = await FactionRepository(
        session.database,
      ).listForProject(session.manifest.id);
      expect(factions.map((f) => f.name), contains('Void Legion'));
    });
  });

  testWidgets('duplicate faction name is rejected with a visible error', (
    tester,
  ) async {
    final session = await seed(tester, 'dup');
    await tester.runAsync(() async {
      await const CreateFactionService().create(
        session.database,
        projectId: session.manifest.id,
        name: 'Alpha',
      );
    });
    await pumpBible(tester, session);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Factions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Faksi Baru'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('faction_name')), 'Alpha');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.textContaining('already exists'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Project Bible with Factions renders without overflow on narrow',
    (tester) async {
      final session = await seed(tester, 'narrow');
      await pumpBible(tester, session, size: const Size(390, 844));

      expect(find.text('PROJECT BIBLE'), findsOneWidget);
      // Narrow viewport uses a section dropdown; the Factions card itself is
      // always rendered below the overview grid.
      expect(find.text('FACTIONS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
