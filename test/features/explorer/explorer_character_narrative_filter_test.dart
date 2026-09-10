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
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

/// Backlog `docs/backlog/character-roles-support.json` phase_one UI item:
/// "Filter character list by role, importance and POV with a clear reset
/// action".
///
/// Drives the real Explorer panel against a real temporary project session:
/// characters with distinct assignments prove role/importance/POV filtering
/// plus the reset action; a character without any assignment stays visible
/// only when the filter is inactive or matches unspecified.
void main() {
  Future<ProjectSession> createSession() async {
    final root = await Directory.systemTemp.createTemp('narr-filter-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Filter project');
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

  NarrativeAssignmentRepository repoOf(ProjectSession session) =>
      NarrativeAssignmentRepository(
        database: session.database,
        projectId: session.manifest.id,
      );

  Finder characterTile(String name) => find.widgetWithText(ListTile, name);

  Future<void> openFilterMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Filter characters by narrative role'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'role, importance and POV filters narrow the list and reset restores it',
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
        await seedCharacter(session, id: 'c-protag', name: 'Alira');
        await seedCharacter(session, id: 'c-antag', name: 'Bravant');
        await seedCharacter(session, id: 'c-minor', name: 'Cenna');
        await seedCharacter(session, id: 'c-plain', name: 'Doran');
        final repo = repoOf(session);
        await repo.saveAssignment(
          NarrativeAssignment(
            novelWorkspaceId: 'novel-1',
            characterId: 'c-protag',
            roles: {NarrativeRole.protagonist},
            importance: NarrativeImportance.major,
            pov: NarrativePov.yes,
          ),
        );
        await repo.saveAssignment(
          NarrativeAssignment(
            novelWorkspaceId: 'novel-1',
            characterId: 'c-antag',
            roles: {NarrativeRole.antagonist},
            importance: NarrativeImportance.major,
            pov: NarrativePov.no,
          ),
        );
        await repo.saveAssignment(
          NarrativeAssignment(
            novelWorkspaceId: 'novel-1',
            characterId: 'c-minor',
            roles: {NarrativeRole.supporting},
            importance: NarrativeImportance.minor,
          ),
        );
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

      List<String> visibleNames() => [
        'Alira',
        'Bravant',
        'Cenna',
        'Doran',
      ].where((name) => characterTile(name).evaluate().isNotEmpty).toList();

      expect(visibleNames(), ['Alira', 'Bravant', 'Cenna', 'Doran']);

      // Role filter: open the dialog, pick the role from the dropdown, apply.
      await openFilterMenu(tester);
      await tester.tap(find.text('All roles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Protagonist').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(visibleNames(), ['Alira']);

      // Reset clears the role filter and restores the full list.
      await openFilterMenu(tester);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(visibleNames(), ['Alira', 'Bravant', 'Cenna', 'Doran']);

      // Importance filter: majors only (Alira + Bravant).
      await openFilterMenu(tester);
      await tester.tap(find.text('All importance levels'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Major').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(visibleNames(), ['Alira', 'Bravant']);

      // Reset, then POV filter: only POV carriers remain.
      await openFilterMenu(tester);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      await openFilterMenu(tester);
      await tester.tap(find.text('All POV values'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(visibleNames(), ['Alira']);

      // Final reset restores the full list.
      await openFilterMenu(tester);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(visibleNames(), ['Alira', 'Bravant', 'Cenna', 'Doran']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('filter dialog holds enlarged text scale without overflow', (
    tester,
  ) async {
    // Accessibility contract: the dialog must reflow at 2.0 text scale
    // (antislop-human R-35) instead of clipping or overflowing.
    final session =
        (await tester.runAsync<ProjectSession>(createSession)) ??
        (throw StateError('temporary session unavailable'));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(() => session.close());
    });
    await tester.runAsync(() async {
      await seedCharacter(session, id: 'c-scale', name: 'Scaled Character');
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
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: MediaQuery(
                // Repo-established pattern (recent_projects_test.dart):
                // enlarged text via MediaQuery textScaler, 2.0 = max scale.
                data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
                child: ExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openFilterMenu(tester);
    await tester.pumpAndSettle();

    expect(find.text('Filter Characters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dismissing the filter dialog keeps the active filter; Reset still clears',
    (tester) async {
      // Hunt run171 BUG-11 (Referee: REAL BUG, Low): showDialog<bool> yields
      // null on barrier dismissal, and the old `else` branch treated that
      // exactly like an explicit Reset — an accidental outside-tap silently
      // discarded the user's active filter. Contract now: only an explicit
      // result mutates state (true -> apply, false -> reset); null is a
      // no-op that leaves both the applied filter and the session intact.
      final session =
          (await tester.runAsync<ProjectSession>(createSession)) ??
          (throw StateError('temporary session unavailable'));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(() => session.close());
      });
      await tester.runAsync(() async {
        await seedCharacter(session, id: 'c-protag', name: 'Alira');
        await seedCharacter(session, id: 'c-antag', name: 'Bravant');
        await repoOf(session).saveAssignment(
          NarrativeAssignment(
            novelWorkspaceId: 'novel-1',
            characterId: 'c-protag',
            roles: {NarrativeRole.protagonist},
            importance: NarrativeImportance.major,
            pov: NarrativePov.yes,
          ),
        );
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

      List<String> visibleNames() => [
        'Alira',
        'Bravant',
      ].where((name) => characterTile(name).evaluate().isNotEmpty).toList();

      expect(visibleNames(), ['Alira', 'Bravant']);

      // Apply a protagonist filter first, so dismissal has something to lose.
      await openFilterMenu(tester);
      await tester.tap(find.text('All roles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Protagonist').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(visibleNames(), ['Alira']);

      // Re-open the dialog and tap the barrier (dismiss -> null result).
      await openFilterMenu(tester);
      expect(find.text('Filter Characters'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Filter Characters'), findsNothing);

      // The active filter must survive the accidental dismissal.
      expect(visibleNames(), ['Alira']);

      // Explicit Reset keeps working: clears the filter.
      await openFilterMenu(tester);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(visibleNames(), ['Alira', 'Bravant']);

      // Dismissal with unsaved dropdown changes neither applies nor clears:
      // change the dropdown, dismiss, and the unfiltered state persists.
      await openFilterMenu(tester);
      await tester.tap(find.text('All roles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Antagonist').last);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(visibleNames(), ['Alira', 'Bravant']);

      expect(tester.takeException(), isNull);
    },
  );
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}
