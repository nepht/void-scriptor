import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/domain/character_scope_layers.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// Step 145.26 Character Scope Layers - Workspace source-scope display slice.
/// The workspace must reveal WHICH scope layer each effective identity field
/// currently resolves from, so overrides are never silent.
void main() {
  Future<(ProjectPackage, ProjectSession, String)> seed(
    WidgetTester tester,
    String name, {
    CharacterScopeState? canonical,
    CharacterScopeState? novel,
  }) async {
    // Real IO (package create, session open, drift writes) must run in
    // tester.runAsync: the fake-async zone does not process real IO.
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    late String characterId;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('scope-ui-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Scope UI $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      final character = await repo.createCharacter(name: 'Qowner');
      characterId = character.assetId;
      if (canonical != null) {
        await repo.updateScopeState(
          character.assetId,
          CharacterScopeLayer.canonical,
          canonical,
        );
      }
      if (novel != null) {
        await repo.updateScopeState(
          character.assetId,
          CharacterScopeLayer.novelSpecific,
          novel,
        );
      }
    });
    return (package, session, characterId);
  }

  Future<void> pumpWorkspace(
    WidgetTester tester,
    ProjectPackage package,
    ProjectSession session,
    String characterId, {
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
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: CharacterWorkspaceScreen(characterId: characterId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'workspace reveals the source scope of effective identity fields',
    (tester) async {
      final (package, session, id) = await seed(
        tester,
        'desktop',
        canonical: const CharacterScopeState(identity: 'Pemelihara Kekosongan'),
        novel: const CharacterScopeState(
          role: 'antagonis',
          currentStatus: 'Dead',
        ),
      );
      await pumpWorkspace(tester, package, session, id);

      // The scope status card is present.
      expect(find.text('Character Scope'), findsOneWidget);

      // Each present layer is revealed as a badge.
      expect(find.text('Canonical'), findsOneWidget);
      expect(find.text('Novel-Specific'), findsOneWidget);
      // The universe/timeline layer has no rows -> not claimed.
      expect(find.text('Universe-Timeline'), findsNothing);

      // Effective-field source is explicit: identity resolves from Canonical,
      // role and current status resolve from Novel-Specific.
      expect(
        find.byWidgetPredicate((w) {
          if (w is! Text) return false;
          final t = w.data ?? '';
          return t.contains('Identity:') && t.contains('(from Canonical)');
        }),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) {
          if (w is! Text) return false;
          final t = w.data ?? '';
          return t.contains('Role:') && t.contains('(from Novel-Specific)');
        }),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) {
          if (w is! Text) return false;
          final t = w.data ?? '';
          return t.contains('Status:') && t.contains('(from Novel-Specific)');
        }),
        findsOneWidget,
      );
    },
  );

  testWidgets('scope status card renders at narrow width without overflow', (
    tester,
  ) async {
    final (package, session, id) = await seed(
      tester,
      'narrow',
      canonical: const CharacterScopeState(identity: 'Pemelihara Kekosongan'),
      novel: const CharacterScopeState(
        role: 'protagonis',
        currentLocation: 'Kutub Utara',
      ),
    );
    await pumpWorkspace(
      tester,
      package,
      session,
      id,
      size: const Size(390, 800),
    );

    // Effective source rows visible on narrow layout too.
    expect(
      find.byWidgetPredicate((w) {
        if (w is! Text) return false;
        final t = w.data ?? '';
        return t.contains('Identity:') && t.contains('(from Canonical)');
      }),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((w) {
        if (w is! Text) return false;
        final t = w.data ?? '';
        return t.contains('Role:') && t.contains('(from Novel-Specific)');
      }),
      findsOneWidget,
    );

    // No RenderFlex overflow diagnostics.
    expect(tester.takeException(), isNull);
  });
}
