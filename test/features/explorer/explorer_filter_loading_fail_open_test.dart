import 'dart:async';
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
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

/// Regression for hunt-20260910 run171 BUG-12 (Referee REAL BUG Low).
///
/// With an active narrative filter while `explorerNarrativeAssignmentsProvider`
/// is still loading, the old code filtered against `valueOrNull ?? const []`
/// (empty list) and rendered zero character tiles with no loading indicator —
/// a transient edge case distinct from the handled `assignmentError` path.
///
/// Contract:
/// - While assignments are loading and a filter is active, the list fails
///   open to the full character list (degraded mode, never empty).
void main() {
  Future<ProjectSession> createSession() async {
    final root = await Directory.systemTemp.createTemp('filter-loading-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Filter loading project');
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

  testWidgets(
    'active role filter while assignments loading fails open (not zero tiles)',
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

      // Keep assignments in loading forever via an uncompleted completer.
      final assignmentsCompleter = Completer<List<NarrativeAssignment>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _FixedSession(session)),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: Directory.systemTemp),
            ),
            explorerNarrativeAssignmentsProvider.overrideWith(
              (ref) => assignmentsCompleter.future,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SizedBox(width: 320, child: ExplorerPanel())),
          ),
        ),
      );
      await tester.pump();
      // Allow the FutureProvider to enter loading.
      await tester.pump(const Duration(milliseconds: 100));

      await applyProtagonistFilter(tester);

      // RED (pre-patch): filter active + loading -> empty list (both gone).
      expect(
        characterTile('Alira'),
        findsOneWidget,
        reason: 'while assignments load, active filter must fail open',
      );
      expect(characterTile('Bravant'), findsOneWidget);
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
