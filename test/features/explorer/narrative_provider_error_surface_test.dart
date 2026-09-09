import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Regression: `void-scriptor-hunt-20260909` BUG-06 consumer layer (Referee
/// REAL BUG, Medium). The explorer watched `explorerNarrativeAssignmentsProvider`
/// through `valueOrNull ?? const []`, so a provider error (realistic trigger:
/// a version-skewed portable import) was invisible AND — with a narrative
/// filter active — silently collapsed the character list, because
/// `own.any(...)` over an empty assignment list matches nobody.
///
/// Contract proven here:
/// 1. The provider error surfaces as a visible tile, never a silent swallow.
/// 2. An active filter fails OPEN to the full character list while the
///    narrative data is unavailable (keeping data visible beats silently
///    hiding it; the error tile explains the degraded mode).
void main() {
  Future<ProjectSession> createSession() async {
    final root = await Directory.systemTemp.createTemp('narr-swallow-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Swallow project');
    return ProjectSessionManager().open(package);
  }

  Future<void> seedCharacter(
    ProjectSession session, {
    required String id,
    required String name,
  }) async {
    final db = session.database;
    final now = DateTime.now();
    await db
        .into(db.assets)
        .insert(
          AssetsCompanion.insert(
            id: id,
            projectId: session.manifest.id,
            name: name,
            type: 'character',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            assetId: id,
            projectId: session.manifest.id,
            displayName: name,
          ),
        );
  }

  ProviderScope failingScope(ProjectSession session) => ProviderScope(
    overrides: [
      projectSessionProvider.overrideWith(() => _FixedSession(session)),
      projectPathsProvider.overrideWithValue(
        ProjectPaths(rootDirectory: Directory.systemTemp),
      ),
      explorerNarrativeAssignmentsProvider.overrideWith(
        (ref) async => throw StateError('narrative data unavailable'),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SizedBox(width: 320, child: ExplorerPanel())),
    ),
  );

  Finder characterTile(String name) => find.widgetWithText(ListTile, name);

  Future<void> applyProtagonistFilter(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Filter characters by narrative role'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All roles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Protagonist').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
  }

  testWidgets('provider error surfaces as a visible tile, not a swallow', (
    tester,
  ) async {
    final session =
        (await tester.runAsync<ProjectSession>(createSession)) ??
        (throw StateError('temporary session unavailable'));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(() => session.close());
    });
    await tester.runAsync(() async {
      await seedCharacter(session, id: 'c-hero', name: 'Alira');
      await seedCharacter(session, id: 'c-side', name: 'Bravant');
    });

    await tester.pumpWidget(failingScope(session));
    await tester.pumpAndSettle();

    expect(characterTile('Alira'), findsOneWidget);
    // RED (pre-patch): the provider error is invisible anywhere in the
    // explorer — `valueOrNull ?? const []` swallows it.
    expect(
      find.textContaining('Narrative data unavailable'),
      findsOneWidget,
      reason: 'a failed narrative-assignments provider must be visible',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'active filter fails open to the full list when narrative data fails',
    (tester) async {
      final session =
          (await tester.runAsync<ProjectSession>(createSession)) ??
          (throw StateError('temporary session unavailable'));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(() => session.close());
      });
      await tester.runAsync(() async {
        await seedCharacter(session, id: 'c-hero', name: 'Alira');
        await seedCharacter(session, id: 'c-side', name: 'Bravant');
      });

      await tester.pumpWidget(failingScope(session));
      await tester.pumpAndSettle();

      await applyProtagonistFilter(tester);

      // RED (pre-patch): filter active + provider error -> empty list.
      expect(
        characterTile('Alira'),
        findsOneWidget,
        reason: 'unavailable narrative data must not empty the list',
      );
      expect(characterTile('Bravant'), findsOneWidget);
      expect(find.textContaining('Narrative data unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('healthy provider with no assignments still filters normally', (
    tester,
  ) async {
    // Positive control for the fail-open rule: with a healthy EMPTY
    // assignment list the filter must genuinely narrow (no character has
    // the protagonist role), proving fail-open is scoped to error state.
    final session =
        (await tester.runAsync<ProjectSession>(createSession)) ??
        (throw StateError('temporary session unavailable'));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(() => session.close());
    });
    await tester.runAsync(() async {
      await seedCharacter(session, id: 'c-hero', name: 'Alira');
      await seedCharacter(session, id: 'c-side', name: 'Bravant');
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _FixedSession(session)),
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: Directory.systemTemp),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SizedBox(width: 320, child: ExplorerPanel())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await applyProtagonistFilter(tester);

    expect(characterTile('Alira'), findsNothing);
    expect(characterTile('Bravant'), findsNothing);
    expect(
      find.textContaining('Narrative data unavailable'),
      findsNothing,
      reason: 'a healthy empty list must not fake an error state',
    );
    final anyAssignment = await tester.runAsync(
      () async => session.database
          .select(session.database.characterNarrativeAssignments)
          .getSingleOrNull(),
    );
    expect(anyAssignment, isNull);
  });
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}
