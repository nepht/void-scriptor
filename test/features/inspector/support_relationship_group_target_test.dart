import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/inspector/presentation/widgets/support_relationship_section.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// BUG-17: the domain + backlog say "supported character/group" but the
/// picker offers only character assets, so faction/group targets cannot be
/// created through the UI. Phase-one scope already includes group (not
/// explicitly deferred) → complete the feature via the existing Faction
/// vocabulary rather than treating it as a docs-only cut.
void main() {
  Future<(ProjectPackage, ProjectSession, String)> seed(
    WidgetTester tester,
    String name, {
    required bool withFaction,
  }) async {
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    late String qId;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('support-group-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Support Group $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      qId = (await repo.createCharacter(name: 'Qowner')).assetId;
      await repo.createCharacter(name: 'Byte');
      final now = DateTime.now();
      const novelId = 'novel-first';
      await session.database
          .into(session.database.assets)
          .insert(
            AssetsCompanion.insert(
              id: novelId,
              projectId: package.projectId,
              name: 'First Novel',
              type: 'story',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await session.database
          .into(session.database.stories)
          .insert(
            StoriesCompanion.insert(
              assetId: novelId,
              projectId: package.projectId,
              title: 'First Novel',
            ),
          );
      if (withFaction) {
        const factionAssetId = 'faction-sentinels';
        await session.database
            .into(session.database.assets)
            .insert(
              AssetsCompanion.insert(
                id: factionAssetId,
                projectId: package.projectId,
                name: 'Sentinels',
                type: 'faction',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await session.database
            .into(session.database.factions)
            .insert(
              FactionsCompanion.insert(
                assetId: factionAssetId,
                projectId: package.projectId,
                name: 'Sentinels',
              ),
            );
      }
    });
    return (package, session, qId);
  }

  Future<void> pumpInspector(
    WidgetTester tester,
    ProjectSession session,
    String characterId,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
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
              width: 1280,
              height: 900,
              child: SupportRelationshipSection(assetId: characterId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'group-target picker exposes faction assets alongside characters (BUG-17)',
    (tester) async {
      final (package, session, qId) = await seed(
        tester,
        'picker',
        withFaction: true,
      );
      addTearDown(() {});
      await pumpInspector(tester, session, qId);
      await tester.tap(find.widgetWithText(TextButton, 'Add Support'));
      await tester.pumpAndSettle();

      // Open the supported-target dropdown menu: character Byte and faction
      // 'Group: Sentinels' must both be offered as targets (BUG-17).
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      expect(find.text('Byte'), findsOneWidget);
      expect(find.text('Group: Sentinels'), findsOneWidget);
    },
  );

  testWidgets(
    'faction-supported row resolves faction name instead of raw UUID (BUG-17)',
    (tester) async {
      final (package, session, qId) = await seed(
        tester,
        'row',
        withFaction: true,
      );
      await NarrativeAssignmentRepository(
        database: session.database,
        projectId: package.projectId,
      ).saveSupport(
        SupportRelationship(
          sourceCharacterId: qId,
          supportedId: 'faction-sentinels',
          storyNovelWorkspaceId: 'novel-first',
          type: SupportType.supporter,
          duration: SupportDuration.permanent,
          status: SupportStatus.active,
        ),
      );
      await pumpInspector(tester, session, qId);
      expect(find.textContaining('Sentinels'), findsOneWidget);
      expect(find.textContaining('faction-sentinels'), findsNothing);
    },
  );

  testWidgets('dialog still opens when only a group exists (BUG-17)', (
    tester,
  ) async {
    // BUG-14 contract guards the no-characters state, but with a group
    // (faction) present the dialog must open normally — groups are valid
    // support targets.
    final (package, session, qId) = await seed(
      tester,
      'group-only',
      withFaction: true,
    );
    // Remove Byte's asset row (picker source) so only the faction remains.
    await (session.database.delete(
      session.database.assets,
    )..where((row) => row.id.equals('char-byte'))).go();
    await pumpInspector(tester, session, qId);
    await tester.tap(find.widgetWithText(TextButton, 'Add Support'));
    await tester.pumpAndSettle();

    expect(find.text('Add Support'), findsWidgets);
    expect(find.textContaining('No other characters exist yet'), findsNothing);
    expect(
      find.byType(DropdownButtonFormField<String>),
      findsAtLeastNWidgets(2),
    );
  });
}
