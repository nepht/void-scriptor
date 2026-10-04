import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

class _SessionOverride extends ProjectSessionController {
  _SessionOverride(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// hunt-run171 BUG-9 (Referee REAL BUG Medium) — production wiring layer.
/// The service-level atomicity lives in novel_creation_atomicity_test.dart;
/// this file locks that BOTH creation surfaces (ProjectOverview "Create
/// Novel" through workspace_resolver, and the Explorer create dialog through
/// createExplorerAsset) go through the atomic operation: when the scene
/// insert fails mid-chain, the user sees the existing failure snackbar AND
/// no orphaned story/chapter rows survive, so a retry cannot duplicate the
/// novel.
///
/// Async-zone note (proven in run159): every tap that launches the real
/// create chain must run inside tester.runAsync against real I/O.
void main() {
  Future<(Directory, ProjectSession)> seed(WidgetTester tester) async {
    late Directory root;
    late ProjectSession session;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('novel-atomic-ui-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Novel Atomicity UI');
      session = await ProjectSessionManager().open(package);
    });
    addTearDown(() async {
      await session.close();
      await root.delete(recursive: true);
    });
    return (root, session);
  }

  Future<void> injectSceneInsertFailure(
    WidgetTester tester,
    ProjectSession session,
  ) async {
    await tester.runAsync(
      () => session.database.customStatement(
        'CREATE TRIGGER story_scene_insert_abort '
        'BEFORE INSERT ON story_scenes '
        'BEGIN SELECT RAISE(ABORT, \'injected scene insert failure\'); END',
      ),
    );
  }

  Future<void> expectCommittedStoryRows(
    WidgetTester tester,
    ProjectSession session,
    int expected,
  ) async {
    await tester.runAsync(() async {
      final stories = await session.database
          .select(session.database.stories)
          .get();
      expect(stories, hasLength(expected));
    });
  }

  Future<void> submitCreateDialog(WidgetTester tester, String novelName) async {
    await tester.enterText(find.byType(TextField), novelName);
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'overview Create Novel rolls back all rows when scene insert fails',
    (tester) async {
      final (root, session) = await seed(tester);
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(
              () => _SessionOverride(session),
            ),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: root),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Novel Workspace'), findsOneWidget);

      await injectSceneInsertFailure(tester, session);
      await tester.runAsync(() => tester.tap(find.text('Create Novel')));
      await tester.pumpAndSettle();
      await submitCreateDialog(tester, 'Void Cube Novel');

      expect(find.text('Novel gagal dibuat. Coba lagi.'), findsOneWidget);
      expect(find.text('Novel created.'), findsNothing);
      await expectCommittedStoryRows(tester, session, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'explorer Create Asset story rolls back all rows when scene insert fails',
    (tester) async {
      final (root, session) = await seed(tester);
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(
              () => _SessionOverride(session),
            ),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: root),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  // Watch (not just read) so the session resolves before the
                  // tap; createExplorerAsset's ref.read needs the settled
                  // value (mirrors run159's optionCounters warm-up).
                  final ready =
                      ref.watch(projectSessionProvider).value != null;
                  return Column(
                    children: [
                      Text('SESSION_READY:$ready'),
                      TextButton(
                        onPressed: () => createExplorerAsset(
                          context,
                          ref,
                          fixedType: AssetType.story,
                        ),
                        child: const Text('CREATE-STORY'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SESSION_READY:true'), findsOneWidget);

      await injectSceneInsertFailure(tester, session);
      await tester.runAsync(() => tester.tap(find.text('CREATE-STORY')));
      await tester.pumpAndSettle();
      await submitCreateDialog(tester, 'Void Cube Novel');

      expect(
        find.text(
          'Aset gagal dibuat. Periksa akses penyimpanan dan coba lagi.',
        ),
        findsOneWidget,
      );
      await expectCommittedStoryRows(tester, session, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
