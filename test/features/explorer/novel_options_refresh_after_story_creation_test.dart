import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/features/character/presentation/widgets/narrative_assignment_card.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/inspector/presentation/widgets/support_relationship_section.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

class _SessionOverride extends ProjectSessionController {
  _SessionOverride(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// hunt-run157 BUG-05 (Referee REAL BUG Medium): the novel-option providers
/// behind the Narrative Assignment and Support Relationship dropdowns derive
/// from asset snapshots that no story-creation path invalidates, so a novel
/// created mid-session stays missing from both dropdowns until an unrelated
/// action rebuilds the graph. The contract locked here: creating a story on
/// EITHER creation surface (Explorer create dialog, ProjectOverview
/// "Create Novel") makes it selectable as story context in the SAME session.
///
/// Async-zone note (proven during RED diagnosis): every tap that launches the
/// real create chain (dialogs, services, Drift + filesystem awaits) must run
/// inside `tester.runAsync`; continuations of a future created in the fake
/// zone never resume against real I/O. Mirrors the proven pattern in
/// test/features/workspace/empty_workspace_navigation_test.dart.
void main() {
  Future<(Directory, ProjectSession)> seed(WidgetTester tester) async {
    late Directory root;
    late ProjectSession session;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('novel-options-refresh-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Novel Options Refresh');
      session = await ProjectSessionManager().open(package);
    });
    addTearDown(() async {
      await session.close();
      await root.delete(recursive: true);
    });
    return (root, session);
  }

  /// Materializes both option providers so a stale cache is observable in
  /// the tree: the counter shows the provider's CURRENT cached snapshot.
  Widget optionCounters() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Consumer(
        builder: (context, ref, _) => Text(
          'NARRATIVE_NOVELS:${ref.watch(narrativeNovelOptionsProvider).valueOrNull?.length}',
        ),
      ),
      Consumer(
        builder: (context, ref, _) => Text(
          'SUPPORT_NOVELS:${ref.watch(supportNovelOptionsProvider).valueOrNull?.length}',
        ),
      ),
    ],
  );

  /// Drives the shared Create dialog (type+name+Create) for both surfaces:
  /// Explorer `Create Asset` and ProjectOverview `Create Novel` use the same
  /// dialog skeleton with a single name TextField and a Create FilledButton.
  Future<void> submitCreateDialog(
    WidgetTester tester,
    ProviderContainer container,
    String novelName,
  ) async {
    await tester.enterText(find.byType(TextField), novelName);
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      for (
        var i = 0;
        i < 100 && container.read(selectionProvider) == null;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> expectNovelVisible(
    WidgetTester tester,
    ProviderContainer container,
    ProjectSession session,
  ) async {
    expect(
      find.text('NARRATIVE_NOVELS:1'),
      findsOneWidget,
      reason:
          'BUG-05: a story created mid-session must be selectable as '
          'narrative assignment context without an unrelated rebuild',
    );
    expect(
      find.text('SUPPORT_NOVELS:1'),
      findsOneWidget,
      reason:
          'BUG-05: a story created mid-session must be selectable as '
          'support relationship context without an unrelated rebuild',
    );
    await tester.runAsync(() async {
      final stories = (await session.database.assetDao.getAllAssets())
          .where((asset) => asset.type == 'story')
          .toList();
      expect(stories, hasLength(1));
    });
    expect(tester.takeException(), isNull);
    expect(container.read(selectionProvider)?.assetType, AssetType.story);
  }

  testWidgets('explorer story creation refreshes novel-option providers', (
    tester,
  ) async {
    final (root, session) = await seed(tester);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _SessionOverride(session)),
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: root),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return Column(
                  children: [
                    TextButton(
                      onPressed: () => createExplorerAsset(
                        context,
                        ref,
                        fixedType: AssetType.story,
                      ),
                      child: const Text('CREATE-STORY'),
                    ),
                    optionCounters(),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('NARRATIVE_NOVELS:0'), findsOneWidget);
    expect(find.text('SUPPORT_NOVELS:0'), findsOneWidget);

    await tester.runAsync(() => tester.tap(find.text('CREATE-STORY')));
    await tester.pumpAndSettle();
    await submitCreateDialog(tester, container, 'Void Cube Novel');
    await expectNovelVisible(tester, container, session);
  });

  testWidgets('overview onCreateNovel refreshes novel-option providers', (
    tester,
  ) async {
    final (root, session) = await seed(tester);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _SessionOverride(session)),
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: root),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return Column(
                  children: [
                    const Expanded(child: WorkspaceResolver()),
                    optionCounters(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Novel Workspace'), findsOneWidget);
    expect(find.text('NARRATIVE_NOVELS:0'), findsOneWidget);
    expect(find.text('SUPPORT_NOVELS:0'), findsOneWidget);

    await tester.runAsync(() => tester.tap(find.text('Create Novel')));
    await tester.pumpAndSettle();
    await submitCreateDialog(tester, container, 'Void Cube Novel');
    await expectNovelVisible(tester, container, session);
  });
}
